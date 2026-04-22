# Remove All PErl!
# Credit to: <https://github.com/amaanq/dotfiles>
# nixos-core project: <https://github.com/feel-co/nixos-core>
#
{
  flake.modules.nixos.raperl =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkDefault;
      inherit (lib.lists) singleton filter;
      inherit (lib.attrsets) optionalAttrs;
    in
    {
      imports = singleton inputs.nixos-core.nixosModules.default;

      system = {
        # nixos-core replaces:
        #   update-users-groups.pl      (user/group/shadow sync)
        #   setup-etc.pl                (/etc/static atomic update)
        #   stage-1-init.sh             (legacy initrd boot)
        #   stage-2-init.sh             (system activation post-initrd)
        nixos-core.enable = true;

        # Unnecessary with flakes.
        tools.nixos-generate-config.enable = mkDefault false;

        # Block perl.
        # forbiddenDependenciesRegexes = singleton "perl";
      };

      environment.systemPackages =
        singleton
        <| pkgs.symlinkJoin {
          name = "handlr-wrapped";
          paths = singleton pkgs.handlr-regex;
          buildInputs = singleton pkgs.makeWrapper;
          postBuild = # sh
            ''
              wrapProgram $out/bin/handlr \
                --add-flags "--disable-notifications"
            '';
        };

      nixpkgs.overlays = singleton (
        final: prev:
        {
          # From <https://github.com/amaanq/dotfiles/blob/b4a94b33395ea6ed4b0949be65b954d9071058b2/modules/common/nixpkgs.nix>

          # git-repo's wrapper pulls the full perl-enabled git.
          git-repo = prev.git-repo.override { git = final.gitMinimal; };

          # in aspell, bin/aspell-import is a perl script which imports
          # ispell wordlists. This is not used in KDE
          aspell = prev.aspell.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              rm -f $out/bin/aspell-import
            '';
          });

          # Patch kio-extras at the kdePackages *scope* level so Dolphin
          # et al. rebuild against the perl-free variant.
          kdePackages = prev.kdePackages.overrideScope (
            _kfinal: kprev: {
              kio-extras = kprev.kio-extras.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace CMakeLists.txt \
                    --replace-fail 'add_subdirectory( info )' \
                                   '# add_subdirectory( info )  # perl-free closure'
                '';
              });
            }
          );

          # From PlumJam

          # Anything that asks for pkgs.git gets the perl-free build.
          git = prev.git.override {
            perlSupport = false;
            withManual = false;
            pythonSupport = false;
            osxkeychainSupport = false;
            withpcre2 = false;
          };

          # hspell: multispell is a perl script.
          hspell = prev.hspell.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              rm -f $out/bin/multispell
            '';
          });

          # radicle-httpd wraps with full git (and man-db/xdg-utils).
          # man-db and xdg-utils are fine; git is the perl carrier.
          radicle-httpd = prev.radicle-httpd.overrideAttrs (old: {
            postFixup = ''
              for program in $out/bin/* ; do
                wrapProgram "$program" \
                  --prefix PATH : "${
                    lib.makeBinPath [
                      final.gitMinimal
                      final.man-db
                      final.xdg-utils
                    ]
                  }"
              done
            '';
          });

          # Qt5 scope may still be used by legacy packages.
          libsForQt5 = prev.libsForQt5.overrideScope (
            kfinal: kprev:
            optionalAttrs (kprev ? kio-extras) {
              kio-extras = kprev.kio-extras.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace CMakeLists.txt \
                    --replace-fail 'add_subdirectory( info )' \
                                   '# add_subdirectory( info )  # perl-free closure'
                '';
              });
            }
          );

          # GNU parallel is written in perl.  This stub lets you discover
          # what still pulls it via `nix why-depends`.
          parallel = final.writeShellScriptBin "parallel" ''
            echo "GNU parallel disabled because it requires perl." >&2
            echo "Run 'nix why-depends /run/current-system nixpkgs#parallel' to find the culprit." >&2
            exit 1
          '';

          # FHS envs (Steam, Vial AppImage, etc.) explicitly include perl
          # in their target package lists.  Strip it out globally.
          #   buildFHSEnv =
          #     args:
          #     let
          #       noPerl = p: (p.pname or "") != "perl";
          #       filteredTargetPkgs =
          #         if args ? targetPkgs then
          #           if builtins.isFunction args.targetPkgs then
          #             pkgs: filter noPerl (args.targetPkgs pkgs)
          #           else if builtins.isList args.targetPkgs then
          #             filter noPerl args.targetPkgs
          #           else
          #             args.targetPkgs
          #         else
          #           null;
          #     in
          #     prev.buildFHSEnv (
          #       args
          #       // optionalAttrs (filteredTargetPkgs != null) {
          #         targetPkgs = filteredTargetPkgs;
          #       }
          #     );
        }
        // optionalAttrs prev.stdenv.hostPlatform.isLinux {

          # From <https://github.com/amaanq/dotfiles/blob/b4a94b33395ea6ed4b0949be65b954d9071058b2/modules/common/nixpkgs.nix>

          xdg-utils = final.symlinkJoin {
            name = "xdg-utils-handlr-shim-${prev.handlr-regex.version or "0"}";
            paths = [
              final.xdg-user-dirs
              (final.writeShellScriptBin "xdg-open" ''exec ${final.handlr-regex}/bin/handlr --disable-notifications open "$@"'')
              (final.writeShellScriptBin "xdg-mime" ''exec ${final.handlr-regex}/bin/handlr --disable-notifications mime "$@"'')
              (final.writeShellScriptBin "xdg-settings" ''exec ${final.handlr-regex}/bin/handlr --disable-notifications get "$@"'')
              (final.writeShellScriptBin "xdg-email" ''exec ${final.handlr-regex}/bin/handlr --disable-notifications open "mailto:$*"'')

              # These are install-time helpers that are not used on NixOS.
              (final.writeShellScriptBin "xdg-desktop-menu" "exit 0")
              (final.writeShellScriptBin "xdg-desktop-icon" "exit 0")
              (final.writeShellScriptBin "xdg-icon-resource" "exit 0")
              (final.writeShellScriptBin "xdg-screensaver" "exit 0")
            ];
            meta = {
              description = "xdg-utils shim backed by handlr-regex (perl-free)";
              mainProgram = "xdg-open";
            };
          };

          # winetricks's wrapper embeds perl in PATH for a handful of niche
          # verbs (mostly font/registry helpers). Scrub the store ref so perl
          # drops out of the closure; if a verb that needs perl is invoked,
          # it'll just error at runtime. This should *probably* be fine.
          winetricks = prev.winetricks.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.removeReferencesTo ];
            postFixup = (old.postFixup or "") + ''
              remove-references-to -t ${final.perl} $out/bin/winetricks $out/bin/.winetricks-wrapped
            '';
          });

          # libvirt defaults to enabling Xen on x86_64 Linux, dragging in
          # xen → ipxe → syslinux → perl. We only use the qemu/KVM driver,
          # so Xen can be dropped.
          libvirt = prev.libvirt.override { enableXen = false; };

          # rnnoise-plugin drags webkitgtk_4_1 into buildInputs purely because
          # JUCE's default plugin profile includes a WebBrowser module. The
          # built shared object has no UI, so we strip webkit and tell JUCE
          # to skip web.
          rnnoise-plugin = prev.rnnoise-plugin.overrideAttrs (old: {
            buildInputs = filter (p: (p.pname or "") != "webkitgtk") (old.buildInputs or [ ]);
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DJUCE_WEB_BROWSER=0" ];
          });
        }

        # From PlumJam
      );
    };
}
