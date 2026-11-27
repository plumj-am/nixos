{ self, ... }:
{
  flake.nixosModules.desktop = self.nixosModules.rex;
  flake.nixosModules.rex =
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
      imports = singleton inputs.rex.nixosModules.default;

      environment.systemPackages =
        singleton
          inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.default;

      services.rex = {
        enable = true;

        extraListen = singleton "tailnet://:7297";
      };

      # `tailscaled.service` reports started as soon as its process runs, which
      # can be seconds before it reassigns the tailnet address. The rex unit
      # `Requires=tailscaled.service` because of its `tailnet://` listener, so
      # on every `nixos-rebuild switch` systemd restarts rex right behind a
      # restarted tailscaled and rex exits with "binding extra listener 0: this
      # host has no tailnet addresses". switch-to-configuration then reports a
      # failed unit and the activation exits with status 4, while a plain boot
      # always worked because tailscaled had time to reconnect first.
      #
      # `tailscale wait` blocks until the backend is running and an address is
      # assigned; the rex module uses it for its Serve unit for the same reason.
      # The `+` prefix runs it as root regardless of the service user, and the
      # timeout keeps a detached tailnet from stalling activation forever.
      systemd.services.rex.serviceConfig.ExecStartPre =
        singleton "+${lib.getExe config.services.tailscale.package} wait --timeout=90s";
    };
}
