{ self, ... }:
{
  # https://github.com/RGBCube/ncc/blob/d4039a9d6c8d3a0757517532708f5f18a866482d/modules/inputs-gcroot.mod.nix
  flake.modules.common.inputs-gcroot =
    { lib, ... }:
    let
      inherit (lib.attrsets) attrValues;
      inherit (lib.lists) elem foldl' singleton;
      inherit (lib.trivial) flip;

      collect =
        collected: parent:
        (parent.inputs or { })
        |> attrValues
        |> flip foldl' collected (
          collected: child:
          if elem "${child}" collected then collected else collect (singleton "${child}" ++ collected) child
        );
    in
    {
      hjemModule.extraDependencies = collect [ ] self;
    };
}
