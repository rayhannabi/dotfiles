local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    -- css = { "prettier" },
    -- html = { "prettier" },
    swift = { "swift_format" },
  },

  formatters = {
    swift_format = {
      stdin = false,
      args = { "$FILENAME", "--in-place" },
    },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
