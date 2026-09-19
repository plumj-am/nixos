{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.nuke;
  flake.modules.nixos.nuke =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkForce;
    in
    {
      # original: `[ pkgs.acl pkgs.attr pkgs.bashInteractive pkgs.bzip2 pkgs.coreutils-full pkgs.cpio pkgs.curl pkgs.diffutils pkgs.findutils pkgs.gawk pkgs.getent pkgs.getconf pkgs.gnugrep pkgs.gnupatch pkgs.gnused pkgs.gnutar pkgs.gzip pkgs.xz pkgs.less pkgs.libcap pkgs.ncurses pkgs.netcat pkgs.mkpasswd pkgs.procps pkgs.su pkgs.time pkgs.util-linux pkgs.which pkgs.zstd ]`
      environment.corePackages = mkForce [
        pkgs.acl # pkgs.uutils-acl # Not ready for use yet.
        pkgs.attr
        pkgs.bzip2
        pkgs.bashInteractive
        pkgs.curl
        pkgs.cpio
        pkgs.getent
        pkgs.gawk
        pkgs.getconf
        pkgs.gnugrep
        pkgs.gnupatch
        pkgs.gzip
        pkgs.less
        pkgs.libcap
        pkgs.mkpasswd
        pkgs.ncurses
        pkgs.netcat
        pkgs.su # pkgs.uutil-shadow # Waiting for nixpkgs.
        pkgs.util-linux # pkgs.uutils-util-linux # Not ready for use yet.
        pkgs.uutils-coreutils-noprefix
        pkgs.uutils-diffutils
        pkgs.uutils-findutils
        pkgs.uutils-procps
        pkgs.uutils-sed
        pkgs.uutils-tar
        pkgs.which
        pkgs.xz
        pkgs.zstd
      ];

      environment.defaultPackages = mkForce [ ];

      nixpkgs.overlays = singleton (
        _final: prev: {
          steam = prev.steam.overrideAttrs { nativeOnly = true; };

          # useless
          libbluray = prev.libbluray.override { withJava = false; };
        }
      );
    };
}
