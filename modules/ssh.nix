{ self, ... }:
let
  sshConfigBase = {
    hjemModule =
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

              Host gerrit
                HostName gerrit.plumj.am
                ControlMaster auto
                ControlPersist 60m
                User plumj-am
                Port 29418
                IdentityFile ${config.directory}/.ssh/id
            '';
        };
      };
  };
in
{
  flake.darwinModules.default = self.darwinModules.ssh;
  flake.darwinModules.ssh =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton sshConfigBase;

      environment.systemPackages = singleton pkgs.openssh;

      services.openssh = {
        enable = true;
        extraConfig = # sshd_config
          ''
            HostKey ${config.sops.secrets.id.path}
            PasswordAuthentication no
            KbdInteractiveAuthentication no
            AcceptEnv SHELLS COLORTERM
          '';
      };
    };

  flake.nixosModules.default = self.nixosModules.ssh;
  flake.nixosModules.ssh =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) listToAttrs;
      inherit (lib.lists) map singleton;
    in
    {
      imports = [
        sshConfigBase
        self.serviceModules.tarssh
      ];

      environment.systemPackages = singleton pkgs.openssh;

      networking.firewall.allowedTCPPorts = [
        2222 # TODO: tarssh
        22
      ];

      programs.ssh.startAgent = true;

      services.openssh = {
        enable = true;
        hostKeys = singleton {
          type = "ed25519";
          inherit (config.sops.secrets.id) path;
        };
        settings = {
          AllowUsers = [
            "root"
            "jam"
          ];
          AllowGroups = [
            "root"
            "wheel"
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
          keys = config.flake.entities.sshKeys;
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
        )
        // {
          "git.plumj.am" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr gerrit-replication";
          };
        };

      programs.ssh.extraConfig = # ssh
        ''
          Host git.plumj.am
            IdentityFile ${config.sops.secrets.id.path}

          # Remote builders: nix execs ssh with no -o overrides, so this is the
          # only place its connection can be bounded. A dead channel then
          # becomes an error instead of a build that never reports.
          Host blackwell date sloe plum
            ConnectTimeout 10
            ServerAliveInterval 15
            ServerAliveCountMax 3
            BatchMode yes
        '';

      services.tarssh = {
        enable = false; # TODO: enable
        listenAddress = "[::]";
        listenPort = 22;
        openFirewall = true;
      };
    };

  flake.nixosModules.openssh-grove-systems =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (config.flake) entities;
    in
    {
      services.openssh.settings = {
        AllowUsers = entities.groveSystemsUsernames;
        AllowGroups = singleton "grove-systems";
      };
    };
}
