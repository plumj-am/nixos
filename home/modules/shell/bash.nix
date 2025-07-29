{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = builtins.getAttr "common" (import ./aliases.nix);
    
    initExtra = ''
      # fzf key bindings
      if command -v fzf >/dev/null 2>&1; then
        bind -m emacs-standard '"\C-f": " \C-b\C-k \C-u`__fzf_cd__`\e\C-e\er\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d"'
        bind -m emacs-standard -x '"\C-g": fzf-file-widget --height ~40%'
      fi
      
      # bash completion directory loading
      if [ -d ~/.bash_completion.d/ ]; then
        for i in ~/.bash_completion.d/*.sh; do
          if [ -r $i ]; then
            . $i
          fi
        done
        unset i
      fi
    '';
  };
}
