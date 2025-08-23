{
  programs.nushell = {
    enable = true;
    shellAliases = {
      cat = "bat";
      ls = "eza";
      sl = "eza";
      ll = "eza -la";
      la = "eza -a";
      lsa = "eza -a";
      lsl = "eza -l -a";
      v = "vim";
      vi = "vim";
      nv = "nvim";
      nvi = "nvim";
      claude = "claude --continue";
      m = "moon";
      mp = "mprocs";
      ko = "kondo";
      g = "git";
      gi = "git";
      gti = "git";
      gt = "git";
      rebuild = "~/nixos-config/rebuild.nu";
      rollback = "~/nixos-config/rollback.nu";
      # for some reason this doesn't work and is called every time I open a new shell
      # nixos-upgrade = "sudo nix-store --verify --check-contents --repair ; sudo nix flake update --flake ~/nixos-config ; sudo nixos-rebuild switch --flake ~/nixos-config#nixos-wsl";
      tt = "toggle-theme";
      cdr = "cd (git rev-parse --show-toplevel | str trim)";
      cdn = "cd ~/nixos-config/dotfiles/nvim";
      cdc = "cd ~/nixos-config";
      cdp = "cd ~/projects";
      cdu = "cd ~/nixos-config/home/modules/shell";

      rm = "rm --recursive --verbose";
      cp = "cp --recursive --verbose --progress";
      mv = "mv --verbose";
      mk = "mkdir";

      tree = "eza --tree --git-ignore --group-directories-first";

      # steam-run for dynamically linked executables
      moon = "steam-run moon";
      proto = "steam-run proto";
      bun = "steam-run bun";
      bunx = "steam-run bunx";
      npx = "steam-run npx";
    };
    settings = {
      edit_mode = "vi";
      buffer_editor = "nvim";
      show_banner = false;
      footer_mode = "auto";

      recursion_limit = 100;
      error_style = "fancy";

      completions = {
        algorithm = "substring";
        sort = "smart";
        case_sensitive = false;
        quick = true;
        partial = true;
        use_ls_colors = true;
      };

      ls = {
        use_ls_colors = true;
        clickable_links = true;
      };

      rm = {
        always_trash = false;
      };

      keybindings = [
        {
          name = "quit_shell";
          modifier = "control";
          keycode = "char_d";
          mode = [
            "emacs"
            "vi_insert"
            "vi_normal"
          ];
          event = null;
        }
      ];
      table = {
        mode = "compact";
        index_mode = "always";
        show_empty = true;
        trim = {
          methodology = "wrapping";
          wrapping_try_keep_words = true;
          truncating_suffix = "...";
        };
      };

      explore = {
        help_banner = true;
        exit_esc = true;
        command_bar_text = "#C4C9C6";
        status_bar_background = { };
        highlight = {
          bg = "yellow";
          fg = "black";
        };
        status = { };
        try = { };
        table = {
          split_line = "#404040";
          cursor = true;
          line_index = true;
          line_shift = true;
          line_head_top = true;
          line_head_bottom = true;
          show_head = true;
          show_index = true;
        };
        config = {
          cursor_color = {
            bg = "yellow";
            fg = "black";
          };
        };
      };

      history = {
        file_format = "sqlite";
        max_size = 10000000;
        sync_on_enter = true;
      };

      filesize = { };

      cursor_shape = {
        emacs = "block";
        vi_insert = "block";
        vi_normal = "block";
      };

      float_precision = 2;
      use_ansi_coloring = true;

      hooks = {
        env_change = {
          PWD = [
            ''{ |before, after| zellij-update-tabname }''
          ];
        };
        display_output = "if (term size).columns >= 100 { table -e } else { table }";
        pre_prompt = [
          ''
            if (which direnv | is-empty) {
              return
            }
            direnv export json | from json | default {} | load-env
            $env.PATH = ($env.PATH | split row (char env_sep))
          ''
        ];
      };

    };

    extraConfig = ''
      ${builtins.readFile ./menus.nu}
      ${builtins.readFile ./functions.nu}
      ${builtins.readFile ./theme.nu}
    '';
    envFile.text = ''
            $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap"
      			$env.LS_COLORS = (vivid generate gruvbox-dark-hard)
    '';
  };
}
