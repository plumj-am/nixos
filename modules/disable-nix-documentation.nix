let
  documentationBase = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
in
{
  flake.modules.nixos.disable-nix-documentation = documentationBase;
  flake.modules.darwin.disable-nix-documentation = documentationBase;
}
