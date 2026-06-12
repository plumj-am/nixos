{
  flake.modules.nixos.nextcloud =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) mkResticBackup merge;
      inherit (config.networking) domain hostName;

      secrets = config.age.secrets;

      fqdn = "cloud.${domain}";
    in
    {
      assertions = singleton {
        assertion = hostName == "sloe";
        message = "nextcloud must run on sloe to ensure adequate disk space is available";
      };

      age.secrets.nextcloudPassword = {
        rekeyFile = ../secrets/nextcloud-password.age;
        owner = "nextcloud";
      };

      services.restic.backups.nextcloud = mkResticBackup "nextcloud" {
        paths = singleton "/var/lib/nextcloud";
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;

        hostName = fqdn;
        https = true;

        configureRedis = true;
        database.createLocally = true;

        config = {
          adminuser = "plumjam";
          adminpassFile = secrets.nextcloudPassword.path;

          dbtype = "pgsql";
        };

        settings = {
          default_phone_region = "PL";

          log_type = "file";

          enabledPreviewProviders = [
            "OC\\Preview\\BMP"
            "OC\\Preview\\GIF"
            "OC\\Preview\\JPEG"
            "OC\\Preview\\Krita"
            "OC\\Preview\\MarkDown"
            "OC\\Preview\\MP3"
            "OC\\Preview\\OpenDocument"
            "OC\\Preview\\PNG"
            "OC\\Preview\\TXT"
            "OC\\Preview\\XBitmap"
            "OC\\Preview\\HEIC"
          ];
        };

        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
          output_buffering = "off";
        };

        extraAppsEnable = true;
        extraApps = {
          inherit (pkgs.nextcloud33.packages.apps)
            bookmarks
            calendar
            contacts
            deck
            forms
            impersonate
            mail
            notes
            previewgenerator
            ;
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.headers}
        '';
      };
    };
}
