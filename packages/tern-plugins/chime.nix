{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # Chime (github:plumj-am/tern-chime) plays a sound when a pane raises an
      # unseen alert, an agent yields, or a long command finishes. Its upstream
      # tree is the plugin directory, so the pin is the install; modules/tern.nix
      # links the files the manifest names. Bump rev and hash together.
      #
      # The upstream tree carries both halves of the plugin. The window half
      # (src/window.luau) decides when a sound is due; the host half
      # (src/host.luau) reads the config, finds a sound player and starts it,
      # because those jobs do not belong on the window's UI thread. The two
      # halves share src/shared.luau, the channel between them.
      #
      # The plugin is built here, not inlined, so the code that runs is the
      # code in the repository.
      packages.tern-chime-plugin = pkgs.fetchFromGitHub {
        owner = "plumj-am";
        repo = "tern-chime";
        rev = "4bb371df30f91ae00fc052ea5d52b3cc77c1b54b";
        hash = "sha256-izsxgcFBztpbRes9hSZRNWnA+84/deZZslsU4RfGuGk=";
      };
    };
}
