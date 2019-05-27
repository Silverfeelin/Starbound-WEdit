require "/scripts/vec2.lua"
require "/scripts/wedit/libs/include.lua"

local Shape = include("/scripts/wedit/objects/shapes/shape.lua")

local Rectangle = Shape:extend()
module = Rectangle

function Rectangle:constructor(bottomLeft, topRight)
  self.bl = vec2.floor(bottomLeft)
  self.tr = vec2.floor(topRight)
end

function Rectangle:fromCenter(center, width, height)
  height = height or width
  local o = setmetatable({}, Rectangle)
  center = vec2.floor(center)
  local wx = math.ceil(width / 2)
  local wy = math.ceil(height / 2)
  local bl = vec2.add(center, {-wx + 1, -wy + 1})
  local tr = vec2.add(center, {width - wx, height - wy})
  o:constructor(bl, tr)
  return o
end

function Rectangle:each()
  local x = self.bl[1] - 1
  local y = self.bl[2]
  local mx = self.tr[1]
  local my = self.tr[2]

  return function()
    x = x + 1
    if x > mx then x = self.bl[1]; y = y + 1 end
    if y <= my then return {x,y} end
  end
end

function Rectangle:outline()
  local bl, tr = self.bl, self.tr
  local h = tr[2] - bl[2] + 1

  return coroutine.wrap(function()
    local y
    if h > 0 then
      y = bl[2]
      for i=bl[1],tr[1] do coroutine.yield({i, y}) end
    end
    if h > 2 then
      for y=bl[2]+1,tr[2]-1 do
        coroutine.yield({bl[1], y})
        coroutine.yield({tr[1], y})
      end
    end
    if h > 1 then
      y = tr[2]
      for i=bl[1],tr[1] do coroutine.yield({i, y}) end
    end
  end)
end

function Rectangle:getStart()
  return self.bl
end

function Rectangle:getEnd()
  return self.tr
end

--[[
local db = DebugRenderer.new()

hook('init', function()
  local rect = Rectangle:create({-10, 5}, {-8, 7})
  for block in rect:each() do
    sb.logInfo("rect %s", sb.printJson(block))
  end
end)

hook('update', function()
  --local rect = Rectangle:create(tech.aimPosition(), vec2.add(tech.aimPosition(), 1))
  local rect = Rectangle:fromCenter(vec2.add(tech.aimPosition(), {-10, 0}), 7)
  for p in rect:each() do db:drawBlock(p, "#00ff0040") end
  for p in rect:outline() do db:drawBlock(p, "#ff000040") end
  rect  = Rectangle:fromCenter(vec2.add(tech.aimPosition(), {-20, 0}), 2)
  for p in rect:each() do db:drawBlock(p, "#00ff0040") end
  for p in rect:outline() do db:drawBlock(p, "#ff000040") end
end)
--]]
