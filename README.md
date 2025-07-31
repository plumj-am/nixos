<h1 align="center">James' NixOS Configuration</h1>

<p align="center">NixOS configuration for WSL</p>

## About

Right now I'm primarily using Windows and WSL but thanks to the [NixOS-WSL](https://github.com/nix-community/NixOS-WSL)
project I can use glorious NixOS inside WSL :]

## Features

Mainly configured for :

- Neovim
- Nushell
- Zellij
- Rust
- TypeScript

Things like Alacritty and other tools etc. are handled in my Windows configuration.

Generally I no longer even touch my Windows environment and instantly hop into
WSL and zellij with...
```bash
wsl -d nixos --exec /etc/profiles/per-user/james/bin/zellij
```
...which automatically launches when I start Alacritty.

## Notes

I'd appreciate any feedback or pointers from someone with more experience using
NixOS :]

Some things have been directly copied from my Windows configs so there may be
remnants of that, especially for nushell.

## License

Copyright (c) James Plummer <jamesp2001@live.co.uk>

This project is licensed under the MIT license ([LICENSE.md] or <http://opensource.org/licenses/MIT>)

[LICENSE.md]: ./LICENSE.md
