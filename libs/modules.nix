{ self }:
let
  inherit (self.modules) mkMerge;
in
{
  modules = {
    # Creates a mergeable attribute set that can be called as a function
    # allows syntax like: `lib.modules.merge { option1 = value1; } <| conditionalOptions`
    merge = mkMerge [ ] // {
      __functor =
        self: next:
        self
        // {
          contents = self.contents ++ [ next ];
        };
    };
  };
}
