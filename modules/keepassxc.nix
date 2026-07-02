let
  # https://deepwiki.com/search/provide-a-list-of-all-the-sett_cd736059-5132-4623-bd77-b4df8bee29a4?mode=fast
  keepassConfig = {
    General = {
      ConfigVersion = 2;
      BackupBeforeSave = true;
      UpdateCheckMessageShown = true;
      MinimizeAfterUnlock = true;
    };

    GUI = {
      LaunchAtStartup = true;
      MinimizeOnStartup = true;
      MinimizeToTray = true;
      MinimizeOnClose = true;
      ShowTrayIcon = true;
      CheckForUpdates = false;
      CheckForUpdatesIncludeBetas = false;
      ToolButtonStyle = 4; # Follows platform style.
    };

    Security = {
      HideTotpPreviewPanel = true;
      ClearSearch = true;
      ClearSearchTimeout = 5; # 5 minutes.
      LockDatabaseIdle = true;
      LockDatabaseIdleSeconds = 3 * 60 * 60; # 3 hours.
    };

    Browser.Enabled = true;
    SSHAgent.Enabled = true;
  };
in
{
  flake.modules.nixos.keepassxc =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.trivial) const flip;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) singleton;
      inherit (lib.generators) toINI;
      inherit (config.myLib) mkResticBackup;
    in
    {
      services.restic.backups.keepassxc = mkResticBackup "keepassxc" {
        paths = [ "/home/jam/keepassxc" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      hjem.extraModule = {
        xdg.mime-apps.default-applications = flip genAttrs (const "org.keepassxc.KeePassXC.desktop") [
          "application/x-keepass2"
        ];

        packages = singleton <| pkgs.keepassxc.override { withKeePassYubiKey = true; };

        files."keepassxc".type = "directory";
        xdg.config.files."keepassxc/keepassxc.ini" = {
          generator = toINI { };
          value = keepassConfig // {
            FdoSecrets = {
              Enabled = true;
              ShowNotification = false;
              ConfirmDeleteItem = true;
              ConfirmAccessItem = true;
              UnlockBeforeSearch = true;
            };
          };
        };
      };
    };

  flake.modules.darwin.keepassxc =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.generators) toINI;
    in
    {
      homebrew.casks = singleton "keepassxc";

      hjem.extraModule = {
        files = {
          "Library/Application Support/KeePassXC/keepassxc.ini" = {
            generator = toINI { };
            value = keepassConfig;
          };
          "keepassxc".type = "directory";
        };
      };
    };
}
