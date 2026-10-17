{ inputs, lib, ... }:
let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
in
{
  imports = singleton inputs.treefmt.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        # nix
        programs.nixfmt = {
          enable = true;
          package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.organix;
        };
        settings.formatter.nixfmt = {
          width = 100;
          indent = 2;
          struct = true;
        };

        # toml
        programs.taplo = {
          enable = true;
          package = pkgs.taplo;
        };
        settings.formatter.taplo =
          let
            settings = pkgs.writers.writeTOML "taplo.toml" {
              formatting = {
                align_entries = true;
                column_width = 100;
                compact_arrays = false;
                reorder_inline_tables = true;
                reorder_keys = true;
              };
            };
          in
          {
            options = [
              "format"
              "--config"
              (toString settings)
            ];
          };

        # css html js jsx less markdown md sass scss ts tsx yaml yml
        # TODO: add more languages once they move to the "Native" section here:
        # <https://oxc.rs/docs/guide/usage/formatter/language-support.html#native>
        programs.oxfmt = {
          enable = true;
          package = pkgs.oxfmt;
          excludes = [
            "*.html"
            "*.json"
            "*.jsonc"
            "*.yaml" # sops files
          ];
        };
        settings.formatter.oxfmt =
          let
            configFile = pkgs.writers.writeJSON ".oxfmtrc.json" {
              bracketSameLine = true;
              printWidth = 100;
              semi = true;
              tabWidth = 3;
              useTabs = true;
            };
          in
          {
            options = [
              "--config"
              "${configFile}"
            ];
          };

        settings.formatter.nufmt =
          let
            configFile =
              pkgs.writers.writeText "config-nufmt.nuon"
                # nu
                ''
                  {
                    indent: 3
                    indent_char: "space"
                    line_length: 100
                    margin: 1
                  }
                '';
          in
          {
            command = getExe pkgs.nufmt;
            options = [
              "--config"
              "${configFile}"
            ];
            includes = singleton "*.nu";
          };

        # qml
        programs.qmlformat.enable = true;
        settings.formatter.qmlformat = {
          options = [
            "--normalize"
            "--objects-spacing"
            "--functions-spacing"
            "--group-attributes-together"
            "--sort-imports"
            "--single-line-empty-objects"
            "--semicolon-rule"
            "essential"
            "--tabs"
            "--indent-width"
            "3"
            "--column-width"
            "100"
          ];
        };
      };
    };
}
