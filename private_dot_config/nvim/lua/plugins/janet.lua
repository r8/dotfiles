return {
  { "janet-lang/janet.vim", ft = "janet" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "janet_simple" } },
  },
}
