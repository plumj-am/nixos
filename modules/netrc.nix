{
  flake.modules.nixos.netrc = {
    nix.settings.netrc-file = "/etc/.netrc";

    sops.secrets.netrc = {
      sopsFile = ../secrets/all/netrc.yaml;
      path = "/etc/.netrc";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
