{
  flake.modules.common.ai-shared =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (lib.strings) concatMapStringsSep;

      npmSkills = [
        {
          repo = "mattpocock/skills";
          skills = [
            "grilling"
            "grill-me"
            "grill-with-docs"
          ];
        }
      ];
      ghSkills = [
        {
          repo = "bos/jj-stack";
          skills = [
            "jj-stack@v0.1.3"
          ];
        }
      ];
    in
    {
      hjemModule = {
        systemd.services.install-ai-plugins-skills = {
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "120s";
          };

          path = [
            pkgs.bash
            pkgs.gcc
            pkgs.gitMinimal
            pkgs.gnumake
            pkgs.nodejs
            pkgs.node-gyp
          ];
          environment.PYTHON = getExe pkgs.python3;
          script = "${pkgs.writers.writeNu "install-ai-plugins-skills.nu" # nu
            ''
              print "installing omp plugins..."
              cd ~/.omp/plugins
              rm --force --recursive bun.lock node_modules/
              ${getExe pkgs.bun} install --force --refresh

              print "installing npm skills..."
              ${concatMapStringsSep "\n" (entry: ''
                print "adding skills from ${entry.repo}"
                (${getExe pkgs.skills} add ${entry.repo}
                  ${concatMapStringsSep " " (skill: "--skill ${skill}") entry.skills}
                  --yes
                  --agent universal
                  --global)
              '') npmSkills}

              print "installing gh skills..."
              ${concatMapStringsSep "\n" (entry: ''
                print "adding skills from ${entry.repo}"
                (${getExe pkgs.gh} skill install ${entry.repo}
                  ${concatMapStringsSep " " (skill: "${skill}") entry.skills}
                  --agent universal
                  --scope user
                  --force)
              '') ghSkills}
            ''
          }";
        };

        systemd.services.install-ai-plugins-skills-trigger = {
          after = singleton "nixos-activation.service";
          wantedBy = singleton "default.target";

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl --user start --no-block install-ai-plugins-skills.service";
          };
        };
      };
    };
}
