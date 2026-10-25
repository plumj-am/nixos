{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs;

      version = "1.1.0";

      # Pinned by the kernel module itself: the firmware the unlock needs is
      # extracted from this NVIDIA release. The driver version that runs on the
      # unlocked card is unrelated.
      nvidiaVersion = "610.43.03";

      # Names produced by firmware/extract_gsp.py + firmware/extract_boot_assets.py,
      # and baked into the module as `request_firmware()` paths (recipes.h).
      firmwareFiles = [
        "booter_load_ga100.bin"
        "booter_load_ga102.bin"
        "booter_load_ad102.bin"
        "falcon_loader.bin"
        "gsp_boot_desc_ga100.bin"
        "gsp_boot_desc_ga102.bin"
        "gsp_boot_desc_ad102.bin"
        "gsp_boot_ga100.bin"
        "gsp_boot_ga102.bin"
        "gsp_boot_ad102.bin"
        "gsp_ga10x.bin"
        "gsp_tu10x.bin"
      ];

      src = pkgs.fetchFromGitHub {
        owner = "Zagitta";
        repo = "gpu-unlock";
        rev = "6081407b312aa3139a2bed62bdda354f4ffddc1d";
        hash = "sha256-6FbsBw20/+MRP676qur+C4glwrKmqlNi3xwAzB82zoA=";
      };

      # Same two inputs and hashes as packaging/arch/PKGBUILD. The build never
      # touches the network: both are fixed-output fetches.
      nvidiaKernelSource = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nvidiaVersion}.tar.xz";
        hash = "sha256-fhGJI8eiPtw2EU1jJzpG4+BOmvmGlaQiA+esLf6fwdw=";
      };

      nvidiaInstaller = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nvidiaVersion}/NVIDIA-Linux-x86_64-${nvidiaVersion}-no-compat32.run";
        hash = "sha256-4IRFHbcwpt8p09dPZVdJxNI248lF99lLUgXoQxj+L5A=";
      };

      # Extracted from the pinned NVIDIA inputs. Kernel-independent, so every
      # kernel build reuses one store path.
      firmware = pkgs.stdenvNoCC.mkDerivation {
        pname = "gpu-unlock-firmware";
        inherit version;

        inherit src;

        nativeBuildInputs = [
          pkgs.python3
          pkgs.zstd
        ];

        buildPhase = ''
          runHook preBuild

          mkdir -p assets
          ${pkgs.python3}/bin/python3 firmware/extract_gsp.py ${nvidiaInstaller} assets

          tar -xf ${nvidiaKernelSource} -C .
          ${pkgs.python3}/bin/python3 firmware/extract_boot_assets.py \
            "NVIDIA-kernel-module-source-${nvidiaVersion}" assets

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          install -Dm644 -t "$out/lib/firmware/gpu-unlock/${nvidiaVersion}" \
            ${lib.concatMapStringsSep " " (name: "assets/${name}") firmwareFiles}

          install -Dm644 assets/NVIDIA-LICENSE "$out/share/licenses/gpu-unlock-firmware/NVIDIA-LICENSE"
          install -Dm644 firmware/NOTICE.md "$out/share/licenses/gpu-unlock-firmware/NOTICE.md"
          install -Dm644 -t "$out/share/licenses/gpu-unlock" licenses/*.txt

          runHook postInstall
        '';

        # Paths relative to `hardware.firmware`/`lib/firmware`, for
        # `boot.initrd.extraFirmwarePaths`. The module has no MODULE_FIRMWARE()
        # entries, so the initrd closure cannot derive them itself.
        passthru.firmwarePaths = map (name: "gpu-unlock/${nvidiaVersion}/${name}") firmwareFiles;

        meta = {
          description = "Generated NVIDIA firmware assets for the gpu-unlock kernel module";
          homepage = "https://github.com/Zagitta/gpu-unlock";
          # No `license`: the assets are NVIDIA-proprietary (redistributable
          # only), and this flake's perSystem `pkgs` has no `allowUnfree`, so
          # classifying them unfree would make the package unevaluatable. The
          # NVIDIA license and firmware/NOTICE.md are installed instead.
          platforms = lib.platforms.linux;
        };
      };

      mkModule =
        kernel:
        kernel.stdenv.mkDerivation {
          pname = "gpu-unlock";
          version = "${version}-${kernel.modDirVersion}";

          inherit src;

          # PR #72 (unmerged, fixes upstream #42). A PRI-error sample
          # (`plm=0xbadf0001 boot=0xbadf00ff cpuctl=0xbadf0010`) passes every
          # bit test in gpu_unlock_gfw_assess() and reads as "GFW ready", while
          # wait_post_flr_gfw() already treats that family as unreadable. This
          # revision has only the all-ones guard, so the cold-card wait can
          # proceed on a card that is still booting. Only the gfw_eval.c hunk
          # applies here: tests/test_gfw_eval.c does not exist at this
          # revision.
          patches = [ ./patches/pr-72-gfw-pri-poll.patch ];

          hardeningDisable = [
            "pic"
            "format"
          ];

          nativeBuildInputs = kernel.moduleBuildDependencies;

          buildPhase = ''
            runHook preBuild

            make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
              M="$PWD/kernel/gpu_unlock" modules

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/lib/modules/${kernel.modDirVersion}/extra"
            cp kernel/gpu_unlock/gpu_unlock.ko "$out/lib/modules/${kernel.modDirVersion}/extra/"

            runHook postInstall
          '';

          passthru = {
            inherit firmware mkModule;
            inherit (firmware) firmwarePaths;
          };

          meta = {
            description = "Unlock full FP/BF16 issue rate on Ampere consumer cards before nvidia binds them";
            homepage = "https://github.com/Zagitta/gpu-unlock";
            license = lib.licenses.gpl2Only;
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      # Kernel modules need a Linux kernel, so the aarch64-darwin system gets
      # neither of these. `gpu-unlock` is built for the kernel pinned by
      # modules/games.nix; NixOS modules use `gpu-unlock.mkModule` with
      # `config.boot.kernelPackages.kernel` instead.
      packages = optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        gpu-unlock = mkModule pkgs.linuxPackages_zen.kernel;
        gpu-unlock-firmware = firmware;
      };
    };
}
