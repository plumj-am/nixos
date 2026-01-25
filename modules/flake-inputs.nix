{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  flake-file = {
    description = "PlumJam's NixOS Configuration Collection";

    inputs = {
      flake-file = {
        url = "github:vic/flake-file";
      };

      import-tree = {
        url = "github:vic/import-tree";
      };
    };
  };
}
