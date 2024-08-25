local M = {}

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
