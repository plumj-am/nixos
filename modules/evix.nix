{ self, ... }:
{
  # evix evaluates a flake's derivation graph through the Nix C API in worker
  # subprocesses, streams one JSON event per attribute, and keeps the warm
  # graph in a per-user daemon. `evix diff` then answers "what does this edit
  # move?" before anything builds; `nh` and `nvd` only answer it afterwards.
  #
  # Only desktop hosts get it: the daemon is a user service, so a server with no
  # interactive config-editing session has nothing to warm.
  flake.modules.nixos.desktop = self.modules.nixos.evix;

  flake.modules.nixos.evix =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      flakePackages = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.evix.nixosModules.default ];

      # Clients read the shared remote token.
      sops.secrets.evix-remote-token = {
        sopsFile = ../secrets/all/evix.yaml;
        key = "remote-token";
        group = "wheel";
        mode = "0440";
      };

      # The module puts `evix` and `evixd` in the system profile and runs the
      # daemon as a sandboxed user service on the default socket
      # ($XDG_RUNTIME_DIR/evix.sock). `evix eval` fills a session there;
      # `query` and `diff` read it back.
      #
      # `package` is this repo's shim (packages/evix/evix.nix): it pins local
      # flake refs to one flavour, ships the flake source and inputs to the
      # configured remotes, and passes the remote token through the
      # environment. `evixd` stays upstream's binary.
      services.evix = {
        enable = true;
        daemon.enable = true;
        package = flakePackages.evix;
      };
    };

  flake.modules.nixos.evix-worker =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      # The shim adds remote flags to every evaluation subcommand, and
      # `worker` accepts none of them, so the service runs upstream's binary.
      upstream = inputs.evix.packages.${pkgs.stdenv.hostPlatform.system}.evix;
    in
    {
      sops.secrets.evix-remote-token = {
        sopsFile = ../secrets/all/evix.yaml;
        key = "remote-token";
        group = "wheel";
        mode = "0440";
      };

      sops.templates."evix-worker-env".content =
        "EVIX_REMOTE_TOKEN=${config.sops.placeholder.evix-remote-token}";

      systemd.services.evix-worker = {
        description = "evix worker daemon";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${getExe upstream} worker --listen 0.0.0.0:7357";
          EnvironmentFile = config.sops.templates."evix-worker-env".path;
          Restart = "on-failure";
          RestartSec = 2;
          StateDirectory = "evix-worker";
          Environment = [ "HOME=/var/lib/evix-worker" ];
          ProtectSystem = "strict";
          ReadWritePaths = [
            "/nix/store"
            "/nix/var/nix"
            "/var/tmp"
          ];
          PrivateTmp = true;
          ProtectHome = true;
          NoNewPrivileges = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
        };
      };
      # Workers run as root because a non-trusted user cannot add fetched store
      # paths through the daemon; the listener is token-authenticated and the
      # firewall trusts only `ts0`.
    };
}
