local Config = {
  files = {}
}
Config.__index = Config
module = Config

function Config:new()
  local o = { data = {} }
  setmetatable(o, self)
  return o
end

function Config.fromFile(file, persist)
  if Config.files[file] then return Config.files[file] end
  local cfg = Config:new()

  cfg.file = file
  cfg.persist = persist
  cfg.data = root.assetJson(file)

  if persist then
    Config.files[file] = cfg
  end

  return cfg
end

function Config.fromStatus(key, default)
  local cfg = Config:new()
  cfg.key = key
  cfg.default = default
  cfg.data = status.statusProperty(key, default)
  return cfg
end

function Config:reload()
  if self.key then
    self.data = status.statusProperty(self.key, self.default)
  elseif cfg.file then
    self.data = root.assetJson(self.file)
  end
end

function Config:toStatus()
  status.setStatusProperty(self.key, self.data)
end

function Config:get(key)
  return self.data[key]
end

function Config:set(key, value)
  self.data[key] = value
end
