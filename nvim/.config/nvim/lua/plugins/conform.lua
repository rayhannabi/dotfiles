return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      swift = { "swift_format" },
      zsh = { "shfmt" },
      sh = { "shfmt" },
      nu = { "nufmt" },
    },

    formatters = {
      swift_format = {
        command = "swift",
        stdin = false,
        args = { "format", "$FILENAME", "--in-place" },
      },
    },
  },
}
