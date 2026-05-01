return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "rust_analyzer", "clangd",
          "marksman", "bashls", "jsonls", "yamlls", "taplo",
          "pyright", "ts_ls", "gopls",
        },
      })

      local servers = {
        "lua_ls", "rust_analyzer", "clangd", "sourcekit",
        "marksman", "bashls", "jsonls", "yamlls", "taplo",
        "pyright", "ts_ls", "gopls", "gdscript",
      }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
        })
      end
      vim.lsp.enable(servers)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Find references" }))
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
          vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
          vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("LspHighlight", { clear = false })
            vim.api.nvim_clear_autocmds({ group = group, buffer = args.buf })
            vim.api.nvim_create_autocmd("CursorHold", {
              group = group,
              buffer = args.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              group = group,
              buffer = args.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
}
