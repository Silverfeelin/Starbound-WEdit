-- TODO: REMOVE

local shapes = {}
module = shapes

--- For each block in a rectangle around a center position, calls callback.
-- @param position Center of the rectangle.
-- @param width Rectangle width.
-- @param [height=width] Rectangle height.
-- @param callback Function called for each block with parameter {x, y}.
-- @returns Table of all blocks.
function shapes.box(position, width, height, callback)
  height = height or width
  local blocks = {}
  local left, bottom  = (width - 1) / 2, (height - 1) / 2
  for x=0,width-1 do
    for y=0, height-1 do
      local block = {position[1] - left + x, position[2] - bottom + y}
      table.insert(blocks, block)
      if callback then callback(block) end
    end
  end
  return blocks
end

--- For each block between bottomLeft and topRight, calls callback.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param callback Function called with {x,y} for every block.
-- @returns Table of all blocks.
function shapes.rectangle(bottomLeft, topRight, callback)
  local bl, tr = vec2.floor(bottomLeft), vec2.floor(topRight)
  local blocks = {}
  for i=0, math.ceil(tr[1] - bl[1]) - 1 do
    for j=0, math.ceil(tr[2] - bl[2]) - 1 do
      local block = {bl[1] + i, bl[2] + j}
      table.insert(blocks, block)
      callback(block)
    end
  end
  return blocks
end

-- For each block in a circle around a position and radius, calls the callback function.
-- @param pos World center of the circle.
-- @param[opt=1] radius Circle radius in blocks.
-- @param callback Function called for each block with parameter {x, y}.
-- @returns Iterator
function shapes.circle(position, radius, callback)
  radius = radius and math.abs(radius) or 1
  local blocks = {}
  for y=-radius,radius do
    for x=-radius,radius do
      if (x*x)+(y*y) <= (radius*radius) then
        local block = {position[1] + x, position[2] + y}
        table.insert(blocks, block)
        callback(block)
      end
    end
  end
  return blocks
end

--- For each block in a line between two points, calls the callback function.
-- This uses the bresenham algorithm implementation by kikito.
-- Licensed under the MIT license: https://github.com/kikito/bresenham.lua/blob/master/MIT-LICENSE.txt.
-- @param startPos First position of the line.
-- @param endPos Second position of the line.
-- @param callback Function called for each block with parameters (x, y).
function shapes.line(startPos, endPos, callback)
  local x0, y0, x1, y1 = startPos[1], startPos[2], endPos[1], endPos[2]
  local sx, sy, dx, dy

  sx = x0 < x1 and 1 or -1
  dx = x0 < x1 and x1 - x0 or x0 - x1

  sy = y0 < y1 and 1 or -1
  dy = y0 < y1 and y1 - y0 or y0 - y1

  local err, e2 = dx-dy, nil

  callback(x0, y0)

  while not(x0 == x1 and y0 == y1) do
    e2 = err + err
    if e2 > -dy then
      err = err - dy
      x0  = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0  = y0 + sy
    end

    callback(x0, y0)
  end
end
