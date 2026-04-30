return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    -- Use npm rather than the plugin's bundled yarn-based installer; yarn install
    -- mutates app/yarn.lock and lazy.nvim then refuses updates over the dirty tree.
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview", ft = "markdown" },
    },
  },
}
