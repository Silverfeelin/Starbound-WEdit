require "/scripts/vec2.lua"
require "/scripts/wedit/libs/include.lua"

local Shape = include("/scripts/wedit/objects/shapes/shape.lua")

local Circle = Shape:extend()
module = Circle

function Circle:constructor(center, radius)
  self.center = vec2.floor(center)
  self.radius = math.floor(radius)
end

local hline = function(xa, xb, y)
  for i=xa,xb do
    coroutine.yield({i, y})
  end
end

function Circle:each()
  -- Based on filled Midpoint algorithm by colinday (https://stackoverflow.com/a/24527943/8523745).
  return coroutine.wrap(function()
    local cx, cy = self.center[1], self.center[2]
    local r = self.radius
    local x = r;
    local y = 0;
    local radiusError = 1 - x;

    while (x >= y) do
      local startX = -x + cx;
      local endX = x + cx;
      hline(startX, endX, y + cy)
      if y ~= 0 then
        hline(startX, endX, -y + cy)
      end
      y = y + 1

        if (radiusError<0) then
            radiusError = radiusError + 2 * y + 1;
        else
            if (x >= y) then
                startX = -y + 1 + cx;
                endX = y - 1 + cx;
                hline( startX, endX,  x + cy );
                hline( startX, endX, -x + cy );
            end
            x = x - 1
            radiusError = radiusError+ 2 * (y - x + 1);
        end

    end
  end)
  --[[
  local r = self.radius
  local x, y = -r - 1, -r
  local sq = r * r
  local cx, cy = self.center[1], self.center[2]
  return coroutine.wrap(function()
    for x = -r, r do
      for y = -r, r do
        if x*x + y*y <= sq then
          coroutine.yield({cx + x, cy + y})
        end
      end
    end
  end)
  --]]
end

function Circle:outline()
  --- Based on Midpoint implementation by Stefan Dietz (https://codepen.io/sdvg/pen/oFACy).
  return coroutine.wrap(function()
    local x0, y0 = self.center[1], self.center[2]
    local x, y = self.radius, 0
    local radiusError = 1 - x

    while x >= y do
      coroutine.yield({x0 + x, y0 + y}, 1) -- [1] y0 A x0 E
      coroutine.yield({x0 - x, y0 - y}, 5) -- [5] y0 C x0 H
      if (x ~= y) then
        coroutine.yield({x0 + y, y0 + x}, 2) -- [2] y0 B x0 F
        coroutine.yield({x0 - y, y0 - x}, 6) -- [6] y0 D x0 G
      end
      if x ~= 0 and y ~= 0 then
        coroutine.yield({x0 - x, y0 + y}, 3) -- [3] y0 C x0 E
        coroutine.yield({x0 + x, y0 - y}, 7) -- [7] y0 A x0 H
        if (x ~= y) then
          coroutine.yield({x0 - y, y0 + x}, 4) -- [4] y0 B x0 G
          coroutine.yield({x0 + y, y0 - x}, 8) -- [8] y0 D x0 F
        end
      end
      y = y + 1
      if radiusError < 0 then
        radiusError = radiusError + 2 * y + 1
      else
        x = x - 1
        radiusError = radiusError + 2 * (y - x + 1)
      end
    end
  end)
  --]]
end

--[[
local db = DebugRenderer.new()

hook('update', function()
  local c = Circle:create(tech.aimPosition(), 3)
  local c2 = Circle:create(vec2.add(tech.aimPosition(), {10, 0}), 4)
  local i = 1

  for p in c:outline() do
    --sb.logInfo("%s [%s]", sb.printJson(p), i)
    db:drawBlock(vec2.add(p, {0, 10}), "#00ff0040")
    world.debugText(""..i, vec2.add(p, {0, 10}), "red")
    i = i + 1
  end
  for p,j in c:outline() do
    --sb.logInfo("%s [%s]", sb.printJson(p), j)
    db:drawBlock(p, "#ff000040")
  end
  for p in c2:each() do db:drawBlock(vec2.add(p, {0, 10}), "#00ff0040") end
  for p in c2:outline() do db:drawBlock(p, "#ff000040") end
end)
--]]
