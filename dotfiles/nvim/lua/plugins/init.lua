local function terminal_shell()
  local zsh = vim.fn.exepath("zsh")
  if zsh ~= "" then
    return { zsh, "--login" }
  end

  return { vim.o.shell, "--login" }
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
