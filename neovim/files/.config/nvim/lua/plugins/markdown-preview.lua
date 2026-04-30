return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    -- Both yarn and npm mutate app/yarn.lock during install (npm rewrites the
    -- registry URLs to npmjs.org), and lazy.nvim then refuses updates over the
    -- dirty tree. Restore yarn.lock and drop npm's package-lock.json after install.
    build = "cd app && npm install --package-lock=false && cd .. && git checkout -- app/yarn.lock && rm -f app/package-lock.json",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview", ft = "markdown" },
    },
  },
}
