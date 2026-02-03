{
  flake.modules.nixos.cgit =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) domain hostName;
      inherit (config.myLib) merge;

      fqdn = "cgit.${domain}";

      cgitSimpleAuth = pkgs.rustPlatform.buildRustPackage {
        pname = "cgit-simple-authentication";
        version = "0-unstable-2025-02-05";

        src = pkgs.fetchFromGitHub {
          owner = "KunoiSayami";
          repo = "cgit-simple-authentication";
          rev = "1d03764b13e4514dbe8bd42cda7fd7d28dfd3e42";
          hash = "sha256-y+is7FIUUh8xDPIB+jRtHPoIZ3Z2iQnj8SriyGUfamI=";
        };

        cargoHash = "sha256-8wLkVK0EJvET0J97GfycvXAsr2I4ge0jF4+JFdsruCo=";

        nativeBuildInputs = singleton pkgs.pkg-config;
        buildInputs = [
          pkgs.openssl
          pkgs.sqlite
        ];

        doCheck = false;
      };

      authDbPath = "/etc/cgit/auth.db";
    in
    {
      assertions = singleton {
        assertion = config.services.forgejo.enable;
        message = "The cgit module should be used on the host running Forgejo, but you're trying to enable it on '${hostName}'.";
      };

      services.redis.servers.cgit = {
        enable = true;
        bind = "127.0.0.1";
        port = 6379;
      };

      services.cgit.${fqdn} = {
        enable = true;
        nginx.virtualHost = fqdn;
        scanPath = "/var/lib/forgejo/repositories";
        gitHttpBackend.checkExportOkFiles = false;
        user = "forgejo";
        group = "forgejo";
        settings = {
          root-title = "PlumJam's Git Repositories";
          root-desc = "Git repositories hosted at plumj.am";
          css = "/cgit.css";
          logo = "/cgit.png";
          favicon = "/favicon.ico";

          branch-sort = "age";
          enable-blame = 1;
          enable-commit-graph = 1;
          enable-follow-links = 1;
          enable-index-owner = 0;
          enable-log-filecount = 1;
          enable-log-linecount = 1;
          enable-tree-linenumbers = 1;
          enable-subject-links = 1;
          max-commit-count = "200";
          max-message-length = "120";
          max-repo-count = "1000";
          max-stats = "year";
          side-by-side-diffs = 1;

          snapshots = "tar.gz tar.bz2 zip";
          readme = ":README.md";

          about-filter = "${pkgs.cgit}/lib/cgit/filters/about-formatting.sh";
          source-filter = "${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py";

          auth-filter = "${cgitSimpleAuth}/bin/cgit-simple-authentication";
          cgit-simple-auth-cookie-ttl = "86400";
          cgit-simple-auth-database = authDbPath;
          cgit-simple-auth-bypass-root = "false";
          cgit-simple-auth-protect = "full";
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        extraConfig = ''
          ${config.services.nginx.goatCounterTemplate}
        '';
      };

      systemd.tmpfiles.rules = [
        "d /etc/cgit 0750 forgejo forgejo -"
        "d /var/cache/cgit 0750 forgejo forgejo - - -"
      ];

      environment.systemPackages = singleton (
        pkgs.runCommand "cgit-auth" { } ''
          mkdir -p $out/bin
          ln -s ${cgitSimpleAuth}/bin/cgit-simple-authentication $out/bin/cgit-auth
        ''
      );
    };
}
