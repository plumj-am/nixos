let
  sudoExtraConfig = # sudoers
    ''
      Defaults pwfeedback
      Defaults !lecture
      Defaults env_keep+="DISPLAY EDITOR PATH"
    '';

  sudoBaseLinux =
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

  sudoBaseDarwin = {
    security.sudo.extraConfig = sudoExtraConfig;

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };

  sudoExtraDesktop = {
    # Persistent auth with run0.
    services.dbus.implementation = "broker";
    security.polkit.extraConfig = # js
      ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.policykit.exec") {
            return polkit.Result.AUTH_ADMIN_KEEP;
          }
        });

        polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop.systemd1.") == 0) {
            return polkit.Result.AUTH_ADMIN_KEEP;
          }
        });
      '';
  };

  sudoExtraServer = {
    security.sudo-rs = {
      wheelNeedsPassword = true;
      extraConfig = # sudoers
        ''
          ${sudoExtraConfig}
          Defaults timestamp_timeout = 0
        '';
    };
  };

in
{
  flake-file.inputs = {
    run0-sudo-shim = {
      url = "github:plumj-am/run0-sudo-shim";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.sudo = sudoBaseLinux;
  flake.modules.darwin.sudo = sudoBaseDarwin;

  flake.modules.nixos.sudo-extra-desktop = sudoExtraDesktop;
  flake.modules.nixos.sudo-extra-server = sudoExtraServer;
}
