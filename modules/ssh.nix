{
  flake.modules.hjem.ssh =
    { pkgs, ... }:
    {
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

  flake.modules.nixos.openssh =
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

  flake.modules.darwin.openssh = { config, ... }: {
    services.openssh = {
      enable = true;
      extraConfig = # sshd_config
        ''
          HostKey ${config.age.secrets.id.path}
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          AcceptEnv SHELLS COLORTERM
        '';
    };
  };
}
