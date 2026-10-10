{ self, ... }:
{
  flake.modules.nixos.s3 = self.modules.nixos.s3-options;
  flake.modules.nixos.s3-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) attrs str;
    in
    {
      options.s3 = {
        caches = mkOptionOf attrs {
          default = { };
          defaultText = "Shared S3 caches configuration";
          description = "S3 caches keyed by name (garage).";
        };
        credentialsFile = mkOptionOf str {
          default = "/var/lib/s3/.aws/credentials";
          description = "Shared S3 credentials file";
        };
      };
    };
}
