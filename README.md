# autopair.nu

A Nushell module that auto-pairs brackets and quotes as you type.

![Terminal recording: brackets and quotes close themselves as they are typed, and backspace removes both](https://github.com/user-attachments/assets/bc19454d-eb07-46c6-8917-615df02d7c58)

## Install

### With Nix

#### Home-manager

```nix
imports = [ inputs.autopair-nu.homeModules.default ];
programs.autopair-nu.enable = true;
```

#### NixOS, nix-darwin

```nix
environment.systemPackages = [ inputs.autopair-nu.packages.${pkgs.system}.default ];
```

#### Profile

```sh
nix profile add github:mst-mkt/autopair.nu
```

### Manually

```nu
let dir = ($nu.user-autoload-dirs | first)
mkdir $dir

http get https://raw.githubusercontent.com/mst-mkt/autopair.nu/main/autopair.nu
| save --force ($dir | path join autopair.nu)
```

### With nupm

Not recommended. [nupm](https://github.com/nushell/nupm) is still experimental.

```nu
nupm install https://github.com/mst-mkt/autopair.nu.git --git

ln -s ($nu.default-config-dir | path join nupm scripts autopair.nu) ($nu.user-autoload-dirs | first | path join autopair.nu)
```

The link is needed because nupm installs scripts outside the autoload directories.

## Requirements

- Nushell 0.102.0 or later
  - `slice`, which indexes the line, was renamed from `range` in this release
  - `$nu.user-autoload-dirs`, which the manual install writes to, landed in the same one

## Development

### Requirements

The following tools and libraries are used. They are managed in `dev/flake.nix`, so using it is recommended.

- [just](https://github.com/casey/just)
- [knope](https://github.com/knope-dev/knope)
- [Nushell](https://www.nushell.sh)
- [nutest](https://github.com/vyadh/nutest)

### Scripts

| command     | description                                         |
| ----------- | --------------------------------------------------- |
| `just dev`  | Start Nushell with the module loaded                |
| `just test` | Run the test suite, forwarding extra args to nutest |

## Inspired by

- [zsh-autopair](https://github.com/hlissner/zsh-autopair)
- [autopair.fish](https://github.com/jorgebucaran/autopair.fish)

## License

[MIT](LICENSE)
