{ inputs, ... }:
{
  config.flake.modules.homeModules.home-module =
  {
    imports = [ inputs.home-modules.hjemModules.hjem-rum ];
  };
}
