{
  flake.modules.nixos.tend =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.sops) secrets;
    in
    {
      imports = singleton inputs.grove.nixosModules.tend;

      sops.secrets = {
        "tend/token" = {
          sopsFile = ../secrets/services/tend.yaml;
          owner = "tend";
          group = "tend";
          mode = "600";
        };
        "tend/app_secret_key" = {
          sopsFile = ../secrets/services/tend.yaml;
          owner = "tend";
          group = "tend";
          mode = "600";
        };
      };

      services.tend = {
        enable = true;
        package = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.tend;

        state_dir = "/var/lib/tend";

        postHookPath = [ ];

        # TEND_FORGEJO__TOKEN and GITHUB_TOKEN (for nix pins).
        environment_file = secrets."tend/token".path;

        schedule = "daily";

        config = {
          forge = {
            type = "github";
            url = "https://github.com";
          };

          github = {
            app_id = 4849861;
            installation_id = 159495263;
            private_key_file = secrets."tend/app_secret_key".path;
          };

          repos = [
            {
              name = "grove";
              owner = "grove-systems";
              repo = "grove";
              base_branch = "master";
              clone_url = "https://github.com/grove-systems/grove";
            }
          ];

          git = {
            author_name = "Tend [bot]";
            author_email = "tend-bot@plumj.am";
          };

          managers = {
            cargo = true;
            npm = true;
            nix = true;
          };

          pr = {
            branch_prefix = "tend/";
            labels = singleton "deps";
            title_prefix = "deps: ";
          };

          updates = {
            minimum_age_days = 7;
            ignore = [ ];
            dry_run = false;
            force_update = false;
            post_hook = # bash
              ''

              '';
          };
        };
      };
    };
}
