{
  config.flake.modules.nixos.netrc = {
    nix.settings.netrc-file = "/etc/.netrc";

    age.secrets.netrc = {
      rekeyFile = ../secrets/netrc.age;
      path = "/etc/.netrc";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
