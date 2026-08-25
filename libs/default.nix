lib:
let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldl' map;
in
lib.extend (
  final: prev:
  [
    ./constants.nix
    ./generators.nix
    ./modules.nix
    ./options.nix
    ./systems.nix
  ]
  |> map (file: import file { self = final; })
  |> foldl' recursiveUpdate prev
)
