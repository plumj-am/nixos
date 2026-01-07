{ self, config, lib, pkgs, ... }: let
  inherit (lib) enabled merge mkIf mkOption types;
  inherit (config.networking) domain;
in {
  imports = [(self + /modules/nginx.nix)];

  options.cache = {
    enable = lib.mkEnableOption "nix-serve cache server";

    fqdn = lib.mkOption {
      type = types.str;
      example = "cache1.example.com";
      description = "Fully qualified domain name for the cache";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8006;
      description = "Port for nix-serve to listen on";
    };

    secretKeyFile = lib.mkOption {
      type = types.path;
      example = "/run/agenix/nixServeKey";
      description = "Path to the secret key file for signing the cache";
    };
  };

  config = mkIf config.cache.enable {
    services.nix-serve = enabled {
      package = pkgs.nix-serve-ng;
      secretKeyFile = config.cache.secretKeyFile;
      bindAddress = "127.0.0.1";
      port = config.cache.port;
    };

    services.nginx.virtualHosts.${config.cache.fqdn} = merge config.services.nginx.sslTemplate {
      locations."= /".return = "301 https://${domain}/404";
      locations."/".proxyPass = "http://127.0.0.1:${toString config.cache.port}";
    };
  };
}
