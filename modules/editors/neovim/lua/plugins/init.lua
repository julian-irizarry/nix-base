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
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("configs.treesitter").setup_core()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("configs.treesitter").setup_textobjects()
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

  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = "InsertEnter",
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },

  { "hrsh7th/nvim-cmp", enabled = false },
  { "hrsh7th/cmp-buffer", enabled = false },
  { "hrsh7th/cmp-path", enabled = false },
  { "hrsh7th/cmp-nvim-lua", enabled = false },
  { "hrsh7th/cmp-nvim-lsp", enabled = false },
  { "L3MON4D3/LuaSnip", enabled = false },
  { "saadparwaiz1/cmp_luasnip", enabled = false },
  { "windwp/nvim-autopairs", enabled = false },
}
