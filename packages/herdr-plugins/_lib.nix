# Shared helpers for herdr plugin packages.
#
# A herdr plugin is a directory holding herdr-plugin.toml, an optional scripts/
# directory, and a compiled binary at the exact relative path the manifest's
# [[build]] and [[panes]] commands name. Herdr resolves those commands against
# the plugin root, so a package that installs anything else is not installable.
{ pkgs }:
let
  inherit (pkgs.lib) concatMapStringsSep concatStrings concatStringsSep;

  quote = argument: ''"${argument}"'';
in
{
  herdrPlugin =
    {
      pname,
      version,
      src,
      cargoHash,
      # Name of the cargo binary. Defaults to pname, but a plugin's crate
      # and its binary can differ.
      binary ? pname,
      # Files under scripts/ that the manifest's [[build]] command runs.
      scripts ? [ ],
      # Programs the test binary needs on PATH, e.g. a real jj repository.
      checkInputs ? [ ],
      # Extra arguments for the test binary, e.g. to skip a broken upstream test.
      testArgs ? [ ],
      meta ? { },
    }:
    pkgs.rustPlatform.buildRustPackage {
      inherit
        cargoHash
        pname
        src
        version
        ;

      nativeCheckInputs = checkInputs;

      meta = {
        platforms = pkgs.lib.platforms.unix;
      }
      // meta;

      installPhase = concatStrings [
        ''
          runHook preInstall

          mkdir -p "$out/target/release" "$out/scripts"
          install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
        ''
        (concatMapStringsSep "\n" (
          script: ''install -Dm755 scripts/${script} "$out/scripts/${script}"''
        ) scripts)
        ''

          # buildRustPackage passes an explicit --target, so the binary lands
          # in target/<triple>/release rather than target/release.
          binary=$(find target -type f -name ${binary} -path '*release*' -print -quit)
          install -Dm755 "$binary" "$out/target/release/${binary}"

          runHook postInstall
        ''
      ];

      checkPhase = ''
        runHook preCheck
        cargo test --bin ${binary} -- ${concatStringsSep " " (map quote testArgs)}
        runHook postCheck
      '';
    };
}
