{ self, ... }:
{
  flake.modules.nixos.uptime-kuma =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        attrNames
        attrValues
        filterAttrs
        isAttrs
        mapAttrsToList
        ;
      inherit (lib.lists)
        concatMap
        filter
        groupBy
        length
        singleton
        ;
      inherit (lib.meta) getExe;
      inherit (lib.modules) merge;
      inherit (lib.strings) concatMapStringsSep concatStrings optionalString;
      inherit (config.networking) domain;

      fqdn = "uptime.${domain}";
      port = 3001;
      host = "127.0.0.1";

      cfg = config.services.uptime-kuma;

      # Uptime Kuma reads the monitor table only when it starts, and it offers
      # no way to create monitors from outside: its REST router serves badges
      # and the push endpoint only, and the JSON import in the UI is
      # deprecated. So the wanted monitors are written straight into SQLite by
      # a preStart script.
      #
      # The monitors come from every host in the flake that serves nginx. A
      # virtual host counts as public when it asks for an ACME certificate,
      # which is what `merge config.services.nginx.sslTemplate` sets.
      # Services without a virtual host (postgres, the build machines) need a
      # monitor of their own.
      servesRoot =
        vhost:
        let
          slash = vhost.locations."/" or { };
          set = name: (slash.${name} or null) != null;
        in
        isAttrs slash
        && !set "return"
        && (set "proxyPass" || set "root" || set "alias" || set "tryFiles" || vhost.root != null);

      publicVhost = vhost: (vhost.useACMEHost or null) != null && servesRoot vhost;

      # Virtual host name -> the hosts that serve it, so a name served from two
      # places stays one monitor.
      monitored =
        filterAttrs (name: _: name != fqdn && name != "_" && name != "localhost")
        <| groupBy (entry: entry.name)
        <| concatMap (
          hostConfig:
          mapAttrsToList (
            name: _: {
              host = hostConfig.config.networking.hostName;
              inherit name;
            }
          )
          <| filterAttrs (_: publicVhost) hostConfig.config.services.nginx.virtualHosts
        )
        <| filter (hostConfig: hostConfig.config.services.nginx.enable)
        <| attrValues self.nixosConfigurations;

      monitoredNames = attrNames monitored;
      servingHosts = hosts: concatMapStringsSep ", " (entry: entry.host) hosts;

      # Any answer from the origin means the name is served: redirects are
      # normal for login pages, 401/403 for auth-gated services and the Garage
      # S3 API, 404 for the Garage web endpoint at "/". Only a dead origin
      # (5xx, TLS or connection failure) counts as down. The cost of this
      # ceiling: a service whose root stops serving content stays green.
      acceptedStatusCodes = ''["200-399","401","403","404"]'';

      # Monitors owned by this module carry this tag. The seeder only inserts,
      # updates and deactivates tagged rows, so monitors made in the UI keep
      # working, notifications attached in the UI keep firing, and history is
      # never dropped.
      markerTag = "nix";

      monitorSql =
        concatStrings
        <| mapAttrsToList (
          name: hosts: # sql
          ''
            INSERT INTO monitor (name, active, user_id, description, interval, retry_interval, url, type, weight, maxretries, accepted_statuscodes_json)
            SELECT '${name}', 1, (SELECT id FROM user ORDER BY id LIMIT 1), '${servingHosts hosts}', 60, 60, 'https://${name}/', 'http', 2000, 2, '${acceptedStatusCodes}'
            WHERE EXISTS (SELECT 1 FROM user)
            AND NOT EXISTS (
              SELECT 1 FROM monitor
              WHERE name = '${name}' AND user_id = (SELECT id FROM user ORDER BY id LIMIT 1)
            );

            UPDATE monitor
            SET active = 1,
                type = 'http',
                url = 'https://${name}/',
                description = '${servingHosts hosts}',
                interval = 60,
                retry_interval = 60,
                maxretries = 2,
                accepted_statuscodes_json = '${acceptedStatusCodes}'
            WHERE name = '${name}' AND user_id = (SELECT id FROM user ORDER BY id LIMIT 1);

            INSERT INTO monitor_tag (monitor_id, tag_id, value)
            SELECT monitor.id, tag.id, NULL
            FROM monitor, tag
            WHERE monitor.name = '${name}'
              AND monitor.user_id = (SELECT id FROM user ORDER BY id LIMIT 1)
              AND tag.name = '${markerTag}'
              AND NOT EXISTS (
                SELECT 1 FROM monitor_tag
                WHERE monitor_tag.monitor_id = monitor.id AND monitor_tag.tag_id = tag.id
              );

            INSERT INTO monitor_group (monitor_id, group_id, weight, send_url)
            SELECT monitor.id, "group".id, 1000, 0
            FROM monitor, "group"
            WHERE monitor.name = '${name}'
              AND "group".name = 'Services'
              AND "group".status_page_id = (SELECT id FROM status_page WHERE slug = 'status')
              AND NOT EXISTS (
                SELECT 1 FROM monitor_group
                WHERE monitor_group.monitor_id = monitor.id AND monitor_group.group_id = "group".id
              );
          '') monitored;

      # Monitors that this module no longer declares are deactivated and taken
      # off the status page, never deleted: heartbeat rows cascade on delete.
      retired = # sql
        ''
          id IN (
            SELECT monitor_tag.monitor_id
            FROM monitor_tag, tag
            WHERE tag.name = '${markerTag}' AND tag.id = monitor_tag.tag_id
          )
          AND name NOT IN (${concatMapStringsSep ", " (name: "'${name}'") monitoredNames})
        '';

      retireSql =
        optionalString (monitoredNames != [ ]) # sql
          ''
            UPDATE monitor SET active = 0
            WHERE ${retired};

            DELETE FROM monitor_group
            WHERE monitor_id IN (SELECT id FROM monitor WHERE ${retired})
              AND group_id IN (
                SELECT "group".id
                FROM "group"
                WHERE "group".name = 'Services'
                  AND "group".status_page_id = (SELECT id FROM status_page WHERE slug = 'status')
              );
          '';

      seedSql =
        pkgs.writeText "uptime-kuma-seed.sql" # sqlite
          ''
            -- Generated by modules/uptime-kuma.nix and applied on every start, so
            -- every statement has to be idempotent.

            INSERT INTO tag (name, color)
            SELECT '${markerTag}', '#4a5568'
            WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = '${markerTag}');

            INSERT INTO status_page (slug, title, icon, theme, published, show_tags)
            SELECT 'status', '${domain}', '/icon.svg', 'light', 1, 0
            WHERE NOT EXISTS (SELECT 1 FROM status_page WHERE slug = 'status');

            UPDATE status_page SET title = '${domain}' WHERE slug = 'status';

            INSERT INTO "group" (name, public, active, weight, status_page_id)
            SELECT 'Services', 1, 1, 1000, (SELECT id FROM status_page WHERE slug = 'status')
            WHERE NOT EXISTS (
              SELECT 1 FROM "group"
              WHERE name = 'Services' AND status_page_id = (SELECT id FROM status_page WHERE slug = 'status')
            );

            ${monitorSql}
            ${retireSql}
          '';

      seedScript = pkgs.writeShellApplication {
        name = "uptime-kuma-seed";
        runtimeInputs = [ pkgs.sqlite ];
        text = # bash
          ''
            db="${cfg.settings.DATA_DIR}kuma.db"

            if [ ! -f "$db" ]; then
              echo "uptime-kuma-seed: $db does not exist yet, nothing to seed"
              exit 0
            fi

            if [ "$(${getExe pkgs.sqlite} "$db" "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'monitor'")" != 1 ]; then
              echo "uptime-kuma-seed: schema is not migrated yet, nothing to seed"
              exit 0
            fi

            # A monitor belongs to a user. Before the account from the setup page
            # exists there is nothing to attach monitors to.
            if [ "$(${getExe pkgs.sqlite} "$db" "SELECT count(*) FROM user")" = 0 ]; then
              echo "uptime-kuma-seed: no user yet, create the admin account and restart"
              exit 0
            fi

            # A broken seed must not keep the dashboard down: report it and let
            # the service start with the monitors it already has.
            if ${getExe pkgs.sqlite} "$db" < ${seedSql}; then
              echo "uptime-kuma-seed: applied ${toString (length monitoredNames)} monitors"
            else
              echo "uptime-kuma-seed: seeding failed, the dashboard keeps its current monitors"
            fi
          '';
      };
    in
    {
      services.uptime-kuma = {
        enable = true;
        settings = {
          HOST = host;
          port = toString port;
        };
      };

      systemd.services.uptime-kuma = {
        preStart = getExe seedScript;
        restartTriggers = [
          seedScript
          seedSql
        ];
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        serverAliases = singleton "status.${domain}";
        locations."/" = {
          proxyPass = "http://${host}:${toString port}";
          proxyWebsockets = true;
          extraConfig = # nginx
            ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
        };
      };
    };
}
