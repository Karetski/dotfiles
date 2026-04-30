return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- sourcekit ships with Xcode; no Mason install needed
        sourcekit = { mason = false },
        -- Godot's GDScript LSP runs inside the editor on TCP 127.0.0.1:6005
        gdscript = { mason = false },
      },
    },
  },
}
