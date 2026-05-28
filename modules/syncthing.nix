{
  flake.modules.nixos.syncthing =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) filterAttrs mapAttrs;

      mkDevice = host: id: {
        inherit id;
        addresses = singleton "tcp://${host}.taild29fec.ts.net:22000";
      };

      devices =
        filterAttrs (_: v: v.id != "")
        <| mapAttrs mkDevice {
          blackwell = "";
          date = "BVND7WF-QAPBTO3-N22MJMT-SLO35ES-7CTST5I-ANUN6ZW-4P3D3OU-O5E7EAS";
          kiwi = "AWF34JY-6S36KPK-LU45ON5-RSEXMTR-BV7KHEP-AUFZQM7-QNXGLDW-UTUVOAW";
          lime = "";
          pear = "";
          plum = "5A4RCFA-WW2UZCX-O2Z5K6T-RR7KGBF-BNLSH4G-F473CGF-VTVBQFD-3F7OBQV";
          sloe = "L2XEYOJ-34LP234-CTOZMSE-VHLQBOZ-JFSPKTK-H33LAML-XKDA5PU-4TYKCQI";
          yuzu = "R2J6HGL-FX7UB2G-55WVDS3-QD54GPO-QCQADZM-X4WUP7R-D2LOZTD-HFDIWAQ";
          onx = "X4Z4IAK-RKPR7QB-CUEDDJ5-2MTQH3Y-U6ER27G-HYLZLQO-2RURC3F-6OM42QK";
          jam-phone = "BFXWXLP-ELXJTG5-MWN6UXF-ODDGBM4-JXI3GQF-JDUFJM4-R4CVIBI-UAAO3AJ";
        };
    in
    {
      systemd.tmpfiles.rules = [
        "d /var/backups 0770 jam users -"
        "d /var/backups/onx 0770 jam users -"
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
            urAccepted = -1; # Disable anonymous usage data prompt and permission.
          };

          folders = {
            onx-backup = {
              id = "dp3tj-rnmrw";
              path = "/var/backups/onx";
              devices = [
                "date"
                "onx"
                "sloe"
                "yuzu"
              ];
              type = "receiveonly";
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
