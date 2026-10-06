{ self, ... }:
{
  flake.modules.common.default.imports = [
    self.modules.common.rust
    self.modules.common.kache
  ];

  flake.modules.common.rust =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      environment.sessionVariables.CARGO_NET_GIT_FETCH_WITH_CLI = "true";

      environment.systemPackages = [
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
          # Nightly.
          "cargo"
          "clippy"
          "miri"
          "rustc"
          "rust-analyzer"
          "rustfmt"
          "rust-std"
          "rust-src"
        ])
        pkgs.cargo-binstall
        pkgs.cargo-nextest
        pkgs.sccache
      ];

      hjemModule = {
        xdg.config.files."rustfmt/rustfmt.toml" = {
          generator = pkgs.writers.writeTOML "rustfmt-rustfmt.toml";
          value = {
            attr_fn_like_width = 80;
            condense_wildcard_suffixes = true;
            doc_comment_code_block_width = 100;
            edition = "2024";
            enum_discrim_align_threshold = 60;
            force_multiline_blocks = true;
            format_code_in_doc_comments = true;
            format_macro_matchers = true;
            format_strings = true;
            group_imports = "StdExternalCrate";
            hex_literal_case = "Upper";
            imports_granularity = "Crate";
            imports_layout = "Vertical";
            inline_attribute_width = 60;
            match_block_trailing_comma = true;
            max_width = 100;
            newline_style = "Unix";
            normalize_comments = true;
            normalize_doc_attributes = true;
            overflow_delimited_expr = true;
            struct_field_align_threshold = 60;
            style_edition = "2024";
            tab_spaces = 3;
            unstable_features = true;
            use_field_init_shorthand = true;
            use_try_shorthand = true;
            wrap_comments = true;
          };
        };
      };
    };

  flake.modules.common.desktop = self.modules.common.rust-extra-desktop;
  flake.modules.common.rust-extra-desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.strings) makeLibraryPath;
    in
    {
      environment.variables.LIBRARY_PATH =
        mkIf config.nixpkgs.hostPlatform.isDarwin <| makeLibraryPath <| singleton pkgs.libiconv;

      environment.systemPackages = [
        pkgs.bacon
        pkgs.cargo-careful
        pkgs.cargo-deny
        pkgs.cargo-generate
        pkgs.cargo-machete
        pkgs.cargo-workspaces
        pkgs.cargo-outdated
        pkgs.dioxus-cli
        pkgs.evcxr
        pkgs.kondo
      ];
    };

  flake.modules.common.kache =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkBefore mkDefault;
    in
    {
      environment.systemPackages =
        singleton
          inputs.kache.packages.${pkgs.stdenv.hostPlatform.system}.default;

      hjemModule = {
        files.".cargo/config.toml" = {
          generator = mkDefault <| pkgs.writers.writeTOML "cargo-config.toml";
          value = {
            build.rustc-wrapper = "kache";
          };
        };

        xdg.config.files."nushell/config.nu".text =
          mkBefore
            # nu
            ''
              $env.config.hooks.env_change.PWD = (
                $env.config.hooks.env_change.PWD? | default [] | append [
                  {||
                    $env.KACHE_BASE_DIR = (
                      try {
                        ${getExe pkgs.jujutsu} workspace root err> /dev/null | str trim
                      } catch { try {
                        ${getExe pkgs.git} rev-parse --show-toplevel err> /dev/null | str trim
                      } catch {
                        pwd
                      }}
                    )
                  }
                ]
              )
            '';
      };
    };
}
