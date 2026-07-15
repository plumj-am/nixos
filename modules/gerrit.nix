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
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib') merge;
      inherit (config.myLib) mkResticBackup;
      inherit (config.networking) domain;
      inherit (config.sops) secrets;

      sshPort = "29418";
      httpPort = "8011";
      fqdn = "gerrit.${domain}";

      stable = "3.14";
      exact = "${stable}.1";

      stateDir = "/var/lib/gerrit";

      builtinPlugins = [
        "commit-message-length-validator"
        "download-commands"
        "gitiles"
        "hooks"
        "replication"
        "reviewnotes"
        "webhooks"
      ];

      checksPlugin =
        pkgs.writers.writeText "graft-checks.js" # js
          ''
            Gerrit.install(plugin => {
              plugin.checks().register({
                fetch: async (change) => {
                  const resp = await fetch(
                    `/checks/api?project=''${encodeURIComponent (change.repo)}&change=''${change.changeNumber}&patchset=''${change.patchsetNumber}`,
                    { credentials: 'include' }
                  );
                  if (!resp.ok) {
                    return { responseCode: 'OK', runs: [] };
                  }
                  const data = await resp.json();
                  return { responseCode: 'OK', runs: data.runs };
                },
              }, {
                fetchPollingIntervalSeconds: 60,
              });
            });
          '';

      externalPlugins = {
        oauth = {
          src = "bazel-stable-${stable}";
          sha256 = "sha256-iUK6WSRLtuZMhZyKRuViKNlEvYFvy2TPUDF6yGgpluk=";
        };
        code-owners = {
          src = "bazel-stable-${stable}";
          sha256 = "sha256-PX8nXvzuIn7ujVtq48tWTWLkufSjmBZmyGjOgb2xqfc=";
        };
        avatars-gravatar = {
          src = "bazel-master-stable-${stable}";
          sha256 = "sha256-A3g7kpwoZosBUWPTgOk9xsDBzO/mFu+klQIW3D83zaQ=";
        };
        git-repo-metrics = {
          src = "gh-bazel-stable-${stable}";
          sha256 = "sha256-z0HioEl32WOi6pLN8ECP6jLs+ddthlgITyUxM7fzjVY=";
        };
        ai-review-agent-provider = {
          src = "gh-bazel-stable-${stable}";
          sha256 = "sha256-JJrEDeuWfFw3Zkmc6nGWSX/QPKEixo9IDqxsacHBcdc=";
        };
        account = {
          src = "gh-bazel-master-master-stable-${stable}";
          sha256 = "sha256-Qi527xYVbenWTLM4ddzk44g0Z8El67LgR9Jq86MNsCc=";
        };
        #
        # replication-status = {
        #   src = "gh-bazel-stable-${stable}";
        #   sha256 = "sha256-NyebDV+OHgIXNJ0t6uy1nzVMeJiCJewB33tozXnMcFc=";
        # };
        # For scripts.
        groovy-provider = {
          src = "gh-bazel-master-stable-${stable}";
          sha256 = "sha256-Pdvb6kGrzdnLtvCRNyRUZt2LjpmggTXThyBWA4I+lIg=";
        };
      };

      plugins =
        mapAttrsToList (
          name: p:
          pkgs.fetchurl {
            url = "https://gerrit-ci.gerritforge.com/job/plugin-${name}-${p.src}/lastStableBuild/artifact/bazel-bin/plugins/${name}/${name}.jar";
            inherit (p) sha256;
          }
        ) externalPlugins
        ++ [ checksPlugin ];

      groovyScript = pkgs.fetchurl {
        url = "https://gerrit.googlesource.com/plugins/scripts/+/refs/heads/master/ai/ai-review-agent-openai-compatible-1.0.groovy";
        sha256 = "sha256-RkXD7DcEke0Y70w+/Zj/dtdJvNR6mXfINDX5Is/X+PQ=";
      };
    in
    {
      imports = singleton inputs.gerrit-autosubmit.nixosModules.default;

      # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/521466 merges.
      nixpkgs.overlays = singleton (
        final: prev: {
          gerrit = prev.gerrit.overrideAttrs {
            version = exact;
            src = final.fetchurl {
              url = "https://gerrit-releases.storage.googleapis.com/gerrit-${exact}.war";
              hash = "sha256-AjMQcGGfEKJ2eR1xXzaqp6bs8OT4S6u/G7Y3JDbAVu0=";
            };
          };
        }
      );

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
        paths = singleton stateDir;
        exclude = singleton "${stateDir}/tmp";
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      systemd.services.gerrit-keys = {
        enable = true;
        before = singleton "gerrit.service";
        wantedBy = singleton "gerrit.service";
        after = singleton "network.target";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = stateDir;
        };
        script = ''
          mkdir -p ${stateDir}/.ssh
          cp ${secrets."gerrit/replication-key".path} ${stateDir}/.ssh/id_replication
          cat > ${stateDir}/.ssh/config <<EOF
          Host *
            IdentityFile ${stateDir}/.ssh/id_replication
          EOF
          chmod 600 ${stateDir}/.ssh/id_replication
          chmod 600 ${stateDir}/.ssh/config
          chmod 700 ${stateDir}/.ssh
          cp -L /etc/ssh/ssh_known_hosts ${stateDir}/.ssh/known_hosts
          chmod 600 ${stateDir}/.ssh/known_hosts
          chown -R git:git ${stateDir}/.ssh

          ln --symbolic --force ${secrets."gerrit/secure-config".path} etc/secure.config
        '';
      };

      users.users.git = {
        isSystemUser = true;
        group = "git";
        home = stateDir;
        createHome = false;
      };
      users.groups.git = { };

      systemd.services.gerrit.serviceConfig = {
        DynamicUser = mkForce false;
        User = "git";
        Group = "git";
      };
      systemd.services.gerrit.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/mkdir -p ${stateDir}/groovy"
        "+${pkgs.coreutils}/bin/cp ${groovyScript} ${stateDir}/groovy/ai-review-agent-openai-compatible-1.0.groovy"
      ];
      services.gerrit = {
        enable = true;

        serverId = "e731e7e0-0873-4a69-a2b4-77a527800a3a";
        jvmHeapLimit = "1536m";
        listenAddress = "[::]:${httpPort}";

        inherit builtinPlugins plugins;

        settings = {
          auth = {
            type = "OAUTH";
            trustedOpenID = "^.*$";
            contributerAgreements = false;
            userNameCaseInsensitive = true;
            gitBasicAuthPolicy = "HTTP";
          };
          oauth.allowRegisterNewEmail = true;

          httpd.listenUrl = "proxy-https://[::]:${httpPort}";

          sshd = {
            listenAddress = "[::]:${sshPort}";
            advertisedAddress = "${fqdn}:${sshPort}";
          };

          cache = {
            threads = 2;
            web_sessions.maxAge = "3 months";
          };

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
            changenum = {
              match = "[Cc][Ll][ :]?(\\d{1,6})\\b";
              link = "/q/$1";
            };
          };

          commitmessage = {
            maxSubjectLength = 65;
            # I want 80 but longer than 72 looks awful in Gerrit commit message preview :/
            maxLineLength = 72;
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
            canonicalWebUrl = "https://${fqdn}";
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

            ai-review-agent-openai-compatible = {
              baseUrl = "https://opencode.ai/zen/v1";
            };

            "groovy-provider".scriptsDir = stateDir;
          };

          user = {
            name = "Gerrit";
            email = "gerrit@plumj.am";
          };

          receive.timeout = "15min";

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
              # "+refs/changes/*:refs/changes/*"
              "+refs/meta/config:refs/meta/config"
            ];

            replicationDelay = 1;
            timeout = 120;
            threads = 3;
            remoteNameStyle = "dash";
            mirror = false;
            replicatePermissions = true;
            projects = singleton "grove";
          };
        };
      };

      services.gerrit-autosubmit = {
        enable = true;
        gerritUrl = "https://${fqdn}";
        gerritUsername = "autosubmit-bot";
        secretsFile = secrets."gerrit-autosubmit/environment".path;
      };

      networking.firewall.allowedTCPPorts = singleton 29418;

      services.nginx.recommendedProxySettings = mkForce false;
      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        locations."/" = {
          proxyPass = "http://localhost:${httpPort}";
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
        locations."/internal/gerrit-auth-check" = {
          proxyPass = "http://localhost:${httpPort}/a/accounts/self";
          extraConfig = # nginx
            ''
              internal;
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
              # Forward the browser's Gerrit session cookie
              proxy_set_header Cookie $http_cookie;
            '';
        };

        locations."/checks/" = {
          proxyPass = "http://sloe.taild29fec.ts.net:8019";
          extraConfig = # nginx
            ''
              auth_request /internal/gerrit-auth-check;
              # The Gerrit checks plugin fetches /checks/api; graft serves /api/checks.
              rewrite ^/checks/api$ /api/checks break;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
        };
      };
    };
}
