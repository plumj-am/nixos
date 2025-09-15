{ config, lib, pkgs, ... }: lib.mkIf config.isDarwin {
  environment.systemPackages = [ pkgs.arc-browser ];
  
  nixpkgs.config.permittedInsecurePackages = [
    "arc-browser-1.106.0-66192"
  ];
}