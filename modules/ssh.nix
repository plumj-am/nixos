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
    { config, ... }:
    {
      config = {
        services.openssh = {
          enable = true;
          hostKeys = [
            {
              type = "ed25519";
              inherit (config.age.secrets.id) path;
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

  config.flake.modules.darwin.openssh = {
    config = {
      services.openssh.enable = true;
    };
  };
}
