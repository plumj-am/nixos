{ self, lib, ... }:
let
  inherit (lib.constants) tailnet;

  domain = "plumj.am";
  fqdn = "rad.${domain}";

  systemNodePort = 8776;
  userNodePort = 8775;
  nodeHttpdPort = 8005;

  personalNodes = [
    # User nodes.
    "z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un@yuzu.${tailnet}:8775"

    # System nodes.
    # "z6MkmE6sDg87jysA5F6toYZDE795Nkcv2KfbVaqRLRQFFt6X@blackwell.${tailnet}:8776"
    # "...@date.${tailnet}:8776"
    "z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6@kiwi.${tailnet}:8776"
    "z6MkffMv6gHyhQQWT1NH8p3X9hiMdxsAnUhtxXTfx2xZSqzz@plum.${tailnet}:8776"
    "z6MkrBKRwq3ADkck29xhyxSvjWiPs9XXoCLxNCZ2egYSNWCv@sloe.${tailnet}:8776"
    "z6MkjteiKR9kqhLXnU3oVDDNf3zpoQPnLfMeqZXGsbVJVKeT@yuzu.${tailnet}:8776"
    "z6MkjTz9sd1wn5HXvNb2YVnYWjSfkYieWwutoUeo24cSGQns@lime.${tailnet}:8776"
  ];

  personalDIDs = [
    "did:key:z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un" # jam@yuzu
    "did:key:z6MkjTz9sd1wn5HXvNb2YVnYWjSfkYieWwutoUeo24cSGQns" # jam@lime
  ];
in
{
  flake.modules.common.desktop = self.modules.common.radicle;
  flake.modules.common.radicle =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.flake) entities;
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;
    in
    {
      sops.secrets."radicle/jam-key" = {
        sopsFile = ../secrets/services/radicle.yaml;
        owner = "jam";
        mode = "600";
      };

      nixpkgs.config.permittedInsecurePackages = singleton "radicle-node-1.10.3"; # private repos are not encrypted etc.

      environment.systemPackages = [
        # inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.rsh-rsh
        pkgs.radicle-node
        pkgs.radicle-tui
      ];

      hjemModule = {
        files = {
          # TODO:
          ".radicle/keys/radicle.pub".text = entities.radicleKeys.${hostName};
          ".radicle/keys/radicle".source = secrets."radicle/jam-key".path;
          # TODO: Need to figure out if ^this^ will be a problem when it is not set.
          # TODO: I don't want it to overwrite the generated key.
          # TODO: Overall bootstrapping is weak for new/reset hosts...

          ".radicle/config.json" = {
            generator = pkgs.writers.writeJSON "radicle-config.json";
            value = {
              publicExplorer = "https://rad.plumj.am/nodes/$host/$rid$path";
              preferredSeeds = personalNodes;

              web.pinned.repositories = [ ];

              cli.hints = true;

              node = {
                alias = "jam@${hostName}.plumj.am";
                listen = singleton "[::]:${toString userNodePort}";
                peers.type = "dynamic";
                connect = personalNodes;
                externalAddresses = singleton "${hostName}.${tailnet}:${toString userNodePort}";
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
        };
      };
    };

  flake.modules.common.default = self.modules.common.radicle-node;
  flake.modules.common.radicle-node =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) optional singleton;
      inherit (config.networking) hostName;
    in
    {
      nixpkgs.config.permittedInsecurePackages = singleton "radicle-node-1.10.3"; # private repos are not encrypted etc.

      environment.systemPackages = singleton pkgs.radicle-node;

      networking.firewall.allowedTCPPorts = singleton systemNodePort;

      services.radicle = {
        enable = true;

        publicKey = config.flake.entities.sshKeys.${hostName};
        privateKey = config.sops.secrets.id.path;
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
              ++ singleton "${hostName}.${tailnet}:${toString systemNodePort}";
            workers = 16;
            relay = "always";
            seedingPolicy = {
              scope = "followed";
              # Sloe has ~2TB to work with so I don't mind it seeding everything.
              default = if hostName == "sloe" then "allow" else "block";
            };
          };
        };
      };
    };

  flake.modules.nixos.radicle-explorer =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) merge;

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
      services.ferronVhosts."${fqdn}, radicle.${domain}, seed.${domain}" =
        merge config.services.ferron.sslTemplate
          {
            root = "${root}";

            index = [ "index.html" ];

            config = # kdl
              ''
                ${config.services.ferron.headers}

                # nginx `try_files $uri $uri/ /index.html`, except that the
                # radicle node HTTP API paths proxy to the local node (the
                # nginx-era node vhost merged into this server block).
                match explorer_api {
                    request.uri.path ~ r"^/(api/|raw/|rad:)"
                }

                if_not explorer_api {
                    rewrite r"^/.*" "/" {
                        last
                        directory false
                        file false
                    }
                }

                if explorer_api {
                    proxy "http://127.0.0.1:${toString nodeHttpdPort}" {
                        request_header -Accept-Encoding
                    }
                }
              '';
          };
    };
}
