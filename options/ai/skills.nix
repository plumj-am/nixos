{ self, ... }:
{
  flake.commonModules.ai-skills = self.commonModules.ai-skills-options;
  flake.commonModules.ai-skills-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types)
        lines
        listOf
        package
        str
        submodule
        ;

      repoSkill = submodule {
        options = {
          repo = mkOption {
            type = str;
            description = "Upstream repository that hosts the skill.";
          };
          skills = mkOption {
            type = listOf str;
            default = [ ];
            description = "List of skill names to install from the repository. Empty means install every skill the repository provides.";
          };
          requires = mkOption {
            type = listOf package;
            default = [ ];
            description = "Packages that must be part of the installed system for this skill set to be installed.";
          };
        };
      };

      localSkill = submodule {
        options = {
          name = mkOption {
            type = str;
            description = "Name of the local skill.";
          };
          skillmd = mkOption {
            type = lines;
            description = "Skill instructions in markdown.";
          };
          requires = mkOption {
            type = listOf package;
            default = [ ];
            description = "Packages that must be part of the installed system for this skill set to be installed.";
          };
        };
      };
    in
    {
      options.ai = {
        skills.gh = mkOption {
          type = listOf repoSkill;
          default = [ ];
          description = ''
            skills to install from github
          '';
        };
        skills.npm = mkOption {
          type = listOf repoSkill;
          default = [ ];
          description = ''
            skills to install from npm
          '';
        };
        skills.local = mkOption {
          type = listOf localSkill;
          default = [ ];
          description = ''
            skills to install from local sources
          '';
        };
        # read-only views of the writable options above, with skill sets whose
        # `requires` packages are missing from this host filtered out
        skills.ghInstalled = mkOption {
          type = listOf repoSkill;
          readOnly = true;
          description = ''
            github skills whose required packages are installed
          '';
        };
        skills.npmInstalled = mkOption {
          type = listOf repoSkill;
          readOnly = true;
          description = ''
            npm skills whose required packages are installed
          '';
        };
        skills.localInstalled = mkOption {
          type = listOf localSkill;
          readOnly = true;
          description = ''
            local skills whose required packages are installed
          '';
        };
      };
    };
}
