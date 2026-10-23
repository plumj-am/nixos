{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.ncp;
  flake.modules.nixos.ncp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) listToAttrs;
      inherit (lib.constants) tailnet;
      inherit (lib.lists)
        filter
        head
        imap0
        singleton
        unique
        ;
      inherit (lib.strings)
        hasInfix
        hasPrefix
        removeSuffix
        replaceStrings
        splitString
        ;

      declared = config.nix.settings.substituters ++ config.nix.settings.extra-substituters;

      isHttp = url: hasPrefix "http://" url || hasPrefix "https://" url;
      isS3 = url: hasPrefix "s3://" url;
      isProxyable = url: isHttp url || isS3 url;

      # Anything the proxy cannot front, for example `file://`, stays a direct
      # substituter behind ncp.
      proxyable = unique <| filter isProxyable declared;
      direct = unique <| filter (url: !isProxyable url) declared;

      private = filter (url: hasInfix tailnet url) proxyable;
      public = filter (url: !hasInfix tailnet url) proxyable;
      ordered = private ++ public;

      # Upstream names come from the URL without its scheme and query, so an
      # `s3://` cache is named by its bucket.
      nameFor =
        url:
        let
          withoutScheme = replaceStrings [ "https://" "http://" "s3://" ] [ "" "" "" ] url;
          withoutQuery = head (splitString "?" withoutScheme);
        in
        replaceStrings [ "/" ":" "." ] [ "-" "-" "-" ] <| removeSuffix "/" withoutQuery;

      upstreams = listToAttrs (
        imap0 (index: url: {
          name = nameFor url;
          value = {
            inherit url;
            order = 10 + index * 10;
            hedge = hasInfix tailnet url;
          };
        }) ordered
      );

      # No cache at all still needs a working config: ncp refuses to start with
      # an empty upstream list.
      fallbackUpstreams = {
        cache-nixos-org = {
          url = "https://cache.nixos.org";
          order = 10;
          hedge = false;
        };
      };
    in
    {
      imports = singleton self.inputs.grove.nixosModules.ncp;

      services.ncp = {
        enable = true;
        package = self.inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.ncp;

        # Make ncp + extraSubstituters the only substituters via
        # `nix.extraOptions` which appends and overrides earlier settings.
        replaceSubstituters = true;

        # Non-HTTP, non-S3 caches stay direct, after the sidecar.
        extraSubstituters = direct;

        config.upstreams = if ordered == [ ] then fallbackUpstreams else upstreams;
      };

      # The `s3` aspect materialises the shared credentials file and makes it
      # group-readable; ncp needs both to sign `s3://` upstreams. Same wiring
      # as shed and graft.
      systemd.services.ncp = {
        after = [ "s3-credentials.service" ];
        serviceConfig.SupplementaryGroups = [ "s3" ];
        environment.AWS_SHARED_CREDENTIALS_FILE = config.s3.credentialsFile;
      };
    };
}
