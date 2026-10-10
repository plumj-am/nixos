{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.rustic;
  flake.modules.nixos.rustic =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      inherit (config.s3.caches.garage)
        alias
        endpoint
        region
        ;
    in
    {
      imports = singleton self.services.rustic;

      sops.secrets."rustic/password".sopsFile = ../secrets/services/rustic.yaml;

      services.rustic = {
        inherit
          alias
          endpoint
          region
          ;
        # The garage cache bucket ("nix") is a shed binary
        # cache: shed evicts from cache_urls, so backups
        # written there would be silently dropped. Use the
        # dedicated "backups" bucket garage-bootstrap
        # provisions instead.
        bucket = "backups";
        credentialsFile = config.s3.credentialsFile;
        passwordFile = config.sops.secrets."rustic/password".path;
      };
    };
}
