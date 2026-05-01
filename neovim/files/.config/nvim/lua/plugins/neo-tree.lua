return {
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
      -- Keep Neo-tree's Git tab responsive in large repos.
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
    config = function(_, opts)
      require("neo-tree").setup(opts)

      vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
      vim.keymap.set("n", "<leader>j", function()
        vim.cmd("Neotree reveal")
        vim.cmd("Neotree focus")
      end, { desc = "Reveal in file tree" })
      vim.keymap.set("n", "<leader>g", "<cmd>Neotree git_status<cr>", { desc = "Git status panel" })
      vim.keymap.set("n", "<leader>i", "<cmd>Neotree diagnostics<cr>", { desc = "Issues panel" })
    end,
  },
}
