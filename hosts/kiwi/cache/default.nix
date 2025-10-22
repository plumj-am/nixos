{ self, config, lib, pkgs, ... }: let
  inherit (lib) enabled merge;

  cacheDomain = "plumj.am";
  fqdn = "cache2.${cacheDomain}";
  portNixServe = 8007;
in {
  imports = [(self + /modules/nginx.nix)];

  age.secrets.nixServeKey = {
    rekeyFile = ./key.age;
    owner     = "root";
  };

  services.nix-serve = enabled {
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.age.secrets.nixServeKey.path;

    bindAddress = "127.0.0.1";
    port = portNixServe;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."= /".return = "301 https://${cacheDomain}/404";
    locations."/".proxyPass = "http://127.0.0.1:${toString portNixServe}";
  };
}
