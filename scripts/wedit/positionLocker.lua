--- Position lockers can be used to restrict actions at certain positions.
-- This is especially useful for preventing multiple asynchronous tasks at the same location.
-- The feature could be expanded on by supporting rectangles, since a lot of WEdit actions make use of rectangular selections.
--
-- LICENSE
-- MIT License. https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

PositionLocker = {}
PositionLocker.__index = PositionLocker

-- Rounds coordinates down, and optionally converts {x,y} into x,y.
-- @param x Coordinate x or table {x,y}.
-- @param[opt] y Coordinate y.
local function getCoordinates(x, y)
  if type(x) == "table" then
    x, y = x[1], x[2]
  end
  return math.floor(x), math.floor(y)
end

--- Instantiates a new position locker.
-- @return Position locker.
function PositionLocker.new()
  local instance = {}
  setmetatable(instance, PositionLocker)
  instance.positions = { foreground = {}, background = {} }
  return instance
end

--- Locks the given position.
-- Returns a value indicating whether the position got locked, or was already locked.
-- @param layer foreground or background.
-- @param x Horizontal world position or table {x,y}.
-- @param[opt] y Vertical world position.
-- @return True if the position was already locked, false otherwise.
function PositionLocker:lock(layer, x, y)
  x, y = getCoordinates(x, y)
  local pos = self.positions[layer]
  if not pos[x] then pos[x] = {} end
  if pos[x][y] then return false end
  pos[x][y] = true
  return true
end

--- Unlocks the given position.
-- Returns a value indicating whether the position got unlocked, or was already unlocked.
-- @param layer foreground or background.
-- @param x Horizontal world position or table {x,y}.
-- @param[opt] y Vertical world position.
function PositionLocker:unlock(layer, x, y)
  x, y = getCoordinates(x, y)
  local pos = self.positions[layer]
  local locked = pos[x] and pos[x][y]
  if locked then pos[x][y] = nil end
  return not not locked
end

--- Checks if the given position is locked.
-- @param layer foreground or background.
-- @param
function PositionLocker:locked(layer, x, y)
  x, y = getCoordinates(x, y)
  local pos = self.positions[layer]
  return pos[x] and not not pos[x][y] or false
end

--- Returns a value indicating whether positions are locked or not.
-- @return True if no positions are locked, false otherwise.
function PositionLocker:empty()
  return #self.positions.foreground == 0 and #self.positions.background == 0 or false
end

--- Clears all locked positions in both layers.
function PositionLocker:clear()
  self.positions = { foreground = {}, background = {} }
end
