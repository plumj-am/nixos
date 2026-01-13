{ lib, ... }:
{
  options.ciLib = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = ''
      Helper functions for CI workflows
    '';
  };

  config.ciLib.commonPathsIgnore =
    rest:
    [
      "README.md"
      "LICENSE.md"
      ".forgejo/workflows/*"
    ]
    ++ rest;

  config.ciLib.commonConcurrency = name: {
    group = "${name}-\${{ forgejo.ref_name }}";
    cancel-in-progress = false;
  };

  config.ciLib.stepsWithCheckout =
    steps:
    [
      {
        name = "Checkout";
        uses = "actions/checkout@v5";
      }
    ]
    ++ steps;

}
