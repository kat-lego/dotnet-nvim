local M = {}

function M.find_file_directory(patterns)
  local current_dir = vim.fn.expand '%:p:h'

  while current_dir ~= '' and current_dir ~= '/' do
    for _, pattern in ipairs(patterns) do
      local files = vim.fn.glob(current_dir .. '/' .. pattern, false, true)
      if #files > 0 then
        return current_dir, files[1]
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end

  return nil, nil
end

function M.get_working_directory(context)
  local csproj = '*.csproj'
  local solution = '*.sln'

  local command_patterns_mapping = {
    ['sln'] = { solution },
    ['add'] = { csproj },
    ['restore'] = { csproj, solution },
    ['build'] = { csproj, solution },
    ['test'] = { csproj, solution },
    ['clean'] = { csproj, solution },
  }

  local pattern = command_patterns_mapping[context]

  if not pattern then
    return vim.fn.expand '%:p:h'
  end

  local cwd, _ = M.find_file_directory(pattern)

  if not cwd then
    local message = ''
    if M.contains(pattern, csproj) then
      message = message .. 'no project (.csproj) file found in the current or parent directories.'
    end

    if M.contains(pattern, solution) then
      message = message .. '\nno solution (.sln) file found in the current or parent directories.'
    end

    print(message)
    return
  end

  return cwd
end

function M.run_command(cmd, cwd)
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

function M.contains(tbl, str)
  for _, v in ipairs(tbl) do
    if v == str then
      return true
    end
  end
  return false
end

return M
