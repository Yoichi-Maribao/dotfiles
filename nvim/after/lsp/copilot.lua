local home = vim.fn.expand "$HOME"
local sysname = vim.loop.os_uname().sysname

local copilot_cmd
if sysname == "Darwin" then
  copilot_cmd = home
    .. "/.volta/tools/image/packages/@github/copilot-language-server-darwin-arm64/lib/node_modules/@github/copilot-language-server-darwin-arm64/copilot-language-server"
elseif sysname == "Linux" then
  copilot_cmd = home
    .. "/.volta/tools/image/packages/@github/copilot-language-server-linux-x64/lib/node_modules/@github/copilot-language-server-linux-x64/copilot-language-server"
end

return {
  cmd = { copilot_cmd, "--stdio" },
  root_markers = { ".git" },
}
