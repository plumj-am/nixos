{ self, config, lib, pkgs, ... }: let
  inherit (config.networking) domain;

  fqdn = "chat.${domain}";
in {
  imports = [ (self + /modules/nginx.nix) ];

  services.nginx.virtualHosts.${fqdn} = lib.merge config.services.nginx.sslTemplate {
    root = pkgs.element-web;

    locations."= /config.json".extraConfig = ''
      default_type application/json;
      return 200 '${builtins.toJSON {
        default_server_config."m.homeserver" = {
					base_url    = "https://matrix.${domain}";
					server_name = domain;
				};
        brand = "chat.plumj.am";

        disable_3pid_login              = true;
        disable_login_language_selector = true;
				disable_guests                  = true;

        bug_report_endpoint_url = null;

        show_labs_settings = true;
        features           = {
          feature_pinning        = "labs";
          feature_custom_status  = "labs";
          feature_custom_tags    = "labs";
          feature_state_counters = "labs";
        };

        default_federate = true;

        default_theme = "light";

        room_directory.servers = [ domain "matrix.org" ];

        enable_presence_by_hs_url = {
          "https://matrix.org"               = false;
          "https://matrix-client.matrix.org" = false;
        };
        setting_defaults.breadcrumbs = true;
      }}';
    '';

    # spa routing serves index.html for all routes
    locations."/".tryFiles = "$uri $uri/ /index.html";

    # static assets caching
    locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$".extraConfig = ''
			expires 1y;
		'';
  };
}
