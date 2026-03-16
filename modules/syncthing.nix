{

  flake.modules.nixos.syncthing =
    { lib, config, ... }:
    let
      inherit (lib.attrsets) attrNames;
      inherit (config.networking) hostName;

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
          id = "";
          addresses = [ "tcp://yuzu.taild29fec.ts.net:22000" ];
        };
      };

      allDevices = attrNames devices;
    in
    {
      users.users.syncthing.extraGroups = [ "radicle-ci" ];

      services.syncthing = {
        enable = true;
        settings = {
          inherit devices;

          options = {
            relaysEnabled = true;
            localAnnounceEnabled = true;
          };

          folders = {
            radicle-ci = {
              path = "/var/lib/radicle-ci/adapters/native";
              devices = allDevices;
              ignorePerms = true;
              copyOwnershipFromParent = true;
            };
          };
        };
      };
    };
}
