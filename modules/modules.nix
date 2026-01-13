{ inputs, ... }:
{
  imports = [
    inputs.parts.flakeModules.modules

    {
      perSystem =
        { inputs', ... }:
        {
          _module.args.pkgs = inputs'.os.legacyPackages;
        };
    }
  ];
}
