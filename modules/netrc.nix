{
  flake.modules.nixos.netrc = {
    nix.settings.netrc-file = "/etc/.netrc";

    sops.secrets = {
      "netrc/system" = {
        sopsFile = ../secrets/all/netrc.yaml;
        path = "/etc/.netrc";
        owner = "root";
        mode = "600";
      };
      "netrc/jam" = {
        sopsFile = ../secrets/all/netrc.yaml;
        path = "/home/jam/.netrc";
        owner = "jam";
        mode = "600";
      };
      "netrc/root" = {
        sopsFile = ../secrets/all/netrc.yaml;
        path = "/root/.netrc";
        owner = "root";
        mode = "600";
      };
    };
  };
}
