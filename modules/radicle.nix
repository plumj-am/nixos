let
  fqdn = "rad.plumj.am";

  radicleUserBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
    in
    {

    };

  radicleNodeBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton optionals;
      inherit (config.myLib) merge;
      inherit (config.networking) hostName;

      nodeServePort = 8005;
      nodePort = 8776;

      personalNodes = [
        "z6MkmE6sDg87jysA5F6toYZDE795Nkcv2KfbVaqRLRQFFt6X@blackwell.taild29fec.ts.net:8776"
        # "...@date.taild29fec.ts.net:8776"
        "z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6@kiwi.taild29fec.ts.net:8776"
        "z6MkffMv6gHyhQQWT1NH8p3X9hiMdxsAnUhtxXTfx2xZSqzz@plum.taild29fec.ts.net:8776"
        "z6MkrBKRwq3ADkck29xhyxSvjWiPs9XXoCLxNCZ2egYSNWCv@sloe.taild29fec.ts.net:8776"
        "z6MkjteiKR9kqhLXnU3oVDDNf3zpoQPnLfMeqZXGsbVJVKeT@yuzu.taild29fec.ts.net:8776"
      ];

      personalDIDs = [
        "did:key:z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un" # jam@yuzu
      ];
    in
    {
      environment.systemPackages = singleton pkgs.radicle-node;

      networking.firewall.allowedTCPPorts = singleton nodePort;

      services.radicle = {
        enable = true;

        publicKey = config.age.rekey.hostPubkey;
        privateKeyFile = config.age.secrets.id.path;
        checkConfig = false; # Allows debugging at systemd unit level.

        httpd = {
          enable = true;
          listenPort = nodeServePort;
        };

        # <https://app.radicle.xyz/nodes/seed.radicle.garden/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/tree/crates/radicle/src/node/config.rs>
        settings = {
          web = {
            name = fqdn;
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
              optionals (hostName == "plum")
              <|
                singleton "${fqdn}:${toString nodePort}" # First because it is highlighted in the radicle-explorer.
                ++ singleton "${hostName}.taild29fec.ts.net:${toString nodePort}";
            seedingPolicy = {
              scope = "followed";
              default = "allow";
            };
          };
        };
      };
      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';

        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString nodeServePort}";
        };

        locations."/raw/" = {
          proxyPass = "http://127.0.0.1:${toString nodeServePort}";
        };

        locations."~ ^/rad:" = {
          proxyPass = "http://127.0.0.1:${toString nodeServePort}";
        };
      };
    };

  radicleExplorerBase =
    { pkgs, config, ... }:
    let
      inherit (config.myLib) merge;

      # <https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z4V1sjrXqjvFdnCUbxPFqd5p4DtH5/tree/config/default.json>
      radicalExplorerConfig = builtins.toJSON {
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
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) mkDesktopEntry;
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.radicle-desktop

          (mkDesktopEntry {
            name = "Radicle-Desktop";
            exec = "radicle-desktop";
            icon = "radicle";
          })
        ];
      };
    };
in
{
  flake.modules.nixos.radicle-node = radicleNodeBase;
  flake.modules.nixos.radicle-explorer = radicleExplorerBase;

  flake.modules.nixos.radicle-tui = radicleTUI;
  flake.modules.nixos.radicle-gui = radicleGUI;
}
