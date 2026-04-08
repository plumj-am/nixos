{
  flake.modules.common.xdg =
    { config, ... }:
    {
      config = {
        nix.settings.use-xdg-base-directories = true;

        hjem.extraModule = {
          environment.sessionVariables = {
            XDG_CACHE_HOME = "${config.directory}/.cache";
            XDG_CONFIG_HOME = "${config.directory}/.config";
            XDG_DATA_HOME = "${config.directory}/.local/share";
            XDG_STATE_HOME = "${config.directory}/.local/state";
          };
        };
      };
    };
}
