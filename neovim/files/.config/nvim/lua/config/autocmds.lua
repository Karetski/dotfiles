vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufLeave", "FocusLost" }, {
  callback = function(ev)
    if vim.bo[ev.buf].modified and vim.bo[ev.buf].buftype == "" and vim.fn.bufname(ev.buf) ~= "" then
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("Neotree show")
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = "LightGrey" })
  end,
})
