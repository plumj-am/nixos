{
  config.flake.modules.hjem.zoxide = {
    rum.programs.zoxide = {
      enable = true;

      flags = [ "--cmd cd" ];

      integrations.nushell.enable = true;
    };
  };
}
