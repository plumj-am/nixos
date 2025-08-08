#!/usr/bin/env nu

def main [] {
    let os = (sys host | get name)
    
    if $os == "Darwin" {
        print "Building Darwin configuration..."
        sudo darwin-rebuild switch --flake ~/nixos-config#darwin
    } else {
        print "Building NixOS configuration..."
        sudo nixos-rebuild switch --flake ~/nixos-config#nixos
    }
}