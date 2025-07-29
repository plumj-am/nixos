{
  common = {
    # file operations
    cat = "bat";
    ls = "eza";
    ll = "eza -la";
    la = "eza -a";
    lsa = "eza -a";
    lsl = "eza -l -a";

    # navigation
    ".." = "cd ..";
    "...." = "cd ../..";
    "......" = "cd ../../..";

    # editors
    v = "vim";
    vi = "vim";
    nv = "nvim";

    # tools
    m = "moon";
    mp = "mprocs";
    ko = "kondo";
    g = "git";

    # system
    rebuild = "sudo nixos-rebuild switch --flake /home/james/nixos-config#nixos";
    
    # theme
    tt = "toggle-theme";
  };
  nushellSpecific = {
    cdr = "cd (git rev-parse --show-toplevel | str trim)";
    cdn = "cd ~/nixos-config/dotfiles/nvim";
    cdc = "cd ~/nixos-config";
    cdp = "cd ~/projects";
    cdu = "cd ~/nixos-config/home/modules/shell";
  };
}
