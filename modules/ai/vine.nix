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
        VINE_API_KEYS=${sops.placeholder."commandcode-1-key"},${sops.placeholder."commandcode-2-key"}
      '';

      services.vine = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.vine;

        environment_file = sops.templates."vine-env".path;

        config = {
          provider_url = "https://api.commandcode.ai/provider/v1";
          host = "127.0.0.1";
          port = 8023;
          cooldown_secs = 60;
          log_level = "info";
        };
      };
    };
}
