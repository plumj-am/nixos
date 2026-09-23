{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.video-player;
  flake.modules.nixos.video-player =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.trivial) const flip;
    in
    {
      hjem.extraModule = {
        xdg.mime-apps.default-applications =
          mkIf config.nixpkgs.hostPlatform.isLinux
          <| flip genAttrs (const "org.kde.haruna.desktop") [
            "audio/aac"
            "audio/ac3"
            "audio/flac"
            "audio/mp4"
            "audio/mpeg"
            "audio/ogg"
            "audio/vnd.wave"
            "audio/webm"
            "audio/x-matroska"
            "audio/x-mpegurl"
            "video/mp2t"
            "video/mp4"
            "video/mpeg"
            "video/ogg"
            "video/quicktime"
            "video/vnd.avi"
            "video/webm"
            "video/x-matroska"
            "video/x-ms-wmv"
          ];

        packages = singleton pkgs.haruna;
      };
    };
}
