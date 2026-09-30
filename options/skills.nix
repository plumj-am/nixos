{ lib }:
{
  repoSkill = lib.types.submodule {
    options = {
      repo = lib.mkOption {
        type = lib.types.str;
        description = "Upstream repository that hosts the skill.";
      };
      skills = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of skill names to install from the repository. Empty means install every skill the repository provides.";
      };
      requires = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages that must be part of the installed system for this skill set to be installed.";
      };
    };
  };

  localSkill = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the local skill.";
      };
      skillmd = lib.mkOption {
        type = lib.types.lines;
        description = "Skill instructions in markdown.";
      };
      requires = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages that must be part of the installed system for this skill set to be installed.";
      };
    };
  };
}
