return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP servers
        "lua_ls",
        "basedpyright",
        "bashls",
        "ts_ls",
        -- Formatters / linters
        "stylua",
        "ruff",
        "prettierd",
        "shfmt",
      },
    },
  },
}