return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      swift = { "swift_format" },
    },

    formatters = {
      swift_format = {
        stdin = false,
        args = { "$FILENAME", "--in-place" },
      },
    },
  },
}
