_: self: _: let
  inherit (self) merge mkMerge;
in {
  # creates a mergeable attribute set that can be called as a function
  # allows syntax like: merge { option1 = value1; } <| conditionalOptions
  merge = mkMerge [] // {
    __functor = self: next: self // {
      contents = self.contents ++ [ next ];
    };
  };

  # convenience functions for common enable patterns
  enabled  = merge { enable = true; };
  disabled = merge { enable = false; };
}