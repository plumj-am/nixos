{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.autolith;
  flake.modules.common.autolith =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.bubblewrap
        # nuke.nix exposes a perl-free autolith on NixOS; darwin lacks the
        # nuke overlay, so fall back to the upstream package.
        (pkgs.autolith or inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.autolith)
      ];

      hjemModule = {
        xdg.config.files."autolith/init.lisp".text = # lisp
          let
            provider = config.ai.providers.headroomVineProxy;
          in
          ''
            (register-openai-compatible-provider
             :name            "${provider.name}"
             :description     "Vine via Headroom"
             :endpoint        "${provider.baseUrl}/chat/completions"
             :models-endpoint "${provider.baseUrl}/models")
          '';
      };
    };
}
