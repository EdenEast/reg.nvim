local util = require("reg.util")
local config = require("reg.config")

local M = {}

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
    vim.ui.select(registers, {
      prompt = "Select Register: ",
      format_item = function(item)
        return string.format([["%s  %s]], item.label, item.value)
      end,
    }, function(register, _)
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
    vim.ui.input({ prompt = "Description: " }, function(description)
      util.store_register(char, description, file)
    end)
  end

  if opts.picker == "select" then
    local registers = util.generate_register_item_list(config.registers)
    vim.ui.select(registers, {
      prompt = "Select Register: ",
      format_item = function(item)
        return string.format([["%s  %s]], item.label, item.value)
      end,
    }, function(register, _)
      inner(register.label)
    end)
  else
    print("Select Register: ")
    inner(util.getchar())
  end
end

return M
