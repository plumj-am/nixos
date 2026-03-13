# NOTE: Has various requirements that I cba setting up right now and maybe won't at all.
# NOTE: Hopefully I can find a better solution than this...
# NOTE: <https://explorer.radicle.gr/nodes/seed.radicle.gr/rad:z39Cf1XzrvCLRZZJRUZnx9D1fj5ws/tree/README.md>
{ lib, ... }:
let
  port = 8009;
in
{
  flake.modules.nixos.woodpecker-server =
    {
      pkgs,
      config,
      inputs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config.networking) domain hostName;
      inherit (config.myLib) merge;
      inherit (config.age) secrets;

      fqdn = "ci.${domain}";
      addon = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.radicle-woodpecker-addon;
    in
    {
      assertions = singleton {
        assertion = hostName == "plum";
        message = "The woodpecker-server module should only be used on the 'plum' host, but you're trying to enable it on '${hostName}'.";
      };

      services.woodpecker-server = {
        enable = true;

        environment = {
          WOODPECKER_HOST = "https://${fqdn}";
          WOODPECKER_SERVER_ADDR = "127.0.0.1:${toString port}";
          WOODPECKER_OPEN = "true";
          WOODPECKER_ADMIN = "plumjam";
          WOODPECKER_ADDON_FORGE = getExe addon;
          WOODPECKER_HOST_URL = "https://${fqdn}";
          RADICLE_API_URL = "https://rad.plumj.am";
          RADICLE_BROWSE_URL = "https://rad.plumj.am";
          LOG_LEVEL = "info";
        };

        environmentFile = [
          secrets.woodpeckerAgentSecret.path
          secrets.woodpeckerRadicleHookSecret.path
        ];
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
    };

  flake.modules.nixos.woodpecker-agent =
    { config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) domain hostName;
      inherit (config.age) secrets;

      fqdn = "ci.${domain}";
    in
    {
      services.woodpecker-agents.agents.${hostName} = {
        enable = true;

        environment = {
          WOODPECKER_SERVER = "127.0.0.1:9000";
          WOODPECKER_BACKEND = "docker";
        };

        environmentFile = singleton secrets.woodpeckerAgentSecret.path;

        extraGroups = singleton "docker";
      };

      virtualisation.docker.enable = true;
    };
}
