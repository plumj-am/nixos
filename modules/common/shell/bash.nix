{ config, lib, ... }: let
  inherit (lib) enabled;
in {
  home-manager.sharedModules = [
    (homeArgs: {
      programs.bash = enabled {
        enableCompletion = true;
        shellAliases = config.environment.shellAliases // {
    			".."     = "cd ..";

    			m  = "moon";
    			mp = "mprocs";
    			ko = "kondo";
    		};

        initExtra = ''
          # Load theme state from theme.json
          if [ -f "$HOME/nixos/modules/common/theme/theme.json" ]; then
            export THEME_MODE=$(grep -o '"mode":"[^"]*"' "$HOME/nixos/modules/common/theme/theme.json" | cut -d'"' -f4)
            export THEME_SCHEME=$(grep -o '"scheme":"[^"]*"' "$HOME/nixos/modules/common/theme/theme.json" | cut -d'"' -f4)
          else
            export THEME_MODE="${config.theme.variant}"
            export THEME_SCHEME="${config.theme.color_scheme}"
          fi

          # fzf key bindings
          if command -v fzf >/dev/null 2>&1; then
            bind -m emacs-standard '"\C-f": " \C-b\C-k \C-u`__fzf_cd__`\e\C-e\er\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d"'
            bind -m emacs-standard -x '"\C-g": fzf-file-widget --height ~40%'
          fi

          # bash completion directory loading
          if [ -d ${homeArgs.config.home.homeDirectory}/.bash_completion.d/ ]; then
            for i in ${homeArgs.config.home.homeDirectory}/.bash_completion.d/*.sh; do
              if [ -r $i ]; then
                . $i
              fi
            done
            unset i
          fi
        '';
      };
    })
  ];
}
