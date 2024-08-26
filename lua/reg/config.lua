local path_sep = jit and (jit.os == "Windows" and "\\" or "/") or package.config:sub(1, 1)

-- stylua: ignore
local valid_registers = {
  '"', "-", "#", "=", "/", "*", "+", ":", ".", "%", "#",
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
}

local default_config = {
  registers = vim.deepcopy(valid_registers),
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
Config.valid_registers = valid_registers

function Config:is_valid_register(char)
  return vim.tbl_contains(self.options.registers, char)
end

setmetatable(Config, {
  __index = function(self, key)
    return self.options[key]
  end,
  __newindex = function(self, key, value)
    self.options[key] = value
  end,
})

return Config
