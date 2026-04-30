-- Custom command palette built on Snacks picker. Aggregates user-described
-- keymaps, common LSP actions, and ex-commands into one fuzzy-searchable list.
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
    { "Rename symbol",         vim.lsp.buf.rename },
    { "Code action",           vim.lsp.buf.code_action },
    { "Go to definition",      vim.lsp.buf.definition },
    { "Go to declaration",     vim.lsp.buf.declaration },
    { "Go to implementation",  vim.lsp.buf.implementation },
    { "Go to type definition", vim.lsp.buf.type_definition },
    { "Find references",       vim.lsp.buf.references },
    { "Hover documentation",   vim.lsp.buf.hover },
    { "Signature help",        vim.lsp.buf.signature_help },
    { "Format buffer",         function() vim.lsp.buf.format({ async = true }) end },
  }
  for _, a in ipairs(lsp_actions) do add(a[1] .. "  [lsp]", a[2]) end

  for name, _ in pairs(vim.api.nvim_get_commands({})) do
    add(name .. "  [cmd]", function() vim.cmd(name) end)
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
    keys = {
      { "<leader>P", command_palette, desc = "Command palette" },
    },
    -- Keep <Esc> from closing the file explorer. In the input field it still
    -- falls back to switching from insert to normal mode (snacks default for i_<Esc>).
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              input = { keys = { ["<Esc>"] = false } },
              list  = { keys = { ["<Esc>"] = false } },
            },
          },
        },
      },
    },
  },
}
