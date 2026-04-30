-- Personal highlight overrides applied after any colorscheme load
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "NONE" })
  end,
})

-- Open the snacks file explorer on startup. If a file was passed on the command
-- line, hand focus back to it so `nvim foo.txt` still lands the cursor in foo.txt.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      Snacks.explorer()
      if vim.fn.argc() > 0 then
        vim.cmd("wincmd p")
      end
    end)
  end,
})

vim.api.nvim_create_user_command("Q", "qall!", {})
