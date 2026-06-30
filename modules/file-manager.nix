{
  flake.modules.nixos.file-manager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.trivial) const flip;
    in
    {
      environment.systemPackages = [
        pkgs.thunar
        pkgs.thunar-volman
        pkgs.thunar-archive-plugin
        pkgs.thunar-media-tags-plugin
        pkgs.thunar-vcs-plugin

        pkgs.tumbler # thumbnails

        # I would like to use but it's a pain for xdg...FileOpener.
        # Skill issue, perhaps.
        # pkgs.kdePackages.dolphin
        pkgs.kdePackages.ark
      ];

      # Thanks again twitter:HSVSphere github:RGBCube
      hjem.extraModule = {
        xdg.mime-apps.default-applications =
          flip genAttrs (const "thunar.desktop") [
            "inode/directory"
          ]
          // flip genAttrs (const "org.kde.ark.desktop") [
            # LIBARCHIVE (READ-WRITE)
            "application/x-tar"
            "application/x-compressed-tar"
            "application/x-bzip-compressed-tar"
            "application/x-bzip2-compressed-tar"
            "application/x-tarz"
            "application/x-xz-compressed-tar"
            "application/x-lzma-compressed-tar"
            "application/x-lzip-compressed-tar"
            "application/x-tzo"
            "application/x-lrzip-compressed-tar"
            "application/x-lz4-compressed-tar"
            "application/x-zstd-compressed-tar"
            "application/x-7z-compressed"

            # LIBARCHIVE (READ-ONLY)
            "application/x-deb"
            "application/x-cd-image"
            "application/x-bcpio"
            "application/x-cpio"
            "application/x-cpio-compressed"
            "application/x-sv4cpio"
            "application/x-sv4crc"
            "application/x-rpm"
            "application/x-compress"
            "application/gzip"
            "application/x-bzip"
            "application/x-bzip2"
            "application/x-lzma"
            "application/x-xz"
            "application/zlib"
            "application/zstd"
            "application/x-lz4"
            "application/x-lzip"
            "application/x-lrzip"
            "application/x-lzop"
            "application/x-source-rpm"
            "application/vnd.debian.binary-package"
            "application/vnd.efi.iso"
            "application/vnd.ms-cab-compressed"
            "application/x-xar"
            "application/x-iso9660-appimage"
            "application/x-archive"

            # ZIP
            "application/zip"
            "application/x-java-archive"

            # RAR
            "application/vnd.rar"

            # ARJ
            "application/x-arj"
            "application/arj"

            # UNARCHIVER
            "application/x-lha"
            "application/x-stuffit"
          ];
      };
    };
}
