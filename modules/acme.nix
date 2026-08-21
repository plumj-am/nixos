{
  flake.modules.nixos.acme =
    { lib', config, ... }:
    let
      inherit (lib') mkValue;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;
    in
    {
      options.security.acme.users = mkValue [ ];

      config = {
        sops.secrets."acme/environment".sopsFile = ../secrets/services/acme.yaml;

        users.groups.acme.members = config.security.acme.users;

        security.acme = {
          acceptTerms = true;

          defaults = {
            environmentFile = secrets."acme/environment".path;
            dnsProvider = "cloudflare";
            dnsResolver = "1.1.1.1";
            email = "security@${domain}";
          };

          certs.${domain} = {
            extraDomainNames = [ "*.${domain}" ];
            group = "acme";
          };
        };
      };
    };
}
