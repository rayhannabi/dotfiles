return {
  {
    "decaycs/decay.nvim",
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local decay = require("decay")
        local decay_core = require("decay.core")
        local colors = decay_core.get_colors("default")
        decay.setup({
          override = {
            WinSeparator = { fg = colors.black },
          },
        })
        decay.load()
      end,
    },
  },
}
