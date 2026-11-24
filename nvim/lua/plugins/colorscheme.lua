local M = {
  "t4lentles5/luna.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
}

M.colors = setmetatable({}, {
  __index = function(_, key)
    local defaults = {
      bg = "#141312",
      bgSecondary = "#0e0e0d",
      fg = "#e5e2e0",
      muted = "#919189",
      cyan = "#c7c7bc",
      purple = "#d0c3c9",
      red = "#ffb4ab",
      yellow = "#c8c6c1",
      blue = "#c7c7bc",
      green = "#c8c6c1",
    }
    if vim.g.qs_colors and vim.g.qs_colors[key] then
      return vim.g.qs_colors[key]
    end
    return defaults[key]
  end,
})

return M
