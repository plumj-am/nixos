{ self, config, lib, ... }: let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  fqdn = domain;
  root = "/var/www/site";
in {
  imports = [(self + /modules/nginx.nix)];

  services.nginx = enabled {
    appendHttpConfig = /* nginx */ ''
      # cache only successful responses
      map $status $cache_header {
        200     "public";
        302     "public";
        default "no-cache";
      }
    '';

    virtualHosts."www.${fqdn}" = merge config.services.nginx.sslTemplate {
      locations."/".return = "301 https://${fqdn}$request_uri";
    };

    virtualHosts._ = merge config.services.nginx.sslTemplate {
      locations."/".return = "301 https://${fqdn}/404";
    };

		# site not ready yet
		virtualHosts.${domain} = lib.merge config.services.nginx.sslTemplate {
			# inherit root;
			extraConfig = ''
				proxy_set_header Accept-Encoding "";
				sub_filter "</head>" '<script data-goatcounter="https://analytics.${domain}/count" async src="https://analytics.${domain}/count.js"></script></head>';
				sub_filter_last_modified on;
				sub_filter_once on;
			'';
			locations."/".return = "404";
  };
  };
}
