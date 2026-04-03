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
vim.keymap.set({ "n", "v" }, "<leader>J", "J")       -- Join lines
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover)  -- Hover docs
vim.keymap.set("i", "jk", "<Esc>")                  -- Exit insert mode
vim.keymap.set("n", "<leader>b", "<cmd>make<cr>",     { desc = "Build (make)" })

-- Keymaps: File tree
vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<cr>") -- Toggle file tree
vim.keymap.set("n", "<leader>j", function()          -- Reveal current file in tree
  vim.cmd("Neotree reveal")
  vim.cmd("Neotree focus")
end)
vim.keymap.set("n", "<leader>g", "<cmd>Neotree git_status<cr>") -- Git status panel
vim.keymap.set("n", "<leader>i", "<cmd>Neotree diagnostics<cr>") -- Issues panel
vim.api.nvim_create_autocmd("VimEnter", {            -- Open file tree on startup
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
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local function command_palette()
        local items = {}

        -- Collect user keymaps with descriptions
        for _, mode in ipairs({ "n", "v", "x", "i" }) do
          for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
            if km.desc and km.desc ~= "" then
              table.insert(items, {
                label = km.desc,
                kind = "keymap",
                display = km.desc .. "  [" .. mode .. " " .. km.lhs .. "]",
                action = function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(km.lhs, true, false, true), mode, false) end,
              })
            end
          end
        end

        -- Collect LSP actions
        local lsp_actions = {
          { label = "Rename symbol",         action = vim.lsp.buf.rename },
          { label = "Code action",           action = vim.lsp.buf.code_action },
          { label = "Go to definition",      action = vim.lsp.buf.definition },
          { label = "Go to declaration",     action = vim.lsp.buf.declaration },
          { label = "Go to implementation",  action = vim.lsp.buf.implementation },
          { label = "Go to type definition", action = vim.lsp.buf.type_definition },
          { label = "Find references",       action = vim.lsp.buf.references },
          { label = "Hover documentation",   action = vim.lsp.buf.hover },
          { label = "Signature help",        action = vim.lsp.buf.signature_help },
          { label = "Format buffer",         action = function() vim.lsp.buf.format({ async = true }) end },
        }
        for _, a in ipairs(lsp_actions) do
          table.insert(items, { label = a.label, kind = "lsp", display = a.label .. "  [lsp]", action = a.action })
        end

        -- Collect user commands
        for name, _ in pairs(vim.api.nvim_get_commands({})) do
          table.insert(items, {
            label = name,
            kind = "command",
            display = name .. "  [cmd]",
            action = function() vim.cmd(name) end,
          })
        end

        -- Deduplicate by display string
        local seen = {}
        local unique = {}
        for _, item in ipairs(items) do
          if not seen[item.display] then
            seen[item.display] = true
            table.insert(unique, item)
          end
        end

        pickers.new({}, {
          prompt_title = "Command Palette",
          finder = finders.new_table({
            results = unique,
            entry_maker = function(item)
              return { value = item, display = item.display, ordinal = item.label }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              if entry then entry.value.action() end
            end)
            return true
          end,
        }):find()
      end

      vim.keymap.set("n", "<C-p>",      builtin.find_files,  { desc = "Find files" })
      vim.keymap.set("n", "<leader>p",  command_palette,     { desc = "Command palette" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep,   { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers,     { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
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
    "lewis6991/satellite.nvim",
    opts = {},
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
