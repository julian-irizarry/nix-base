return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function(_, opts)
      opts.winopts = {
        preview = {
          vertical = "up:65%",
          layout = "vertical",
          wrap = true,
        },
      }
      opts.keymap = {
        builtin = {
          true, -- inherit defaults
          ["<C-j>"] = "preview-down",
          ["<C-k>"] = "preview-up",
        },
        fzf = {
          true, -- inherit defaults
          ["ctrl-q"] = "select-all+accept",
          ["ctrl-j"] = "preview-half-page-down",
          ["ctrl-k"] = "preview-half-page-up",
        },
      }
    end,
  },

  { "folke/which-key.nvim", enabled = false },

  { "tpope/vim-fugitive", lazy = false },

  { "vimpostor/vim-tpipeline", event = "VeryLazy" },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "lsp-setup",
    dir = vim.fn.stdpath "config",
    name = "lsp-setup",
    lazy = false,
    priority = 900,
    dependencies = { "saghen/blink.cmp" },
    config = function()
      require "configs.lsp"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "c",
        "python",
        "cmake",
        "cpp",
        "rust",
      },

      highlightghlight = {
        enable = true, -- Enable syntax highlighting
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    config = function()
      require "configs.nvim-treesitter-textobjects"
    end,
  },

  {
    "kyazdani42/nvim-tree.lua",
    opts = function(_, opts)
      -- Customize or extend the existing options
      opts.hijack_cursor = false
      opts.update_cwd = true
      opts.update_focused_file = {
        enable = true,
        update_cwd = true,
      }

      -- Attach the custom keybinding setup (on_attach)
      opts.on_attach = function(bufnr)
        local api = require "nvim-tree.api"
        api.config.mappings.default_on_attach(bufnr)
      end

      return opts
    end,
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  { "mbbill/undotree", lazy = false },

  { "mrjones2014/smart-splits.nvim", lazy = false },

  {
    "mrcjkb/rustaceanvim",
    version = "^8",
    lazy = false, -- Already lazy loaded by filetype
    config = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              checkOnSave = true,
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
            },
          },
        },
      }
    end,
  },
}
