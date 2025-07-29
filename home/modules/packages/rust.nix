{ pkgs, fenix, ... }:

{
  home.packages = [
    fenix.packages.${pkgs.system}.complete.toolchain
    pkgs.cargo-binstall
  ];

  home.file."install-cargo-extras.sh" = {
    text = ''
      #!/usr/bin/env bash
      # script to install additional cargo packages not available in nixpkgs
      
      echo "Installing additional cargo packages with cargo-binstall..."
      
      cargo binstall -y \
        cargo-machete \
        bacon-ls \
        dioxus-cli \
        sleek \
        cargo-workspaces \
        cargo-fuzz \
        cargo-careful
      
      echo "Additional cargo packages installed"
    '';
    executable = true;
  };
}

