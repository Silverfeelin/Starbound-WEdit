--- Starbound Object Class. Contains data of a placeable object.
-- Identifiable with tostring(obj).
local Object = {}
module = Object

Object.__index = Object
Object.__tostring = function() return "starboundObject" end

--- Creates and returns a Starbound object.. object.
-- The object values (i.e. parameters) are copied when the object is created.
-- Further changes to the object in the world won't change this Object.
-- @param id Entity id of the source object.
-- @param offset Offset from the bottom left corner of the copied area.
-- @return Starbound Object data. Contains id, offset, name, parameters, [items].
function Object.create(id, offset, name)
  if not id then error("WEdit: Attempted to create a Starbound Object object without a valid entity id") end
  if not offset then error(string.format("WEdit: Attempted to create a Starbound Object for (%s) without a valid offset", id)) end

  local object = {
    id = id,
    offset = offset
  }

  setmetatable(object, Object)

  object.name = name or object:getName()
  object.parameters = parameters or object:getParameters()
  object.items = object:getItems(true)

  return object
end

--- Returns the identifier of the object.
-- @return Object name.
function Object:getName()
  return world.entityName(self.id)
end

--- Returns the full parameters of the object.
-- @return Object parameters.
function Object:getParameters()
  return world.getObjectParameter(self.id, "", nil)
end

--- Returns the items of the container object, or nil if the object isn't a container.
-- @param clearTreasure If true, sets the treasurePools parameter to nil, to avoid random loot after breaking the object.
-- @return Contained items, or nil.
function Object:getItems(clearTreasure)
  if clearTreasure then self.parameters.treasurePools = nil end
  return self.parameters.objectType == "container" and world.containerItems(self.id) or nil
end
