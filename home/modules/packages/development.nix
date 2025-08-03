{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # language servers
    lua-language-server
    typescript-language-server
    svelte-language-server
    tailwindcss-language-server
    astro-language-server
    nixd
    gopls
    vscode-json-languageserver
    yaml-language-server

    stylua
    nodePackages.prettier
    prettierd
    nixfmt-rfc-style
    nufmt
    dprint
    ruff
    sleek

    nodejs
    bun
    python3
    # gcc # disabled for avr-gcc
    gnumake
    vscode-extensions.vadimcn.vscode-lldb.adapter

    # embedded stuff for avr-hal
    pkgsCross.avr.buildPackages.gcc
    pkg-config
    avrdude
    ravedude

    steam-run
    moon
    proto
    mprocs

    claude-code
    gemini-cli
    nix-index
    comma
    gh
  ];
}
