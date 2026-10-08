{
  flake.modules.nixos.comfyui =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;

      isNvidiaGpu = config.systemInfo.gpu.vendor == "nVidia Corporation";
    in
    {
      imports = singleton inputs.comfyui.nixosModules.default;

      unfree.allowedNames = mkIf isNvidiaGpu [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "cuda_nvrtc"
      ];

      nix.settings = {
        extra-substituters = [
          "https://cache.flox.dev"
          "https://cache.nixos-cuda.org"
        ];
        extra-trusted-public-keys = [
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      services.comfyui = {
        enable = true;
        enableManager = true;

        listenAddress = "127.0.0.1";
        port = 8025;

        gpuSupport = "cuda";

        dataDir = "/var/lib/comfyui";
        createUser = true;

        bundledCustomNodes = true;
      };
    };
}
