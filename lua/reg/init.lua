local util = require("reg.util")
local config = require("reg.config")

local M = {}

local function is_valid_register(char)
  local is_valid = config:is_valid_register(char)
  if not is_valid then
    vim.notify(string.format([[Invalid register: "%s]], char), vim.log.levels.WARN)
  end
  return is_valid
end

local function ui_select_register(registers, cb)
  vim.ui.select(registers, {
    prompt = "Select Register: ",
    format_item = function(item)
      return string.format([["%s  %s]], item.label, item.value)
    end,
  }, function(register, _)
    cb(register.label)
  end)
end

function M.edit(opts)
  opts = opts or {}

  local function inner(char)
    local ui = vim.api.nvim_list_uis()[1]
    local winopts = config.editor
    winopts.relative = "editor"
    winopts.row = math.floor(ui.height * 0.1)
    winopts.col = math.floor(ui.width * 0.1)

    local buffer = util.create_edit_buffer(char)
    vim.api.nvim_open_win(buffer, true, winopts)
    vim.api.nvim_win_set_buf(0, buffer)
  end

  if opts.picker == "select" then
    local registers = util.generate_register_item_list(config.registers)
    ui_select_register(registers, function(register, _)
      inner(register.label)
    end)
  else
    print("Select Register: ")
    inner(util.getchar())
  end
end

function M.save(opts)
  opts = opts or {}
  local file = opts.file or config.cache_file

  local function inner(char)
    if not is_valid_register(char) then
      return
    end

    vim.ui.input({ prompt = "Description: " }, function(description)
      util.store_register(char, description, file)
    end)
  end

  if opts.picker == "select" then
    local registers = util.generate_register_item_list(config.registers)
    ui_select_register(registers, function(register, _)
      inner(register.label)
    end)
  else
    print("Select Register: ")
    inner(util.getchar())
  end
end

function M.load(opts)
  opts = opts or {}
  local file = opts.file or config.cache_file

  local stored_items = util.generate_macro_item_list(file)
  if #stored_items == 0 then
    vim.notify("No macros stored", vim.log.levels.INFO)
    return
  end

  local function inner(register, item)
    if not is_valid_register(register) then
      return
    end

    util.load_register(register, item.description, file)
    vim.notify(string.format([[Set '%s' to register "%s]], item.description, register), vim.log.levels.INFO)
  end

  vim.ui.select(stored_items, {
    prompt = "Select Macro: ",
    format_item = function(item)
      return string.format([[[%s]: %s]], item.description, item.value)
    end,
  }, function(item, _)
    if opts.picker == "select" then
      ui_select_register(util.generate_register_item_list(config.registers), function(register)
        inner(register, item)
      end)
    else
      print("Select Register: ")
      local register = util.getchar()
      inner(register, item)
    end
  end)
end

return M
