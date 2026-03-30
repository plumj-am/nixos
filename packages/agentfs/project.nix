{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      toolchain = inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
        "cargo"
        "rustc"
        "rust-std"
      ];

      rustPlatform = pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };
    in
    {
      packages.agentfs = rustPlatform.buildRustPackage {
        pname = "agentfs";
        version = "0.6.4";

        src = pkgs.fetchFromGitHub {
          owner = "tursodatabase";
          repo = "agentfs";
          rev = "refs/tags/v0.6.4";
          hash = "sha256-wIBSMcuMXDgXieu4NzC/XSAJH6OqiNsXH5jAJPiMTqw=";
        };

        cargoRoot = "cli";
        buildAndTestSubdir = "cli";
        cargoHash = "sha256-vshjtLfjAhrbIPB36et2KuAnEE2qoKRP6a/Lm9gVXQk=";

        nativeBuildInputs = [ pkgs.pkg-config ];

        buildInputs = [
          pkgs.libunwind
          pkgs.openssl
          pkgs.xz
        ];

        # build.rs links lzma and gcc_s on Linux.
        postFixup = lib.optionalString pkgs.stdenv.isLinux ''
          patchelf --add-needed libgcc_s.so.1 $out/bin/agentfs
        '';

        env = {
          LD_LIBRARY_PATH = "${pkgs.openssl.out}/lib";
        };
      };
    };
}
