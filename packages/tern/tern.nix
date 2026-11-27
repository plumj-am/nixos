{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (lib.attrsets) attrNames getLib;
      inherit (lib.strings) concatStringsSep getName makeLibraryPath;

      # Tern is a closed-beta Stencil Labs product. There is no public source
      # or download URL yet (build.stencil.so is auth-gated).
      version = "0.9.36";

      # The platforms do not ship the same thing:
      #
      # - x86_64-linux: a tar.gz holding `tern/tern`, the TUI binary. Most of
      #   its dependencies are dlopen()'d, so the derivation fixes the rpath.
      # - aarch64-darwin: a zip holding `Tern.app`, the signed app bundle
      #   (daemon, LaunchAgents/Daemons, nested tray app). There is no separate
      #   macOS CLI archive.
      #
      # No public download: the archives live in the store, added by hand.
      #
      # fetchurl copies the content without referencing the path, so each
      # path needs a GC root or `nix store gc` deletes it and the build fails.
      #
      # For a new release (flat mode is required: plain `nix store add-file`
      # NAR-hashes the file, so fetchurl finds no store path for it and the
      # sandboxed build fails with `curl: (37) Could not open file`):
      /*
         nix-store --add-fixed sha256 ~/Downloads/Tern-<version>-<platform>.{tar.gz,zip}

         sudo ln -sfn <PATH> /nix/var/nix/gcroots/per-user/$(id -u)/tern-<platform>

         nix hash file --type sha256 --base64 ~/Downloads/Tern-<version>-<platform>.{tar.gz,zip}
      */
      #
      # then update version, storePath and hash below.
      #
      # A running Tern pins the old version. To retire an old session:
      # - `pkill -f tern` isn't necessary
      # - close every old-version window first (an open one respawns its own
      #   daemon from the old store path)
      # - launch Tern fresh
      # - run "Restart session daemon" from a new-version window
      releases = {
        x86_64-linux = {
          file = "Tern-${version}-linux-x86_64.tar.gz";
          storePath = "/nix/store/fzp90g9agw8adqc2zbsbmfxrhscn1qb3-Tern-0.9.36-linux-x86_64.tar.gz";
          hash = "sha256-XEJvGCxnK0GotYbhDrCNXwUG6ZDEMfpHYZYcgt7/zzI=";
        };
        aarch64-darwin = {
          file = "Tern-${version}-macos-arm64.zip";
          storePath = "/nix/store/d8ig70igbdgb2n9jh2khnlpfq7dq49b8-Tern-0.9.36-macos-arm64.zip";
          hash = "sha256-9v0V3PB5z3C+bPfShRvgeagysF0/31LU74Opl0xr560=";
        };
      };

      # DT_NEEDED holds only libc/libm/libdl/libpthread/librt/libutil/ libgcc_s,
      # plus libstdc++ as of 0.4.0. Everything else is dlopen()'d at runtime,
      # so autoPatchelf would miss it; this set comes from `strings` on the
      # binary, diffed against the previous release (0.7.0 added
      # libpulse-simple.so.0): wgpu's Vulkan + EGL/GLES chain, the Wayland and
      # X11 windows, the WebKitGTK / WPEWebKit bindings for the browser block,
      # and libpipewire for screen sharing. X11 came with 0.5.0
      # (STENCIL_DISPLAY_SERVER); tern dlopens libxcb.so.1 there, and
      # libxkbcommon covers libxkbcommon-x11.so.0 too, since both ship in one
      # lib/. libX11 itself is still not in the binary -- webkitgtk_4_1 pulls it
      # in through libsoup and gtk3's X11 backend.
      runtimeLibs = with pkgs; [
        stdenv.cc.cc.lib
        vulkan-loader
        libglvnd
        wayland
        libxkbcommon
        libxcb
        glib
        gtk3
        webkitgtk_4_1
        libwpe
        libwpe-fdo
        # tern dlopens libpipewire for screen sharing itself, so the library has
        # to be reachable, not just the daemon.
        pipewire
        # tern dlopens libpulse-simple.so.0 itself as of 0.7.0 (PulseAudio simple
        # API), so it has to be reachable too.
      ];

      # Programs tern runs at runtime: LD_LIBRARY_PATH cannot
      # supply a program, so these need PATH, not an rpath
      # entry:
      #
      # zenity - the file/save/confirmation dialogs; without it tern reports "no dialog tool (install zenity or kdialog)"
      # glib   - gsettings, for the desktop clock setting (it lives in glib.bin; plain `glib` has no bin/ at all).
      #          0.9.30 dropped its gdbus call (Reveal in File Manager now asks the file manager over the portal)
      # perf   - drives the `perf since` marks
      runtimePrograms = with pkgs; [
        zenity
        glib.bin
        perf
      ];

      # WebKitGTK's TLS backend is a GIO module that libsoup dlopens, and
      # neither webkitgtk nor libsoup carries glib-networking -- without it the
      # browser block cannot make https requests.
      #
      # tern reads the org.gnome.desktop.interface schema itself, so the desktop
      # schemas must be on XDG_DATA_DIRS or the read fails and the settings fall
      # back to tern's own defaults.
      #
      # WebKitGTK plays media through gstreamer; without the plugin path it
      # cannot find a decoder.
      webkitRuntimeEnv = with pkgs; [
        "--prefix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules"
        "--prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
        "--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${getLib gst_all_1.gst-plugins-base}/lib/gstreamer-1.0"
      ];

      runtimeLibraryPath = makeLibraryPath runtimeLibs;

      # Linux: the tarball holds `tern/tern`. Fix the interpreter and rpath
      # before wrapping, then expose the runtime programs and the WebKit
      # environment the TUI needs.
      linuxInstallPhase = ''
        runHook preInstall

        # unpackPhase sets sourceRoot=tern, so cwd is already the tarball's
        # tern/ directory and the only file in it is ./tern.
        appDir="$out/opt/tern"
        mkdir -p "$appDir" "$out/bin"
        cp -a . "$appDir/"
        chmod -R u+w "$appDir"

        # Before the wrapper, so strip sees a real file.
        strip --strip-unneeded "$appDir/tern" || true

        rpath="${runtimeLibraryPath}:\''$ORIGIN/../lib:\''$ORIGIN"
        patchelf --set-rpath "$rpath" "$appDir/tern"
        patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$appDir/tern"

        # Runtime programs and WebKit environment.
        makeWrapper "$appDir/tern" "$out/bin/tern" \
          --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}" \
          --prefix PATH : "${lib.makeBinPath runtimePrograms}" \
          ${concatStringsSep " " webkitRuntimeEnv}

        runHook postInstall
      '';

      # Darwin: the zip holds a signed `Tern.app`; nothing to link or patch.
      # The bundle carries its own daemon and tray helper, and macOS finds
      # them relative to the executable, so only the location matters.
      darwinInstallPhase = ''
        runHook preInstall

        # stdenv opens tar and the compressors, but has no zip unpack hook.
        unzip -q "$src"

        mkdir -p "$out/Applications" "$out/bin"
        cp -a "Tern.app" "$out/Applications/"
        chmod -R u+w "$out/Applications/Tern.app"

        # Contents/MacOS/tern is the bundle executable and also answers the
        # CLI-style arguments (`tern ctl`, `--version`). A symlink leaves the
        # signed file alone, unlike copying it into bin/.
        ln -s "$out/Applications/Tern.app/Contents/MacOS/tern" "$out/bin/tern"

        runHook postInstall
      '';

      # Flake packages build against the flake-level pkgs, not the host's, so a
      # host's `unfree.allowedNames` never reaches this derivation.
      #
      # The gate binds at nixpkgs import time, so `pkgs.extend` cannot open it:
      # only a re-import can, and it gets an allowlist for this name alone.
      unfreePkgs = import pkgs.path {
        hostPlatform = pkgs.stdenv.hostPlatform;
        inherit system;
        config = pkgs.config // {
          allowUnfreePredicate = name: getName name == "tern";
        };
      };

    in
    {
      packages.tern =
        let
          fail = msg: throw "tern: ${msg}";
          release = releases.${system} or { };
        in
        unfreePkgs.stdenvNoCC.mkDerivation {
          pname = "tern";
          inherit version;

          src =
            if releases ? "${system}" then
              unfreePkgs.fetchurl {
                name = release.file;
                url = "file://${release.storePath}";
                inherit (release) hash;
              }
            else
              fail "no archive for ${system} (packaged: ${concatStringsSep ", " (attrNames releases)})";

          nativeBuildInputs =
            if pkgs.stdenv.hostPlatform.isDarwin then
              [ pkgs.unzip ]
            else
              [
                pkgs.makeWrapper
                pkgs.patchelf
                pkgs.binutils
              ];

          dontConfigure = true;
          dontBuild = true;
          # Nothing to configure or build. Strip is a no-op for now but a future
          # release that does ship symbols will get stripped.
          #
          # dontPatchELF keeps the generic fixupPhase from rewriting the RPATH
          # set below; autoPatchelf has no work to do, because everything
          # outside libc/libstdc++ is dlopen()'d at runtime.
          dontPatchELF = true;

          # Darwin: the bundle arrives signed, and fixupPhase has nothing to
          # normalize here (no shebangs, man pages or desktop files). Its
          # default stripDebugList covers Applications/, and llvm-strip rewrites
          # the Mach-O, which invalidates the code signature shipped in the
          # bundle -- on arm64 an unsigned binary is killed at launch. Skip all
          # of fixup so the app reaches $out byte-for-byte. `dontFixup` skips
          # the whole phase, strip included: do not add `dontStrip` here.
          dontFixup = pkgs.stdenv.hostPlatform.isDarwin;

          # stdenv cannot open zips; the darwin installPhase does it.
          dontUnpack = pkgs.stdenv.hostPlatform.isDarwin;

          installPhase = if pkgs.stdenv.hostPlatform.isDarwin then darwinInstallPhase else linuxInstallPhase;

          meta = {
            description = "Rust-native, Kitty-compatible terminal multiplexer";
            homepage = "https://stencil.so/tern";
            license = lib.licenses.unfree;
            mainProgram = "tern";
            platforms = attrNames releases;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          };
        };
    };
}
