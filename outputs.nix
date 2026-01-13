inputs:
inputs.parts.lib.mkFlake { inherit inputs; } {
  imports = [
    ./modules/flake-inputs.nix
    (inputs.import-tree ./modules)
  ];
}
