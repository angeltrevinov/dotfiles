return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Formatters / linters (mason package names)
        "stylua",
        "ruff",
        "prettierd",
        "shfmt",
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        -- LSP servers
        "lua_ls",
        "basedpyright",
        "bashls",
        "ts_ls",
      },
    },
  },
}
