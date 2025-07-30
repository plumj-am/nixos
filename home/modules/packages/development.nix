{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # language servers
    lua-language-server
    nodePackages.typescript-language-server
    svelte-language-server
    tailwindcss-language-server
    nodePackages."@astrojs/language-server"
    nixd

    stylua
    nodePackages.prettier
    prettierd
    nixfmt-rfc-style
    nufmt

    nodejs
    python3
    gcc
    gnumake

    claude-code
    # gemini-cli
    nix-index
    comma
    gh

    bacon
    cargo-nextest
    cargo-deny
    jj
    kondo
    mprocs
    sqlx-cli
  ];
}
