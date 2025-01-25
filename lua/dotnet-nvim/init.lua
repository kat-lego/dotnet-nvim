local M = {}

-- Helper function to run shell commands and capture output
local function run_command(cmd, cwd)
  local handle
  if cwd then
    handle = assert(io.popen('cd ' .. vim.fn.shellescape(cwd) .. ' && ' .. cmd, 'r'))
  else
    handle = assert(io.popen(cmd, 'r'))
  end
  local result = handle:read '*a'
  handle:close()
  return result
end

-- Function to run dotnet commands
function M.run_dotnet_command(args)
  if not args or #args == 0 then
    vim.api.nvim_err_writeln 'No arguments provided for dotnet command.'
    return
  end

  local cwd = vim.fn.expand '%:p:h' -- Get the directory of the current buffer
  local cmd = 'dotnet ' .. table.concat(args, ' ')
  local output = run_command(cmd, cwd)
  vim.api.nvim_out_write(output .. '\n')
end

-- Setup function to define commands
function M.setup()
  -- Define :Dotnet command in Neovim
  vim.api.nvim_create_user_command('Dotnet', function(opts)
    M.run_dotnet_command(opts.fargs)
  end, {
    nargs = '*', -- Accept multiple arguments
    complete = function(arg_lead)
      local completions = {
        'sln',
        'new',
        'build',
        'run',
        'test',
        'publish',
        'restore',
        'clean',
      }

      -- Add directory suggestions
      local dirs = vim.fn.glob('**/', true, true)
      for _, dir in ipairs(dirs) do
        table.insert(completions, dir)
      end

      local matches = {}
      for _, item in ipairs(completions) do
        if item:match('^' .. vim.pesc(arg_lead)) then
          table.insert(matches, item)
        end
      end
      return matches
    end,
  })
end

return M
