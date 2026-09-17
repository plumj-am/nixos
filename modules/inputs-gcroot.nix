{ self, ... }:
{
  # https://github.com/RGBCube/ncc/blob/d4039a9d6c8d3a0757517532708f5f18a866482d/modules/inputs-gcroot.mod.nix
  flake.modules.common.default = self.modules.common.inputs-gcroot;
  flake.modules.common.inputs-gcroot =
    { lib, ... }:
    let
      inherit (lib.attrsets) attrValues;
      inherit (lib.lists) elem foldl' singleton;
      inherit (lib.strings) isStorePath;
      inherit (lib.trivial) flip;

      # Some inputs do not resolve to a store path of their own: a relative
      # path input (`path:./some/subdir`) points inside the parent flake's
      # store copy, so coercing it yields `<store>/source/<subdir>`. Nothing
      # extra needs keeping alive there -- the parent's store path is collected
      # anyway -- and `types.package` rejects the value.
      collect =
        collected: parent:
        (parent.inputs or { })
        |> attrValues
        |> flip foldl' collected (
          collected: child:
          let
            value = "${child}";
          in
          if elem value collected || !(isStorePath value) then
            collected
          else
            collect (singleton value ++ collected) child
        );
    in
    {
      hjemModule.extraDependencies = collect [ ] self;
    };
}
