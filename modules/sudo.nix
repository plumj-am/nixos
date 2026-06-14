let
  sudoExtraConfig = # sudoers
    ''
      Defaults pwfeedback
      Defaults !lecture
      Defaults env_keep+="DISPLAY EDITOR PATH"
    '';
in
{
  flake.modules.nixos.sudo-desktop =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      package = pkgs.symlinkJoin {
        name = "sudo";
        paths = singleton inputs.run0-sudo-shim.packages.${pkgs.stdenv.hostPlatform.system}.run0-sudo-shim;
        nativeBuildInputs = singleton pkgs.makeWrapper;
        postBuild = ''
          wrapProgram $out/bin/sudo --add-flags "--run0-extra-arg=--background="
        '';
      };
    in
    {
      environment.systemPackages = singleton package;

      users.users.jam.extraGroups = [ "wheel" ];

      security = {
        sudo.enable = false;
        polkit.enable = true;

        pam.services.systemd-run0 = {
          setLoginUid = true;
          pamMount = false;
        };
      };

      # Persistent auth with run0.
      services.dbus.implementation = "broker";
      security.polkit.extraConfig = # js
        ''
          polkit.addRule(function(_action, subject) {
            if (subject.isInGroup("wheel")) {
              return polkit.Result.YES;
            }
          });
        '';
    };

  flake.modules.darwin.sudo-desktop = {
    security.sudo.extraConfig = sudoExtraConfig;

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };

  flake.modules.nixos.sudo-server = {
    users.users.jam.extraGroups = [ "wheel" ];

    security.sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
      extraConfig = # sudoers
        ''
          ${sudoExtraConfig}
          Defaults timestamp_timeout = 0
        '';
    };
  };
}
