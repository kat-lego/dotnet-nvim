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

-- Helper function to list directories and files under a given path
local function get_path_completions(input)
  local path = input == '' and './' or input
  local abs_path = vim.fn.fnamemodify(path, ':p')
  local dir = vim.fn.isdirectory(abs_path) == 1 and abs_path or vim.fn.fnamemodify(abs_path, ':h')
  local items = vim.fn.globpath(dir, '*', false, true)
  return vim.tbl_map(function(item)
    return vim.fn.fnamemodify(item, ':.')
  end, items)
end

-- Helper function to find a specific file in the current or parent directories
local function find_file_directory(file_pattern)
  local current_dir = vim.fn.expand '%:p:h' -- Get the directory of the current buffer
  while current_dir ~= '' and current_dir ~= '/' do
    local files = vim.fn.glob(current_dir .. '/' .. file_pattern, false, true)
    if #files > 0 then
      return current_dir, files[1]
    end
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end
  return nil, nil
end

-- Function to run dotnet commands
function M.run_dotnet_command(args)
  if not args or #args == 0 then
    vim.api.nvim_err_writeln 'No arguments provided for dotnet command.'
    return
  end

  local cmd = 'dotnet ' .. table.concat(args, ' ')
  local cwd

  if args[1] == 'sln' then
    cwd = select(1, find_file_directory '*.sln')
    if not cwd then
      vim.api.nvim_err_writeln 'No solution (.sln) file found in the current or parent directories.'
      return
    end
  elseif args[1] == 'add' then
    local csproj_dir, csproj_file = find_file_directory '*.csproj'
    if not csproj_file then
      vim.api.nvim_err_writeln 'No project (.csproj) file found in the current or parent directories.'
      return
    end
    table.insert(args, 2, csproj_file) -- Add the .csproj file path as the second argument
    cwd = csproj_dir
  else
    cwd = vim.fn.expand '%:p:h' -- Default to the directory of the current buffer
  end

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
    complete = function(arg_lead, cmd_line)
      local args = vim.split(cmd_line, '%s+')
      local context = args[2] or ''
      local completions = {}

      -- Complete 'dotnet add' and 'dotnet sln' with .csproj files
      if context == 'add' then
        if args[3] == 'reference' then
          completions = get_path_completions(args[4] or '')
        end
      elseif context == 'sln' then
        completions = get_path_completions(args[4] or '')
      else
        -- General dotnet commands
        completions = {
          'sln',
          'new',
          'build',
          'run',
          'test',
          'publish',
          'restore',
          'clean',
          'add',
        }
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
