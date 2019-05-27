require "/scripts/vec2.lua"
require "/scripts/wedit/libs/include.lua"

local Shape = include("/scripts/wedit/objects/shapes/shape.lua")

local Line = Shape:extend()
module = Line

function Line:constructor(from, to)
  self.from = vec2.floor(from)
  self.to = vec2.floor(to)
end

function Line:each()
  error("Not implemented")
end

function Line:outline()
  return self:each()
end
