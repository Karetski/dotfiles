-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- nvm exposes node only via an interactive-zsh shell function, so Mason-installed
-- Node LSPs (bashls, pyright, ts_ls, yamlls, jsonls) can't resolve `#!/usr/bin/env node`
-- when nvim is launched outside an interactive shell. Prepend the installed version's bin.
local nvm_bins = vim.fn.glob("~/.nvm/versions/node/*/bin", true, true)
if #nvm_bins > 0 then
  table.sort(nvm_bins)
  vim.env.PATH = nvm_bins[#nvm_bins] .. ":" .. vim.env.PATH
end

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 250
vim.opt.virtualedit = "onemore"
vim.opt.exrc = true
vim.opt.mouse = "a"

-- Diagnostics
vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = true,
  signs = true,
})

-- Leader
vim.g.mapleader = " "

-- Keymaps: Navigation
vim.keymap.set({ "n", "v" }, "H", "0")              -- Jump to line start
vim.keymap.set({ "n", "v" }, "L", function()         -- Jump past line end
  local col = vim.fn.col("$")
  vim.fn.cursor(0, col)
end)
vim.keymap.set({ "n", "v" }, "J", "G")              -- Jump to file end
vim.keymap.set({ "n", "v" }, "K", "gg")             -- Jump to file start
vim.keymap.set({ "n", "v" }, "<M-l>", "w")          -- Next word
vim.keymap.set({ "n", "v" }, "<M-h>", "b")          -- Previous word

-- Keymaps: Buffers and splits
vim.keymap.set("n", "<M-H>", "<cmd>bprev<cr>")      -- Previous buffer
vim.keymap.set("n", "<M-L>", "<cmd>bnext<cr>")      -- Next buffer
vim.keymap.set("n", "<leader>e", "<C-w>l")           -- Focus right split

-- Keymaps: Editing
vim.keymap.set("n", "<leader>v", "ggVG",             { desc = "Select all" })
vim.keymap.set({ "n", "v" }, "<leader>J", "J")       -- Join lines
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover)  -- Hover docs
vim.keymap.set("i", "jk", "<Esc>")                  -- Exit insert mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>") -- Clear search highlight
vim.keymap.set("n", "<leader>b", "<cmd>make<cr>",     { desc = "Build (make)" })
vim.keymap.set({ "n", "v" }, "<leader>=", function() -- LSP format buffer/selection
  vim.lsp.buf.format({ async = true })
end, { desc = "LSP format" })
vim.keymap.set("n", "<leader>x", function()          -- Open current file in system app
  vim.ui.open(vim.fn.expand("%:p"))
end, { desc = "Open file in system app" })

-- Keymaps: File tree
vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<cr>") -- Toggle file tree
vim.keymap.set("n", "<leader>j", function()          -- Reveal current file in tree
  vim.cmd("Neotree reveal")
  vim.cmd("Neotree focus")
end)
vim.keymap.set("n", "<leader>g", "<cmd>Neotree git_status<cr>") -- Git status panel
vim.keymap.set("n", "<leader>i", "<cmd>Neotree diagnostics<cr>") -- Issues panel

vim.api.nvim_create_autocmd("VimEnter", {            -- Open side panels on startup
  callback = function()
    vim.cmd("Neotree show")
  end,
})

-- Keymaps: Disabled defaults
vim.keymap.set("n", "s",     "<Nop>")               -- Disable substitute char (use cl)
vim.keymap.set("n", "S",     "<Nop>")               -- Disable substitute line (use cc)
vim.keymap.set("n", "q",     "<Nop>")               -- Disable macro recording
vim.keymap.set("n", "Q",     "<Nop>")               -- Disable replay macro

-- Commands
vim.api.nvim_create_user_command("Q", "qall!", {})     -- Close all windows at once

-- Auto save
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufLeave", "FocusLost" }, {
  callback = function(ev)
    if vim.bo[ev.buf].modified and vim.bo[ev.buf].buftype == "" and vim.fn.bufname(ev.buf) ~= "" then
      vim.api.nvim_buf_call(ev.buf, function() vim.cmd("silent! write") end)
    end
  end,
})

-- Highlights
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = "LightGrey" })
  end,
})

-- Plugins
require("lazy").setup({
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "mrbjarksen/neo-tree-diagnostics.nvim",
    },
    opts = {
      sources = { "filesystem", "git_status", "diagnostics" },
      -- Keep Neo-tree's Git tab responsive in large repos. The git_status
      -- source calls `git status` synchronously and asks for every untracked
      -- file by default, which is slow when directories like node_modules,
      -- build outputs, or generated files are present.
      event_handlers = {
        {
          event = "before_git_status",
          handler = function(args)
            for i, arg in ipairs(args.status_args or {}) do
              if vim.startswith(arg, "--untracked-files=") then
                args.status_args[i] = "--untracked-files=normal"
              elseif vim.startswith(arg, "--ignored=") then
                args.status_args[i] = "--ignored=no"
              end
            end
          end,
        },
      },
      git_status_scope_to_path = true,
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem", display_name = "󰉓 Files" },
          { source = "git_status", display_name = "󰊢 Git" },
          { source = "diagnostics", display_name = "󰒡 Issues" },
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        filtered_items = { visible = true },
        use_libuv_file_watcher = true,
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
        sections = {
          lualine_x = {
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then return "" end
                local names = {}
                for _, c in ipairs(clients) do
                  table.insert(names, c.name)
                end
                return " " .. table.concat(names, ", ")
              end,
            },
            "encoding",
            "filetype",
          },
        },
      })
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      local function command_palette()
        local items, seen = {}, {}

        local function add(label, action)
          if seen[label] then return end
          seen[label] = true
          table.insert(items, { text = label, action = action })
        end

        for _, mode in ipairs({ "n", "v", "x", "i" }) do
          for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
            if km.desc and km.desc ~= "" then
              local label = string.format("%s  [%s %s]", km.desc, mode, km.lhs)
              add(label, function()
                local keys = vim.api.nvim_replace_termcodes(km.lhs, true, false, true)
                vim.api.nvim_feedkeys(keys, mode, false)
              end)
            end
          end
        end

        local lsp_actions = {
          { "Rename symbol",         vim.lsp.buf.rename },
          { "Code action",           vim.lsp.buf.code_action },
          { "Go to definition",      vim.lsp.buf.definition },
          { "Go to declaration",     vim.lsp.buf.declaration },
          { "Go to implementation",  vim.lsp.buf.implementation },
          { "Go to type definition", vim.lsp.buf.type_definition },
          { "Find references",       vim.lsp.buf.references },
          { "Hover documentation",   vim.lsp.buf.hover },
          { "Signature help",        vim.lsp.buf.signature_help },
          { "Format buffer",         function() vim.lsp.buf.format({ async = true }) end },
        }
        for _, a in ipairs(lsp_actions) do add(a[1] .. "  [lsp]", a[2]) end

        for name, _ in pairs(vim.api.nvim_get_commands({})) do
          add(name .. "  [cmd]", function() vim.cmd(name) end)
        end

        Snacks.picker({
          source = "Command Palette",
          items = items,
          format = "text",
          confirm = function(picker, item)
            picker:close()
            if item and item.action then item.action() end
          end,
        })
      end

      vim.keymap.set("n", "<leader>p",  function() Snacks.picker.files() end,                 { desc = "Find files" })
      vim.keymap.set("n", "<leader>P",  command_palette,                                      { desc = "Command palette" })
      vim.keymap.set("n", "<leader>o",  function() Snacks.picker.lsp_symbols() end,           { desc = "Document symbols" })
      vim.keymap.set("n", "<leader>O",  function() Snacks.picker.lsp_workspace_symbols() end, { desc = "Workspace symbols" })
      vim.keymap.set("n", "<leader>f",  function() Snacks.picker.lines() end,                  { desc = "Search buffer lines" })
      vim.keymap.set("n", "<leader>fg", function() Snacks.picker.grep() end,                  { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end,               { desc = "Buffers" })
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
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    config = function()
      vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Toggle markdown preview" })
    end,
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
          "marksman", "bashls", "jsonls", "yamlls", "taplo",
          "pyright", "ts_ls", "gopls",
        },
      })

      local servers = {
        "lua_ls", "rust_analyzer", "clangd", "sourcekit",
        "marksman", "bashls", "jsonls", "yamlls", "taplo",
        "pyright", "ts_ls", "gopls",
      }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
        })
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
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      completion = {
        documentation = { auto_show = true },
      },
      sources = {
        default = { "lsp", "path", "buffer" },
      },
      cmdline = {
        enabled = true,
      },
    },
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
