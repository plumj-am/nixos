{
  flake.modules.nixos.rebuild =
    { pkgs, config, ... }:
    let
      inherit (config.myLib) mkDesktopEntry;
      inherit (builtins) map readFile;

      rebuildScript = pkgs.writeScriptBin "rebuild" (readFile ./nushell.rebuild.nu);
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor
        rebuildScript

      ]
      ++ (map (mkDesktopEntry { inherit pkgs; }) [
        {
          name = "Rebuild";
          exec = "rebuild";
        }
        {
          name = "Rollback";
          exec = "rebuild --rollback";
        }
      ]);
    };
}
