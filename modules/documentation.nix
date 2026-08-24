{ self, ... }:
{
  flake.modules.common.default = self.modules.common.documentation;
  flake.modules.common.documentation = {
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
}
