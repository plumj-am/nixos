{ pkgs, config, lib, ... }: let
  inherit (lib) mkIf;
in {
  environment.systemPackages = [
    # starship-jj from crates.io
    (pkgs.rustPlatform.buildRustPackage rec {
      pname = "starship-jj";
      version = "0.5.1";
      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-tQEEsjKXhWt52ZiickDA/CYL+1lDtosLYyUcpSQ+wMo=";
      };
      cargoHash = "sha256-+rLejMMWJyzoKcjO7hcZEDHz5IzKeAGk1NinyJon4PY=";
      meta = {
        description = "Starship module for Jujutsu VCS";
        homepage = "https://crates.io/crates/starship-jj";
      };
    })
  ];

  home-manager.sharedModules = [{
    home.file.".config/starship-jj/starship-jj.toml" = mkIf config.isDesktop {
      text = /* toml */ ''
        module_separator = " "
        reset_color = false

        [bookmarks]
        search_depth = 100
        exclude      = []

        # Disable the symbol module.
        # [[module]]
        # type     = "Symbol"
        # symbol   = "󱗆 "
        # color    = "Blue"

        [[module]]
        type                 = "Bookmarks"
        separator            = " "
        color                = "Magenta"
        behind_symbol        = "⇡"
        surround_with_quotes = false

        [[module]]
        type                 = "Commit"
        max_length           = 18
        empty_text           = "(no description)"
        surround_with_quotes = true

        [[module]]
        type      = "State"
        separator = " "

        [module.conflict]
        disabled = false
        text     = "(CONFLICT)"
        color    = "Red"

        [module.divergent]
        disabled = false
        text     = "(DIVERGENT)"
        color    = "Cyan"

        [module.empty]
        disabled = false
        text     = "(EMPTY)"
        color    = "Yellow"

        [module.immutable]
        disabled = false
        text     = "(IMMUTABLE)"
        color    = "Yellow"

        [module.hidden]
        disabled = false
        text     = "(HIDDEN)"
        color    = "Yellow"

        [[module]]
        type     = "Metrics"
        template = "[{changed} {added}{removed}]"
        color    = "Magenta"

        [module.changed_files]
        prefix = ""
        suffix = ""
        color  = "Cyan"

        [module.added_lines]
        prefix = "+"
        suffix = ""
        color  = "Green"

        [module.removed_lines]
        prefix = "-"
        suffix = ""
        color  = "Red"
      '';
    };
  }];
}
