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
      inherit (config.sops) secrets;

      # Same cache URLs as `./s3-upload.nix`.
      s3SharedArgs = "&priority=43&multipart-upload=true&multipart-threshold=50M&multipart-chunk-size=10M";

      fsn1Alias = "plumjam-fsn1";
      fsn1S3Cache = "s3://plumjam/nix?endpoint=fsn1.your-objectstorage.com&profile=${fsn1Alias}${s3SharedArgs}";

      garageAlias = "plumjam-garage";
      garageRegion = "garage";
      # garageS3Cache = "s3://nix?endpoint=sloe.taild29fec.ts.net:8015&profile=plumjam-garage&region=${garageRegion}${s3SharedArgs}";
    in
    {
      imports = singleton inputs.shed.nixosModules.shed;
      # imports = singleton inputs.grove.nixosModules.shed;

      sops.secrets = {
        "s3/fsn1/access-key".sopsFile = ../secrets/all/s3.yaml;
        "s3/fsn1/secret-key".sopsFile = ../secrets/all/s3.yaml;
        "s3/garage/access-key".sopsFile = ../secrets/all/s3.yaml;
        "s3/garage/secret-key".sopsFile = ../secrets/all/s3.yaml;
      };

      services.shed = {
        enable = true;
        package = inputs.shed.packages.${pkgs.stdenv.hostPlatform.system}.shed;
        # package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.shed;

        state_dir = "/var/lib/shed";

        config = fix (config: {
          cache_urls = [
            fsn1S3Cache
            # TODO: Garage has been returning "is not supported" for narinfo
            # PUTs; disabled until fixed.
            # garageS3Cache
          ];
          scan_interval_secs = 6 * 3600;
          min_size_bytes = 10240;
          min_caches_to_evict = length config.cache_urls;
        });
      };

      systemd.services.shed = {
        # Shed runs `nix copy --to s3://...?profile=<alias>`. Nix resolves the
        # profile via $AWS_SHARED_CREDENTIALS_FILE - materialise one with an
        # entry per cache from sops secrets at start.
        serviceConfig.ExecStartPre =
          let
            creds = pkgs.writeShellScript "shed-aws-creds" ''
              set -eu
              mkdir -p ${config.services.shed.state_dir}/.aws
              umask 077
              cat > ${config.services.shed.state_dir}/.aws/credentials <<EOF
              [${fsn1Alias}]
              aws_access_key_id=$(cat "$CREDENTIALS_DIRECTORY/s3-fsn1-access-key")
              aws_secret_access_key=$(cat "$CREDENTIALS_DIRECTORY/s3-fsn1-secret-key")
              [${garageAlias}]
              aws_access_key_id=$(cat "$CREDENTIALS_DIRECTORY/s3-garage-access-key")
              aws_secret_access_key=$(cat "$CREDENTIALS_DIRECTORY/s3-garage-secret-key")
              region=${garageRegion}
              EOF
              chown shed:shed ${config.services.shed.state_dir}/.aws/credentials
            '';
          in
          "+${creds}";

        serviceConfig.LoadCredential = [
          "s3-fsn1-access-key:${secrets."s3/fsn1/access-key".path}"
          "s3-fsn1-secret-key:${secrets."s3/fsn1/secret-key".path}"
          "s3-garage-access-key:${secrets."s3/garage/access-key".path}"
          "s3-garage-secret-key:${secrets."s3/garage/secret-key".path}"
        ];

        environment.AWS_SHARED_CREDENTIALS_FILE = "${config.services.shed.state_dir}/.aws/credentials";
      };
    };
}
