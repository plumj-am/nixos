let
  ncpsBase =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.types) str;
      inherit (lib.options) mkOption;
      inherit (lib.modules) mkBefore;
      inherit (config) networking;
      inherit (config.nix) settings;

      urls = settings.extra-substituters ++ settings.substituters or [ ];
      publicKeys = settings.extra-trusted-public-keys ++ settings.trusted-public-keys or [ ];

      hostName = "cache-proxy-${networking.hostName}";
      localUrl = "http://localhost:${port}";
      port = "8501";
    in
    {

      options.nix-cache-proxy.publicKey = mkOption {
        type = str;
        default = "";
        description = "Public key for the local cache proxy";
      };

      config = {
        assertions = singleton {
          assertion = config.nix-cache-proxy.publicKey != "";
          message = "nix-cache-proxy.publicKey must be set to use the local cache proxy.";
        };

        nix.settings.substituters = mkBefore [ localUrl ];
        nix.settings.extra-trusted-public-keys = mkBefore [
          config.nix-cache-proxy.publicKey
        ];

        services.ncps = {
          enable = true;
          cache = {
            inherit hostName;
            upstream = {
              inherit urls publicKeys;
            };
          };
        };
      };
    };
in
{
  flake.modules.nixos.nix-cache-proxy = ncpsBase;
  flake.modules.darwin.nix-cache-proxy = ncpsBase;
}
