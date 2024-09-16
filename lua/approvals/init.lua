local M = {}

-- Utility function to get the current file's full path
local function get_current_file_path()
  return vim.api.nvim_buf_get_name(0)
end

-- Utility function to get the file extension
local function get_file_extension()
  local file = get_current_file_path()
  return file:match '^.+(%..+)$'
end

-- Function to determine the executor based on file extension
local function get_executor(extension)
  local executors = {
    ['.py'] = 'python',
    ['.js'] = 'node',
    ['.lua'] = 'lua',
    ['.sh'] = 'bash',
    -- Add more executors as needed
  }
  return executors[extension]
end

-- Function to execute the current file and capture stdout
local function execute_file()
  local file_path = get_current_file_path()
  local extension = get_file_extension()
  local executor = get_executor(extension)

  if not executor then
    vim.notify('No executor found for extension: ' .. extension, vim.log.levels.ERROR)
    return nil
  end

  local cmd = executor .. ' ' .. file_path
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read '*a'
    handle:close()
    return result
  else
    vim.notify('Failed to execute command: ' .. cmd, vim.log.levels.ERROR)
    return nil
  end
end

-- Function to write output to a file
local function write_output(file_path, content)
  local file = io.open(file_path, 'w')
  if file then
    file:write(content)
    file:close()
  else
    vim.notify('Failed to write to file: ' .. file_path, vim.log.levels.ERROR)
  end
end

-- Function to read file content
local function read_file(file_path)
  local file = io.open(file_path, 'r')
  if file then
    local content = file:read '*a'
    file:close()
    return content
  else
    return ''
  end
end

-- Function to compare .received and .approved files
local function compare_outputs(received, approved)
  return received == approved
end

-- Function to open diff view
local function open_diff(received_path, approved_path)
  -- Open received file in a new tab
  vim.cmd('tabnew')
  -- Open vertical split for received and approved files
  vim.cmd('edit ' .. received_path)
  vim.cmd('vsplit ' .. approved_path)
  vim.cmd 'windo diffthis'
  
  -- Focus on the left side (received)
  vim.cmd('wincmd h')
end

-- Main action
function M.approve()
  local received = execute_file()
  if received == nil then
    return
  end

  local file_path = get_current_file_path()
  local received_path = file_path .. '.received'
  local approved_path = file_path .. '.approved'

  write_output(received_path, received)

  -- Ensure .approved file exists
  local approved = read_file(approved_path)
  if approved == '' then
    write_output(approved_path, '')
    approved = ''
  end

  if compare_outputs(received, approved) then
    vim.notify('verified', vim.log.levels.INFO)
  else
    open_diff(received_path, approved_path)
    vim.notify('Output mismatch. Diff opened.', vim.log.levels.WARN)
  end
end

-- Setup function to create a command
function M.setup()
  vim.api.nvim_create_user_command('ApprovalTest', M.approve, {})
end

return M
