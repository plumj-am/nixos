{ lib, config, ... }:
let
  inherit (lib.attrsets) genAttrs mapAttrs;
  inherit (lib.lists) singleton;
  inherit (config) theme;

  denoJsTsLanguages = {
    JavaScript = "js";
    JSX = "jsx";
    TSX = "tsx";
    TypeScript = "ts";
  };

  denoFmtArgs = [
    "fmt"
    "--use-tabs"
    "--no-semicolons"
    "--indent-width"
    "4"
    "--unstable-component"
    "--ext"
  ];

  withTypos = lsps: lsps ++ [ "typos" ];
in
with theme;
{
  auto_update = false;
  base_keymap = "VSCode";
  helix_mode = true;
  load_direnv = "direct";
  cursor_blink = false;
  show_edit_predictions = false; # Annoying spam popups.
  vertical_scroll_margin = 6;
  horizontal_scroll_margin = 12;
  use_system_path_prompts = false;
  restore_on_startup = "launchpad";
  confirm_quit = true;
  selection_highlight = false;
  scrollbar.show = "never";

  telemetry = {
    diagnostics = false;
    metrics = false;
  };

  git_hosting_providers = singleton {
    provider = "forgejo";
    name = "git.plumj.am";
    base_url = "https://git.plumj.am";
  };

  active_pane_modifiers = {
    inactive_opacity = 0.85;
    border_size = border.small;
  };

  terminal.shell.program = "nu";

  vim = {
    highlight_on_yank_duration = 500;
    use_smartcase_find = true;
    use_system_clipboard = "never";
    cursor_shape = {
      normal = "block";
      insert = "bar";
      replace = "underline";
      visual = "underline";
    };
  };

  command_aliases = {
    bc = "pane::CloseActiveItem";
    rl = "editor::ReloadFile";
    lspr = "editor::RestartLanguageServer";
    wn = "workspace::SaveWithoutFormat";
  };

  inlay_hints = {
    enabled = true;
    show_type_hints = true;
    show_parameter_hints = true;
    show_other_hints = true;
  };

  diagnostics_max_severity = "hint";
  diagnostics.inline.enabled = true;

  tab_bar.show = false;

  tabs = {
    file_icons = true;
    show_diagnostics = "all";
  };

  git.inline_blame.enabled = true;

  project_panel = {
    default_width = 300;
    indent_size = 16;
    entry_spacing = "standard";
    starts_open = false;
  };

  which_key = {
    enabled = true;
    delay_ms = 0;
  };

  ui_font_family = font.sans.name;
  ui_font_size = font.size.medium;

  buffer_font_family = font.mono.name;
  buffer_font_size = font.size.medium;

  agent_ui_font_size = font.size.medium;
  agent_buffer_font_size = font.size.medium;

  theme = {
    mode = "system";
    dark = themes.zed.dark;
    light = themes.zed.light;
  };

  auto_install_extensions = genAttrs [
    "astro"
    "cargotom"
    "deno"
    "haskell"
    "ini"
    "justfile"
    "kdl"
    "nix"
    "nu"
    "nu-lint"
    "qml"
    "rust"
    "sql"
    "svelte"
    "toml"
    "typos"

    "opencode"
    "context7"

    "jj-conflict-resolver"
  ] (_: true);

  search = {
    regex = true;
    center_on_match = true;
  };

  use_smartcase_search = true;

  search_on_input = true;

  seed_search_query_from_cursor = "selection";

  auto_signature_help = true;

  expand_excerpt_lines = 10;
  excerpt_context_lines = 6;

  preview_tabs = {
    enable_preview_from_file_finder = true;
    enable_preview_from_project_panel = true;
    enabled = true;
  };

  document_folding_ranges = "on";

  gutter = {
    code_actions = false;
    runnables = false;
  };

  agent.default_model = {
    provider = "zai";
    model = "glm-5";
  };

  language_models = {
    openai_compatible.zai = {
      api_url = "https://api.z.ai/api/coding/paas/v4";
      available_models =
        let
          inherit (lib.strings) toLower;

          models = [
            "GLM-5"
            "GLM-4.7"
            "GLM-4.7-FlashX"
            "GLM-4.7-Flash"
            "GLM-4.6"
            "GLM-4.5"
            "GLM-4.5-X"
            "GLM-4.5-Air"
            "GLM-4.5-AirX"
            "GLM-4.5-Flash"
          ];

          mkGlmModel = display_name: {
            inherit display_name;
            name = toLower display_name;
            max_tokens = 200000;
            max_output_tokens = 128000;
            max_completion_tokens = 128000;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = true;
              prompt_cache_key = true;
            };
          };
        in
        map mkGlmModel models;
    };
  };

  languages =
    let
      mkDenoFmt = ext: {
        external = {
          command = "deno";
          arguments = denoFmtArgs ++ singleton ext;
        };
      };
    in
    {
      Nix = {
        language_servers = withTypos [
          "nixd"
          "!nil"
        ];

        formatter.external.command = "nixfmt";
      };

      Nushell = {
        tab_size = 3;
        language_servers = withTypos [
          "nu-lsp"
          "nu-lint"
        ];
      };

      Rust = {
        tab_size = 3;
        language_servers = withTypos [ "rust-analyzer" ];
      };

      TOML = {
        language_servers = withTypos [ "taplo" ];

        formatter.external = {
          command = "taplo";
          arguments = [
            "fmt"
            "--option"
            "align_entries=true"
            "--option"
            "column_width=100"
            "--option"
            "compact_arrays=false"
            "--option"
            "reorder_inline_tables=true"
            "--option"
            "reorder_keys=true"
            "{buffer_path}"
          ];
        };
      };

      Markdown = {
        language_servers = withTypos [ "marksman" ];
        formatter = mkDenoFmt "md";
      };

      Just = {
        language_servers = withTypos [ "just-lsp" ];

        formatter.external.command = "just-formatter";
      };

      Nu = {
        tab_size = 3;
        language_servers = withTypos [ "nu-lsp" ];
      };

      Astro = {
        language_servers = withTypos [ "astrols" ];

        formatter = mkDenoFmt "astro";
      };

      CSS = {
        language_servers = withTypos [ ];

        formatter = mkDenoFmt "css";
      };

      SCSS = {
        language_servers = withTypos [ ];

        formatter = mkDenoFmt "scss";
      };

      HTML = {
        language_servers = withTypos [ ];

        formatter = mkDenoFmt "html";
      };

      JSON = {
        language_servers = withTypos [ "jsonls" ];

        formatter = mkDenoFmt "json";
      };

      JSONC = {
        language_servers = withTypos [ "jsonls" ];

        formatter = mkDenoFmt "jsonc";
      };

      Svelte = {
        language_servers = withTypos [ "svelte-language-server" ];

        formatter = mkDenoFmt "svelte";
      };

      Vue = {
        language_servers = withTypos [ "vuels" ];

        formatter = mkDenoFmt "vue";
      };

      YAML = {
        language_servers = withTypos [ "yamlls" ];

        formatter = mkDenoFmt "yaml";
      };
    }
    // mapAttrs (_name: ext: {
      language_servers = withTypos [
        "deno"
        "!typescript-language-server"
        "!vtsls"
        "!eslint"
      ];

      formatter = mkDenoFmt ext;
    }) denoJsTsLanguages;

  lsp = {
    rust-analyzer = {
      initialization_options = {
        cargo.features = "all";
        procMacro.enable = true;
        check.command = "clippy";
        inlayHints.enable = null;
      };
    };

    nixd.binary.arguments = singleton "--inlay-hints";

    deno = {
      settings.javascript = {
        enable = true;
        lint = true;
        unstable = true;

        suggest.imports.hosts."https://deno.land" = true;

        inlayHints.enumMemberValues.enabled = true;
        inlayHints.functionLikeReturnTypes.enabled = true;
        inlayHints.parameterNames.enabled = "all";
        inlayHints.parameterTypes.enabled = true;
        inlayHints.propertyDeclarationTypes.enabled = true;
        inlayHints.variableTypes.enabled = true;
      };
    };
  };
}
