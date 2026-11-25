{
  flake.nixosModules.vine =
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

      system = pkgs.stdenv.hostPlatform.system;

      grovePkgs = inputs.grove.packages.${system};
    in
    {
      imports = singleton inputs.grove.nixosModules.deploy;

      ai.secrets = true;

      # Vine is the tailnet-facing endpoint. The generation binds loopback and
      # the proxy socket binds every interface, so the firewall opens 8023 on
      # `ts0` alone.
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -i ts0 -p tcp --dport 8023 -j nixos-fw-accept
        ip6tables -A nixos-fw -i ts0 -p tcp --dport 8023 -j nixos-fw-accept
      '';

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

      # Deploy reads the grove and nixpkgs trees from their store paths on every
      # update, and `builtins.toJSON` drops the context of a path, so the system
      # closure has to hold both. A flake input value carries that context.
      system.extraDependencies = [
        inputs.grove.outPath
        inputs.nixpkgs.outPath
      ];

      services.deploy = {
        enable = true;
        package = grovePkgs.deploy;

        # Deploy evaluates the store copies of the trees above, so it needs no
        # fetch credential, and root owns the state directory it roots the
        # generations under.
        eval_user = null;

        services.vine = {
          # The host's own grove revision is what deploys here: `deploy update`
          # re-evaluates this tree, and the artifact carries the vine binary it
          # builds.
          flake_path = inputs.grove.outPath;
          nixpkgs_path = inputs.nixpkgs.outPath;

          activation = "proxy";
          listen = "0.0.0.0:8023";
          environment_files = singleton sops.templates."vine-env".path;

          settings = {
            cooldown_secs = 60;
            log_level = "info";
            # The unit declares `StateDirectory = vine`, so the dynamic user
            # owns this file.
            usage_log = "/var/lib/vine/usage.jsonl";

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
    };
}
