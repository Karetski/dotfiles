-- Open neo-tree on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("Neotree show")
  end,
})

-- Personal highlight overrides applied after any colorscheme load
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = "LightGrey" })
  end,
})

vim.api.nvim_create_user_command("Q", "qall!", {})
