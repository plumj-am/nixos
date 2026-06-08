{
  description = "PlumJam's NixOS Configuration Collection";

  outputs =
    { self, ... }@args:
    let
      tackInputs = (import ./.tack) {
        overrides = args.tackOverrides or { };
      };
      # Strip tack's functor so it's a plain attrset of pins.
      pins = removeAttrs tackInputs [ "__functor" ];
      # flake-parts builds inputs' from self.inputs - since the flake
      # declares no inputs, inject tack pins so inputs'.os still works
      selfWithInputs = self // {
        inputs = pins;
      };
      inputs = pins // {
        self = selfWithInputs;
      };
    in
    import ./outputs.nix inputs;
}
