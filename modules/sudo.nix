let
  sudoExtraConfig = # sudoers
    ''
      Defaults pwfeedback
      Defaults !lecture
      Defaults env_keep+="DISPLAY EDITOR PATH"
    '';
in
{
  flake.modules.nixos.sudo =
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
    };

  flake.modules.darwin.sudo = {
    security.sudo.extraConfig = sudoExtraConfig;

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };

  flake.modules.nixos.sudo-extra-desktop = {
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

  flake.modules.nixos.sudo-extra-server = {
    security.sudo-rs = {
      wheelNeedsPassword = true;
      extraConfig = # sudoers
        ''
          ${sudoExtraConfig}
          Defaults timestamp_timeout = 0
        '';
    };
  };
}
