{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.forgejo-cli;
  flake.modules.nixos.forgejo-cli =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;
    in
    {
      sops.secrets."forgejo-cli/config" = {
        sopsFile = ../secrets/services/forgejo.yaml;
        owner = "jam";
        mode = "600";
      };

      shellAliases.fj = "fj --host https://git.plumj.am";

      environment.systemPackages = singleton pkgs.forgejo-cli;

      hjemModule = {
        xdg.data.files."forgejo-cli/keys.json".source = secrets."forgejo-cli/config".path;
      };
    };
}
