local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local data = {
  selection = {{}, {}},
  stage = 0
}

local function validLine()
  local line = data.selection
  if not line then return false end
  return not not (line[1] and line[1][1] and line[2] and line[2][1])
end


--- Function to draw a line of blocks between two selected points
local function Ruler()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Ruler")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Fill foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Fill background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Primary Fire: Create line.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Alt Fire: Clear line.", {0,-4})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Block: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-5})

  local line = data.selection

  -- Draw line
  if not data.selecting and InputHelper.shift and InputHelper.primary and not InputHelper.isShiftLocked() then
    InputHelper.shiftLock()

    -- Set first point
    line[1] = tech.aimPosition()
    line[2] = {}

    -- Start selecting second point
    data.selecting = true
    data.bindA = Bind.create("primaryFire", function()
      -- Dragging selection; update second point.
      line[2] = tech.aimPosition()

      -- Round each value down.
      line[1][1] = math.floor(line[1][1])
      line[2][1] = math.floor(line[2][1])
      line[1][2] = math.floor(line[1][2])
      line[2][2] = math.floor(line[2][2])
    end, true)
    data.bindB = Bind.create("primaryFire=false", function()
      data.bindA:unbind()
      data.bindA = nil
      data.bindB:unbind()
      data.bindB = nil
      data.selecting = false
    end)
  end

  -- Fill / Clear line
  if not InputHelper.isShiftLocked() and not data.selecting then
    if InputHelper.shift and InputHelper.alt then
      -- Clear line
      InputHelper.shiftLock()
      data.selection = {{},{}}
    elseif not InputHelper.shift then
      -- Fill line
      local layer = InputHelper.primary and "foreground" or InputHelper.alt and "background" or nil
      if layer and validLine() then
        InputHelper.shiftLock()
        local block = Palette.getMaterialName()
        if block ~= "air" and block ~= "none" then
          shapes.line(line[1], line[2], function(x, y) world.placeMaterial({x, y}, layer, block, 0, true) end)
        else
          shapes.line(line[1], line[2], function(x, y) world.damageTiles({{x,y}}, layer, {x,y}, "blockish", 9999, 0) end)
        end
      end
    end
  end

  -- Draw information
  if validLine() then
    -- Draw boxes around every block in the current selection.
    shapes.line(line[1], line[2],
    function(x, y)
      world.debugLine({x, y}, {x + 1, y}, "green")
      world.debugLine({x, y + 1}, {x + 1, y + 1}, "green")
      world.debugLine({x, y}, {x, y + 1}, "green")
      world.debugLine({x + 1, y}, {x + 1, y + 1}, "green")
    end)

    -- Calculate line length for display
    local w, h = math.abs(line[1][1] - line[2][1]) + 1, math.abs(line[1][2] - line[2][2]) + 1
    local length = w > h and w or h
    DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Length: ^red;" .. length .. " ^yellow;blocks ^red;(" .. w .. "x" .. h .. ")^yellow;.", {0,-6})
  end
end


module = {
  action = Ruler,
  data = data
}

