{ self, ... }:
{
  flake.modules.common.ai-skills = self.modules.common.ai-skills-options;
  flake.modules.common.ai-skills-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types)
        lines
        listOf
        package
        str
        submodule
        ;

      repoSkill = submodule {
        options = {
          repo = mkOptionOf str {
            description = "Upstream repository that hosts the skill.";
          };
          skills = mkOptionOf (listOf str) {
            default = [ ];
            description = "List of skill names to install from the repository. Empty means install every skill the repository provides.";
          };
          requires = mkOptionOf (listOf package) {
            default = [ ];
            description = "Packages that must be part of the installed system for this skill set to be installed.";
          };
        };
      };

      localSkill = submodule {
        options = {
          name = mkOptionOf str {
            description = "Name of the local skill.";
          };
          skillmd = mkOptionOf lines {
            description = "Skill instructions in markdown.";
          };
          requires = mkOptionOf (listOf package) {
            default = [ ];
            description = "Packages that must be part of the installed system for this skill set to be installed.";
          };
        };
      };
    in
    {
      options.ai = {
        skills.gh = mkOptionOf (listOf repoSkill) {
          type = listOf repoSkill;
          default = [ ];
          description = ''
            skills to install from github
          '';
        };
        skills.npm = mkOptionOf (listOf repoSkill) {
          default = [ ];
          description = ''
            skills to install from npm
          '';
        };
        skills.local = mkOptionOf (listOf localSkill) {
          default = [ ];
          description = ''
            skills to install from local sources
          '';
        };
        # read-only views of the writable options above, with skill sets whose
        # `requires` packages are missing from this host filtered out
        skills.ghInstalled = mkOptionOf (listOf repoSkill) {
          readOnly = true;
          description = ''
            github skills whose required packages are installed
          '';
        };
        skills.npmInstalled = mkOptionOf (listOf repoSkill) {
          readOnly = true;
          description = ''
            npm skills whose required packages are installed
          '';
        };
        skills.localInstalled = mkOptionOf (listOf localSkill) {
          readOnly = true;
          description = ''
            local skills whose required packages are installed
          '';
        };
      };
    };
}
