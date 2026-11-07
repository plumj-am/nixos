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
      inherit (lib.attrsets) genAttrs;
      inherit (lib.filesystem) baseNameOf;
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
        VINE_UPSTREAMS_COMMANDCODE_DECISION__API_KEYS=${sops.placeholder."commandcode-1-key"},${
          sops.placeholder."commandcode-2-key"
        }
        VINE_UPSTREAMS_TYPESAFE_DECISION__API_KEYS=${sops.placeholder."typesafe-1-key"}
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
              skip_models = singleton "typesafe/jev";
            };
            commandcode_decision = {
              url = "https://api.commandcode.ai/provider/v1/systemone";
              order = 15;
              only_models = singleton "typesafe/jev";
            };
            typesafe_decision = {
              url = "https://api.typesafe.ai/v1/systemone";
              order = 20;
              model_map."typesafe/jev" = "jev-latest";
              only_models = singleton "typesafe/jev";
            };
            opendesign = {
              url = "https://amr-link.open-design.ai/v1";
              order = 30;
              # What model is sent and what the upstream calls it.
              model_map =
                genAttrs [
                  "z-ai/glm-5.3-flash"
                  "xiaomi/mimo-v2.6-flash"
                  "xiaomi/mimo-v2.6-pro"
                ] baseNameOf
                // {
                  "deepseek/deepseek-v4.1-flash" = "deepseek-v4.1-flash-eco";
                };

              # client-sent ids this upstream does not serve; exact match
              skip_models = [
                "inclusionai/ling-3.1-flash-1019:free"
                "minimax/minimax-m3.1-flash:free"
                "reflection/beam:free"
                "typesafe/jev"
              ];
            };
          };
        };
      };
    };
}
