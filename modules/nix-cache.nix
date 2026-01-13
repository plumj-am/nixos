{
  config.flake-file.inputs = {
    harmonia = {
      url = "github:nix-community/harmonia";
      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
      inputs.treefmt-nix.follows = "treefmt";
    };
  };

  config.flake.modules.nixos.nix-cache =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.types) types;
      inherit (config.myLib) merge;
      inherit (config.networking) domain;
      inherit (lib.lists) singleton;

      port = 5000;
    in
    {
      imports = singleton inputs.harmonia.nixosModules.harmonia;

      options.cache = {
        subdomain = lib.mkOption {
          type = types.str;
          example = "cache1";
          description = "Subdomain where the cache will be served";
        };
      };

      config = {
        services.harmonia-dev.daemon = {
          enable = true;
        };

        services.harmonia-dev.cache = {
          enable = true;
          signKeyPaths = singleton config.age.secrets.nixServeKey.path;
        };

        services.nginx.virtualHosts."${config.cache.subdomain}.${domain}" =
          merge config.services.nginx.sslTemplate
            {
              locations."/".proxyPass = "http://127.0.0.1:${toString port}";
            };
      };
    };
}
