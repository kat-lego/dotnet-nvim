local utilities = require 'dotnet-nvim.utilities'
local M = {}

function M.get_path_completions(path, prefix)
  local itemsString = vim.fn.glob(path .. '/' .. prefix .. '*')
  local items = vim.split(itemsString, '\n', { trimempty = true })

  local matches = {}

  for _, item in ipairs(items) do
    table.insert(matches, string.sub(item, #path + 2))
  end

  return matches
end

function M.get_package_completions(packagePrefix)
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

function M.completions(arg_lead, cmd_line)
  local args = vim.split(cmd_line, '%s+')
  local context = args[2] or ''
  local completions = {}

  local cwd = utilities.get_working_directory()

  if context == 'add' then
    if args[3] == 'reference' then
      completions = M.get_path_completions(cwd, args[4] or '')
    elseif args[3] == 'package' then
      completions = M.get_package_completions(args[4] or '')
    else
      completions = { 'reference', 'package' }
    end
  elseif context == 'sln' then
    if args[3] == 'add' or args[3] == 'remove' then
      completions = M.get_path_completions(cwd, args[4] or '')
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

return M
