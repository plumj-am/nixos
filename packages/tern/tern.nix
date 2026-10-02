{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      # Tern is a closed-beta Stencil Labs product. There is no public
      # download URL (build.stencil.so is auth-gated behind auth.stencil.so)
      # and no published source.
      version = "0.4.0";
      filename = "Tern-${version}-linux-x86_64.tar.gz";

      # Tern ships no public download, so the tarball lives in the store,
      # added by hand. It stays out of version control.
      #
      # fetchurl copies the content and does not reference this path, so the
      # path has a GC root. Without it, `nix store gc` deletes the tarball and
      # every build fails. To move to a new release:
      #
      #   let version = "0.4.0"
      #
      #   (nix store add-file --name $"Tern-($version)-linux-x86_64.tar.gz"
      #     ~/Downloads/Tern-($version)-linux-x86_64.tar.gz)
      #
      #   (sudo ln -sfn <PATH FROM LAST COMMAND OUTPUT>
      #     /nix/var/nix/gcroots/per-user/(id -u)/tern)
      #
      # then update below with the new path and hash.
      release = {
        storePath = "/nix/store/vbz6hs7klrcih0pcm383619vssdx0mvn-Tern-0.4.0-linux-x86_64.tar.gz";
        hash = "sha256-yKJJGA7cOXx4Noa6ITnyKKns5tZwgAHapOirKS5J7is=";
      };

      supportedSystems = [
        "x86_64-linux"
      ];

      # DT_NEEDED holds only libc/libm/libdl/libpthread/librt/libutil/
      # libgcc_s, plus libstdc++ as of 0.4.0. Everything else is dlopen()'d
      # at runtime, so autoPatchelf would miss it entirely; this set comes
      # from `strings` on the binary, diffed against the previous release:
      # wgpu's Vulkan + EGL/GLES chain, the Wayland + xkbcommon window, and
      # the WebKitGTK / WPEWebKit bindings for the browser block. There is no
      # X11 in the binary at all -- no libX11, no libxcb.
      runtimeLibs = with pkgs; [
        stdenv.cc.cc.lib
        vulkan-loader
        libglvnd
        wayland
        libxkbcommon
        glib
        gtk3
        webkitgtk_4_1
        libwpe
        libwpe-fdo
      ];

      runtimeLibraryPath = lib.makeLibraryPath runtimeLibs;

      # Flake packages build against the flake-level pkgs, not the host's, so
      # a host's `unfree.allowedNames` never reaches this derivation. The gate
      # binds at nixpkgs import time, so `pkgs.extend` cannot open it: only a
      # re-import can, and it gets an allowlist for this name alone.
      unfreePkgs = import pkgs.path {
        hostPlatform = pkgs.stdenv.hostPlatform;
        system = system;
        config = pkgs.config // {
          allowUnfreePredicate = name: lib.getName name == "tern";
        };
      };

    in
    {
      packages.tern =
        let
          fail = msg: throw "tern: ${msg}";
        in
        unfreePkgs.stdenvNoCC.mkDerivation {
          pname = "tern";
          inherit version;

          # An absolute path outside the flake cannot be used: pure evaluation
          # mode rejects it. fetchurl checks `release.hash` against the content.
          src =
            if system == "x86_64-linux" then
              unfreePkgs.fetchurl {
                name = filename;
                url = "file://${release.storePath}";
                hash = release.hash;
              }
            else
              fail "only x86_64-linux builds are packaged (got ${system})";

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.patchelf
            # stdenvNoCC has no strip; it comes from binutils.
            pkgs.binutils
          ];

          dontConfigure = true;
          dontBuild = true;
          # Strip upstream's unstripped binary: 96 MB -> 76 MB (the .symtab
          # is 3.7 MiB, the .strtab 16 MiB; the remaining ~76 MB is real
          # code, mostly a statically linked wgpu/naga). dontPatchELF keeps
          # the generic fixupPhase from rewriting the RPATH we set below;
          # nothing is missing from DT_NEEDED, so autoPatchelf has no work
          # to do anyway.
          dontPatchELF = true;

          installPhase = ''
            runHook preInstall

            # unpackPhase sets sourceRoot=tern, so cwd is already the tarball's
            # tern/ directory: the executable is ./tern and the fonts are
            # ./assets/fonts. Keep assets/ a sibling of the binary, because
            # stencil_kit::assets::dir falls back to <exe dir>/assets.
            appDir="$out/opt/tern"
            mkdir -p "$appDir" "$out/bin" "$out/share/applications"
            cp -a . "$appDir/"
            chmod -R u+w "$appDir"

            # Before the wrapper, so strip sees a real file.
            strip --strip-unneeded "$appDir/tern" || true

            rpath="${runtimeLibraryPath}:\''$ORIGIN/../lib:\''$ORIGIN"
            patchelf --set-rpath "$rpath" "$appDir/tern"
            patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$appDir/tern"

            # assets/ must be resolvable: stencil_kit::assets::dir checks
            # $STENCIL_ASSETS, else <exe dir>/assets, and refuses to load the
            # bundled page fonts without it ("cannot load the page fonts
            # (set STENCIL_ASSETS)"). Pin it so the store path works from
            # any cwd.
            makeWrapper "$appDir/tern" "$out/bin/tern" \
              --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}" \
              --set STENCIL_ASSETS "$appDir/assets" \
              --set TERN_UPDATE_EXPLANATION \
              "Tern is managed by Nix; update packages/tern in your flake to move to a newer build."

            cat > "$out/share/applications/tern.desktop" <<EOF
            [Desktop Entry]
            Type=Application
            Name=Tern
            Comment=A neoterminal for the Electron-weary
            Exec=tern
            Terminal=true
            Categories=System;TerminalEmulator;
            EOF

            runHook postInstall
          '';

          # A window needs a Wayland compositor, so this test only works on a
          # machine with a display. `tern --help` exercises the loader, the
          # RPATH and the bundled assets without one.
          passthru.tests.tern-help =
            pkgs.runCommand "tern-help" { nativeBuildInputs = [ self.packages.${system}.tern ]; }
              ''
                HOME=$TMPDIR tern --help >/dev/null
                touch "$out"
              '';

          meta = {
            description = "Rust-native, Kitty-compatible terminal multiplexer";
            homepage = "https://stencil.so/tern";
            license = lib.licenses.unfree;
            mainProgram = "tern";
            platforms = supportedSystems;
          };
        };
    };
}
