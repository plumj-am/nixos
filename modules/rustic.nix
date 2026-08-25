{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.rustic;
  flake.modules.nixos.rustic =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      inherit (config.s3.caches.garage)
        alias
        bucket
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
          bucket
          endpoint
          region
          ;
        credentialsFile = config.s3.credentialsFile;
        passwordFile = config.sops.secrets."rustic/password".path;
      };
    };
}
