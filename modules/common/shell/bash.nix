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

    			tt = "toggle-theme";
    		};

        initExtra = ''
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
