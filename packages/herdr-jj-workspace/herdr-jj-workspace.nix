{
  perSystem =
    { pkgs, ... }:
    {
      # Herdr resolves a plugin manifest's relative commands against the plugin
      # root, and the jj-workspace plugin finds its own binary at
      # <script dir>/../target/release/jj-workspace. Both only hold with this
      # exact layout, so the build installs nothing else.
      packages.herdr-jj-workspace = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-plugin-jj-workspace";
        version = "0.5.0";

        src = pkgs.fetchFromGitHub {
          owner = "expnn";
          repo = "herdr-plugin-jj-workspace";
          rev = "772c5181acc95b81587154e6003e2141828caacb";
          hash = "sha256-GSxZSh/RzGomGLR8GqMHrC87ujvu/s4VJcXtoFRbZhU=";
        };

        cargoHash = "sha256-IO5fdUqYGt350xcNpeWezONVJVKbk9Ykp4iMlwCnzhA=";

        installPhase = # sh
          ''
            runHook preInstall

            mkdir -p "$out/target/release" "$out/scripts"
            install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
            install -Dm755 scripts/setup-workspace.sh "$out/scripts/setup-workspace.sh"

            # buildRustPackage passes an explicit --target, so the binary lands
            # in target/<triple>/release rather than target/release.
            binary=$(find target -type f -name jj-workspace -path '*release*' -print -quit)
            install -Dm755 "$binary" "$out/target/release/jj-workspace"

            runHook postInstall
          '';

        # The upstream setup_* tests create <root>/main but never <root>/main/.jj,
        # so the script's pointer derivation fails on any machine, not only in
        # Nix. The other tests still run.
        checkPhase = # sh
          ''
            runHook preCheck
            cargo test --bin jj-workspace -- --skip tests::setup_
            runHook postCheck
          '';

        meta = {
          description = "Herdr plugin to create and remove jj workspaces";
          homepage = "https://github.com/expnn/herdr-plugin-jj-workspace";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.unix;
        };
      };
    };
}
