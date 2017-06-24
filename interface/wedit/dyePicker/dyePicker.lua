local holding = false

function canvasClickEvent(position, button, isButtonDown)
  sb.logInfo(" Button %s", button)
  if button == 0 then
    holding = isButtonDown
  elseif button == 2 and isButtonDown then
    clearColor()
  end
end

require "/interface/wedit/dyePicker/spectrum.lua"
require "/scripts/vec2.lua"

local canvas
local position = {-1,-1}

function init()
  canvas = widget.bindCanvas("eventCanvas")

  local serializedPos = status.statusProperty("wedit.dyePicker.position")
  if serializedPos then selectColor(serializedPos) end

  status.setStatusProperty("wedit.dyePicker.open", true)
end

function update()
  if holding then
    local pos = canvas:mousePosition()
    if not vec2.eq(position, pos) then
      selectColor(pos)
      position = pos
    end
  end
end

function uninit()
  status.setStatusProperty("wedit.dyePicker.open", false)
end

function selectColor(pos)
  status.setStatusProperty("wedit.dyePicker.position", pos)

  -- Clamp position within canvas bounds
  local clampedPos = {
    clamp(pos[1], 0, 157),
    clamp(pos[2], 0, 54)
  }
  -- Invert Y
  local colorPos = {clampedPos[1] + 1, 54 - clampedPos[2] + 1}

  if pos[1] < 1 then pos[1] = 1 end
  if pos[2] < 1 then pos[2] = 1 end
  if pos[1] > 141 then pos[1] = pos[1] - 16 end
  if pos[1] > 141 then pos[1] = 141 end
  if pos[2] > 38 then pos[2] = pos[2] - 16 end
  if pos[2] > 38 then pos[2] = 38 end

  -- Get color
  local color = spectrum[colorPos[1]][colorPos[2]]
  status.setStatusProperty("wedit.dyePicker.color", color)

  -- Set image
  local img = "/interface/wedit/dyePicker/indicator.png?replace;ffffff="..num2hex(color[1])..num2hex(color[2])..num2hex(color[3])
  canvas:clear()
  canvas:drawImage(img, pos)

  position = pos
end

function clearColor()
  canvas:clear()
  status.setStatusProperty("wedit.dyePicker.position", nil)
  status.setStatusProperty("wedit.dyePicker.color", nil)
end

-- http://snipplr.com/view/13086/number-to-hex/
function num2hex(num)
    local hexstr = "0123456789abcdef"
    local s = ""
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == "" then s = "00" end
    if string.len(s) == 1 then s = "0" .. s end
    return s
end

--[[
  Clamps and returns a value between the minimum and maximum value.
  @param i - Value to clamp.
  @param low - Minimum bound (inclusive).
  @param high - Maximum bound (inclusive).
  @return - low when i<low, high when i>high, or i.
]]
function clamp(i, low, high)
  if low > high then low, high = high, low end
  return math.min(high, math.max(low, i))
end