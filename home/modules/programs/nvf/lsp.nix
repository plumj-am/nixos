{
  programs.nvf.settings.vim = {
    languages = {
      enableTreesitter = true;

      html = {
        enable = true;
        # treesitter.autoTagHtml = true;
      };

      # commented ones don't have builtins
      astro.enable = true;
      # bacon-ls.enable = true;
      go.enable = true;
      # json.enable = true;
      lua.enable = true;
      nix.enable = true;
      nu.enable = true;
      rust.enable = true;
      svelte.enable = true;
      tailwind.enable = true;
      ts.enable = true;
      yaml.enable = true;

    };

  };
}
