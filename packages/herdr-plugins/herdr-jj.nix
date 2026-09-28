{
  perSystem =
    { pkgs, ... }:
    {
      packages.herdr-jj = (import ./_lib.nix { inherit pkgs; }).herdrPlugin {
        pname = "herdr-jj";
        version = "0.1.0";

        # Upstream publishes no release tags, so no version can name this rev.
        # The manifest and Cargo.toml read 0.1.0, but the sha is what pins it.

        src = pkgs.fetchFromGitHub {
          owner = "OliverGilan";
          repo = "herdr-jj";
          rev = "4fe4efacf70bf5986c1e2ed49f11772d6358bc81";
          hash = "sha256-kjbLFtCd3vMIA0wwpgOXo7yps8QJDIlvgTaHoPwZgKU=";
        };

        cargoHash = "sha256-0Yp58X/ldgJdA/CpTzH8CGk0HnvE4toPRMSwD4VJ+20=";

        # Unit tests need jj.
        checkInputs = [ pkgs.jujutsu ];

        meta = {
          description = "Herdr plugin to create, open and remove jj workspaces";
          homepage = "https://github.com/OliverGilan/herdr-jj";
          license = pkgs.lib.licenses.mit;
        };
      };
    };
}
