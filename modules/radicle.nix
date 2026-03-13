let
  domain = "plumj.am";
  fqdn = "rad.${domain}";

  systemNodePort = 8776;
  userNodePort = 8775;
  nodeHttpdPort = 8005;

  personalNodes = [
    # User nodes.
    "z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un@yuzu.taild29fec.ts.net:8775"

    # System nodes.
    "z6MkmE6sDg87jysA5F6toYZDE795Nkcv2KfbVaqRLRQFFt6X@blackwell.taild29fec.ts.net:8776"
    # "...@date.taild29fec.ts.net:8776"
    "z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6@kiwi.taild29fec.ts.net:8776"
    "z6MkffMv6gHyhQQWT1NH8p3X9hiMdxsAnUhtxXTfx2xZSqzz@plum.taild29fec.ts.net:8776"
    "z6MkrBKRwq3ADkck29xhyxSvjWiPs9XXoCLxNCZ2egYSNWCv@sloe.taild29fec.ts.net:8776"
    "z6MkjteiKR9kqhLXnU3oVDDNf3zpoQPnLfMeqZXGsbVJVKeT@yuzu.taild29fec.ts.net:8776"
    "z6MkjTz9sd1wn5HXvNb2YVnYWjSfkYieWwutoUeo24cSGQns@lime.taild29fec.ts.net:8776"
  ];

  personalDIDs = [
    "did:key:z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un" # jam@yuzu
    "did:key:z6MkjTz9sd1wn5HXvNb2YVnYWjSfkYieWwutoUeo24cSGQns" # jam@lime
  ];

  radicleUserBase =
    {
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton (
        { pkgs, osConfig, ... }:
        let
          inherit (osConfig.flake) keys;
          inherit (osConfig.age) secrets;
          inherit (osConfig.networking) hostName;

          json = pkgs.formats.json { };
        in
        {
          packages = singleton pkgs.radicle-node;

          files = {
            ".radicle/keys/radicle.pub".text = keys."${hostName}-jam-radicle";
            ".radicle/keys/radicle".source = secrets.radicleUserKey.path;
            # TODO: Need to figure out if ^this^ will be a problem when it is not set.
            # TODO: I don't want it to overwrite the generated key.
            # TODO: Overall bootstrapping is weak for new/reset hosts...

            ".radicle/config.json".source = json.generate "radicle-config.json" {
              publicExplorer = "https://rad.plumj.am/nodes/$host/$rid$path";
              preferredSeeds = personalNodes;
              web = {
                pinned = {
                  repositories = [ ];
                };
              };
              cli = {
                hints = true;
              };
              node = {
                alias = "jam@${hostName}.plumj.am";
                listen = singleton "[::]:${toString userNodePort}";
                peers = {
                  type = "dynamic";
                };
                connect = personalNodes;
                externalAddresses = singleton "${hostName}.taild29fec.ts.net:${toString userNodePort}";
                network = "main";
                log = "INFO";
                relay = "auto";
                limits = {
                  routingMaxSize = 1000;
                  routingMaxAge = 604800;
                  gossipMaxAge = 1209600;
                  fetchConcurrency = 1;
                  maxOpenFiles = 4096;
                  rate = {
                    inbound = {
                      fillRate = 5.0;
                      capacity = 1024;
                    };
                    outbound = {
                      fillRate = 10.0;
                      capacity = 2048;
                    };
                  };
                  connection = {
                    inbound = 128;
                    outbound = 16;
                  };
                  fetchPackReceive = "500.0 MiB";
                };
                workers = 16;
                seedingPolicy = {
                  scope = "followed";
                  default = "block";
                };
              };
            };
          };
        }
      );
    };

  radicleNodeBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton optional;
      inherit (config.myLib) merge;
      inherit (config.networking) hostName;
    in
    {
      environment.systemPackages = singleton pkgs.radicle-node;

      networking.firewall.allowedTCPPorts = singleton systemNodePort;

      services.radicle = {
        enable = true;

        publicKey = config.age.rekey.hostPubkey;
        privateKeyFile = config.age.secrets.id.path;
        checkConfig = false; # Allows debugging at systemd unit level.

        httpd = {
          enable = true;
          listenPort = nodeHttpdPort;
        };

        # <https://app.radicle.xyz/nodes/seed.radicle.garden/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/tree/crates/radicle/src/node/config.rs>
        settings = {
          web = {
            name = fqdn;
            description = "PlumJam's public seeding node | Xitter: @plumj_am";
            avatarUrl = "https://plumj.am/public/plumjam.png";
            bannerUrl = "https://plumj.am/public/plumjam-banner4.png";
            pinned.repositories = [
              "rad:z2FHgLfWUnYBXMpqFRTjciK7vAVjR" # plumjam/nixos
              "rad:z5MipPXTdCWp87hUwvyY1DLgiBgS" # plumjam/plumj.am
            ];
          };

          preferredSeeds = personalNodes;

          node = {
            alias = "rad-${hostName}.plumj.am";
            connect = personalNodes;
            follow = personalDIDs;
            externalAddresses =
              optional (hostName == "plum") "${fqdn}:${toString systemNodePort}" # First because it is highlighted in the radicle-explorer.
              ++ singleton "${hostName}.taild29fec.ts.net:${toString systemNodePort}";
            workers = 16;
            relay = "always";
            seedingPolicy = {
              scope = "followed";
              default = if hostName == "plum" then "allow" else "block";
            };
          };
        };
      };
      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';

        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString nodeHttpdPort}";
        };

        locations."/raw/" = {
          proxyPass = "http://127.0.0.1:${toString nodeHttpdPort}";
        };

        locations."~ ^/rad:" = {
          proxyPass = "http://127.0.0.1:${toString nodeHttpdPort}";
        };
      };
    };

  radicleTUI =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      config = {
        shellAliases.rad = "rad-tui";

        hjem.extraModules = singleton {
          packages = singleton pkgs.radicle-tui;
        };
      };
    };

  radicleGUI =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.radicle-desktop;
      };
    };
in
{
  flake.modules.nixos.radicle =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    radicleUserBase { inherit lib; }
    // {
      networking.firewall.allowedTCPPorts = singleton userNodePort;

      systemd.user.services.radicle-user-node = {
        description = "Radicle User Node";
        wantedBy = [ "default.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionUser = "jam";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.radicle-node}/bin/rad node start";
          Restart = "on-failure";
          RestartSec = "5";
        };
      };
    };

  flake.modules.darwin.radicle = radicleUserBase;

  flake.modules.nixos.radicle-node = radicleNodeBase;
  flake.modules.darwin.radicle-node = radicleNodeBase;

  flake.modules.nixos.radicle-explorer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.myLib) merge;

      toJSON = lib.generators.toJSON { };

      # <https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z4V1sjrXqjvFdnCUbxPFqd5p4DtH5/tree/config/default.json>
      radicalExplorerConfig = toJSON {
        nodes = {
          fallbackPublicExplorer = "https://app.radicle.xyz/nodes/$host/$rid$path";
          requiredApiVersion = "~0.18.0";
          defaultHttpdPort = 443;
          defaultLocalHttpdPort = 8080;
          defaultHttpdScheme = "https";
        };
        source.commitsPerPage = 30;
        supportWebsite = "https://radicle.zulipchat.com";
        preferredSeeds = [
          {
            hostname = "rad.plumj.am";
            port = 443;
            scheme = "https";
          }
        ];
      };

      root = pkgs.radicle-explorer.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          cat > ./config/local.json << 'EOF'
          ${radicalExplorerConfig}
          EOF
        '';
      });
    in
    {
      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        serverAliases = [
          "radicle.${domain}"
          "seed.${domain}"
        ];
        locations."/" = {
          index = "index.html";
          inherit root;
          extraConfig = # nginx
            ''
              try_files $uri $uri/ /index.html;
            '';
        };
      };
    };

  flake.modules.nixos.radicle-tui = radicleTUI;
  flake.modules.darwin.radicle-tui = radicleTUI;

  flake.modules.nixos.radicle-gui = radicleGUI;
  flake.modules.darwin.radicle-gui = radicleGUI;
}
