local HueshiftHelper = {}
module = HueshiftHelper

--- Gets the hueshift of a neighbouring same block.
-- Checks adjacent blocks above, to the left, right, below, behind or in front of the given block.
-- If the block matches the given block (or block at the position and layer), return the hueshift of the block.
-- This can be used by tools such as the pencil, to fill in terrain that uses the natural world block colors.
-- @param pos Block position.
-- @param layer "foreground" or "background".
-- @param[opt] Material name. If omitted, uses the block at pos in layer.
-- @return Hueshift of same neighboring block, or 0.
function HueshiftHelper.neighbor(pos, layer, block)
  if type(block) == "nil" then block = world.material(pos, layer) end
  if not block then return 0 end -- air

  local positions = {
    {pos[1], pos[2] - 1},
    {pos[1], pos[2] + 1},
    {pos[1] - 1, pos[2]},
    {pos[1] + 1, pos[2]}
  }

  -- Adjacent
  for _,position in ipairs(positions) do
    if world.material(position, layer) == block then
      return world.materialHueShift(position, layer)
    end
  end

  -- Opposite layer
  local oLayer = layer == "foreground" and "background" or "foreground"
  if world.material(pos, oLayer) == block then
    return world.materialHueShift(pos, oLayer)
  end

  return 0
end
