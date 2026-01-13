{ config, ... }:
let
  inherit (config.ciLib) commonConcurrency stepsWithCheckout;
in
{
  flake.actions-nix.workflows.".forgejo/workflows/update-flake-inputs.yml" = {
    name = "Update Flake Inputs";
    on = {
      schedule = [
        # See `./update-flake-inputs.nix` for more details.
        { cron = "0 0 * * *"; } # Every day at 00:05. Keep ahead of `./update-flake-inputs.yml`.
      ];
      workflow_dispatch = { };
    };
    concurrency = commonConcurrency "update-flake-inputs";
    jobs = {
      update-flake-inputs = {
        name = "Update Flake Inputs";
        runs-on = "plum";
        steps = stepsWithCheckout [
          {
            name = "Update specific inputs";
            run = # bash
              ''
                nix flake update opencode claude-code
              '';
          }
          {
            name = "Commit and push changes";
            run = # bash
              ''
                fj auth add-key plumjam ''${{ secrets.FORGEJO_TOKEN }}

                git config --global user.name "PlumJam [bot]"
                git config --global user.email "forgejo-bot@plumj.am"

                if [ -n "$(git status --porcelain flake.lock)" ]; then
                  git add flake.lock
                  git commit -m "nix: Update flake inputs for AI tools."
                  git push origin master
                  echo "Changes committed and pushed."
                else
                  echo "No changes to push."
                fi
              '';
          }
        ];
      };
    };
  };
}
