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
      inherit (config.sops) secrets;
    in
    {
      sops.secrets."forgejo-cli/config" = {
        sopsFile = ../secrets/services/forgejo.yaml;
        owner = "jam";
        mode = "600";
      };

      shellAliases.fj = "fj --host https://git.plumj.am";

      hjem.extraModule = {
        packages = singleton pkgs.forgejo-cli;

        xdg.data.files."forgejo-cli/keys.json".source = secrets."forgejo-cli/config".path;
      };
    };
}
