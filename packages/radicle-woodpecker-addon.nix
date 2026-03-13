{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) fetchgit buildGoModule;
      inherit (pkgs.lib.licenses) asl20;
    in
    {
      packages.radicle-woodpecker-addon = buildGoModule {
        pname = "radicle-woodpecker-addon";
        version = "0.3.0";

        src = fetchgit {
          url = "https://seed.radicle.gr/rad:z39Cf1XzrvCLRZZJRUZnx9D1fj5ws";
          rev = "7009456529aa614ecc40bd5640de07d56deeea75";
          hash = "sha256-cXccs2de6jbpVQZ9pAHlgIAEQ0hCv6mZb775KyG2Izc=";
        };

        vendorHash = "sha256-SHQvy3YxTVo/D0+/mPaJx34vXvANbWcFv11xY2dgyM8=";

        ldflags = [
          "-X"
          "radicle-woodpecker-addon/pkg/version.Version=0.3.0"
        ];

        meta = {
          description = "Radicle addon for Woodpecker CI";
          homepage = "https://seed.radicle.gr/rad:z39Cf1XzrvCLRZZJRUZnx9D1fj5ws";
          license = asl20;
          mainProgram = "radicle-woodpecker-addon";
        };
      };
    };
}
