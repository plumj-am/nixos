{ pkgs, config, ... }:
let
  aliases = import ./aliases.nix;
  alias_string = builtins.concatStringsSep "\n" (
    builtins.map (
      name: "alias " + name + " = " + aliases.common.${name}
    ) (builtins.attrNames aliases.common)
  );
  nushell_alias_string = builtins.concatStringsSep "\n" (
    builtins.map (
      name: "alias " + name + " = " + aliases.nushellSpecific.${name}
    ) (builtins.attrNames aliases.nushellSpecific)
  );
in
{
  programs.nushell = {
    enable = true;
    configFile.text = alias_string + "\n" + nushell_alias_string + "\n" + 
      (builtins.readFile ./config.nu) + "\n" + 
      (builtins.readFile ./menus.nu) + "\n" + 
      (builtins.readFile ./functions.nu) + "\n" +
      (builtins.readFile ./theme.nu);
    envFile.text = ''
      $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap"
    '';
  };
}
