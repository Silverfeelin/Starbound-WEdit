require "/interface/wedit/dyePicker/dyePickerUtil.lua"
require "/scripts/vec2.lua"

local wColors = "colors"
local widgetColorIndices = { none = -1, white = 0, black = 1, red = 2, orange = 3, yellow = 4, green = 5, blue = 6, pink = 7 }

local forceClosed = false

function init()
  -- Prevent multiples dye pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- weditController.lua forces them back to false on init.
  if status.statusProperty("wedit.dyePicker.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.dyePicker.open", true)
  loadSerializedColor()
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.dyePicker.open", false)
  end
end

function pickColor(_, data)
  dyePickerUtil.setSerializedColor(data)
end

-- Gets the color from the selected widget.
function getSelectedColor()
  local index = widget.getSelectedOption(wColors)
  local data = widget.getData(string.format("%s.%s", wColors, index))
  return data
end

-- Loads the serialized color and updates the widget selection.
function loadSerializedColor()
  local selectedColor = dyePickerUtil.getSerializedColor()
  if selectedColor then
    local selectionIndex = widgetColorIndices[selectedColor]
    if selectionIndex then
      -- Note: this will also call pickColor.
      widget.setSelectedOption(wColors, selectionIndex)
    end
  end
end