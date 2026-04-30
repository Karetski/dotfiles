-- Personal keymaps. Loaded after LazyVim defaults; ours override theirs.

-- Navigation: H/L/J/K become 0/$/G/gg
vim.keymap.set({ "n", "v" }, "H", "0")
vim.keymap.set({ "n", "v" }, "L", function()
  local col = vim.fn.col("$")
  vim.fn.cursor(0, col)
end)
vim.keymap.set({ "n", "v" }, "J", "G")
vim.keymap.set({ "n", "v" }, "K", "gg")
vim.keymap.set({ "n", "v" }, "<M-l>", "w")
vim.keymap.set({ "n", "v" }, "<M-h>", "b")

-- Rescue keys for the standard J/K behaviors (lost to the remap above)
vim.keymap.set({ "n", "v" }, "<leader>J", "J", { desc = "Join lines" })
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover docs" })

-- Reveal current file in the snacks explorer
vim.keymap.set("n", "<leader>j", function()
  Snacks.explorer({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Reveal file in explorer" })

-- Insert-mode escape
vim.keymap.set("i", "jk", "<Esc>")

-- Editing
vim.keymap.set("n", "<leader>v",  "ggVG",            { desc = "Select all" })
vim.keymap.set("n", "<leader>cb", "<cmd>make<cr>",   { desc = "Build (make)" })

-- macOS file actions (under <leader>f to avoid colliding with <leader>x* trouble keys)
vim.keymap.set("n", "<leader>fo", function()
  vim.ui.open(vim.fn.expand("%:p"))
end, { desc = "Open file in system app" })
vim.keymap.set("n", "<leader>fO", function()
  vim.fn.system("open -R " .. vim.fn.shellescape(vim.fn.expand("%:p")))
end, { desc = "Reveal in Finder" })

-- Disabled defaults
vim.keymap.set("n", "s", "<Nop>")  -- Use cl
vim.keymap.set("n", "S", "<Nop>")  -- Use cc
vim.keymap.set("n", "q", "<Nop>")  -- No macro recording
vim.keymap.set("n", "Q", "<Nop>")  -- No macro replay
