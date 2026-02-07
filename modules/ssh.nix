let
  sshConfigBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
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
    };

  nixosOpensshBase =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      services.openssh = {
        enable = true;
        hostKeys = singleton {
          type = "ed25519";
          inherit (config.age.secrets.id) path;
        };
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

  darwinOpensshBase =
    { config, ... }:
    {
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
in
{
  flake.modules.nixos.ssh = sshConfigBase;
  flake.modules.darwin.ssh = sshConfigBase;

  flake.modules.nixos.openssh = nixosOpensshBase;
  flake.modules.darwin.openssh = darwinOpensshBase;
}
