{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.ai-shared;
  flake.modules.common.ai-shared =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.ai) skills;
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (lib.strings) concatMapStringsSep;
      # `skills add`/`gh skill install` list skills instead of installing when
      # no skill is named, so an empty list means "every skill in the repo".
      # Keep the star quoted: nushell glob-expands a bare `*`.
      npmSkillFlags =
        entry:
        if entry.skills == [ ] then
          "--skill '*'"
        else
          concatMapStringsSep " " (skill: "--skill ${skill}") entry.skills;

      ghSkillFlags =
        entry:
        if entry.skills == [ ] then "--all" else concatMapStringsSep " " (skill: "${skill}") entry.skills;
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
                  ${npmSkillFlags entry}
                  --yes
                  --agent universal
                  --global)
              '') skills.npm}

              print "installing gh skills..."
              ${concatMapStringsSep "\n" (entry: ''
                print "adding skills from ${entry.repo}"
                (${getExe pkgs.gh} skill install ${entry.repo}
                  ${ghSkillFlags entry}
                  --agent universal
                  --scope user
                  --force)
              '') skills.gh}
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
