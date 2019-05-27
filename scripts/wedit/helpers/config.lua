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
  if Config.files[file] then return file end

  local cfg = Config:new()
  cfg.data = root.assetJson(file)

  if persist then
    Config.files[file] = cfg
  end

  return cfg
end

function Config:get(key)
  return self.data[key]
end

function Config:set(key, value)
  self.data[key] = value
end
