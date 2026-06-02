let
  commonModule =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        CARGO_NET_GIT_FETCH_WITH_CLI = "true";
      };

      environment.systemPackages = [
        pkgs.cargo-binstall
        pkgs.cargo-nextest
        pkgs.dioxus-cli
        pkgs.sccache
      ];
    };

  rustDesktop =
    { pkgs, inputs }:
    {
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
        pkgs.bacon
        pkgs.cargo-careful
        pkgs.cargo-deny
        pkgs.cargo-generate
        pkgs.cargo-machete
        pkgs.cargo-workspaces
        pkgs.cargo-outdated
        pkgs.evcxr
        pkgs.kondo
      ];
    };
in
{
  flake.modules.nixos.rust =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports =
        singleton
        <| commonModule {
          inherit pkgs;
        };

      environment.systemPackages =
        singleton
        <| inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
          # Nightly.
          "cargo"
          "clippy"
          "miri"
          "rustc"
          "rustfmt"
          "rust-std"
          "rust-src"
        ];

      hjem.extraModule = {
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

  flake.modules.nixos.rust-desktop =
    { pkgs, inputs, ... }:
    {
      imports = [
        (rustDesktop { inherit pkgs inputs; })
        (commonModule { inherit pkgs; })
      ];
    };

  flake.modules.darwin.rust-desktop =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (lib.strings) makeLibraryPath;
    in
    {
      imports = [
        (rustDesktop { inherit pkgs inputs; })
      ];
      environment.variables = {
        LIBRARY_PATH = makeLibraryPath [ pkgs.libiconv ];
      };
    };
}
