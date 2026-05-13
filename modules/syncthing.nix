{

  flake.modules.nixos.syncthing =
    let
      devices = {
        blackwell = {
          id = "";
          addresses = [ "tcp://blackwell.taild29fec.ts.net:22000" ];
        };
        date = {
          id = "BVND7WF-QAPBTO3-N22MJMT-SLO35ES-7CTST5I-ANUN6ZW-4P3D3OU-O5E7EAS";
          addresses = [ "tcp://date.taild29fec.ts.net:22000" ];
        };
        kiwi = {
          id = "";
          addresses = [ "tcp://kiwi.taild29fec.ts.net:22000" ];
        };
        lime = {
          id = "";
          addresses = [ "tcp://lime.taild29fec.ts.net:22000" ];
        };
        pear = {
          id = "";
          addresses = [ "tcp://pear.taild29fec.ts.net:22000" ];
        };
        plum = {
          id = "";
          addresses = [ "tcp://plum.taild29fec.ts.net:22000" ];
        };
        sloe = {
          id = "";
          addresses = [ "tcp://sloe.taild29fec.ts.net:22000" ];
        };
        yuzu = {
          id = "R2J6HGL-FX7UB2G-55WVDS3-QD54GPO-QCQADZM-X4WUP7R-D2LOZTD-HFDIWAQ";
          addresses = [ "tcp://yuzu.taild29fec.ts.net:22000" ];
        };

        onx = {
          id = "";
          addresses = [ "tcp://onx.taild29fec.ts.net:22000" ];

        };
      };
    in
    {
      systemd.tmpfiles.rules = [
        "d /var/backups 0600 jam users -"
        "d /var/backups/onx 0600 jam users -"
      ];

      services.syncthing = {
        enable = true;
        user = "jam";
        dataDir = "/home/jam";
        settings = {
          inherit devices;

          options = {
            relaysEnabled = true;
            localAnnounceEnabled = true;
          };

          folders = {
            onx-backup = {
              path = "/var/backups/onx";
              devices = [
                "sloe"
                "onx"
              ];
              ignorePerms = true;
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "7200"; # 2h
                  maxAge = "2592000"; # 30d
                };
              };
            };
          };
        };
      };
    };
}
