return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      swift = { "swift_format" },
      zsh = { "shfmt" },
      sh = { "shfmt" },
    },

    formatters = {
      swift_format = {
        command = "swift format",
        stdin = false,
        args = { "$FILENAME", "--in-place" },
      },
    },
  },
}
