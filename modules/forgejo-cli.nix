{
  flake.modules.nixos.forgejo-cli =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.age) secrets;
    in
    {
      config = {
        age.secrets.forgejoCliConfig = {
          rekeyFile = ../secrets/forgejo-cli-config.age;
          owner = "jam";
          mode = "600";
        };

        hjem.extraModule = {
          packages = singleton pkgs.forgejo-cli;

          xdg.data.files."forgejo-cli/keys.json".source = secrets.forgejoCliConfig.path;
        };
      };
    };
}
