{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  helium-browser = let
    version = "0.6.3.1";

    # I don't care about aarch64 because I have no aarch64 machines.
    # Keep that in mind if you're copying this.
    arch = if config.isLinux then {
      arch = "x86_64";
      hash = "sha256:37b2692cb39db2762ecd8ade37589a1c8f7dd8c4764ae5d39971df6ba7ddd545";
    } else null;
  in
  if arch == null then null else
  pkgs.appimageTools.wrapType2 {
    pname = "helium-browser";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${arch.arch}.AppImage";
      inherit (arch) hash;
    };
  };
in {
  home-manager.sharedModules = mkIf (config.isDesktopNotWsl && helium-browser != null) [{
    home.packages = [ helium-browser ];

    xdg.desktopEntries.helium-browser = {
      name     = "Helium Browser";
      icon     = "helium-browser";
      exec     = "helium-browser";
      terminal = false;
    };
  }];
}
