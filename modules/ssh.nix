{
  config.flake.modules.hjem.ssh =
    { pkgs, ... }:
    {
      rum.programs.nushell.aliases.mosh = "mosh --no-init";

      files.".ssh/config".text = # ssh
        ''
          StrictHostKeyChecking accept-new
          IdentitiesOnly yes

          Host *
            SetEnv COLORTERM="truecolor" TERM="xterm-256color"
            ControlMaster auto
            ControlPersist 60m
            ServerAliveCountMax 2
            ServerAliveInterval 60
            IdentityFile /home/jam/.ssh/id
        '';

      packages = [
        pkgs.mosh
      ];
    };

  config.flake.modules.nixos.openssh =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;
    in
    {
      options.openssh = {
        enable = mkEnableOption "openssh";
      };

      config = mkIf config.openssh.enable {
        services.openssh = {
          enable = true;
          hostKeys = [
            {
              type = "ed25519";
              path = config.age.secrets.id.path;
            }
          ];
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            AcceptEnv = [
              "SHELLS"
              "COLORTERM"
            ];
          };
        };
      };
    };

  config.flake.modules.darwin.openssh =
    { config, lib, ... }:
    let
      inherit (lib.options) mkEnableOption;
      inherit (lib.modules) mkIf;
    in
    {
      options.openssh = {
        enable = mkEnableOption "openssh";
      };

      config = mkIf config.openssh.enable {
        services.openssh.enable = true;
      };
    };
}
