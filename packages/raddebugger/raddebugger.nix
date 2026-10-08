{
  perSystem =
    { pkgs, lib, ... }:
    let
      raddebugger =
        {
          clangStdenv ? pkgs.clangStdenv,
        }:
        assert clangStdenv.cc.cc.pname == "gcc" || clangStdenv.cc.cc.pname == "clang";
        clangStdenv.mkDerivation (finalAttrs: {
          pname = "raddebugger";
          version = "0.9.29-alpha";

          strictDeps = true;
          __structuredAttrs = true;

          src = pkgs.fetchFromGitHub {
            owner = "EpicGames";
            repo = "raddebugger";
            tag = "v${finalAttrs.version}";
            hash = "sha256-IQNicRWKdIamDeQU1RRceRR2QgoUlomQYoeCgepO10w=";
          };

          nativeBuildInputs = [
            pkgs.bash
            pkgs.makeWrapper
            pkgs.copyDesktopItems
          ];

          buildInputs = [
            pkgs.freetype
            pkgs.libx11
            pkgs.libxext
            pkgs.libxfixes
            pkgs.libGL
          ];

          postPatch = ''
            patchShebangs build.sh

            substituteInPlace build.sh \
              --replace-fail '$(git describe --always --dirty)' 'v${finalAttrs.version}' \
              --replace-fail '$(git rev-parse HEAD)' 'v${finalAttrs.version}'
          '';

          buildPhase = ''
            runHook preBuild

            ./build.sh '${clangStdenv.cc.cc.pname}' release raddbg radlink radbin torture

            runHook postBuild
          '';

          doCheck = false; # fails on my machine

          checkPhase = ''
            runHook preCheck

            ./build/torture '*'

            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 -t "$out/bin" build/{raddbg,radlink,radbin}
            install -Dm644 data/logo.png "$out/share/icons/hicolor/256x256/raddbg.png"

            runHook postInstall
          '';

          postFixup = ''
            for prog in "$out/bin/"*; do
              wrapProgram "$prog" \
                --prefix PATH : "${
                  lib.makeBinPath [
                    pkgs.zenity
                    pkgs.libllvm
                  ]
                }"
            done
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "raddbg";
              desktopName = "RAD Debugger";
              genericName = "Debugger";
              comment = "Graphical debugger";
              icon = "raddbg";
              exec = "raddbg %U";
              terminal = false;
              categories = [
                "Development"
                "Debugger"
              ];
              startupNotify = true;
              startupWMClass = "RADDBG";
            })
          ];

          passthru = {
            tests.raddebugger-gcc = raddebugger { clangStdenv = pkgs.gccStdenv; };

            updateScript = pkgs.nix-update-script { };
          };

          meta = {
            homepage = "https://github.com/EpicGames/raddebugger";
            description = "A native, user-mode, multi-process, graphical debugger.";
            license = lib.licenses.mit;
            platforms = [ "x86_64-linux" ];
            mainProgram = "raddbg";
          };
        });
    in
    {
      packages.raddebugger = raddebugger { };
    };
}
