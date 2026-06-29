{
  flake.modules.nixos.gerrit =
    {
      inputs,
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.myLib) mkResticBackup;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      port = 8011;
    in
    {
      imports = singleton inputs.gerrit-autosubmit.nixosModules.default;

      sops.secrets = {
        "gerrit/secure-config" = {
          sopsFile = ../secrets/services/gerrit.yaml;
          owner = "git";
          group = "git";
        };
        "gerrit/replication-key" = {
          sopsFile = ../secrets/services/gerrit.yaml;
          owner = "git";
          group = "git";
        };
        "gerrit-autosubmit/environment".sopsFile = ../secrets/services/gerrit.yaml;
      };

      services.restic.backups.gerrit = mkResticBackup "gerrit" {
        paths = [ "/var/lib/gerrit" ];
        exclude = [ "/var/lib/gerrit/tmp" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      systemd.services.gerrit-keys = {
        enable = true;
        before = [ "gerrit.service" ];
        wantedBy = [ "gerrit.service" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = "/var/lib/gerrit";
        };
        script = ''
          mkdir -p /var/lib/gerrit/.ssh
          cp ${secrets."gerrit/replication-key".path} /var/lib/gerrit/.ssh/id_replication
          cat > /var/lib/gerrit/.ssh/config <<EOF
          Host *
            IdentityFile /var/lib/gerrit/.ssh/id_replication
          EOF
          chmod 600 /var/lib/gerrit/.ssh/id_replication
          chmod 600 /var/lib/gerrit/.ssh/config
          chmod 700 /var/lib/gerrit/.ssh
          cp -L /etc/ssh/ssh_known_hosts /var/lib/gerrit/.ssh/known_hosts
          chmod 600 /var/lib/gerrit/.ssh/known_hosts
          chown -R git:git /var/lib/gerrit/.ssh

          ln --symbolic --force ${secrets."gerrit/secure-config".path} etc/secure.config
        '';
      };

      users.users.git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/gerrit";
        createHome = false;
      };
      users.groups.git = { };

      systemd.services.gerrit.serviceConfig = {
        DynamicUser = mkForce false;
        User = "git";
        Group = "git";
      };
      services.gerrit = {
        enable = true;
        package = inputs.gerrit.packages.${pkgs.stdenv.hostPlatform.system}.gerrit.overrideAttrs (old: {
          # Remove the patch that appends version string with "-dirty-nix" so buildbot can
          # correctly send status updates to Gerrit.
          postPatch =
            lib.replaceStrings [ "sed -Ei 's,^(STABLE_BUILD_GERRIT_LABEL.*)$,\\1-dirty-nix,' .version" ] [ "" ]
              old.postPatch;
        });

        serverId = "e731e7e0-0873-4a69-a2b4-77a527800a3a";
        jvmHeapLimit = "1536m";
        listenAddress = "[::]:${toString port}";

        builtinPlugins = [
          "commit-message-length-validator"
          "download-commands"
          "gitiles"
          "hooks"
          "replication"
          "reviewnotes"
          "webhooks"
        ];
        plugins = [
          inputs.gerrit.packages.${pkgs.stdenv.hostPlatform.system}.oauth
          inputs.gerrit.packages.${pkgs.stdenv.hostPlatform.system}.code-owners
        ];

        settings = {
          auth = {
            type = "OAUTH";
            trustedOpenID = "^.*$";
            contributerAgreements = false;
            userNameCaseInsensitive = true;
            gitBasicAuthPolicy = "HTTP";
          };
          oauth.allowRegisterNewEmail = true;

          httpd.listenUrl = "proxy-https://[::]:${toString port}";

          sshd = {
            listenAddress = "[::]:29418";
            advertisedAddress = "gerrit.plumj.am:29418";
          };

          cache.web_sessions.maxAge = "3 months";

          change = {
            addChangeReviewFootersToCommitMessage = true;
            allowBlame = true;
            allowMarkdownBase64ImagesInComments = true;
            enableAttentionSet = true;
            enableAssignee = false;
            diff3ConflictView = true;
            maxUpdates = 10000;
          };

          commentlink = {
            changeid = {
              match = "(I[0-9a-f]{8,40})";
              link = "/q/$1";
            };
            forgejo = {
              match = "#(\\d+)";
              link = "https://git.plumj.am/grove-systems/grove/issues/$1";
            };
          };

          commitmessage = {
            maxSubjectLength = 65;
            maxLineLength = 80;
            longLinesThreshold = 33;
            rejectTooLong = true;
          };

          download.command = [
            "checkout"
            "cherry_pick"
            "format_patch"
            "pull"
          ];

          gerrit = {
            canonicalWebUrl = "https://gerrit.plumj.am";
            docUrl = "/Documentation";
          };

          plugin = {
            code-owners = {
              # A Code-Review +2 vote is required from a code owner.
              requiredApproval = "Code-Review+2";
              # The OWNERS check can be overriden using an Owners-Override vote.
              # overrideApproval = "Owners-Override+1";
              # People implicitly approve their own changes automatically.
              enableImplicitApprovals = "TRUE";
              disabledBranch = "refs/meta/config";
            };
          };

          user = {
            name = "Gerrit";
            email = "gerrit@plumj.am";
          };

          sendemail.enable = false;
        };

        replicationSettings = {
          gerrit.replicateOnStartup = true;
          replication.updateRefErrorMaxRetries = 3;
          remote.forgejo = {
            url = "forgejo@git.plumj.am:grove-systems/grove.git";
            push = [
              "+refs/heads/*:refs/heads/*"
              "+refs/tags/*:refs/tags/*"
              # "+refs/changes/*:refs/changes/*" # Necessary for buildbot to pick it up.
              "+refs/meta/config:refs/meta/config"
            ];

            # Keep an eye on this and ./buildbot.nix ->  grove-gerrit scheduler -> treeStableTimer
            # If the gap is too small, buildbot won't have a ref to fetch for the build and the
            # git step will fail.
            replicationDelay = 1;
            timeout = 120;
            threads = 3;
            remoteNameStyle = "dash";
            mirror = false;
            replicatePermissions = true;
            projects = [ "grove" ];
          };
        };
      };

      services.gerrit-autosubmit = {
        enable = true;
        gerritUrl = "https://gerrit.plumj.am";
        gerritUsername = "autosubmit-bot";
        secretsFile = secrets."gerrit-autosubmit/environment".path;
      };

      networking.firewall.allowedTCPPorts = singleton 29418;

      services.nginx.recommendedProxySettings = mkForce false;
      services.nginx.virtualHosts."gerrit.${domain}" = merge config.services.nginx.sslTemplate {
        locations."/" = {
          proxyPass = "http://localhost:${toString port}";
          extraConfig = # nginx
            ''
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header Host $host:443;
              proxy_buffering off;
              proxy_read_timeout 3600;
              proxy_cookie_path / /; # Reset from commonHttpConfig in ./nginx.nix
              # Gerrit should be left to handle it's own cookies or it breaks oauth.
            '';
        };
      };
    };
}
