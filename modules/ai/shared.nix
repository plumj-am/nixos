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
      inherit (lib.modules) mkForce;
      inherit (lib.strings) concatMapStringsSep;
      inherit (config.ai) skills;

      # v2.7.0 has no `omp` id in the provider matrix (`--only omp` exits 2 with
      # "unknown agent: omp"), so the install service dies before caveman — and
      # before every later step. omp support landed on main after the tag; pin
      # the commit until a tagged release ships it.
      cavemanSource = pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "2fd153c67988e980fb0b2455c90832159a6a5a25";
        hash = "sha256-KFfU8LmNajKLZcOXOFisn4beTcg2YL+rpasr39UgSZE=";
      };
      cavemanInstaller =
        pkgs.runCommand "caveman-installer-ultra"
          {
            nativeBuildInputs = [ pkgs.gnused ];
          }
          ''
            cp -r ${cavemanSource}/. $out
            chmod -R u+w $out
            substituteInPlace $out/src/hooks/caveman-config.js \
              --replace-fail "return 'full';" "return 'ultra';"
          '';
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

        # technically defined more than once
        xdg.config.files."caveman/config.json" = {
          generator = mkForce <| pkgs.writers.writeJSON "caveman-config.json";
          value.defaultMode = "ultra";
        };
      };
    };
}
