local function terminal_shell()
  local fish = vim.fn.exepath("fish")
  if fish ~= "" then
    return { fish, "--login" }
  end

  return { "zsh", "--login" }
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        shell = terminal_shell(),
      },
    },
  },
}
