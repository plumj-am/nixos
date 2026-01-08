{
  config.flake.modules.nixosModules.immutable-users =
  {
    users.mutableUsers = false;
  };
}
