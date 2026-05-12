{ inputs, ... }:
{
  flake.modules.nixos.buildbot-master =
    {
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') merge;
      inherit (config.networking) domain hostName;
      inherit (config.age) secrets;

      buildbot-nix-patched =
        let
          orig = config.services.buildbot-nix.packages.python.pkgs.callPackage (
            inputs.buildbot-nix + "/packages/buildbot-nix.nix"
          ) { buildbot-gitea = config.services.buildbot-nix.packages.buildbot-gitea; };
        in
        orig.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/buildbot-nix-gcroot-warning.patch
            ./patches/buildbot-nix-no-cancel.patch
          ];
          postPatch = (old.postPatch or "") + ''
            substituteInPlace buildbot_nix/nix_build.py \
              --replace-fail \
                '"--accept-flake-config",' '
                "--accept-flake-config",
                "--builders", "",
                "--fallback",
              '
          '';
        });
    in
    {
      imports = singleton inputs.buildbot-nix.nixosModules.buildbot-master;

      assertions = singleton {
        assertion = hostName == "plum";
        message = "The buildbot-master module should only be used on the 'plum' host.";
      };

      age.secrets = {
        buildbotAccessToken.rekeyFile = ../secrets/buildbot-access-token.age;
        buildbotWebhookSecret.rekeyFile = ../secrets/buildbot-webhook-secret.age;
        buildbotOauthSecret.rekeyFile = ../secrets/buildbot-oauth-secret.age;
        buildbotWorkersFile.rekeyFile = ../secrets/buildbot-workers-file.age;
        buildbotHttpBasicAuthPassword.rekeyFile = ../secrets/buildbot-http-basic-auth-password.age;
        buildbotCookieSecret.rekeyFile = ../secrets/buildbot-cookie-secret.age;
      };

      services.buildbot-nix.packages.buildbot-nix = buildbot-nix-patched;

      services.buildbot-nix.master = {
        enable = true;

        domain = "buildbot.${domain}";
        admins = singleton "PlumJam";

        workersFile = secrets.buildbotWorkersFile.path;
        httpBasicAuthPasswordFile = secrets.buildbotHttpBasicAuthPassword.path;

        gitea = {
          enable = true;

          instanceUrl = "https://git.${domain}";
          topic = null;

          oauthId = "26db7117-c7ec-4bc9-b273-7b12bb0f83aa";
          oauthSecretFile = secrets.buildbotOauthSecret.path;
          tokenFile = secrets.buildbotAccessToken.path;
          webhookSecretFile = secrets.buildbotWebhookSecret.path;
        };

        accessMode.fullyPrivate = {
          backend = "gitea";

          clientId = "26db7117-c7ec-4bc9-b273-7b12bb0f83aa";
          clientSecretFile = secrets.buildbotOauthSecret.path;
          cookieSecretFile = secrets.buildbotCookieSecret.path;
        };

        branches = {
          next.matchGlob = "next";
          mergeQueue.matchGlob = "gitea-mq/*";
        };
      };

      # Much taken from: <https://git.lix.systems/lix-project/buildbot-nix/src/branch/main/buildbot_nix/__init__.py>
      services.buildbot-master.extraConfig = # python
        ''
          from buildbot.plugins import changes, reporters, schedulers, util
          from buildbot.reporters.generators.build import BuildStatusGenerator
          from buildbot.reporters.message import MessageFormatterFunction

          def gerritReviewFmt(url, data):
              if 'build' not in data:
                  raise ValueError('`build` is supposed to be present to format a build')

              build = data['build']
              if 'builder' not in build and 'name' not in build['builder']:
                  raise ValueError('either `builder` or `builder.name` is not present in the build dictionary, unexpected format request')

              builderName = build['builder']['name']

              if len(build['results']) != 1:
                  raise ValueError('this review request contains more than one build results, unexpected format request')

              result = build['results'][0]
              if result == util.RETRY:
                  return dict()

              if builderName != f'{build["properties"].get("event.project")}/nix-eval':
                  return dict()

              failed = build['properties'].get('failed_builds', [[]])[0]

              labels = {
                  'Verified': -1 if result != util.SUCCESS else 1,
              }

              message =  "Buildbot finished compiling your patchset!\n"
              message += "The result is: %s\n" % util.Results[result].upper()
              if result != util.SUCCESS:
                  message += "\nFailed checks:\n"
                  for check, how, urls in failed:
                      if not urls:
                          message += "  "
                      message += f" - {check}: {how}"
                      if urls:
                          message += f" (see {', '.join(urls)})"
                      message += "\n"

              if url:
                  message += "\nFor more details visit:\n"
                  message += build['url'] + "\n"

              return dict(message=message, labels=labels)

          # Pull in change events from Gerrit
          c['change_source'] = [
              changes.GerritChangeSource(
                  gerritserver='gerrit.plumj.am',
                  gerritport=29418,
                  username='buildbot',
                  identity_file='/run/agenix/gerritBuildbotSshKey',
                  handled_events=["patchset-created", "change-restored", "ref-updated"],
              )
          ]

          c['schedulers'] = [
              schedulers.AnyBranchScheduler(
                  name="grove-gerrit-upload-master",
                  change_filter=util.GerritChangeFilter(
                      branch='master',
                      eventtype='patchset-created',
                  ),
                  treeStableTimer=30, # Give time for Gerrit replication to complete.
                  builderNames=["PlumWorks/grove/nix-eval"],
              ),
              # TODO: Doesn't work yet. Maybe we just accept it and let buildbot run after
              # changes get replicated to Forgejo so the status is easy to see?
              schedulers.AnyBranchScheduler(
                  name="grove-gerrit-merge-master",
                  change_filter=util.GerritChangeFilter(
                      branch='master',
                      eventtype='ref-updated',
                  ),
                  treeStableTimer=30, # Give time for Gerrit replication to complete.
                  builderNames=["PlumWorks/grove/nix-eval"],
              )
          ]

          # Report build results back as Verified votes
          c['services'].append(
              reporters.GerritStatusPush(
                  server='gerrit.plumj.am',
                  username='buildbot',
                  port=29418,
                  identity_file='/run/agenix/gerritBuildbotSshKey',
                  generators=[
                    BuildStatusGenerator(
                      message_formatter=MessageFormatterFunction(
                        lambda data: gerritReviewFmt(self.url, data),
                        "plain",
                        want_properties=True,
                        want_steps=True,
                      ),
                    ),
                  ],
              )
          )

          c["protocols"] = {"pb": {"port": "tcp:9989:interface=\\:\\:"}}

          c['www']['ui_default_config'] = {
            'Home.sidebar_menu_groups_expand_behavior': "Always expand",
            'Builders.show_workers_name': True,
          }
        '';

      networking.firewall.allowedTCPPorts = singleton 9989;

      # Override default GitHub scopes which are incompatible with Forgejo.
      systemd.services.oauth2-proxy.environment = {
        OAUTH2_PROXY_SCOPE = "read:user read:organization";
      };

      services.nginx.virtualHosts."buildbot.${domain}" = merge config.services.nginx.sslTemplate { };
    };

  flake.modules.nixos.buildbot-worker =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.networking) hostName;
      inherit (config.age) secrets;
    in
    {
      imports = singleton inputs.buildbot-nix.nixosModules.buildbot-worker;

      age.secrets = {
        buildbotMasterPassword.rekeyFile = ../secrets/buildbot-master-password.age;
      };

      nix.settings.trusted-users = singleton "buildbot-worker";

      services.buildbot-nix.worker = {
        enable = true;

        masterUrl =
          if hostName == "plum" then "tcp:host=localhost:port=9989" else "tcp:host=plum:port=9989";

        workerPasswordFile = secrets.buildbotMasterPassword.path;
      };
    };
}
