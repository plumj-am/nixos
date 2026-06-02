{
  flake.modules.nixos.acme =
    { config, ... }:
    let
      inherit (config.networking) domain;
      inherit (config.myLib) mkValue;
    in
    {
      options.security.acme.users = mkValue [ ];

      config = {
        age.secrets.acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;

        users.groups.acme.members = config.security.acme.users;

        security.acme = {
          acceptTerms = true;

          defaults = {
            environmentFile = config.age.secrets.acmeEnvironment.path;
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
