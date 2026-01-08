{ config, pkgs, lib, ... }: let
  inherit (lib) mkIf;
in
{
  config.theme.font = {
    size.small  = 12;
    size.term   = 12;
    size.normal = 16;
    size.big    = 20;

    # mono.name    = "JetBrainsMono Nerd Font Mono";
    # mono.family  = "JetBrainsMono Nerd Font";
    # mono.package = pkgs.nerd-fonts.jetbrains-mono;

    # mono.name    = "Fira Code Nerd Font Mono";
    # mono.family  = "Fira Code Nerd Font";
    # mono.package = pkgs.nerd-fonts.fira-code;

    # mono.name    = "Hasklug Nerd Font Mono";
    # mono.family  = "Hasklug Nerd Font";
    # mono.package = pkgs.nerd-fonts.hasklug;

    # mono.name    = "Iosevka Nerd Font Mono";
    # mono.family  = "Iosevka Nerd Font";
    # mono.package = pkgs.nerd-fonts.iosevka;

    # mono.name    = "Cascadia Code NF";
    # mono.family  = "Cascadia Code";
    # mono.package = pkgs.cascadia-code;

    # mono.name    = "Hack Nerd Font Mono";
    # mono.family  = "Hack Nerd Font";
    # mono.package = pkgs.nerd-fonts.hack;

    mono.name    = "Maple Mono NF";
    mono.family  = "Maple Mono";
    mono.package = pkgs.maple-mono.NF;

    sans.name    = "Lexend";
    sans.family  = "Lexend";
    sans.package = pkgs.lexend;
  };

  # Virtual console for login.
  config.console = {
    earlySetup = true;
    font       = "Lat2-Terminus16";
    packages   = [ pkgs.terminus_font ];
  };

  config.fonts.fontconfig.enable = mkIf (!config.useTheme) true;

  config.fonts.packages = mkIf config.useTheme [
    config.theme.font.mono.package
    config.theme.font.sans.package

    # Fallback for emojis and icons.
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-lgc-plus
    pkgs.noto-fonts-color-emoji
  ];
}

