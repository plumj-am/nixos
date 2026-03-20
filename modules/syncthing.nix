{

  flake.modules.nixos.syncthing =
    { lib, ... }:
    let
      inherit (lib.attrsets) attrNames;

      devices = {
        # blackwell = {
        #   id = "COZUXV4-HYFNNR2-APPQQL3-7QUUZFN-6VXGKOI-YSYS5VQ-3TAHZ6Y-P2USQAO";
        #   addresses = [ "tcp://blackwell.taild29fec.ts.net:22000" ];
        # };
        date = {
          id = "";
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
          id = "INKVUCX-QTQRO26-TG3HMMR-CVGOU4L-4JWGU7H-FDPW6QI-EWVJLMB-4GUQIA4";
          addresses = [ "tcp://plum.taild29fec.ts.net:22000" ];
        };
        sloe = {
          id = "OL4HTIF-PU3A7G4-K7QXABE-FUIFI3U-JHEKRSV-AKEPZU6-6Y5CXA2-KMMKQA4";
          addresses = [ "tcp://sloe.taild29fec.ts.net:22000" ];
        };
        yuzu = {
          id = "JL3HLSF-2JP4K7Y-MHDQWLQ-USTAS4D-W4LQNSK-BKR4PD5-Q72IUMR-H7MYIA5";
          addresses = [ "tcp://yuzu.taild29fec.ts.net:22000" ];
        };
      };

      allDevices = attrNames devices;

    in
    {
      users.users.syncthing.extraGroups = [ "radicle" ];

      systemd.tmpfiles.rules = [
        "d /var/lib/radicle-ci/adapters 2775 radicle radicle -"
        "d /var/lib/radicle-ci/reports 2775 radicle radicle -"
      ];

      services.syncthing = {
        enable = true;
        settings = {
          inherit devices;

          options = {
            relaysEnabled = true;
            localAnnounceEnabled = true;
          };

          folders = {
            radicle-ci-adapters = {
              path = "/var/lib/radicle-ci/adapters";
              devices = allDevices;
              ignorePerms = true;
              ignorePatterns = [
                "native/**/src"
              ];
            };
            radicle-ci-reports = {
              path = "/var/lib/radicle-ci/reports";
              devices = allDevices;
              ignorePerms = true;
            };
          };
        };
      };
    };
}
