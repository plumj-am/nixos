# PlumJam's Dendritic NixOS Configuration

> [!WARN]
> Subject to major changes. This is not a finished state and some things are
> still being migrated from my old config.

NixOS configurations for 8 personal machines:

| Name      | System  | Platform       | Follows                  | Active |
| --------- | ------- | -------------- | ------------------------ | :----: |
| Blackwell | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Date      | Laptop  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Kiwi      | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Lime      | Macbook | aarch64-darwin | nix-darwin[^2]           |        |
| Pear      | WSL     | x86_64-linux   | nixos-wsl[^3]            |   ✔    |
| Plum      | Server  | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |
| Sloe      | Server  | x86_64-linux   | nixos-unstable-small[^1] |        |
| Yuzu      | Desktop | x86_64-linux   | nixos-unstable-small[^1] |   ✔    |

[^1]: [nixos-unstable-small](https://nixos.wiki/wiki/Nix_channels#:~:text=nixos%2Dunstable%2Dsmall)

[^2]: [nix-darwin](https://github.com/nix-darwin/nix-darwin)

[^3]: [nixos-wsl](https://github.com/nix-community/NixOS-WSL)

## Features

- Multiple hosts
- Dendritic structure with
  [flake-parts](https://github.com/hercules-ci/flake-parts)
- [Hjem](https://github.com/feel-co/hjem) for home management
- [Hjem Rum](https://github.com/snugnug/hjem-rum) for home modules

## How it works

Everything lives under `modules/`.

Each module (for the most part) is grouped by feature as opposed to individual
applications/services. Using
[flake-parts](https://github.com/hercules-ci/flake-parts), these modules live at
`flake.modules.{nixos,darwin,hjem}`.

Modules contains 1 or more of the following:

```
flake.modules.<class>.<feature> = {}
```

For example, our `modules/window-manager.nix` looks like this:

```nix
{
  flake.modules.hjem.window-manager = { /* ... */ };
  flake.modules.nixos.window-manager = { /* ... */ };
  flake.modules.darwin.window-manager = { /* ... */ };
}
```

> [!NOTE]
> Note that `hjem` modules are automatically included in any host that uses the
> `hjem` module - this may change.

The `darwin` and `nixos` modules are then used in `modules/hosts.nix`. Modules
are grouped by type at the top of the file to avoid repeated configs and a
`mkConfig` helper is used to simplify the inline config module of each host,
again to reduce repetition. An example of what this could look like:

```nix
{
  # For NixOS systems:
  flake.nixosConfigurations.hostName = inputs.os.lib.nixosSystem {
    inherit specialArgs;
    modules = with inputs.self.modules.nixos; [
      # ... other packages
      window-manager
    ];
  };

  # Or for Darwin systems:
  flake.darwinConfigurations.hostName = inputs.os-darwin.lib.darwinSystem {
    inherit specialArgs;
    modules = with inputs.self.modules.darwin; [
      # ... other packages
      window-manager
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

Imports are handled by import-tree in `modules/outputs.nix`. It automatically
imports all nix files in the specified directory (`./modules` in my case).

import-tree: <https://github.com/vic/import-tree>

### Flake inputs

Flake inputs are automatically managed by flake-file which allows me to
use/define inputs closer to where they are used. For example,
`modules/editor.nix` contains `flake-file.inputs.helix`. By running
`nix run .#write-flake` the `flake.nix` file is automatically updated by
flake-file.

flake-file: <https://github.com/vic/flake-file>

### CI

Forgejo workflows are generated with actions.nix in `ci/`. On every push, each
host is built and cached automatically in an S3 bucket using self-hosted runners
(see `modules/forgejo-action-runner.nix`).

actions.nix is really nice, it gives you the power and flexibility of Nix for
creating workflows. See `ci/nix-ci.nix` and `ci/lib.nix` for some examples.

actions.nix: <https://github.com/nialov/actions.nix>

### myLib

There may be unfamiliar functions/helpers in some files - these come from
`modules/lib.nix`.

### Theming

I have a custom theming setup which can be seen in `modules/theme.nix`. It does
rely on a rebuild but it's a simple toggle between light/dark and gruvbox/pywal
modes by running shortcuts setup in Fuzzel. It automatically updates colour
schemes and refreshes necessary applications to apply changes.

The pywal mode generates colours from the current wallpaper.

The gruvbox mode uses the defined themes in `modules/themes.nix` and some base16
colours for applications that can make use of them.

## Other comments

Modules that are yet to be migrated live in `modules/_to-migrate/`. The
underscore prefix tells import-tree to ignore this directory so we can easily
migrate them gradually without breaking builds.

Inputs use different names to what you might expect:

- nixpkgs -> os
- nix-darwin -> os-darwin
- nixos-wsl -> os-wsl

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
├── ci/                # CI with actions.nix (generates .forgejo/workflows/*)
│   └── ...
├── modules/           # All modules live in here
│   ├── inputs.nix     # flake-file configs
│   ├── outputs.nix    # Flake outputs
│   ├── hosts.nix      # Host definitions
│   ├── actions.nix    # Generates CI workflows from `ci/`
│   ├── theme.nix      # System-wide theming
│   ├── ...
│   ├── _to-migrate/   # Modules waiting for migration to new dendritic setup
│   │   └── ...
│   └── quickshell/    # Quickshell configs (not currently used)
│       └── ...
├── secrets/           # Secrets managed by agenix
│   ├── ...
│   └── rekeyed/       # Rekeyed secrets from agenix-rekey
│       └── ...
├── flake.lock
├── flake.nix          # Contents generated by flake-file
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
