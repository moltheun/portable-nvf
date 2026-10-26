{
  description = "Portable nvf — self-extracting Neovim bundle for any Linux x86_64";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nvf, ... }:
    let
      # Target architecture: WSL Ubuntu on x86_64
      targetSystem = "x86_64-linux";

      # Minimal nvf configuration — enough to be useful, small enough to bundle
      nvfModule = {
        config.vim = {
          viAlias = true;
          vimAlias = true;

          # Core editing
          treesitter.enable = true;
          autocomplete.blink-cmp.enable = true;
          lsp.enable = true;

          # Languages
          languages = {
            enableTreesitter = true;
            nix = {
              enable = true;
              format.enable = true;
            };
            python = {
              enable = true;
              format = {
                enable = true;
                type = [ "ruff" ];
              };
            };
            bash.enable = true;
            markdown.enable = true;
            yaml.enable = true;
          };

          # Quality of life
          statusline.lualine.enable = true;
          mini = {
            icons.enable = true;
            ai.enable = true;
            surround.enable = true;
          };

          # Search/navigation
          telescope.enable = true;

          # File explorer
          filetree.neo-tree.enable = true;

          # Git integration
          git.gitsigns.enable = true;

          # Clipboard
          clipboard = {
            enable = true;
            registers = "unnamedplus";
          };

          undoFile.enable = true;

          # Theme
          theme = {
            enable = true;
            name = "catppuccin";
            style = "macchiato";
          };
        };
      };

      # Build the neovim derivation using nvf's standalone neovimConfiguration
      # This is the pure package — no home-manager, no NixOS module system
      nvfNeovim =
        (nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.${targetSystem};
          modules = [ nvfModule ];
        }).neovim;

      # The launcher script — this is what nix-bundle wraps.
      # nix-user-chroot sets up /nix/store from the bundled archive at runtime,
      # then execs nvim. No root, no system install.
      launcherPkgs = nixpkgs.legacyPackages.${targetSystem};
      launcher = launcherPkgs.writeScriptBin "portable-nvf" ''
        #!${launcherPkgs.runtimeShell}
        exec ${nvfNeovim}/bin/nvim "$@"
      '';

    in
    {
      packages.${targetSystem} = {
        default = launcher;
        nvf = nvfNeovim;
      };
    };
}