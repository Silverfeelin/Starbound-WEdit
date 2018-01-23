--- Debug renderers can be used to render lines, points and text on the world.
-- Each rendered element lasts one frame.
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

require "/scripts/vec2.lua"

DebugRenderer = {}
DebugRenderer.__index = DebugRenderer
DebugRenderer.defaultColor = "green"

--- Instantiates a new debug renderer.
-- @return Debug renderer.
function DebugRenderer.new()
  local instance = {}
  setmetatable(instance, DebugRenderer)
  return instance
end

--- Draws a rectangle.
-- @param p1 Bottom left world position {x,y}.
-- @param p2 Top right world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawRectangle(p1, p2, color)
  color = color or self.defaultColor
  x1, y1, x2, y2 = math.floor(p1[1]), math.floor(p1[2]), math.ceil(p2[1]), math.ceil(p2[2])
  self:drawLine({x1, y2}, {x2, y2}, color) -- top edge
  self:drawLine({x1, y1}, {x1, y2}, color) -- left edge
  self:drawLine({x2, y1}, {x2, y2}, color) -- right edge
  self:drawLine({x1, y1}, {x2, y1}, color) -- bottom edge
end

--- Draws a rectangle around a block.
-- @param p Block world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawBlock(p, color)
  color = color or self.defaultColor
  local x1, y1 = math.floor(p[1]), math.floor(p[2])
  self:drawRectangle({x1, y1}, {x1 + 1, y1 + 1}, color)
end

--- Draws a line.
-- @param p1 First world position {x, y}.
-- @param p2 Second world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawLine(p1, p2, color)
  color = color or self.defaultColor
  world.debugLine(p1, p2, color)
end

--- Draws text in the world.
-- @param text Text to draw.
-- @param p World position.
-- @param[opt="green"] color Text color. String or {r,g,b}.
function DebugRenderer:drawText(text, p, color)
  color = color or self.defaultColor
  world.debugText(text, p, color)
end

--- Draws text relative to the player position.
-- @param text Text to draw.
-- @param offset Offset from the player position.
-- @parm[opt="green"] color Text color. String or {r,g,b}.
function DebugRenderer:drawPlayerText(text, offset, color)
  color = color or self.defaultColor
  offset = offset or {0, 0}
  local p = vec2.add(mcontroller.position(), offset)
  world.debugText(text, p, color)
end