{
  flake.modules.nixos.website-plumjam =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
      inherit (config.networking) domain;

      fqdn = domain;

      normalPort = 8003;
      nerdPort = 8004;

      csp =
        scriptSources:
        # kdl
        ''
          header -Content-Security-Policy
          header +Content-Security-Policy "script-src ${scriptSources}; script-src-elem ${scriptSources}; img-src 'self' data: https: ghchart.rshah.org;"
        '';

      normalCsp = csp "'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain}";
      nerdCsp = csp "'self' 'unsafe-inline' 'unsafe-eval' ${domain} *.${domain} kit.fontawesome.com https://kit.fontawesome.com";

      proxiedVhost =
        port: cspKdl:
        # kdl
        ''
          ${config.services.ferron.headers}
          ${cspKdl}
          ${config.services.ferron.goatCounterTemplate}

          location "/" {
              proxy "http://127.0.0.1:${toString port}" {
                  # The GoatCounter template rewrites the response body, so the
                  # upstream must answer uncompressed.
                  request_header -Accept-Encoding
              }
          }
        '';
    in
    {
      imports = singleton inputs.plumj-am.nixosModules.default;

      services.plumjam-website.sites = {
        normal = {
          enable = true;
          port = normalPort;
        };
        nerd = {
          enable = true;
          port = nerdPort;
        };
      };

      services.ferronVhosts = {
        # Redirect www.plumj.am to plumj.am
        "www.${fqdn}" = merge config.services.ferron.sslTemplate {
          config = # kdl
            ''
              status 301 {
                  location "https://${fqdn}{{request.uri}}"
              }

              ${config.services.ferron.headers}
            '';
        };

        "nerd.${fqdn}" = merge config.services.ferron.sslTemplate {
          config = proxiedVhost nerdPort nerdCsp;
        };

        ${fqdn} = merge config.services.ferron.sslTemplate {
          config = proxiedVhost normalPort normalCsp;
        };
      };
    };
}
