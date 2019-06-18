local Rectangle = include("/scripts/wedit/objects/shapes/rectangle.lua")

local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local data = {
  selection = {{},{}},
  rawSelection = {}
}

local function Select()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Selection Tool")

  if SelectionHelper.isValid() then
    DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Remove selection.", {0,-2})
    local w, h = SelectionHelper.getEnd()[1] - SelectionHelper.getStart()[1], SelectionHelper.getEnd()[2] - SelectionHelper.getStart()[2]
    DebugRenderer.info:drawPlayerText(string.format("^shadow;^yellow;Current Selection: (^red;%s^yellow;x^red;%s^yellow;).", w, h), {0,-3})
  end

  -- RMB resets selection entirely
  if not InputHelper.isLocked() and InputHelper.alt then
    InputHelper.lock();
    data.stage = 0
    SelectionHelper.clear()
    return
  end

  if data.stage == 0 then
    -- Select stage 0: Not selecting.
    DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Select area.", {0,-1})
    DebugRenderer.instance:drawBlock(tech.aimPosition())

    if InputHelper.primary and not InputHelper.isLocked() then
      -- Start selection; set first point.
      data.stage = 1
      data.rawSelection[1] = tech.aimPosition()
    end
    return
  end

  if data.stage == 1 then
    -- Select stage 1: Selection started.
    DebugRenderer.info:drawPlayerText("^shadow;^yellow;Drag mouse and let go to select an area.", {0,-1})

    if not InputHelper.primary then
      data.stage = 0
      data.rawSelection = {}
      return
    end

    -- Dragging selection; update second point.
    data.rawSelection[2] = tech.aimPosition()

    -- Update converted coordinates.
    -- Compare X (1 is smallest):

    local bottomLeft = {
      math.floor(math.min(data.rawSelection[1][1], data.rawSelection[2][1])),
      math.floor(math.min(data.rawSelection[1][2], data.rawSelection[2][2]))
    }
    local topRight = {
     math.floor(math.max(data.rawSelection[1][1], data.rawSelection[2][1])),
     math.floor(math.max(data.rawSelection[1][2], data.rawSelection[2][2]))
    }

    SelectionHelper.set(Rectangle:create(bottomLeft, topRight))
    return
  end

  -- Select stage is not valid; reset it.
  data.stage = 0
end

module = {
  action = Select,
  data = data
}
