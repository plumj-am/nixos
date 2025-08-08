#!/usr/bin/env nu

def main [] {
    let os = (sys host | get name)
    
    if $os == "Darwin" {
        print "Rolling back Darwin configuration..."
        sudo darwin-rebuild switch --rollback --flake ~/nixos-config#darwin
    } else {
        print "Rolling back NixOS configuration..."
        sudo nixos-rebuild switch --rollback --flake ~/nixos-config#nixos
    }
}