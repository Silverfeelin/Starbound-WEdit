local StatusStorage = {}
module = StatusStorage

StatusStorage.__index = StatusStorage

function StatusStorage:new(key)
  local o = { key = key and key .. ";" }
  setmetatable(o, self)
  return o
end

function StatusStorage:get(key, default)
  return status.statusProperty(self.key or "" .. key, default)
end

function StatusStorage:set(key, value)
  return status.setStatusProperty(self.key or "" .. key, default)
end
