{ self, ... }:
{
  flake.commonModules.default = self.commonModules.documentation;
  flake.commonModules.documentation = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
}
