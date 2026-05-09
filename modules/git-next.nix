{
  flake.modules.nixos.git-next =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;

      dataDir = "/var/lib/git-next";
      configFile = config.age.secrets.gitNextConfig.path;

      port = 8009;
      openFirewall = false;

      package = pkgs.rustPlatform.buildRustPackage (final: {
        pname = "git-next";
        version = "2026.5.2";

        src = pkgs.fetchgit {
          url = "https://codeberg.org/kemitix/git-next";
          tag = "v${final.version}";
          hash = "sha256-Jv/cywLZUIYJXKq/aiSNXzNx2pmB0idAtOhDCoKCJcs=";
        };
        cargoHash = "sha256-2DWD2IJr9f4XDLw2Mz7dXg+dCCEM6O4w9EAFe9CvVoo=";
        cargoDepsName = final.pname;

        doCheck = false;

        nativeBuildInputs = singleton pkgs.pkg-config;
        buildInputs = [
          # pkgs.perl
          pkgs.openssl
          pkgs.dbus
          pkgs.zlib
        ];
        OPENSSL_NO_VENDOR = 1;

        meta.mainProgram = "git-next";
      });
    in
    {
      age.secrets.gitNextConfig = {
        rekeyFile = ../secrets/git-next-config.age;
        owner = "git-next";
        group = "git-next";
        mode = "600";
      };

      users.users.git-next = {
        isSystemUser = true;
        group = "git-next";
        home = dataDir;
      };
      users.groups.git-next = { };

      networking.firewall.allowedTCPPorts = mkIf openFirewall [ port ];

      systemd.services.git-next = {
        description = "git-next trunk-based development server";
        after = [
          "network-online.target"
          "forgejo.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStartPre = "${pkgs.coreutils}/bin/ln -sf ${configFile} ${dataDir}/git-next-server.toml";
          ExecStart = "${getExe package} server start";
          WorkingDirectory = dataDir;
          User = "git-next";
          Group = "git-next";
          StateDirectory = "git-next";
          Restart = "on-failure";
          RestartSec = "5s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ dataDir ];
        };
      };
    };
}
