{ self, ... }:
{
  flake.modules.common.default = self.modules.common.ai-skills;
  flake.modules.common.ai-skills =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) attrByPath;
      inherit (lib.lists) all elem filter;
      # a skill set documents a tool; installing it is only useful when that
      # tool is in the system, so gate on the packages the host actually has
      installedPackages =
        (attrByPath [ "environment" "systemPackages" ] [ ] config)
        ++ (attrByPath [ "home" "packages" ] [ ] config);
      installedSkills =
        entries: filter (entry: all (dep: elem dep installedPackages) (entry.requires or [ ])) entries;
    in
    {
      config = {
        ai.skills.npm = [
          {
            repo = "mattpocock/skills";
            skills = [
              "grilling"
              "grill-me"
              "grill-with-docs"
            ];
          }
          {
            repo = "https://github.com/stablyai/orca";
            skills = [
              "orchestration"
              "orca-cli"
            ];
            # the orca skills drive the orca CLI, so skip them where it is absent
            requires = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca ];
          }
        ];
        ai.skills.gh = [
          {
            repo = "bos/jj-stack";
            skills = [
              "jj-stack@7d8a68f3de6273e4c08c250f8aae1b1c9a2" # v1.3.0 (matches ../jujutsu.nix)
            ];
          }
          {
            repo = "github/gh-stack";
            skills = [
              "gh-stack@2bd699a544a09cb5c45a013d03416e0894b0454e" # v0.1.1
            ];
          }
        ];
        ai.skills.local = [
          {
            name = "pr-review-cron";
            skillmd = ''
              ---
              name: pr-review-cron
              description: Review pull requests for bugs, performance, security issues, and code quality
              ---

              # Code Review Guidelines

              When reviewing a pull request:

              ## What to Check
              1. **Bugs** — Logic errors, off-by-one, null/undefined handling
              2. **Security** — Injection, auth bypass, secrets in code, SSRF
              3. **Performance** — N+1 queries, unbounded loops, memory leaks
              4. **Style** — Naming conventions, dead code, missing error handling
              5. **Tests** — Are changes tested? Do tests cover edge cases?

              ## Output Format
              For each finding:
              - **File:Line** — exact location (hyperlinked!)
              - **Severity** — Critical / Warning / Suggestion
              - **What's wrong** — one sentence
              - **Fix** — how to fix it

              ## Rules
              - Be specific. Quote the problematic code.
              - Don't flag style nitpicks unless they affect readability.
              - If the PR looks good, say so. Don't invent problems.
              - End with: APPROVE / REQUEST_CHANGES / COMMENT
            '';
          }
        ];

        ai.skills.ghInstalled = installedSkills config.ai.skills.gh;
        ai.skills.npmInstalled = installedSkills config.ai.skills.npm;
        ai.skills.localInstalled = installedSkills config.ai.skills.local;
      };
    };
}
