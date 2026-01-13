{
  flake.modules.nixos.disable-nix-documentation = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };

  flake.modules.darwin.disable-nix-documentation = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
}
