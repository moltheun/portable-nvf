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
      targetSystem = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${targetSystem};
      line-width = 89;

      nvfModule = { config, ... }: {
        config.vim = {
          viAlias = true;
          vimAlias = true;

          # ── Clipboard ──
          clipboard = {
            enable = true;
            registers = "unnamedplus";
          };

          undoFile.enable = true;

          # ── Theme: kanso via lazy (no built-in theme) ──
          theme.enable = false;

          # ── Vim options (from options.nix) ──
          options = {
            tabstop = 2;
            shiftwidth = 2;
            softtabstop = 2;
            expandtab = true;
            smartindent = true;
            wrap = false;
            incsearch = true;
            ignorecase = true;
            smartcase = true;
            hlsearch = false;
            number = true;
            relativenumber = true;
            termguicolors = true;
            cmdheight = 1;
            scrolloff = 10;
            completeopt = "menuone,noinsert,noselect";
            signcolumn = "yes";
            conceallevel = 2;
            breakindent = true;
            hidden = true;
            errorbells = false;
            swapfile = false;
            backup = false;
            backspace = "indent,eol,start";
            splitright = true;
            splitbelow = true;
            autochdir = false;
            mouse = "a";
            modifiable = true;
            encoding = "UTF-8";
            updatetime = 250;
            timeoutlen = 300;
            startofline = true;
            foldlevelstart = 99;
          };

          # ── Autocmds: save/restore folds (from options.nix) ──
          autocmds = [
            {
              event = [ "BufWinLeave" ];
              pattern = [ "*.*" ];
              command = "mkview";
              desc = "Save view (including folds)";
            }
            {
              event = [ "BufWinEnter" ];
              pattern = [ "*.*" ];
              command = "silent! loadview";
              desc = "Load view (including folds)";
            }
          ];

          # ── Lazy plugins ──
          lazy.plugins = {
            "kanso.nvim" = {
              package = pkgs.vimPlugins.kanso-nvim;
              after = ''
                require("kanso").setup({
                  theme = "mist",
                  transparent = false,
                  dimInactive = true,
                  terminalColors = true,
                  overrides = function(colors)
                    return {
                      Visual = { bg = "#4a5568" },
                    }
                  end,
                })
                vim.cmd("colorscheme kanso-mist")
              '';
            };
            "eyeliner.nvim" = {
              package = pkgs.vimPlugins.eyeliner-nvim;
              setupModule = "eyeliner";
              setupOpts = {
                dim = true;
              };
            };
            "nvim-various-textobjs" = {
              package = pkgs.vimUtils.buildVimPlugin {
                pname = "nvim-various-textobjs";
                version = "unstable-2025-01-14";
                src = pkgs.fetchFromGitHub {
                  owner = "chrisgrieser";
                  repo = "nvim-various-textobjs";
                  rev = "71bd98e08e96a730a60566f929a6ac3974ede0e0";
                  hash = "sha256-VDRZ8OLR76pudbrxQbY2dnHxDZwN0Y8pgeetkGjd5Sk=";
                };
                doCheck = false;
              };
              setupModule = "various-textobjs";
              setupOpts = {
                useDefaultKeymaps = true;
              };
            };
          };

          # ── Statusline ──
          statusline.lualine.enable = true;

          # ── Utility ──
          utility.diffview-nvim.enable = true;

          # ── Snacks (replaces telescope + neo-tree + dashboard) ──
          utility.snacks-nvim = {
            enable = true;
            setupOpts = {
              bigfile = { enabled = true; };
              notifier = { enabled = true; };
              quickfile = { enabled = true; };
              statuscolumn = {
                enabled = true;
                folds = { open = true; };
              };
              picker = { enabled = true; };
              lazygit = { enabled = true; };
              dashboard = {
                enabled = true;
                sections = [
                  { section = "header"; }
                  { section = "keys"; gap = 1; padding = 1; }
                  {
                    pane = 2;
                    icon = " ";
                    title = "Recent Files";
                    section = "recent_files";
                    indent = 2;
                    padding = 1;
                  }
                  {
                    pane = 2;
                    icon = " ";
                    title = "Projects";
                    section = "projects";
                    indent = 2;
                    padding = 1;
                  }
                  {
                    pane = 2;
                    icon = " ";
                    title = "Git Status";
                    section = "terminal";
                    enabled = true;
                    cmd = "git status --short --branch --renames";
                    height = 5;
                    padding = 1;
                    ttl = 300;
                    indent = 3;
                  }
                ];
              };
            };
          };

          # ── Flash (from flash.nix) ──
          utility.motion.flash-nvim = {
            enable = true;
            mappings = {
              jump = null;
              remote = null;
              treesitter = null;
              treesitter_search = null;
              toggle = null;
            };
            setupOpts = {
              label.uppercase = false;
              modes.char.enabled = false;
            };
          };

          # Flash custom <CR> keymap
          maps.normal."<CR>" = {
            desc = "Flash";
            lua = true;
            action = ''
              function()
                if vim.bo.filetype == "qf" then
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
                else
                  require("flash").jump()
                end
              end
            '';
          };

          # Flash custom search
          luaConfigRC.flash-custom-search = ''
            require("flash").setup({
              search = {
                mode = function(str)
                  local custom_preceding_chars_set = "[_-]"
                  return "\\<" .. str .. "\\|" .. custom_preceding_chars_set .. "\\zs" .. str
                end,
              },
            })
          '';

          # ── Autocomplete: blink-cmp with custom keymaps ──
          autocomplete.blink-cmp = {
            enable = true;
            mappings = {
              confirm = null;
              next = null;
              previous = null;
            };
            setupOpts = {
              cmdline.keymap.preset = "default";
              keymap = {
                preset = "none";
                "<C-n>" = [ "select_next" "fallback" ];
                "<C-p>" = [ "select_prev" "fallback" ];
                "<C-y>" = [ "select_and_accept" ];
                "<C-e>" = [ "cancel" "fallback" ];
                "<C-space>" = [ "show" "show_documentation" "hide_documentation" ];
                "<C-b>" = [ "scroll_documentation_up" "fallback" ];
                "<C-f>" = [ "scroll_documentation_down" "fallback" ];
              };
            };
          };

          # ── Treesitter ──
          treesitter = {
            enable = true;
            textobjects.enable = false;
          };

          # ── Mini modules ──
          mini = {
            icons.enable = true;
            ai.enable = true;
            diff.enable = true;
            surround.enable = true;
            jump2d.enable = false;
          };

          # ── LSP (disable default mappings — snacks handles them) ──
          lsp = {
            enable = true;
            mappings = {
              goToDefinition = null;
              goToDeclaration = null;
              goToType = null;
              listImplementations = null;
              listReferences = null;
              nextDiagnostic = null;
              previousDiagnostic = null;
              openDiagnosticFloat = null;
              documentHighlight = null;
              listDocumentSymbols = null;
              addWorkspaceFolder = null;
              removeWorkspaceFolder = null;
              listWorkspaceFolders = null;
              listWorkspaceSymbols = null;
              hover = null;
              signatureHelp = null;
              renameSymbol = null;
              codeAction = null;
              format = null;
              toggleFormatOnSave = null;
            };
          };

          # ── Languages ──
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
            markdown = {
              enable = true;
              extensions.render-markdown-nvim = {
                enable = true;
                setupOpts = {
                  file_types = [ "markdown" "codecompanion" ];
                  win_options = {
                    conceallevel = {
                      default = 2;
                      rendered = 2;
                    };
                  };
                  heading = {
                    width = "block";
                    min_width = line-width;
                    sign = false;
                  };
                  code = {
                    width = "block";
                    min_width = line-width;
                    sign = false;
                  };
                  dash = {
                    width = line-width;
                  };
                  indent = {
                    enabled = false;
                    skip_level = 2;
                  };
                  render_modes = true;
                  anti_conceal = {
                    ignore = {
                      code_border = true;
                    };
                  };
                  latex = {
                    enabled = false;
                  };
                };
              };
            };
            yaml.enable = true;
          };

          # ── Which-key (from whichkey.nix) ──
          luaConfigRC.whichKeyTriggers = ''
            require("which-key").setup({
              triggers = {
                { "<auto>", mode = "nixsotc" },
                { "sw",     mode = "n" },
                { "s",      mode = "n" },
              }
            })
          '';

          binds.whichKey = {
            enable = true;
            setupOpts = {
              preset = "helix";
            };
            register = {
              "sw" = "[Sw]ap";
              "[" = "Previous";
              "]" = "Next";
              "<leader>s" = "[S]earch";
              "<leader>sg" = "[G]it";
              "<leader>t" = "[T]oggle";
              "<leader>g" = "[G]it";
              "<leader>m" = "[M]arkdown";
            };
          };

          # ── Prose soft-wrap (from prose.nix) ──
          luaConfigRC.prose-wrap = ''
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "markdown", "quarto" },
              callback = function()
                local opt = vim.opt_local
                opt.wrap = true
                opt.linebreak = true
                opt.breakindent = true
                opt.showbreak = "↪ "
                opt.breakat = " \\t!@*-+;:,./?"
                local opts = { buffer = true, silent = true }
                vim.keymap.set({ "n", "v" }, "j", "gj", opts)
                vim.keymap.set({ "n", "v" }, "k", "gk", opts)
                vim.keymap.set({ "n", "v" }, "0", "g0", opts)
                vim.keymap.set({ "n", "v" }, "$", "g$", opts)
                vim.keymap.set({ "n", "v" }, "^", "g^", opts)
              end,
            })
          '';

          # ── Keymaps (from snacks.nix) ──
          keymaps = [
            # Window navigation
            { key = "<C-h>"; mode = [ "n" ]; action = "<C-w>h"; desc = "Go to Left Window"; }
            { key = "<C-j>"; mode = [ "n" ]; action = "<C-w>j"; desc = "Go to Lower Window"; }
            { key = "<C-k>"; mode = [ "n" ]; action = "<C-w>k"; desc = "Go to Upper Window"; }
            { key = "<C-l>"; mode = [ "n" ]; action = "<C-w>l"; desc = "Go to Right Window"; }
            { key = "<C-h>"; mode = [ "t" ]; action = "<cmd>wincmd h<CR>"; desc = "Go to Left Window"; }
            { key = "<C-j>"; mode = [ "t" ]; action = "<cmd>wincmd j<CR>"; desc = "Go to Lower Window"; }
            { key = "<C-k>"; mode = [ "t" ]; action = "<cmd>wincmd k<CR>"; desc = "Go to Upper Window"; }
            { key = "<C-l>"; mode = [ "t" ]; action = "<cmd>wincmd l<CR>"; desc = "Go to Right Window"; }

            # Top pickers & explorer
            { key = "<leader><space>"; mode = [ "n" ]; action = "function() Snacks.picker.smart() end"; lua = true; desc = "Smart Find Files"; }
            { key = "<leader>tf"; mode = [ "n" ]; action = "function() Snacks.explorer() end"; lua = true; desc = "File Explorer"; }

            # Find
            { key = "<leader>sc"; mode = [ "n" ]; action = "function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end"; lua = true; desc = "Find Config File"; }
            { key = "<leader>sf"; mode = [ "n" ]; action = "function() Snacks.picker.files() end"; lua = true; desc = "Find Files"; }
            { key = "<leader>sgf"; mode = [ "n" ]; action = "function() Snacks.picker.git_files() end"; lua = true; desc = "Find Git Files"; }
            { key = "<leader>sp"; mode = [ "n" ]; action = "function() Snacks.picker.projects() end"; lua = true; desc = "Projects"; }
            { key = "<leader>sP"; mode = [ "n" ]; action = "function() Snacks.picker() end"; lua = true; desc = "Pickers"; }
            { key = "<leader>sr"; mode = [ "n" ]; action = "function() Snacks.picker.recent() end"; lua = true; desc = "Recent"; }

            # Git
            { key = "<leader>gb"; mode = [ "n" ]; action = "function() Snacks.picker.git_branches() end"; lua = true; desc = "Git Branches"; }
            { key = "<leader>gl"; mode = [ "n" ]; action = "function() Snacks.picker.git_log() end"; lua = true; desc = "Git Log"; }
            { key = "<leader>gL"; mode = [ "n" ]; action = "function() Snacks.picker.git_log_line() end"; lua = true; desc = "Git Log Line"; }
            { key = "<leader>gs"; mode = [ "n" ]; action = "function() Snacks.picker.git_status() end"; lua = true; desc = "Git Status"; }
            { key = "<leader>gS"; mode = [ "n" ]; action = "function() Snacks.picker.git_stash() end"; lua = true; desc = "Git Stash"; }
            { key = "<leader>gd"; mode = [ "n" ]; action = "function() Snacks.picker.git_diff() end"; lua = true; desc = "Git Diff (Hunks)"; }
            { key = "<leader>gf"; mode = [ "n" ]; action = "function() Snacks.picker.git_log_file() end"; lua = true; desc = "Git Log File"; }

            # Grep
            { key = "<leader>sa"; mode = [ "n" ]; action = "function() Snacks.picker.grep() end"; lua = true; desc = "Grep"; }
            { key = "<leader>sw"; mode = [ "n" "x" ]; action = "function() Snacks.picker.grep_word() end"; lua = true; desc = "Visual selection or word"; }

            # Search
            { key = "<leader>s\""; mode = [ "n" ]; action = "function() Snacks.picker.registers() end"; lua = true; desc = "Registers"; }
            { key = "<leader>s:"; mode = [ "n" ]; action = "function() Snacks.picker.command_history() end"; lua = true; desc = "Command History"; }
            { key = "<leader>sd"; mode = [ "n" ]; action = "function() Snacks.picker.diagnostics() end"; lua = true; desc = "Diagnostics"; }
            { key = "<leader>si"; mode = [ "n" ]; action = "function() Snacks.picker.icons() end"; lua = true; desc = "Icons"; }
            { key = "<leader>sj"; mode = [ "n" ]; action = "function() Snacks.picker.jumps() end"; lua = true; desc = "Jumps"; }
            { key = "<leader>sk"; mode = [ "n" ]; action = "function() Snacks.picker.keymaps() end"; lua = true; desc = "Keymaps"; }
            { key = "<leader>sl"; mode = [ "n" ]; action = "function() Snacks.picker.loclist() end"; lua = true; desc = "Location List"; }
            { key = "<leader>sm"; mode = [ "n" ]; action = "function() Snacks.picker.marks() end"; lua = true; desc = "Marks"; }
            { key = "<leader>sq"; mode = [ "n" ]; action = "function() Snacks.picker.qflist() end"; lua = true; desc = "Quickfix List"; }
            { key = "<leader>sR"; mode = [ "n" ]; action = "function() Snacks.picker.resume() end"; lua = true; desc = "Resume"; }
            { key = "<leader>su"; mode = [ "n" ]; action = "function() Snacks.picker.undo() end"; lua = true; desc = "Undo History"; }

            # LSP
            { key = "gd"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_definitions() end"; lua = true; desc = "Goto Definition"; }
            { key = "gD"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_declarations() end"; lua = true; desc = "Goto Declaration"; }
            { key = "grr"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_references() end"; lua = true; desc = "References"; }
            { key = "gri"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_implementations() end"; lua = true; desc = "Goto Implementation"; }
            { key = "grt"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_type_definitions() end"; lua = true; desc = "Goto Type Definition"; }
            { key = "<leader>ss"; mode = [ "n" ]; action = "function() Snacks.picker.lsp_workspace_symbols() end"; lua = true; desc = "LSP Workspace Symbols"; }

            # Other
            { key = "<leader>tz"; mode = [ "n" ]; action = "function() Snacks.zen.zoom() end"; lua = true; desc = "Toggle Zoom"; }
            { key = "<leader>tZ"; mode = [ "n" ]; action = "function() Snacks.zen() end"; lua = true; desc = "Toggle Zen Mode"; }
            { key = "<leader>t."; mode = [ "n" ]; action = "function() Snacks.scratch() end"; lua = true; desc = "Toggle Scratch Buffer"; }
            { key = "<leader>tS"; mode = [ "n" ]; action = "function() Snacks.scratch.select() end"; lua = true; desc = "Select Scratch Buffer"; }
            { key = "<leader>gB"; mode = [ "n" "v" ]; action = "function() Snacks.gitbrowse() end"; lua = true; desc = "Git Browse"; }
            { key = "<leader>gg"; mode = [ "n" ]; action = "function() Snacks.lazygit() end"; lua = true; desc = "Lazygit"; }
            { key = "<c-/>"; mode = [ "n" ]; action = "function() Snacks.terminal() end"; lua = true; desc = "Toggle Terminal"; }
            { key = "<c-_>"; mode = [ "n" ]; action = "function() Snacks.terminal() end"; lua = true; desc = "which_key_ignore"; }
          ];
        };
      };

      nvfNeovim =
        (nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ nvfModule ];
        }).neovim;

      launcher = (pkgs.writeScriptBin "portable-nvf" ''
        #!${pkgs.runtimeShell}
        exec ${nvfNeovim}/bin/nvim "$@"
      '').overrideAttrs (_old: {
        pname = "portable-nvf";
      });

    in
    {
      packages.${targetSystem} = {
        default = launcher;
        nvf = nvfNeovim;
      };
    };
}