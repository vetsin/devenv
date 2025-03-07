{ pkgs, inputs, ... }: {
  env.TEST = "op://MyVault/unit test/username";
  onepassword = {
    enabled = true;
    wrapped = [ "printenv" ];
  };
}
