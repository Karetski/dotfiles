return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "mrbjarksen/neo-tree-diagnostics.nvim" },
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
        follow_current_file    = { enabled = true },
        hijack_netrw_behavior  = "open_current",
        filtered_items         = { visible = true },
        use_libuv_file_watcher = true,
      },
      window = { width = 30 },
    },
  },
}
