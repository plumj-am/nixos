let
  sshConfigBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule =
        { config, ... }:
        {
          # HACK: Use copy type to prevent permissions issues on the resulting symlink.
          # Otherwise we get this error:
          # "Bad owner or permissions on /home/jam/.ssh/config"
          files.".ssh/config" = {
            permissions = "0600";
            type = "copy";
            text = # ssh
              ''
                StrictHostKeyChecking accept-new
                IdentitiesOnly yes

                Host *
                  SetEnv COLORTERM="truecolor" TERM="xterm-256color"
                  ControlMaster auto
                  ControlPersist 60m
                  ServerAliveCountMax 2
                  ServerAliveInterval 60
                  IdentityFile ${config.directory}/.ssh/id
              '';
          };

          packages = singleton pkgs.mosh;
        };
    };

  sshAgentBase = {
    # TODO: Handle ssh agent on darwin.
    programs.ssh.startAgent = true;
  };

  nixosOpensshBase =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton map;
      inherit (lib.attrsets) listToAttrs;
    in
    {
      services.sshguard.enable = true;

      services.openssh = {
        enable = true;
        hostKeys = singleton {
          type = "ed25519";
          inherit (config.age.secrets.id) path;
        };
        settings = {
          AllowUsers = [
            "root"
            "jam"
          ];
          AllowGroups = [
            "root"
            "wheel"
            "ssh"
          ];
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          AcceptEnv = [
            "SHELLS"
            "COLORTERM"
          ];
        };
      };

      programs.ssh.knownHosts =
        let
          keys = config.flake.keys;
          hosts = [
            "blackwell"
            "date"
            "kiwi"
            "lime"
            "pear"
            "plum"
            "sloe"
            "yuzu"
          ];
        in
        listToAttrs (
          map (name: {
            inherit name;
            value.publicKey = keys.${name};
          }) hosts
        );
    };

  nixosOpensshExtraUsers =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      services.openssh.settings = {
        AllowUsers = singleton "anamana";
        AllowGroups = singleton "ssh";
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
  flake.modules.nixos.ssh = {
    imports = [
      sshConfigBase
      sshAgentBase
    ];
  };
  flake.modules.darwin.ssh = sshConfigBase;

  flake.modules.nixos.openssh = nixosOpensshBase;
  flake.modules.nixos.openssh-extra-users = nixosOpensshExtraUsers;
  flake.modules.darwin.openssh = darwinOpensshBase;
}
