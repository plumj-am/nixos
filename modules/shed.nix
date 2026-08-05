{
  flake.modules.nixos.shed =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton length;
      inherit (lib.fixedPoints) fix;
      inherit (config.s3) fsn1;

      # Same shared args as `./s3-upload.nix`.
      s3SharedArgs = "&priority=43&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";
      fsn1S3Cache = "s3://plumjam/nix?endpoint=fsn1.your-objectstorage.com&profile=${fsn1.alias}${s3SharedArgs}";
    in
    {
      imports = singleton inputs.grove.nixosModules.shed;

      services.shed = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.shed;

        state_dir = "/var/lib/shed";

        config = fix (config: {
          cache_urls = [
            fsn1S3Cache
            # TODO: Garage has been returning "is not supported" for narinfo
            # PUTs; disabled until fixed.
          ];
          scan_interval_secs = 6 * 3600;
          min_size_bytes = 10240;
          min_caches_to_evict = length config.cache_urls;
        });
      };

      # Shed runs `nix copy --to s3://...?profile=<alias>`. Nix resolves the
      # profile via $AWS_SHARED_CREDENTIALS_FILE - the shared file is
      # materialised by the `s3` aspect (s3-credentials.service).
      systemd.services.shed = {
        serviceConfig.SupplementaryGroups = [ "s3" ];
        environment.AWS_SHARED_CREDENTIALS_FILE = config.s3.credentialsFile;
      };
    };
}
