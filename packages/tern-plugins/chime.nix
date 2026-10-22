{
  perSystem =
    { pkgs, ... }:
    {
      # Chime (github:H4vC/tern-chime) plays a sound when a pane raises an
      # unseen alert, an agent yields, or a long command finishes. Its upstream
      # tree is the plugin directory, so the pin is the install; modules/tern.nix
      # links the files the manifest names. Bump rev and hash together.
      packages.tern-chime-plugin = pkgs.fetchFromGitHub {
        owner = "plumj-am";
        repo = "tern-chime";

        rev = "5c8ef776bb9bc25151b7996ef643358efca19da9";
        hash = "sha256-dXzD2zDVsSMja5reqrBlzHu1JLdAQlEtYlxxM6tTMug=";
      };
    };
}
