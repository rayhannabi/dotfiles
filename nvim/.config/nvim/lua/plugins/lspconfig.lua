return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Swift SourceKit LSP
      sourcekit = {
        mason = false,
      },
      -- Zig
      zls = {},
    },
  },
  setup = {
    sourcekit = {
      capabilities = {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      },
    },
  },
}
