{ self, ... }:
{
  flake.nixosModules.web-server = self.nixosModules.acme;
  flake.nixosModules.acme =
    {
      config,
      ...
    }:
    let
      inherit (config.networking) domain;
      inherit (config.sops) secrets;
    in
    {
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
