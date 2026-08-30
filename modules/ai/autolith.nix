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
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.autolith
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
