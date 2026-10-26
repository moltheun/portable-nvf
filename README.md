# portable-nvf

A self-extracting, portable Neovim (configured with [nvf](https://github.com/notashelf/nvf)) bundle for x86_64 Linux. 

**No Nix required on the target.** Download, extract, run. The bundle includes the entire Nix closure — Neovim, all plugins, treesitter grammars, LSP servers, formatters — packed into a single self-extracting executable via [nix-bundle](https://github.com/nix-community/nix-bundle) (arx + nix-user-chroot).

## Quick start

```bash
# Download from GitHub Releases
wget https://github.com/theunis/portable-nvf/releases/latest/download/portable-nvf-x86_64.tar.gz
tar xzf portable-nvf-x86_64.tar.gz
chmod +x portable-nvf-x86_64
./portable-nvf-x86_64
```

That's it. You're in Neovim with a working config.

## What's inside

- **Neovim** (latest from nixpkgs unstable)
- **nvf configuration**: treesitter, LSP, autocomplete (blink-cmp), telescope, neo-tree, gitsigns, lualine, catppuccin theme
- **Language support**: Nix (nil + nixfmt), Python (ruff), Bash, Markdown, YAML
- **Treesitter grammars** for all enabled languages

## Requirements on target

- x86_64 Linux kernel (WSL Ubuntu, regular Ubuntu, Arch, Fedora, whatever)
- `/bin/sh` (basically any Unix)
- That's it. No Nix, no nixpkgs, no network access.

## How it works

1. A flake builds Neovim with nvf's `neovimConfiguration` (standalone, no home-manager)
2. `nix-bundle` wraps the entire Nix store closure into a self-extracting arx archive
3. At runtime, `nix-user-chroot` mounts the bundled `/nix/store` into a private namespace, then execs nvim
4. No root required. No system modifications. No persistent install.

## Build it yourself

```bash
# On any Linux with Nix + flakes
nix build .#default
# Bundle into self-extracting executable:
nix run github:nix-community/nix-bundle -- --bundle-exec .#default/bin/portable-nvf portable-nvf-x86_64
```

## Customize

Edit `flake.nix` — the `nvfModule` attrset controls the entire Neovim configuration via nvf options. See the [nvf manual](https://notashelf.github.io/nvf/) for all available options.

## Limitations

- **Architecture**: x86_64-linux only (that's what WSL Ubuntu runs). For aarch64, change `targetSystem` in the flake.
- **Size**: expect ~150-300MB uncompressed. The tarball shrinks it significantly.
- **External tools**: LSP servers and formatters are bundled, but tools like `git` are expected to exist on the target already.
- **No package management on target**: this is a frozen snapshot. Update by downloading a new release.

## License

MIT