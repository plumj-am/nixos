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
      inherit (config.sops) secrets;

      fqdn = "cloud.${domain}";
    in
    {
      assertions = singleton {
        assertion = hostName == "sloe";
        message = "nextcloud must run on sloe to ensure adequate disk space is available";
      };

      sops.secrets."nextcloud/plumjam-password" = {
        sopsFile = ../secrets/services/nextcloud.yaml;
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
          adminpassFile = secrets."nextcloud/plumjam-password".path;

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

  flake.modules.nixos.nextcloud-client =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = { osConfig, ... }: {
        packages = singleton pkgs.nextcloud-client;
        # This is probably a bad idea.
        xdg.config.files."Nextcloud/nextcloud.cfg" = {
          type = "copy";
          permissions = "600"; # Need to set or it won't start.
          text =
            # ini
            ''
              [General]
              clientPreviousVersion=
              clientVersion=33.0.5
              confirmExternalStorage=true
              desktopEnterpriseChannel=stable
              isVfsEnabled=false
              lastSelectedAccount=0
              launchOnSystemStartup=true
              monoIcons=true
              moveToTrash=false
              newBigFolderSizeLimit=500
              notifyExistingFoldersOverLimit=false
              optionalServerNotifications=true
              promptDeleteAllFiles=false
              showCallNotifications=true
              showChatNotifications=true
              showInExplorerNavigationPane=false
              showQuotaWarningNotifications=true
              stopSyncingExistingFoldersOverLimit=false
              updateChannel=stable
              useNewBigFolderSizeLimit=true

              [Accounts]
              0\Folders\1\ignoreHiddenFiles=false
              0\Folders\1\journalPath=.sync_2287fed0df6f.db
              0\Folders\1\localPath=/home/jam/Pictures/
              0\Folders\1\paused=false
              0\Folders\1\targetPath=/${osConfig.networking.hostName}/pictures
              0\Folders\1\version=2
              0\Folders\1\virtualFilesMode=off
              0\Folders\2\ignoreHiddenFiles=false
              0\Folders\2\journalPath=.sync_9618a8250da1.db
              0\Folders\2\localPath=/home/jam/keepassxc/
              0\Folders\2\paused=false
              0\Folders\2\targetPath=/keepassxc
              0\Folders\2\version=2
              0\Folders\2\virtualFilesMode=off
              0\authType=webflow
              0\dav_user=plumjam
              0\desktopEnterpriseChannel=invalid
              0\displayName=plumjam
              0\encryptionCertificateSha256Fingerprint=@ByteArray()
              0\networkDownloadLimit=0
              0\networkDownloadLimitSetting=0
              0\networkProxyHostName=
              0\networkProxyNeedsAuth=false
              0\networkProxyPort=0
              0\networkProxyType=2
              0\networkProxyUser=
              0\networkUploadLimit=0
              0\networkUploadLimitSetting=0
              0\serverColor=@Variant(\0\0\0\x43\x1\xff\xff\0\0\x82\x82\xc9\xc9\0\0)
              0\serverHasValidSubscription=false
              0\serverTextColor=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0)
              0\serverVersion=33.0.5.1
              0\url=https://cloud.plumj.am
              0\version=13
              0\webflow_user=plumjam
              version=13

              [Nextcloud]
              autoUpdateCheck=false

              [Settings]
              geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\xff\xff\xff\xfd\xff\xff\xff\xe2\0\0\x3\xb8\0\0\x3\xf5\0\0\0\0\0\0\0\0\0\0\x3\xb5\0\0\x3\xf2\0\0\0\0\0\0\0\0\a\x80\0\0\0\0\0\0\0\0\0\0\x3\xb5\0\0\x3\xf2)
            '';
        };
      };
    };
}
