{
  flake.modules.nixos.home-assistant =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.fixedPoints) fix;
      inherit (lib.lists) singleton;
      inherit (lib.modules) merge;
      inherit (config.helpers) rustic;
      inherit (config.localisation) location time_zone units;
      inherit (config.networking) domain;

      # Home Assistant pulls in pyturbojpeg, whose check phase needs pytest-memray.
      # That suite fails in the sandbox on Python 3.14, so drop its checks.
      hassPkgs =
        pkgs.appendOverlays
        <| singleton (
          _final: prev: {
            python314 = prev.python314.override {
              packageOverrides = _: pyPrev: {
                pytest-memray = pyPrev.pytest-memray.overridePythonAttrs (_: {
                  doCheck = false;
                  doInstallCheck = false;
                });

                # The `wiz` component declares pywizlight==0.6.3, but nixpkgs ships
                # 0.6.6, which changed `wizlight.state` from a single PilotParser
                # into a list. Every WiZ entity then dies on construction with
                # "'list' object has no attribute 'get_brightness'", so the
                # integration appears under Settings but registers no devices.
                # Pin until nixpkgs catches up.
                pywizlight = fix (
                  pywizlight:
                  pyPrev.pywizlight.overridePythonAttrs (_: {
                    version = "0.6.3";
                    pyproject = null;
                    format = "setuptools";

                    src = pkgs.fetchFromGitHub {
                      owner = "sbidy";
                      repo = "pywizlight";
                      tag = "v${pywizlight.version}";
                      hash = "sha256-rCoWdqvFLSLNBAHeFJ6f9kZpIg4WyE8VJLpmsYl+gJM=";
                    };
                  })
                );
              };
            };
          }
        );

      fqdn = "hass.${domain}";
      port = 8021;

      # Home Assistant 2026.8 moved the HTTP settings out of configuration.yaml
      # into the .storage/http store. A YAML `http:` block is migrated only once,
      # as an unconfirmed "pending" config that is reverted to the built-in
      # default after five minutes unless it is promoted in the UI - and YAML is
      # then ignored for good. Write the promoted shape into the stable slot
      # instead, so it applies directly and is never reverted. Rewritten on every
      # start, so changes made through the UI do not survive a restart.
      httpStoreFile = (pkgs.formats.json { }).generate "home-assistant-http.json" {
        version = 2;
        minor_version = 2;
        key = "http";
        data = {
          stable = {
            server_host = singleton "127.0.0.1";
            server_port = port;
            cors_allowed_origins = singleton "https://cast.home-assistant.io";
            # The nginx frontend always sends X-Forwarded-For, and Home Assistant
            # answers every request carrying it with HTTP 400 unless the proxy is
            # trusted.
            use_x_forwarded_for = true;
            trusted_proxies = [
              "127.0.0.1/32"
              "::1/128"
            ];
            login_attempts_threshold = -1;
            ip_ban_enabled = true;
            ssl_profile = "modern";
            use_x_frame_options = true;
            # Rewritten on every start, so keep a fixed stamp.
            created_at = "1970-01-01T00:00:00+00:00";
            error = null;
            error_message = null;
          };
          pending = null;
          yaml_migration_done = true;
        };
      };
      hassPython = hassPkgs.home-assistant.python3Packages;

      # py_mini_racer is not in nixpkgs, and upstream cannot be built from source:
      # its release process builds V8 out-of-band and refuses a plain source
      # build. Use the upstream manylinux wheel, which carries a statically
      # linked V8 plus its ICU data, needing only glibc and libgcc_s at runtime.
      pyMiniRacer = hassPython.buildPythonPackage {
        pname = "py-mini-racer";
        version = "0.14.1";
        format = "wheel";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/c2/3c/c5bd479784826bbbc69f713aae2bcfd5ef353ba4e5e0e661666938474535/mini_racer-0.14.1-py3-none-manylinux_2_27_x86_64.whl";
          hash = "sha256-zfOgiOE2PxamlSiPiCq/drNwW44d8hQYIIuH7QEAN6Q=";
        };

        nativeBuildInputs = singleton pkgs.autoPatchelfHook;
        buildInputs = singleton pkgs.stdenv.cc.cc.lib;

        doCheck = false;
        pythonImportsCheck = singleton "py_mini_racer";
      };

      # The builder runs nixpkgs' manifest check, so a dependency that stops
      # matching manifest.json fails the build instead of failing at runtime.
      # WiZ lights need no custom component: the built-in `wiz` one is enough.
      dreameVacuum = fix (
        dreame:
        hassPkgs.buildHomeAssistantComponent {
          owner = "Tasshack";
          domain = "dreame_vacuum";
          version = "2.0.0b25";

          src = pkgs.fetchFromGitHub {
            owner = "Tasshack";
            repo = "dreame-vacuum";
            tag = "v${dreame.version}";
            hash = "sha256-eZcv3Xwywt4UDxEU1aP60+KtOj1xibPPahFim2U5gaA=";
          };

          # A fixed-output hash identifies content, not the tag. If the hash still
          # points at a release already present in the store, Nix returns that
          # release without fetching anything, so bumping `version` alone looks
          # like it worked while the old code is still shipped. Check the manifest
          # actually in the source and fail instead.
          postPatch = ''
            grep -qE "\"version\": *\"v${dreame.version}\"" \
              custom_components/dreame_vacuum/manifest.json || {
              echo "dreame-vacuum source is not v${dreame.version}; the hash points at a" >&2
              echo "different release. Update the hash for tag v${dreame.version}." >&2
              exit 1
            }
          '';

          dependencies = with hassPython; [
            pillow
            numpy
            requests
            pycryptodome
            python-miio
            paho-mqtt
            pyMiniRacer
          ];
        }
      );
    in
    {
      services.rustic.backups.home-assistant = rustic.mkBackup "home-assistant" {
        paths = singleton "/var/lib/hass";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      services.home-assistant = {
        enable = true;
        package = hassPkgs.home-assistant.overrideAttrs (_: {
          doInstallCheck = false;
        });
        extraArgs = [ ];

        configDir = "/var/lib/hass";

        extraComponents = [
          "default_config" # Required to finish onboarding.
          "met"
          "esphome"
          "wiz" # WiZ smart lights, via pywizlight.
          "google_translate" # Text-to-speech; its config entry needs gtts.
        ];

        extraPackages = _: [ ];

        customComponents = singleton dreameVacuum;
        customLovelaceModules = with hassPkgs.home-assistant-custom-lovelace-modules; [
          xiaomi-vacuum-map-card
          light-entity-card
        ];

        themes = [ ];

        configWritable = true;
        config = {
          homeassistant = {
            name = "Home";
            inherit time_zone;
            unit_system = units.system;
            temperature_unit = units.temperature_short;
            inherit (location) latitude longitude;
          };
        };

        config.lovelace.dashboards.nixos-lovelace = {
          mode = "yaml";
          filename = "ui-lovelace.yaml";
          title = "Home";
          icon = "mdi:home-assistant";
          show_in_sidebar = true;
        };

        # Declarative config.
        lovelaceConfigFile = null;
        lovelaceConfigWritable = false;

        # Non-empty customLovelaceModules switches Lovelace to YAML resources and
        # registers the card at /local/nixos-lovelace-modules/, so this dashboard
        # only has to reference it. The card generates its own icons and tiles.
        lovelaceConfig = {
          title = "Home";
          views = [
            {
              title = "Lights";
              path = "lights";
              icon = "mdi:lightbulb-group";
              # A panel view renders its single card at full width. The default
              # masonry view is much narrower, which squeezed the three cards
              # together and wrapped the longer name onto a second line, leaving
              # the row uneven.
              type = "panel";
              cards =
                singleton
                  # A grid card lays the lights out side by side; cards stack
                  # vertically otherwise. `square` defaults to true, which forces
                  # each card square and clips the colour wheel.
                  {
                    type = "grid";
                    columns = 3;
                    square = false;
                    cards = [
                      # The bulbs are two RGBWW and one RGBW. The card only shows a
                      # warm-white slider for RGBWW, so the RGBW card would come out
                      # one slider shorter than its neighbours. Turn that slider off
                      # everywhere so all three cards have identical contents and
                      # therefore identical height.
                      {
                        type = "custom:light-entity-card";
                        entity = "light.wiz_rgbw_tunable_aa0d66";
                        warm_white_value = false;
                        persist_features = true;
                      }
                      {
                        type = "custom:light-entity-card";
                        entity = "light.wiz_rgbww_tunable_3b5160";
                        warm_white_value = false;
                        persist_features = true;
                      }
                      {
                        type = "custom:light-entity-card";
                        entity = "light.wiz_rgbww_tunable_3b88f0";
                        warm_white_value = false;
                        persist_features = true;
                      }
                    ];
                  };
            }
            {
              title = "Vacuum";
              path = "vacuum";
              icon = "mdi:robot-vacuum";
              cards = singleton {
                type = "custom:xiaomi-vacuum-map-card";
                entity = "vacuum.george_droid";
                map_source.camera = "camera.george_droid_map";
                # The integration publishes calibration from the map camera,
                # so no manual calibration points are needed.
                calibration_source.camera = true;
                vacuum_platform = "Tasshack/dreame-vacuum";
              };
            }
          ];
        };

        openFirewallForComponents = false;
      };

      # Home Assistant reads this store before it serves a request. The unit
      # already has its own preStart, so append to it instead of replacing it.
      systemd.services.home-assistant.preStart = lib.mkAfter ''
        install -d -m700 "${config.services.home-assistant.configDir}/.storage"
        install -m600 ${httpStoreFile} "${config.services.home-assistant.configDir}/.storage/http"
      '';

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };

      # Device discovery needs inbound UDP that the default policy refuses.
      # mDNS probes go to a multicast group and WiZ bulbs answer from their
      # service port to an ephemeral one, so no reverse conntrack flow exists
      # and the replies look like new connections. The WiZ reply port cannot be
      # matched by allowedUDPPorts, which only matches a destination port.
      networking.firewall = {
        allowedUDPPorts = singleton 5353;
        extraCommands = ''
          iptables -A nixos-fw -p udp --sport 38899 -j nixos-fw-accept
        '';
      };
    };
}
