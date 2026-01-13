{ inputs, ... }:
{
  config.flake-file.inputs = {
    parts = {
      url = "github:hercules-ci/flake-parts";

      inputs.nixpkgs-lib.follows = "os";
    };
  };

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
