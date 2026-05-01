return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc",
        "python", "javascript", "typescript",
        "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "swift", "rust", "c", "cpp", "objc", "go",
        "gdscript", "godot_resource",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
