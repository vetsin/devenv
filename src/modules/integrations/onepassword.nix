{ pkgs, lib, config, ... }:
let
  inherit (lib) mkOption types literalExpression;
  cfg = config.onepassword;
in
{
  options.onepassword = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the op cli";
    };

    package = mkOption {
      type = types.package;
      default = pkgs._1password-cli; # unfree package
      defaultText = literalExpression "pkgs._1password-cli";
      description = "The op package to use.";
    };

    account = mkOption {
      type = types.str;
      default = "";
      description = "A specific account to use for signin";
    };

    wrapped = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "processes/packages to wrap with `op run`";
    };

    envFile = mkOption {
      type = types.str;
      default = "";
      description = "optional .env file to use to inject secrets";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.account != "") {
      env.OP_ACCOUNT = "${cfg.account}";
    })
    (lib.mkIf (cfg.enable) {
      packages = [ cfg.package ];
      # just wrap specific commands, as to limit accidental exposure
      enterShell = ''
        ${lib.toShellVar "OP_WRAPPED" cfg.wrapped}
        for P in "''${OP_WRAPPED[@]}"; do
          alias $P="${cfg.package}/bin/op run ${lib.optionalString (cfg.envFile != "") ''--env-file=${cfg.envFile}''} -- $P"
        done
        ${cfg.package}/bin/op whoami
      '';
    })
  ];
}
