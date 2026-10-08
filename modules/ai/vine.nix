{
  flake.modules.nixos.vine =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) sops;
    in
    {
      imports = singleton inputs.grove.nixosModules.vine;

      ai.secrets = true;

      sops.templates."vine-env".content = ''
        VINE_UPSTREAMS_COMMANDCODE__API_KEYS=${sops.placeholder."commandcode-1-key"},${
          sops.placeholder."commandcode-2-key"
        }
        VINE_UPSTREAMS_OPENDESIGN__API_KEYS=${sops.placeholder."opendesign-1-key"}
      '';

      services.vine = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.vine;

        environment_file = sops.templates."vine-env".path;

        config = {
          host = "127.0.0.1";
          port = 8023;
          cooldown_secs = 60;
          log_level = "info";

          upstreams = {
            commandcode = {
              url = "https://api.commandcode.ai/provider/v1";
              order = 10;
              model_map = { };
            };
            opendesign = {
              url = "https://amr-link.open-design.ai/v1";
              order = 20;
              # what model is sent and what the upstream calls it
              model_map = {
                "deepseek/deepseek-v4.1-flash" = "deepseek-v4-flash";
                "z-ai/glm-5.3-flash" = "glm-5.3-flash";
                "xiaomi/mimo-v2.6-flash" = "mimo-v2.6-flash";
                "xiaomi/mimo-v2.6-pro" = "mimo-v2.6-pro";
              };
            };
          };
        };
      };
    };
}
