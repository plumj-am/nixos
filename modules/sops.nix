{
  flake.modules.nixos.sops =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton inputs.sops.nixosModules.default;

      environment.systemPackages = singleton pkgs.sops;

      sops = {
        defaultSopsFile = ../secrets/all/shared.yaml;
        useSystemdActivation = true;
        age.sshKeyPaths = [
          "${config.users.users.jam.home}/.ssh/id"
          "${config.users.users.root.home}/.ssh/id"
        ];
      };
    };

  flake.modules.darwin.sops =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton inputs.sops.darwinModules.default;

      environment.systemPackages = singleton pkgs.sops;

      sops = {
        defaultSopsFile = ../secrets/all/shared.yaml;
        useSystemdActivation = true;
        age.sshKeyPaths = singleton "${config.users.users.jam.home}/.ssh/id";
      };
    };
}
