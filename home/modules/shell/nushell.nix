{ pkgs, config, ... }:
{
  programs.nushell = {
    enable = true;
    shellAliases = {
      cat = "bat";
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      lsa = "eza -a";
      lsl = "eza -l -a";
      v = "vim";
      vi = "vim";
      nv = "nvim";
      m = "moon";
      mp = "mprocs";
      ko = "kondo";
      g = "git";
      rebuild = "sudo nixos-rebuild switch --flake /home/james/nixos-config#nixos";
      tt = "toggle-theme";
      cdr = "cd (git rev-parse --show-toplevel | str trim)";
      cdn = "cd ~/nixos-config/dotfiles/nvim";
      cdc = "cd ~/nixos-config";
      cdp = "cd ~/projects";
      cdu = "cd ~/nixos-config/home/modules/shell";
    };
    settings = {
      buffer_editor = "nvim";
      show_banner = false;
      
      ls = {
        use_ls_colors = true;
        clickable_links = true;
      };
      
      rm = {
        always_trash = false;
      };
      
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
        status_bar_background = {};
        highlight = { bg = "yellow"; fg = "black"; };
        status = {};
        try = {};
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
          cursor_color = { bg = "yellow"; fg = "black"; };
        };
      };
      
      history = {
        max_size = 10000;
        sync_on_enter = true;
      };
      
      filesize = {};
      
      cursor_shape = {
        emacs = "block";
        vi_insert = "block";
        vi_normal = "block";
      };
      
      float_precision = 2;
      use_ansi_coloring = true;
      
      hooks = {
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
    '';
  };
}
