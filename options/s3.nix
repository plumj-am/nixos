{ self, ... }:
{
  flake.modules.nixos.s3 = self.modules.nixos.s3-options;
  flake.modules.nixos.s3-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) attrs enum str;
    in
    {
      options.s3 = {
        backend =
          mkOptionOf
            (enum [
              "garage"
              "rustfs"
            ])
            {
              default = "garage";
              description = ''
                Object store that backs the shared S3 cache. The cache name
                `garage` is kept for compatibility: switching this option moves
                the endpoint, not the bucket, alias, region, or credentials.
                It does not move objects. The `nix` cache may go cold. The
                `backups` bucket becomes a fresh rustic repository: clear
                `/var/cache/rustic-backups-*` on every backup host before the
                first run, or the stale initialisation marker makes rustic
                refuse to init a new repository.
              '';
            };

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
