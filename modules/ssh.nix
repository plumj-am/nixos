let
  commonModule =
    { pkgs, ... }:
    let
      identityPath = "/home/jam/.ssh/id";
    in
    {
      environment.systemPackages = [ pkgs.mosh ];

      sshConfig = ''
        strictHostKeyChecking accept-new
        identitiesOnly yes

        Match *
        COLORTERM=truecolor
        TERM=xterm-256color

        controlMaster auto
        controlPersist 60m
        serverAliveCount 2
        serverAliveInterval 60

        IdentityFile ${identityPath}
      '';
    };

in
{
  config.flake.modules.hjem.ssh = {

  };

  config.flake.modules.nixos.ssh = {

  };

  config.flake.modules.darwin.ssh = {

  };

  config.flake.modules.nixos.openssh =
    { config, lib, ... }:
    let
      inherit (lib)
        mkIf
        mkEnableOption
        ;
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
      inherit (lib)
        mkIf
        mkEnableOption
        ;
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
