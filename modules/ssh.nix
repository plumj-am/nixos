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

      programs.ssh.knownHosts = {
        blackwell.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSi4SKhqze7ZzhJFcUF9KW/4nXX1MfvZjUqrYWNDi9c";
        date.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa";
        kiwi.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af";
        pear.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ";
        plum.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr";
        sloe.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK42xzC/vWHZC9SiU/8IBBd2pn7mggBYFQ8themKAic/";
        yuzu.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0";
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
