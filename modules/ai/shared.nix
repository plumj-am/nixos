{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.ai-shared;
  flake.modules.common.ai-shared =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.strings) concatMapStringsSep;
      inherit (config.ai) skills;

      # Pinned with opencode.nix; bump together.
      cavemanInstaller = pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "v2.7.0";
        hash = "sha256-dsGzPscjy7FfaovfYML2q+RmuBJwwEJ9sjeHi+Niv6Y=";
      };
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
            inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
          ];
          environment.PYTHON = getExe pkgs.python3;
          script = "${pkgs.writers.writeNu "install-ai-plugins-skills.nu" # nu
            ''
              print "installing omp plugins..."
              cd ~/.omp/plugins
              rm --force --recursive bun.lock node_modules/
              ${getExe pkgs.bun} install --force --refresh
              print "installing caveman plugins..."
              node ${cavemanInstaller}/bin/install.js --only omp --only opencode --non-interactive

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

              print "installing rtk extension..."
              # rtk 0.45.0 has no `--agent omp`: the pi extension is the same file OMP
              # loads through legacy-pi-compat, and PI_CODING_AGENT_DIR redirects the
              # install into OMP's agent directory.
              with-env { PI_CODING_AGENT_DIR: ($env.HOME | path join ".omp/agent") } {
                ${getExe pkgs.rtk} init --agent pi --global --auto-patch
              }

              print "installing opencode plugin..."
              # One file, no config side effects: ~/.config/opencode/plugins/rtk.ts
              ${getExe pkgs.rtk} init -g --opencode --auto-patch
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
