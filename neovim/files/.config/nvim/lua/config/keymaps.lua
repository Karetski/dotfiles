vim.keymap.set({ "n", "v" }, "H", "0", { desc = "Jump to line start" })
vim.keymap.set({ "n", "v" }, "L", function()
  local col = vim.fn.col("$")
  vim.fn.cursor(0, col)
end, { desc = "Jump past line end" })
vim.keymap.set({ "n", "v" }, "J", "G", { desc = "Jump to file end" })
vim.keymap.set({ "n", "v" }, "K", "gg", { desc = "Jump to file start" })
vim.keymap.set({ "n", "v" }, "<M-l>", "w", { desc = "Next word" })
vim.keymap.set({ "n", "v" }, "<M-h>", "b", { desc = "Previous word" })

vim.keymap.set("n", "<M-H>", "<cmd>bprev<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<M-L>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>e", "<C-w>l", { desc = "Focus right split" })

vim.keymap.set("n", "<leader>v", "ggVG", { desc = "Select all" })
vim.keymap.set({ "n", "v" }, "<leader>J", "J", { desc = "Join lines" })
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover docs" })
if not vim.g.normal_editor_mode then
  vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
end
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>b", "<cmd>make<cr>", { desc = "Build (make)" })
vim.keymap.set("n", "<leader>x", function()
  vim.ui.open(vim.fn.expand("%:p"))
end, { desc = "Open file in system app" })

vim.keymap.set("n", "s", "<Nop>", { desc = "Disabled" })
vim.keymap.set("n", "S", "<Nop>", { desc = "Disabled" })
vim.keymap.set("n", "q", "<Nop>", { desc = "Disabled" })
vim.keymap.set("n", "Q", "<Nop>", { desc = "Disabled" })

vim.api.nvim_create_user_command("Q", "qall!", {})

if vim.g.normal_editor_mode then
  local function termcodes(keys)
    return vim.api.nvim_replace_termcodes(keys, true, false, true)
  end

  local function feed(keys)
    vim.api.nvim_feedkeys(termcodes(keys), "n", false)
  end

  local function stopinsert()
    if vim.fn.mode():match("[iR]") then
      vim.cmd.stopinsert()
    end
  end

  local function select_all()
    stopinsert()
    feed("ggVG")
  end

  local function search()
    stopinsert()
    feed("/")
  end

  local function find_files()
    if Snacks then
      Snacks.picker.files()
    else
      vim.cmd.edit()
    end
  end

  local function command_palette()
    if Snacks then
      Snacks.picker.commands()
    else
      vim.ui.input({ prompt = ":" }, function(command)
        if command and command ~= "" then
          vim.cmd(command)
        end
      end)
    end
  end

  local familiar_maps = {
    { "<C-s>", function() vim.cmd.write() end, "Save" },
    { "<D-s>", function() vim.cmd.write() end, "Save" },
    { "<C-f>", search, "Search" },
    { "<D-f>", search, "Search" },
    { "<C-a>", select_all, "Select all" },
    { "<D-a>", select_all, "Select all" },
    { "<C-z>", function() vim.cmd.undo() end, "Undo" },
    { "<D-z>", function() vim.cmd.undo() end, "Undo" },
    { "<C-y>", function() vim.cmd.redo() end, "Redo" },
    { "<D-Z>", function() vim.cmd.redo() end, "Redo" },
    { "<C-o>", find_files, "Open file" },
    { "<D-o>", find_files, "Open file" },
    { "<C-p>", command_palette, "Command palette" },
    { "<D-p>", command_palette, "Command palette" },
  }

  for _, mapping in ipairs(familiar_maps) do
    vim.keymap.set({ "n", "i", "v" }, mapping[1], mapping[2], { desc = mapping[3] })
  end

  vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "Paste" })
  vim.keymap.set("i", "<D-v>", "<C-r>+", { desc = "Paste" })
  vim.keymap.set({ "n", "v" }, "<C-v>", '"+p', { desc = "Paste" })
  vim.keymap.set({ "n", "v" }, "<D-v>", '"+p', { desc = "Paste" })
  vim.keymap.set({ "x", "s" }, "<C-c>", '"+y', { desc = "Copy" })
  vim.keymap.set({ "x", "s" }, "<D-c>", '"+y', { desc = "Copy" })
  vim.keymap.set({ "x", "s" }, "<C-x>", '"+d', { desc = "Cut" })
  vim.keymap.set({ "x", "s" }, "<D-x>", '"+d', { desc = "Cut" })
end
