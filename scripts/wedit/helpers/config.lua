local Config = {}
Config.__index = Config
module = Config

--- Instantiates a new debug renderer.
-- @return Debug renderer.
function Config:new()
  local o = { data = {} }

  setmetatable(o, self)
  return o
end

function Config:fromFile(file)
  local cfg = Config:new()
  cfg.data = root.assetJson(file)
  return cfg
end

function Config:get(key)
  return self.data[key]
end

function Config:set(key, value)
  self.data[key] = value
end
