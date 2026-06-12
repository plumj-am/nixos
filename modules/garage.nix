{
  flake.modules.nixos.garage =
    {
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain;

      secrets = config.age.secrets;

      fqdnS3 = "s3.${domain}";
      fqdnWebUI = "cdn.${domain}";
      portS3 = 8015;
      portWebUI = 8016;
      portRPC = 8017;
    in
    {
      age.secrets.garageEnvironment.rekeyFile = ../secrets/garage-environment.age;

      services.garage = {
        enable = true;
        package = pkgs.garage_2;

        environmentFile = secrets.garageEnvironment.path;

        settings = {
          data_dir = singleton {
            capacity = "1.25T";
            path = "/var/lib/garage/data";
          };

          replication_factor = 1;
          consistency_mode = "consistent";

          metadata_fsync = true;
          data_fsync = true;

          rpc_bind_addr = "[::]:${toString portRPC}";

          s3_api = {
            s3_region = "garage";

            api_bind_addr = "[::]:${toString portS3}";
            root_domain = fqdnS3;
          };

          s3_web = {
            bind_addr = "[::]:${toString portWebUI}";
            root_domain = fqdnWebUI;
          };
        };
      };

      services.nginx.virtualHosts.${fqdnS3} = merge config.services.nginx.sslTemplate {
        extraConfig = # nginx
          ''
            client_max_body_size 5g;
          '';
        locations."/".proxyPass = "http://[::1]:${toString portS3}";
      };

      services.nginx.virtualHosts.${fqdnWebUI} = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://[::1]:${toString portWebUI}";
      };
    };
}
