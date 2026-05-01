local function command_palette()
  local items, seen = {}, {}

  local function add(label, action)
    if seen[label] then return end
    seen[label] = true
    table.insert(items, { text = label, action = action })
  end

  for _, mode in ipairs({ "n", "v", "x", "i" }) do
    for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
      if km.desc and km.desc ~= "" then
        local label = string.format("%s  [%s %s]", km.desc, mode, km.lhs)
        add(label, function()
          local keys = vim.api.nvim_replace_termcodes(km.lhs, true, false, true)
          vim.api.nvim_feedkeys(keys, mode, false)
        end)
      end
    end
  end

  local lsp_actions = {
    { "Rename symbol", vim.lsp.buf.rename },
    { "Code action", vim.lsp.buf.code_action },
    { "Go to definition", vim.lsp.buf.definition },
    { "Go to declaration", vim.lsp.buf.declaration },
    { "Go to implementation", vim.lsp.buf.implementation },
    { "Go to type definition", vim.lsp.buf.type_definition },
    { "Find references", vim.lsp.buf.references },
    { "Hover documentation", vim.lsp.buf.hover },
    { "Signature help", vim.lsp.buf.signature_help },
    { "Format buffer", function() vim.lsp.buf.format({ async = true }) end },
  }
  for _, action in ipairs(lsp_actions) do
    add(action[1] .. "  [lsp]", action[2])
  end

  for name, _ in pairs(vim.api.nvim_get_commands({})) do
    add(name .. "  [cmd]", function()
      vim.cmd(name)
    end)
  end

  Snacks.picker({
    source = "Command Palette",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.action then item.action() end
    end,
  })
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      vim.keymap.set("n", "<leader>p", function() Snacks.picker.files() end, { desc = "Find files" })
      vim.keymap.set("n", "<leader>P", command_palette, { desc = "Command palette" })
      vim.keymap.set("n", "<leader>o", function() Snacks.picker.lsp_symbols() end, { desc = "Document symbols" })
      vim.keymap.set("n", "<leader>O", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "Workspace symbols" })
      vim.keymap.set("n", "<leader>f", function() Snacks.picker.lines() end, { desc = "Search buffer lines" })
      vim.keymap.set("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
    end,
  },
}
