return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = false,
    },
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

      vim.keymap.set({ "n", "v" }, "<leader>=", function()
        conform.format({ async = true, lsp_format = "fallback" })
      end, { desc = "Format" })
    end,
  },
}
