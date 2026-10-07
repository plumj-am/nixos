{ self, ... }:
{
  flake.modules.nixos.web-server = self.modules.nixos.ferron;
  flake.modules.nixos.ferron =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.networking) domain;

      cfg = config.services.ferron;

      # Vhost definitions live in `services.ferronVhosts` (option schema
      # mirrors the upstream module's `services.ferron.hosts`) and this
      # aspect renders ferron.conf itself via `services.ferron.configFile`.
      #
      # Why not the upstream module's own rendering: it always emits a demo
      # `*:80` host block, and in ferron 3.0.0-rc.9 the mere presence of an
      # explicit-port block flips the shared port to HTTPS once any TLS
      # host exists (probe: `*:80 { }` plus a bare TLS host =>
      # "HTTPS server listening on :80"; plain HTTP dead). A bare `*`
      # catch-all is no alternative: `status` on the wildcard bleeds into
      # named hosts. Rendering ourselves keeps every host a bare hostname
      # (plain HTTP on the default HTTP port, TLS on the default HTTPS
      # port), and setting `configFile` turns the upstream demo def into a
      # no-op (`mkIf configFile == null`), so it cannot leak back in.
      #
      # The rendering logic below is copied from the upstream module
      # (nix/module.nix in ferronweb/ferron) and must stay in sync with it.

      indent4 = s: "    " + builtins.replaceStrings [ "\n" ] [ "\n    " ] s;

      # Header values are always double-quoted (CSP et al. contain spaces
      # and semicolons). Backslashes and double quotes are escaped; `{{...}}`
      # interpolation passes through untouched.
      escapeHeaderValue = s: "\"" + builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s + "\"";

      headersLines =
        headers:
        (lib.mapAttrsToList (name: value: "header ${name} ${escapeHeaderValue value}") headers.set)
        ++ (lib.mapAttrsToList (name: value: "header +${name} ${escapeHeaderValue value}") headers.add)
        ++ (map (name: "header -${name}") headers.unset);

      cacheLines =
        cache:
        let
          sub =
            (lib.optional cache.litespeedOverrideCacheControl "litespeed_override_cache_control")
            ++ (lib.optional cache.emitLitespeedHeaders "emit_litespeed_headers")
            ++ (lib.optional (cache.vary != [ ]) "vary ${lib.concatStringsSep " " cache.vary}")
            ++ (lib.optional (
              cache.varyCookies != [ ]
            ) "vary_cookies ${lib.concatStringsSep " " cache.varyCookies}")
            ++ (lib.optional (cache.ignore != [ ]) "ignore ${lib.concatStringsSep " " cache.ignore}")
            ++ (lib.optional (
              cache.maxResponseSize != null
            ) "max_response_size ${toString cache.maxResponseSize}");
        in
        if !cache.enable then
          [ ]
        else if sub == [ ] then
          [ "cache" ]
        else
          [ "cache {\n${indent4 (lib.concatStringsSep "\n" sub)}\n}" ];

      hostDirectives =
        host:
        # TLS first: affects listener setup (see docs/configuration/security/tls.md).
        (lib.optional (!host.tls.enable) "tls false")
        ++ (lib.optional (
          host.tls.enable && host.tls.cert != null && host.tls.key != null
        ) "tls ${host.tls.cert} ${host.tls.key}")
        ++ (lib.optional (
          host.httpsRedirect != null
        ) "https_redirect ${lib.boolToString host.httpsRedirect}")
        ++ (lib.optional (host.root != null) "root ${host.root}")
        ++ (lib.optional (
          host.index != null && host.index != [ ]
        ) "index ${lib.concatStringsSep " " host.index}")
        ++ (cacheLines host.cache)
        ++ (lib.optional (host.proxy != null) (
          if host.proxyExtraConfig == "" then
            "proxy ${host.proxy}"
          else
            "proxy ${host.proxy} {\n${indent4 host.proxyExtraConfig}\n}"
        ))
        ++ (lib.optional (host.fcgiPhp != null) "fcgi_php ${host.fcgiPhp}")
        ++ (headersLines host.headers)
        ++ (lib.optional host.spaFallback ''
          rewrite r"^/.*" "/" {
              last
              directory false
              file false
          }'');

      hostBlock = name: host: ''
        ${name} {
        ${lib.concatStringsSep "\n" (hostDirectives host)}
        ${host.config}
        }
      '';

      generatedConf = pkgs.writeText "ferron.conf" ''
        {
        ${cfg.globalConfig}
        }

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList hostBlock config.services.ferronVhosts)}

        ${cfg.extraConfig}
      '';

      explicitPortHosts = lib.filter (name: builtins.match ".*:[0-9]+$" name != null) (
        builtins.attrNames config.services.ferronVhosts
      );
    in
    {
      imports = [ inputs.ferron.nixosModules.default ];

      options.services.ferronVhosts = lib.mkOption {
        default = { };
        description = ''
          Ferron host blocks rendered into ferron.conf by the web-server
          aspect (same schema as the upstream `services.ferron.hosts`, which
          is bypassed; see the comment in modules/ferron.nix).
        '';
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              config = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "Verbatim content appended at the end of the host block.";
              };

              root = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Web root (`root <path>`).";
              };

              index = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                default = null;
                description = "Directory index files (`index <name>...`).";
              };

              proxy = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Reverse-proxy upstream (`proxy <url>`).";
              };

              proxyExtraConfig = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "Verbatim lines inside the `proxy <url> { ... }` block.";
              };

              tls = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Set to false to render `tls false`.";
                };
                cert = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "TLS certificate path for manual TLS.";
                };
                key = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "TLS private key path for manual TLS.";
                };
              };

              httpsRedirect = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Renders `https_redirect true|false` when set.";
              };

              spaFallback = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Single-page-app fallback rewrite for non-file, non-directory requests.";
              };

              fcgiPhp = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "PHP-FPM backend (`fcgi_php <url>`).";
              };

              headers = {
                set = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Replace (set) response headers.";
                };
                add = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Append response headers (allows duplicates).";
                };
                unset = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Remove response headers.";
                };
              };

              cache = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Enables HTTP response caching for this host.";
                };
                litespeedOverrideCacheControl = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "LSCache compatibility (litespeed_override_cache_control).";
                };
                emitLitespeedHeaders = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Echo X-LiteSpeed-* headers on cache hits.";
                };
                vary = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Response partitioning dimensions (vary ...).";
                };
                varyCookies = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Cookie partitioning dimensions (vary_cookies ...).";
                };
                ignore = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Cache-control tokens to ignore (ignore ...).";
                };
                maxResponseSize = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Largest cacheable response body in bytes.";
                };
              };
            };
          }
        );
      };

      config = {
        assertions = [
          {
            assertion = explicitPortHosts == [ ];
            message = ''
              services.ferronVhosts contains explicit-port selectors (${lib.concatStringsSep ", " explicitPortHosts}).
              In ferron 3.0.0-rc.9 they flip the shared port to HTTPS when any TLS host
              exists. Use bare hostname selectors instead.
            '';
          }
          {
            # With configFile set, upstream's demo `*:80` def is discharged
            # (its content is empty), but the submodule key itself remains.
            # Anything beyond that shape is a vhost defined on the bypassed
            # option - it would silently never be rendered.
            assertion = builtins.attrNames cfg.hosts == [ "*:80" ] && cfg.hosts."*:80".config == "";
            message = ''
              services.ferron.hosts carries definitions beyond the upstream
              demo block (${lib.concatStringsSep ", " (builtins.attrNames cfg.hosts)}).
              The web-server aspect renders services.ferronVhosts through
              services.ferron.configFile; move host definitions there.
            '';
          }
        ];

        # Fail at deploy instead of a systemd restart loop: the same check
        # the unit runs in ExecStartPre.
        system.checks = [
          (pkgs.runCommand "ferron-config-validate" { } ''
            ${lib.getExe cfg.package} validate -c ${generatedConf}
            touch $out
          '')
        ];

        networking.firewall = {
          allowedTCPPorts = [
            443
            80
          ];
          allowedUDPPorts = [ 443 ];
        };

        security.acme = {
          users = [ "ferron" ];

          certs.${domain}.reloadServices = [ "ferron.service" ];
        };

        services.ferron = {
          enable = true;
          package = inputs.ferron.packages.${pkgs.stdenv.hostPlatform.system}.ferron-bin;
          openFirewall = false;

          # Access and application logs go to stdout, which systemd
          # captures in the journal (`journalctl -u ferron`). This drops
          # the upstream module default of rotated files under
          # /var/log/ferron.
          globalConfig = ''
            console_log
          '';

          # Self-rendered (see the comment above); the upstream module's
          # generated file - including its demo `*:80` block - is unused.
          configFile = generatedConf;
        };
      };
    };
}
