-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 250

-- Leader
vim.g.mapleader = " "

-- Keymaps
vim.keymap.set("n", "H", "0")
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "J", "G")
vim.keymap.set("n", "K", "gg")
vim.keymap.set("n", "e", "w")
vim.keymap.set("n", "w", "b")
vim.keymap.set("n", "W", "B")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "<M-H>", "<cmd>bprev<cr>")
vim.keymap.set("n", "<M-L>", "<cmd>bnext<cr>")
vim.keymap.set("n", "<leader>e", "<C-w>l")
vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<cr>")
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("Neotree show")
  end,
})
vim.keymap.set("n", "<leader>j", "<cmd>Neotree reveal<cr>")

-- Highlights
vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "none" })

-- Plugins
require("lazy").setup({
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "git_status", display_name = " Git" },
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        filtered_items = { visible = true },
      },
      window = { width = 30 },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc",
        "python", "javascript", "typescript",
        "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "swift", "rust", "c", "cpp", "objc", "go",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    config = function()
      require("lualine").setup({
        options = { globalstatus = true },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<C-p>",      builtin.find_files,  { desc = "Find files" })
      vim.keymap.set("n", "<leader>p",  builtin.commands,    { desc = "Command palette" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep,   { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers,     { desc = "Buffers" })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        vim.keymap.set("n", "]h", gs.next_hunk,  { buffer = bufnr, desc = "Next hunk" })
        vim.keymap.set("n", "[h", gs.prev_hunk,  { buffer = bufnr, desc = "Prev hunk" })
        vim.keymap.set("n", "<leader>gS", gs.stage_hunk,  { buffer = bufnr, desc = "Stage hunk" })
        vim.keymap.set("n", "<leader>gr", gs.reset_hunk,  { buffer = bufnr, desc = "Reset hunk" })
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
      end,
    },
  },
  {
    "williamboman/mason.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "rust_analyzer", "clangd",
        },
      })

      local servers = { "lua_ls", "rust_analyzer", "clangd", "sourcekit" }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, {})
      end
      vim.lsp.enable(servers)

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)

          -- Highlight symbol under cursor
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("LspHighlight", { clear = false })
            vim.api.nvim_clear_autocmds({ group = group, buffer = args.buf })
            vim.api.nvim_create_autocmd("CursorHold", {
              group = group,
              buffer = args.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              group = group,
              buffer = args.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "latte" })
      vim.cmd("colorscheme catppuccin")
    end,
  },
})
