{
  flake.modules.common.disable-nix-documentation = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
}
