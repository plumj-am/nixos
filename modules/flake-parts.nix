{ inputs, ... }:
{
  imports = [
    inputs.parts.flakeModules.modules
    {
      debug = true; # For nixd.

      perSystem =
        { inputs', ... }:
        {
          _module.args.pkgs = inputs'.os.legacyPackages;
        };
    }
  ];
}
