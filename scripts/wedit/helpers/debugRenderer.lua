require "/scripts/vec2.lua"
require "/scripts/wedit/libs/scriptHooks.lua"

--- Debug renderers can be used to render lines, points and text on the world.
-- Each rendered element lasts one frame.
local DebugRenderer = {}
module = DebugRenderer

DebugRenderer.__index = DebugRenderer
DebugRenderer.defaultColor = "green"

--- Instantiates a new debug renderer.
-- @return Debug renderer.
function DebugRenderer:new()
  local instance = { enabled = true }
  setmetatable(instance, self)
  return instance
end

--- Draws a rectangle.
-- @param p1 Bottom left world position {x,y}.
-- @param p2 Top right world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawRectangle(p1, p2, color)
  if not self.enabled then return end
  color = color or self.defaultColor
  x1, y1, x2, y2 = math.floor(p1[1]), math.floor(p1[2]), math.ceil(p2[1]) + 1, math.ceil(p2[2]) + 1
  self:drawLine({x1, y2}, {x2, y2}, color) -- top edge
  self:drawLine({x1, y1}, {x1, y2}, color) -- left edge
  self:drawLine({x2, y1}, {x2, y2}, color) -- right edge
  self:drawLine({x1, y1}, {x2, y1}, color) -- bottom edge
end

--- Draws a rectangle around a block.
-- @param p Block world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawBlock(p, color)
  if not self.enabled then return end
  color = color or self.defaultColor
  local x1, y1 = math.floor(p[1]), math.floor(p[2])
  self:drawRectangle({x1, y1}, {x1, y1}, color)
end

--- Draws a line.
-- @param p1 First world position {x, y}.
-- @param p2 Second world position {x, y}.
-- @param[opt="green"] color Line color. String or {r,g,b}.
function DebugRenderer:drawLine(p1, p2, color)
  if not self.enabled then return end
  color = color or self.defaultColor
  world.debugLine(p1, p2, color)
end

--- Draws text in the world.
-- @param text Text to draw.
-- @param p World position.
-- @param[opt="green"] color Text color. String or {r,g,b}.
function DebugRenderer:drawText(text, p, color)
  if not self.enabled then return end
  color = color or self.defaultColor
  world.debugText(text, p, color)
end

--- Draws text relative to the player position.
-- @param text Text to draw.
-- @param offset Offset from the player position.
-- @parm[opt="green"] color Text color. String or {r,g,b}.
function DebugRenderer:drawPlayerText(text, offset, color)
  if not self.enabled then return end
  color = color or self.defaultColor

  offset = offset or {0, 0}
  local lineSpacing = status.statusProperty("wedit.info.lineSpacing") or 1
  offset[2] = offset[2] * lineSpacing

  local pos = vec2.add(mcontroller.position(), {0, -3})
  pos = vec2.add(pos, offset)
  world.debugText(text, pos, color)
end

-- Shared instance
DebugRenderer.instance = DebugRenderer:new()
DebugRenderer.info = DebugRenderer:new()

hook("init", function()
  message.setHandler("wedit.showInfo", localHandler(function(enabled)
    DebugRenderer.info.enabled = enabled
    status.setStatusProperty("wedit.showingInfo", bool)
  end))
end)
