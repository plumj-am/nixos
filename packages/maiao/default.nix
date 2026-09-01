{
  perSystem =
    { pkgs, ... }:
    {
      packages.maiao = pkgs.buildGoModule {
        pname = "maiao";
        version = "1.4.0";

        src = pkgs.fetchFromGitHub {
          owner = "runetes";
          repo = "maiao";
          rev = "maiao-v1.4.0";
          hash = "sha256-sMxEtvDYluRBQGGrCbHZcBDTESdgdVd3+HuE7k3ELFM=";
        };

        modRoot = ".";
        subPackages = [ "cmd/maiao" ];

        vendorHash = "sha256-1q88bEFo1RKOE9k1Ii3ThcahECQVF40yHUVVEk08RXw=";
      };
    };
}
