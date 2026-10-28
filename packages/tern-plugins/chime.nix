{
  perSystem =
    { pkgs, ... }:
    {
      # Plays a sound when a pane raises an unseen alert, an agent yields, or a
      # long command finishes.
      packages.tern-chime-plugin = pkgs.fetchFromGitHub {
        owner = "H4vC";
        repo = "tern-chime";

        rev = "45a8371b9cb0fbeedbebe3a38f4bbfb3b48fc4ab";
        hash = "sha256-nxRHyk0yge1gNv4CLr+zJS8zM0groMtsFJERsXWbIHE=";
      };
    };
}
