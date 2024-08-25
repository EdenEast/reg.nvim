local base64 = require("reg.base64")
local M = {}

local function djb2(str)
  local hash = 5381
  for i = 1, #str do
    hash = bit.lshift(hash, 5) + hash + str:byte(i)
  end
  return hash
end

local function save_data(data, path)
  local file = io.open(path, "w")
  if not file then
    vim.notify("Failed to open file: " .. path, vim.log.levels.ERROR)
    return
  end

  local content = vim.fn.json_encode(data)
  file:write(content)
  file:close()
end

local function load_data(path)
  if vim.fn.filereadable(path) ~= 0 then
    local file = io.open(path, "r")
    if not file then
      vim.notify("Failed to open file: " .. path, vim.log.levels.ERROR)
      return {}
    end

    local content = file:read("*a")
    file:close()

    if content == "" then
      return {}
    end

    return vim.fn.json_decode(content)
  end
  return {}
end

function M.getchar()
  local i = vim.fn.getchar()
  return vim.fn.nr2char(i)
end

function M.generate_register_item_list(registers)
  registers = registers or require("regedit.config").registers

  local items = {}

  for _, register in ipairs(registers) do
    local content = vim.fn.getreg(register)
    local regtype = vim.fn.getregtype(register)

    table.insert(items, {
      label = register,
      value = content,
      type = regtype,
    })
  end

  return items
end

function M.store_register(register, description, path)
  local reg = vim.fn.getreg(register)
  if not reg then
    vim.notify("Register is empty", vim.log.levels.WARN)
    return
  end

  local regtype = vim.fn.getregtype(register)
  local data = load_data(path)

  local key = tostring(djb2(description))
  data[key] = {
    type = regtype,
    description = description,
    content = base64.encode(reg),
  }

  save_data(data, path)
end

function M.load_register(register, description, path)
  local key = tostring(djb2(description))
  local data = load_data(path)
  local item = data[key]

  if not item then
    vim.notify("No saved register found with description: " .. description, vim.log.levels.ERROR)
    return
  end

  local content = base64.decode(item.content)
  vim.fn.setreg(register, content, item.type)
end

function M.create_edit_buffer(register)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local regtype = vim.fn.getregtype(register)
  local content = vim.fn.getreg(register)
  content = type(regtype) == "string" and content:gsub("\n", "\\n") or content

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { content })
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_buf_set_name(bufnr, "editing @" .. register)

  -- Set keymaps to close the buffer
  local delete_buf = function()
    vim.api.nvim_buf_delete(bufnr, { unload = true })
  end
  vim.keymap.set("n", "<escape>", delete_buf, { buffer = bufnr })
  vim.keymap.set("n", "<c-c>", delete_buf, { buffer = bufnr })
  vim.keymap.set("n", "q", delete_buf, { buffer = bufnr })

  vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
    buffer = bufnr,
    callback = function(buf_opts)
      local buf_content = table.concat(vim.api.nvim_buf_get_lines(buf_opts.buf, 0, -1, true))
      local newcontent = buf_content:gsub("\\n", "\n")
      vim.fn.setreg(register, newcontent, regtype)

      vim.api.nvim_win_close(0, true)
    end,
  })

  return bufnr
end

return M
