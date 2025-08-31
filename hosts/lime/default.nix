lib: {
  class = "darwin";
  config = lib.darwinSystem' {
    system = "aarch64-darwin";
    modules = [
      ./configuration.nix
    ];
  };
}