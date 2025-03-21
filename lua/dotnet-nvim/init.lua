local M = {}

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

local function get_path_completions(pathPrefix)
  local path = nil

  if pathPrefix == '' or pathPrefix == './' then
    path = './'
  else
    path = pathPrefix
  end

  local parent_path, path_item = path:match '(.*/)(.*)'

  if not parent_path then
    parent_path = './'
    path_item = path
  end

  local abs_parent_path = vim.fn.fnamemodify(parent_path, ':p')
  local possible_parent_path_items = vim.fn.readdir(abs_parent_path)

  local matches = {}
  for _, item in ipairs(possible_parent_path_items) do
    if item:match('^' .. vim.pesc(path_item)) then
      table.insert(matches, item)
    end
  end

  for i, item in ipairs(matches) do
    matches[i] = abs_parent_path .. item
  end

  return matches
end

local function get_package_completions(packagePrefix)
  local query = packagePrefix or ''
  local url = 'https://api-v2v3search-0.nuget.org/query?q=' .. vim.fn.escape(query, '"') .. '&take=20'
  local result = vim.fn.system { 'curl', '-s', url }
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local data = vim.fn.json_decode(result)
  local packages = {}

  if data and data.data then
    for _, pkg in ipairs(data.data) do
      local id = pkg.id
      if id:match('^' .. vim.pesc(query)) then
        table.insert(packages, id)
      end
    end
  end

  return packages
end

local function get_completions(arg_lead, cmd_line)
  local args = vim.split(cmd_line, '%s+')
  local context = args[2] or ''
  local completions = {}

  if context == 'add' then
    if args[3] == 'reference' then
      completions = get_path_completions(args[4] or '')
    elseif args[3] == 'package' then
      completions = get_package_completions(args[4] or '')
    else
      completions = { 'reference', 'package' }
    end
  elseif context == 'sln' then
    if args[3] == 'add' or args[3] == 'remove' then
      completions = get_path_completions(args[4] or '')
    else
      completions = { 'add', 'remove' }
    end
  else
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
end

-- Setup function to define commands
function M.setup()
  -- Define :Dotnet command in Neovim
  vim.api.nvim_create_user_command('Dotnet', function(opts)
    M.run_dotnet_command(opts.fargs)
  end, {
    nargs = '*', -- Accept multiple arguments
    complete = get_completions,
  })
end

return M
