return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { flavour = "latte" },
  },
  -- Pin LazyVim's colorscheme to catppuccin (default would be tokyonight)
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
