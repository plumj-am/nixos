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
    python3
    gcc
    gnumake
    vscode-extensions.vadimcn.vscode-lldb.adapter

    claude-code
    gemini-cli
    nix-index
    comma
    gh
  ];
}
