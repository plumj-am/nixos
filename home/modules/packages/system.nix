{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # file navigation & search
    eza
    fd
    ripgrep
    fzf
    tree
    
    # benchmarking
    hyperfine
    
    # file operations
    bat
    
    vim
    bash
    nushell
    
    # network tools
    curl
    wget
    
    # system monitoring
    htop
  ];
}