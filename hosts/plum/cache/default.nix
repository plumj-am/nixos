{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  fqdn = "cache.${domain}";
  portNixServe = 8006;
in {
  imports = [(self + /modules/nginx.nix)];

  age.secrets.nixServeKey = {
    file = ./key.age;
    owner = "root";
  };

  services.nix-serve = enabled {
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.age.secrets.nixServeKey.path;

    bindAddress = "127.0.0.1";
    port = portNixServe;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."= /".return = "301 https://${domain}/404";
    locations."/".proxyPass = "http://127.0.0.1:${toString portNixServe}";
  };
}
