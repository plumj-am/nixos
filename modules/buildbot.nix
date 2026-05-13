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

      # Gerrit integration for grove repo. See: ./GERRIT_BUILDBOT.md
      services.buildbot-master.extraConfig = # python
        ''
          from twisted.python import log
          from buildbot.plugins import changes, reporters, schedulers, util
          from buildbot.reporters.generators.build import BuildStatusGenerator
          from buildbot.reporters.message import MessageFormatterFunction

          # --- Build Canceller: gerrit-aware branch key ---
          # Groups gerrit refs by change number (strips patchset), passes through
          # regular branches and PR refs unchanged.
          def gerritBranchKey(b):
              ref = b['branch']
              if ref.startswith('refs/changes/'):
                  return ref.rsplit('/', 1)[0]  # refs/changes/12/3456/1 → refs/changes/12/3456
              if ref.startswith(('refs/pull/', 'refs/merge-requests/')):
                  return ref.rsplit('/', 1)[0]  # refs/pull/123/merge → refs/pull/123
              return ref

          # --- Gerrit Status Report Formatter ---
          # Sends Verified +/-1 votes to Gerrit. Only fires for builds marked
          # with the `gerrit_change` property.
          def gerritReviewFmt(url, data):
              if 'build' not in data:
                  raise ValueError('`build` is supposed to be present to format a build')

              build = data['build']
              result = build['results']

              if result == util.RETRY:
                  return dict()

              # Only report on gerrit-originated builds
              if not build['properties'].get('gerrit_change', False):
                  return dict()

              # Only report on nix-eval (top-level build; sub-builds trigger duplicate reports)
              builderName = build['builder']['name']
              if not builderName.endswith('/nix-eval'):
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

          # --- Gerrit Change Source ---
          # Detects patchset-created and change-restored events via Gerrit SSH stream.
          c['change_source'] = [
              changes.GerritChangeSource(
                  gerritserver='gerrit.plumj.am',
                  gerritport=29418,
                  username='buildbot',
                  identity_file='/run/agenix/gerritBuildbotSshKey',
                  handled_events=["patchset-created", "change-restored"],
              )
          ]

          # --- Gerrit Schedulers ---
          # NOTE: Reuses gitea builders (PlumWorks/grove/nix-eval). Checkout uses
          # steps.Git from Forgejo URL — relies on Gerrit→Forgejo replication
          # completing within treeStableTimer (30s).
          # Post-merge (ref-updated) builds are handled by Gitea webhooks after
          # Gerrit replication updates Forgejo's default branch.
          c['schedulers'] = [
              schedulers.AnyBranchScheduler(
                  name="grove-gerrit-upload-master",
                  change_filter=util.GerritChangeFilter(
                      branch='master',
                      eventtype='patchset-created',
                  ),
                  treeStableTimer=30,
                  builderNames=["PlumWorks/grove/nix-eval"],
                  properties={
                      "event.project": "grove",
                      "project": "grove",
                      "gerrit_change": True,
                  },
              ),
          ]

          # --- Gerrit Status Reporter (Verified vote) ---
          c['services'].append(
              reporters.GerritStatusPush(
                  'gerrit.plumj.am',
                  'buildbot',
                  port=29418,
                  identity_file='/run/agenix/gerritBuildbotSshKey',
                  generators=[
                      BuildStatusGenerator(
                          message_formatter=MessageFormatterFunction(
                              lambda data: gerritReviewFmt('https://buildbot.plumj.am', data),
                              "plain",
                              want_properties=True,
                              want_steps=True,
                          ),
                      ),
                  ],
              )
          )

          # --- Build Canceller ---
          # Replaces upstream canceller (disabled via removed patch). Dynamically
          # discovers all nix-eval builders at config time and cancels in-progress
          # builds when a new change arrives for the same branch/ref-group.
          eval_builders = [
              b.name for b in c.get('builders', [])
              if b.name.endswith('/nix-eval')
          ]
          if eval_builders:
              c['services'].append(
                  util.OldBuildCanceller(
                      "build_canceller",
                      filters=[
                          (eval_builders, util.SourceStampFilter(filter_fn=lambda ss: True))
                      ],
                      branch_key=gerritBranchKey,
                  )
              )

          # --- Protocols (worker connection) ---
          c["protocols"] = {"pb": {"port": "tcp:9989:interface=\\:\\:"}}

          # --- UI ---
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
