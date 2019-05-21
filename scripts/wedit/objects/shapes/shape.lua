local Shape = {}
module = Shape

Shape.__index = Shape
function Shape:create(...)
  local o = setmetatable({}, self)
  o:constructor(...)
  return o
end

function Shape:constructor() end

function Shape:extend()
    local t = setmetatable({}, {__index = self})
    t.__index = t
    return t
end
