{ pkgs, ... }: {
  environment.systemPackages = [
    # starship-jj from crates.io
    (pkgs.rustPlatform.buildRustPackage rec {
      pname = "starship-jj";
      version = "0.5.1";
      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-tQEEsjKXhWt52ZiickDA/CYL+1lDtosLYyUcpSQ+wMo=";
      };
      cargoHash = "sha256-+rLejMMWJyzoKcjO7hcZEDHz5IzKeAGk1NinyJon4PY=";
      meta = {
        description = "Starship module for Jujutsu VCS";
        homepage = "https://crates.io/crates/starship-jj";
      };
    })
  ];
}