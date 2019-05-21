--- Starbound Block Class.
-- Identifiable with tostring(obj).
local Block = {}
module = Block

Block.__index = Block
Block.__tostring = function() return "starboundBlock" end

--- Creates and returns a block object.
-- The block values (i.e. material) are copied when the object is created.
-- Further changes to the block in the world don't modify the instantiated Block.
-- @param position - Original position of the block.
-- @param offset - Offset from the bottom left corner of the copied area.
function Block.create(position, offset)
  if not position then error("WEdit: Attempted to create a Block object for a block without a valid original position.") end
  if not offset then error(string.format("WEdit: Attempted to create a Block object for a block at (%s, %s) without a valid offset.", position[1], position[2])) end

  local block = {
    position = position,
    offset = offset
  }

  setmetatable(block, Block)

  block.foreground = {
    material = block:getMaterial("foreground"),
    mod = block:getMod("foreground"),
  }
  if block.foreground.material then
    block.foreground.materialColor = block:getMaterialColor("foreground")
    block.foreground.materialHueshift = block:getMaterialHueshift("foreground")
  end

  block.background = {
    material = block:getMaterial("background"),
    mod = block:getMod("background")
  }
  if block.background.material then
    block.background.materialColor = block:getMaterialColor("background")
    block.background.materialHueshift = block:getMaterialHueshift("background")
  end

  block.liquid = block:getLiquid()

  return block
end

--- Returns the material name of this block, if any.
-- @param layer "foreground" or "background".
-- @return Material name in the given layer.
function Block:getMaterial(layer)
  return world.material(self.position, layer)
end

--- Returns the matmod name of this block, if any.
-- @param layer "foreground" or "background".
-- @return Matmod name in the given layer.
function Block:getMod(layer)
  return world.mod(self.position, layer)
end

function Block:getMaterialColor(layer)
  local color = world.materialColor(self.position, layer)
  return color ~= 0 and color
end

--- Returns the hueshift of this block.
-- If the material doesn't exist, this will still return 0.
-- @param layer "foreground" or "background".
-- @return Material hueshift.
function Block:getMaterialHueshift(layer)
  return world.materialHueShift(self.position, layer)
end

--- Returns the liquid datas of this block, if any.
-- @return Nil or liquid data: {liquidID, liquidAmnt}.
function Block:getLiquid()
  return world.liquidAt(self.position)
end
