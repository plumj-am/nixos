{ self, ... }:
{
  flake.nixosModules.s3 = self.nixosModules.s3-options;
  flake.nixosModules.s3-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) attrs enum str;
    in
    {
      options.s3 = {
        backend = mkOption {
          type = enum [
            "garage"
            "rustfs"
          ];
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

        caches = mkOption {
          type = attrs;
          default = { };
          defaultText = "Shared S3 caches configuration";
          description = "S3 caches keyed by name (garage).";
        };
        credentialsFile = mkOption {
          type = str;
          default = "/var/lib/s3/.aws/credentials";
          description = "Shared S3 credentials file";
        };
      };
    };
}
