# PlumJam's Dendritic NixOS Configuration

> [!WARNING]
> Subject to major changes. This is not a finished state and some things are
> still being migrated from my old config.

Dendritic NixOS configurations for 8 personal machines:

| Name      | System  | Platform       | Follows                  | Active |
| --------- | ------- | -------------- | ------------------------ | :----: |
| Blackwell | Server  | x86_64-linux   | nixos-unstable-small[^1] |        |
| Date      | Laptop  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Kiwi      | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Lime      | Macbook | aarch64-darwin | nix-darwin[^2]           |        |
| Pear      | WSL     | x86_64-linux   | nixos-wsl[^3]            |   ✔    |
| Plum      | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Sloe      | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Yuzu      | Desktop | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |

[^1]: [nixos-unstable-small](https://nixos.wiki/wiki/Nix_channels#:~:text=nixos%2Dunstable%2Dsmall)

[^2]: [nix-darwin](https://github.com/nix-darwin/nix-darwin)

[^3]: [nixos-wsl](https://github.com/nix-community/NixOS-WSL)

## Features

- Multiple hosts
- Dendritic structure with
  [flake-parts](https://github.com/hercules-ci/flake-parts)
- [Hjem](https://github.com/feel-co/hjem) for $HOME management
- No `specialArgs` or janky passing around of configs between layers[^4]

[^4]: Apart from inherit `specialArgs = { inherit inputs; };` for each host. It
    is necessary for any host configuration.

## How it works

Almost everything lives under `modules/`.

Each module (for the most part) is grouped by feature as opposed to individual
applications/services. Using
[flake-parts](https://github.com/hercules-ci/flake-parts), these modules live at
`flake.modules.{common,nixos,darwin}`.

Modules contain 1 or more of the following:

```
flake.modules.<class>.<aspect> = {}
```

For example:

```nix
{
  # modules/git.nix
  flake.modules.common.git = { /* ... */ };

  # modules/window-manager.nix
  flake.modules.nixos.window-manager = { /* ... */ };
  flake.modules.darwin.window-manager = { /* ... */ };
}
```

`hjem` modules are included within the `common`, `nixos`, and `darwin` classes
via `hjem.extraModule` as can be seen below. `hjem.extraModule` is a custom
option that lets me use `hjem.extraModules = []` as a `singleton` without
needing to specify it every time. See `modules/hjem.nix` for the implementation
but, note that there is no implementation for `common` due to how the `common`
class works (by auto-merging). See the "Other comments" section below for more
details.

```nix
{
  flake.modules.common.zellij =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (config) theme;
    in
    {
      hjem.extraModule = {
        # ... hjem specific config
      };
      # ... rest of config
    }
}
```

The `common`, `darwin`, and `nixos` classes are then used in `hosts/`. Some
aspects are grouped in `modules/aspects.nix` to avoid repeated configs and a
`mkConfig` helper is used to simplify the inline config module of each host,
again to reduce repetition. The implementation for `mkConfig` can be seen in
`modules/lib.nix`.

Examples of what this looks like:

```nix
{
  # For NixOS systems:
  flake.nixosConfigurations.hostName = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = with inputs.self.modules.nixos; [
      # ... other aspects
      window-manager

      # Inline module for individual config.
      {
        config = mkConfig inputs "hostName" "x86_64-linux" {
          # ... config here
        };
      }
    ];
  };

  # Or for Darwin systems:
  flake.darwinConfigurations.hostName = inputs.os-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = with inputs.self.modules.darwin; [
      # ... other packages
      window-manager

      # Inline module for individual config.
      {
        config = mkConfig inputs "hostName" "aarch64-darwin" {
          # ... config here
        };
      }
    ];
  };
}
```

As mentioned before, additional configuration for the hosts is defined in an
inline module inside the `modules = []` section of each host. There we define
configurations that are exclusive to the host and can't trivially be made a
module such as unique `secrets` configuration.

## Other tools

### Secrets

All secrets are handled by (r)agenix and agenix-rekey.

agenix: <https://github.com/ryantm/agenix>

ragenix: <https://github.com/yaxitech/ragenix>

agenix-rekey: <https://github.com/oddlama/agenix-rekey>

### Imports

Imports are handled by an `importTree` function in `outputs.nix`. It
automatically imports all nix files in the specified directories (`./modules`,
`./hosts`, and `./packages` in my case).

### myLib

There may be unfamiliar functions/helpers in some files - these come from
`modules/lib.nix`.

### Theming

I have a custom theming setup which can be seen in `modules/theme.nix`. It does
rely on a rebuild but it's a simple toggle between light/dark and
gruvbox/matugen modes by running shortcuts setup in my Quickshell launcher and
the `tt`/`toggle-theme` script. It automatically updates colour schemes and
refreshes necessary applications to apply changes.

The gruvbox mode uses the defined themes in `modules/theme.nix` and some base16
colours for applications that can make use of them.

### Quickshell

I have a fairly basic Quickshell setup which I have used to replace Fuzzel,
Mako, Waybar/Ashell, and more.

It has the following features (non-exhaustive):

- Bar
  - Media
  - Current window
  - Tray
  - System stats
  - Theme toggle
  - Control center toggle
  - Notification toggle and count
  - Privacy module (shows active mic/webcam)
  - Date/time
  - Power/session drawer toggle
- Launcher
- Control center
  - Input volume
  - Output volume
  - Bluetooth toggle
  - Network information
- Notifications
- Session/power drawer
- Media controls
- Clipboard history drawer

The configuration can be found in `modules/quickshell`.

## Other comments

The previous version of my configurations can be seen on the
[pre-dendritic](https://git.plumj.am/plumjam/nixos/src/branch/pre-dendritic)
branch if you are interested. The dendritic version was merged from pull request
[#1](https://git.plumj.am/plumjam/nixos/pulls/1) in commit
[#750cdc5fba](https://git.plumj.am/plumjam/nixos/commit/750cdc5fba89d8d29961cf9255bf6029d0bb8465)
on 2026-01-29.

A version using [Hjem Rum](https://github.com/snugnug/hjem-rum) can be seen on
the [hjem-rum](https://git.plumj.am/plumjam/nixos/src/branch/hjem-rum) branch.
Hjem Rum was removed in pull request
[#2](https://git.plumj.am/plumjam/nixos/pulls/2) in commit
[962048fa7a](https://git.plumj.am/plumjam/nixos/commit/962048fa7a385d7663ee7a007d23e857586e1136)
on 2026-02-01. I'd like to mention that it is an excellent tool! I just didn't
really need it and I already use generators or write config files directly for
the most part anyway.

Modules that are yet to be migrated live in `modules/_to-migrate/`. The
underscore prefix tells my `importTree` function to ignore this directory so we
can easily migrate them gradually without breaking builds.

Inputs use different names to what you might expect:

- nixpkgs -> os
- nix-darwin -> os-darwin
- nixos-wsl -> os-wsl

`osConfig` comes from Hjem and can be used to access the system-level `config`
alongside the hjem level `config`.

`flake.modules.common` works by merging automatically with
`flake.modules.{nixos,darwin}`. Basically, all the `common` aspects can be
accessed from either `common`, `nixos`, or `darwin`.

If you're interested in learning more about dendritic Nix, feel free to learn
from my config and consider checking the following links:

- <https://dendrix.oeiuwq.com/Dendritic.html>
- <https://github.com/Doc-Steve/dendritic-design-with-flake-parts>

Sites I found helpful for Nix settings/options/lib:

- <https://mynixos.com>
- <https://nix-darwin.github.io/nix-darwin/manual>
- <https://teu5us.github.io/nix-lib.html>

Documentation for flake-parts:

- <https://flake.parts>

## Contributing

If you're more experienced with this style of configuration, I'm happy to accept
criticism or suggestions for improvements via an issue or pull request.

## Map

The structure of the repository and a few key files are highlighted below:

```sh
.
├── hosts/             # All hosts live in here
├── packages/          # Some packages I expose in the flake
├── modules/           # All modules live in here
│   ├── theme.nix      # System-wide theming
│   ├── ...
│   ├── _to-migrate/   # Modules waiting for migration to new dendritic setup
│   │   └── ...
│   └── quickshell/    # Quickshell configs
│       └── ...
├── secrets/           # Secrets managed by agenix
│   ├── ...
│   └── rekeyed/       # Rekeyed secrets from agenix-rekey
│       └── ...
├── outputs.nix        # Flake outputs
├── flake.lock
├── flake.nix
└── ...
```

## License

```
The MIT License (MIT)

Copyright (c) 2025-present PlumJam <git@plumj.am>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
