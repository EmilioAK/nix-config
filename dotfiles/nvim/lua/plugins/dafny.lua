return {
  recommended = {
    ft = "dafny",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dafny = {
          cmd = { "dafny", "server" },
          mason = false,
        },
      },
    },
  },
  {
    "mlr-msft/vim-loves-dafny",
    commit = "d75d3b074a3da2b0fa9fd5bc980f52ec82c2ad7b",
  },
}
