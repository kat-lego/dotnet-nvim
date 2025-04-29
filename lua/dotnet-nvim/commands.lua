local utilities = require 'dotnet-nvim.utilities'
local M = {}

function M.dotnet_command(opts)
  local args = opts.fargs

  if not args or #args == 0 then
    print 'no arguments provided for dotnet command.'
    return
  end

  local cmd = 'dotnet ' .. table.concat(args, ' ')
  local cwd = utilities.get_working_directory(args[1])
  local output = utilities.run_command(cmd, cwd)
  print(output .. '\n')
end

function M.setup()
  local completions = require('dotnet-nvim.completions').completions
  vim.api.nvim_create_user_command('Dotnet', M.dotnet_command, { nargs = '*', complete = completions })
end

return M
