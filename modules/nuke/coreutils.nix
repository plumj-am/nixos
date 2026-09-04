{ self, ... }:
{
  flake.modules.nixos.nuke = self.modules.nixos.nuke-coreutils;
  flake.modules.nixos.nuke-coreutils =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton head;
      inherit (lib.trivial) flip;
      inherit (lib.filesystem) baseNameOf;
      inherit (lib.strings) replicate stringLength;
    in
    {
      system.replaceDependencies.replacements =
        let
          candidates = [
            # Not ready for use yet: <https://github.com/uutils/acl>
            # {
            #   prev = pkgs.acl;
            #   final = pkgs.uutils-acl;
            #   finalName = "u-acl";
            # }
            {
              prev = pkgs.coreutils;
              final = pkgs.uutils-coreutils-noprefix;
              finalName = "u-coreutils";
            }
            {
              prev = pkgs.coreutils-full;
              final = pkgs.uutils-coreutils-noprefix;
              finalName = "u-coreutils";
            }
            {
              prev = pkgs.diffutils;
              final = pkgs.uutils-diffutils;
              finalName = "u-diffutils";
            }
            {
              prev = pkgs.findutils;
              final = pkgs.uutils-findutils;
              finalName = "u-findutils";
            }
            {
              prev = pkgs.gnused;
              final = pkgs.uutils-sed;
              finalName = "u-sed";
            }
            {
              prev = pkgs.gnutar;
              final = pkgs.uutils-tar;
              finalName = "u-tar";
            }
            {
              prev = pkgs.hostname;
              final = pkgs.uutils-hostname;
              finalName = "u-hostname";
            }
            {
              prev = pkgs.hostname-debian;
              final = pkgs.uutils-hostname;
              finalName = "u-hostname";
            }
            {
              prev = pkgs.procps;
              final = pkgs.uutils-procps;
              finalName = "u-procps";
            }
            # Waiting for nixpkgs uutils-shadow: <https://github.com/NixOS/nixpkgs/pull/546635>
            # {
            #   prev = pkgs.su;
            #   final = pkgs.uutils-shadow;
            #   finalName = "u-shadow";
            # }
            # {
            #   prev = pkgs.shadow;
            #   final = pkgs.uutils-shadow;
            #   finalName = "u-login";
            # }
            # Not ready for use yet: <https://github.com/uutils/util-linux>
            # {
            #   prev = pkgs.util-linux;
            #   final = pkgs.uutils-util-linux;
            #   finalName = "u-util-linux";
            # }
          ];
        in
        flip map candidates (
          {
            prev,
            final,
            finalName,
          }:
          let
            # Extract the actual store path name (without the hash) from a derivation
            oldStorePathName =
              let
                base = baseNameOf prev.outPath; # e.g. "hash-util-linux-2.42.2-bin"
                # Capture everything after the first dash
                match = lib.strings.match "^[^-]+-(.*)$" base;
              in
              assert match != null;
              head match;

            name =
              let
                padding = stringLength oldStorePathName - stringLength finalName;
              in
              assert padding >= 0;
              finalName + replicate padding "_";

            mvCompat = final == pkgs.uutils-coreutils-noprefix;
          in
          {
            oldDependency = prev;
            newDependency = pkgs.symlinkJoin {
              inherit name;
              paths = singleton final;

              # Until this is fixed: <https://github.com/uutils/coreutils/issues/11321>.
              # Without it, we get prompted for mv confirmation during activation.
              nativeBuildInputs = if mvCompat then [ pkgs.makeWrapper ] else [ ];
              postBuild =
                if mvCompat then
                  # bash
                  ''
                    rm $out/bin/mv
                    makeWrapper \
                      ${pkgs.uutils-coreutils-noprefix}/bin/mv \
                      $out/bin/mv --add-flags "--force"
                  ''
                else
                  "";
            };
          }
        );

      nixpkgs.overlays = singleton (
        final: prev:
        let
          replaceCoreutils =
            program: rest:
            prev.${program}.override {
              coreutils = final.uutils-coreutils-noprefix;
            }
            // rest;
        in
        {
          alsa-ucm-conf = replaceCoreutils "alsa-ucm-conf" { };
          bash = replaceCoreutils "bash" { };
          mangohud = replaceCoreutils "mangohud" {
            # gnugrep = final.uutils-grep; # not in nixpkgs yet
            gnused = final.uutils-sed;
          };
          # networkmanager = replaceCoreutils "network-manager" {}; # Can't be done: leads to type mismatches.
          openresolv = replaceCoreutils "openresolv" { };
          systemd = replaceCoreutils "systemd" { }; # Uses coreutils for `${coreutils}/bin/false` lol...
          systemdMinimal = replaceCoreutils "systemdMinimal" { };
        }
      );
    };
}
