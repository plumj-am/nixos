{
  flake.modules.nixos.opengist =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config.networking) domain hostName;
      inherit (config.myLib) merge systemdHardened;

      fqdn = "gist.${domain}";
      port = 8002;
      forgejoUrl = "git.plumj.am";

      user = "forgejo";
      workDir = "/var/lib/opengist";
    in
    {
      assertions = singleton {
        assertion = config.services.forgejo.enable;
        message = "The opengist module should be used on the host running Forgejo, but you're trying to enable it on '${hostName}'.";
      };

      systemd.services.opengist = {
        description = "OpenGist";
        after = [
          "network.target"
          "forgejo.service"
        ];
        requires = singleton "forgejo.service";
        wantedBy = singleton "multi-user.target";
        path = singleton pkgs.git;

        serviceConfig = systemdHardened // {
          Type = "notify";
          User = user;
          Group = user;
          ExecStart = "${getExe pkgs.opengist} --config /etc/opengist/config.yml";
          Restart = "always";
          WorkingDirectory = workDir;
          EnvironmentFile = singleton config.age.secrets.opengistEnvironment.path;

          RuntimeDirectory = "opengist";
          ReadWritePaths = singleton workDir;
        };
      };

      services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
        locations."/".proxyPass = "http://0.0.0.0:${toString port}";
      };

      environment.etc."opengist/config.yml".text = # yml
        ''
          log-level: warn

          opengist-home: ${workDir}
          external-url: https://${fqdn}

          git.default-branch: master

          http.port: ${toString port}
          ssh.git-enabled: false

          gitea.name: ${forgejoUrl}
          gitea.url: https://${forgejoUrl}/

          custom.name: PlumJam's Gist Server
          custom.static-links:
            - name: <PlumJam's Git Forge>
              path: https://${forgejoUrl}
        '';
    };
}
