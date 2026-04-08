{
  flake.modules.nixos.tangled-knot =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) merge;
      inherit (config.networking) domain;

      knotFqdn = "knot.${domain}";
      host = "0.0.0.0";
      knotPort = "8003";
    in
    {
      imports = singleton inputs.tangled.nixosModules.knot;

      services.tangled.knot = {
        enable = true;

        gitUser = "tangled";
        stateDir = "/var/lib/tangled-knot";
        repo.mainBranch = "master";

        git = {
          userName = "PlumJam Tangled [bot]";
          userEmail = "tangled-bot@plumj.am";
        };

        server = {
          listenAddr = "${host}:${knotPort}";
          owner = "did:plc:sj32bbckrvqjhqsi77c6lcbb";
          hostname = knotFqdn;
        };
      };

      services.nginx.virtualHosts.${knotFqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
        locations = {
          "/".proxyPass = "http://${host}:${knotPort}";
          "/events" = {
            proxyPass = "http://${host}:${knotPort}";
            proxyWebsockets = true;
          };
        };
      };

      services.openssh.settings = {
        AllowUsers = singleton "tangled";
        AllowGroups = singleton "tangled";
      };
    };

  flake.modules.nixos.tangled-spindle =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) merge;
      inherit (config.networking) domain;

      spindleFqdn = "spindle.${domain}";
      host = "0.0.0.0";
      spindlePort = "8004";
    in
    {
      imports = singleton inputs.tangled.nixosModules.spindle;

      services.tangled.spindle = {
        enable = false; # Will investigate more in the future once private repos are possible.

        server = {
          listenAddr = "${host}:${spindlePort}";
          hostname = spindleFqdn;
          owner = "did:plc:sj32bbckrvqjhqsi77c6lcbb";
        };

        pipelines = {
          workflowTimeout = "300m";
        };
      };

      services.nginx.virtualHosts.${spindleFqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
        locations = {
          "/".proxyPass = "http://${host}:${spindlePort}";
          "/events" = {
            proxyPass = "http://${host}:${spindlePort}";
            proxyWebsockets = true;
          };
        };
      };
    };
}
