ZL:KDASJFLKSDJF
  { pkgs, lib, config, ... }:
  let
    inherit (lib) mkOption types;
    cfg = config.devcontainer;
    settingsFormat = pkgs.formats.yaml { };
    file = settingsFormat.generate "teller-from-nix.yml" cfg.settings;

  in
  {
    options.teller = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the teller secret management tool";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.teller;
        defaultText = lib.literalExpression "pkgs.teller";
        description = "The teller package to use.";
      };

      processes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Wrap specific proccesses with teller. If empty, teller secrets will be injected into the environment for all processes.";
        defaultText = lib.literalExpression ''
          [ "your-process" "other-process" ]
        '';
        example = [ "your-process" "other-process" ];
      };

      settingsFile = mkOption {
        type = types.nullOr lib.types.path;
        default = null;
        description = ''
          The teller.yml file path to use as a configuration, if you do not specify settings via the `settings` option.
        '';
        example = lib.literalExpression ''
          ./teller.yml 
        '';
      };

      settings = lib.mkOption {
        type = types.submodules {
          freeformType = settingsFormat.type;

          options.project = mkOption {
            type = types.str;
          };
          options.confirm = mkOption {
            type = types.str;
          };
          options.opts = mkOption {
            type = types.attrs;
          };
          options.providers = mkOption {
            type = types.attrs;
          };
        };

        default = { };


        description = lib.mdDoc ''
          Teller settings defined via nix instead of a yaml file.
        '';
      };


    };

    config = lib.mkMerge [
      (lib.mkIf config.teller.enable {
        assertions = [
          {
            assertion = cfg.settings == { } || cfg.settingsFile == null;
            message = ''
              `teller.settings` and `teller.settingsFile` are both set.
              Only one of the two may be set. Remove one of the two options.
            '';
          }
          {
            assertion = cfg.settings != { } && cfg.settingsFile != null;
            message = ''
              must set either `teller.settings` or `teller.settingsFile`
            '';
          }
        ];

        packages =
          [ cfg.package ]
          ++ lib.optionals
            (cfg.processes != [ ])
            map
            (name:
              pkgs.writeScriptBin name ''
                exec ${cfg.package}/bin/teller --config ${file} run --redact -- ${name}
              '')
            cfg.processes;

      })
      (lib.mkIf (config.teller.enable && cfg.processses == [ ]) {
        enterShell = ''
          eval "$(${cfg.package}/bin/teller --config ${file} sh)"
        '';
      })
    ];
  }
