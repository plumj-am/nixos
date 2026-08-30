{
  flake.modules.common.autolith =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      hjemModule = {
        packages = [
          pkgs.bubblewrap
          # nuke.nix exposes a perl-free autolith on NixOS; darwin lacks the
          # nuke overlay, so fall back to the upstream package.
          (pkgs.autolith or inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.autolith)
        ];

        xdg.config.files."autolith/init.lisp".text = # lisp
          ''
            (register-openai-compatible-provider
             :name            "command-code"
             :description     "Command Code"
             :endpoint        "https://api.commandcode.ai/provider/v1/chat/completions"
             :models-endpoint "https://api.commandcode.ai/provider/v1/models")
          '';
      };
    };
}
