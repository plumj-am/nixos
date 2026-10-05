{ self, ... }:
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
      MinimizeOnStartup = false;
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
      LockDatabaseIdleSeconds = 6 * 60 * 60; # 6 hours.
    };

    Browser.Enabled = true;
    SSHAgent.Enabled = true;
  };
in
{
  flake.modules.nixos.desktop = self.modules.nixos.keepassxc;
  flake.modules.nixos.keepassxc =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.generators) toINI;
      inherit (lib.lists) singleton;
      inherit (lib.trivial) const flip;
      inherit (config.helpers) rustic;
    in
    {
      services.rustic.backups.keepassxc = rustic.mkBackup "keepassxc" {
        paths = [ "/home/jam/keepassxc" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      environment.systemPackages = singleton <| pkgs.keepassxc.override { withKeePassYubiKey = true; };

      hjemModule = {
        xdg.mime-apps.default-applications = flip genAttrs (const "org.keepassxc.KeePassXC.desktop") [
          "application/x-keepass2"
        ];

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

  flake.modules.darwin.desktop = self.modules.darwin.keepassxc;
  flake.modules.darwin.keepassxc =
    { lib, ... }:
    let
      inherit (lib.generators) toINI;
      inherit (lib.lists) singleton;
    in
    {
      homebrew.casks = singleton "keepassxc";

      hjemModule = {
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
