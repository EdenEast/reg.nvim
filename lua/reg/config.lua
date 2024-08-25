local path_sep = jit and (jit.os == "Windows" and "\\" or "/") or package.config:sub(1, 1)

local function list_registers()
  local registers = { '"', "-", "#", "=", "/", "*", "+", ":", ".", "%", "#" }
  for i = 0, 9 do
    table.insert(registers, tostring(i))
  end
  for i = 97, 122 do
    table.insert(registers, string.char(i))
  end
  return registers
end

local default_config = {
  registers = list_registers(),
  cache_file = vim.fn.stdpath("cache") .. path_sep .. "reg.json",
  editor = {
    width = 100,
    height = 2,
    style = "minimal",
    border = "rounded",
  },
}

local Config = {}
Config.options = vim.deepcopy(default_config)

setmetatable(Config, {
  __index = function(self, key)
    return self.options[key]
  end,
  __newindex = function(self, key, value)
    self.options[key] = value
  end,
})

return Config
