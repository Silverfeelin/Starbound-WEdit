require "/interface/wedit/huePicker/huePickerUtil.lua"

local wHue = "hue"

local forceClosed = false

function init()
  if status.statusProperty("wedit.huePicker.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.huePicker.open", true)
  loadSerializedHue()
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.huePicker.open", nil)
  end
end

function pickHue(_, data)
  local h = widget.getSliderValue(wHue)
  widget.setText("lblValue", h)
  widget.setImage("imgPreview", widget.getData("imgPreview") .. "?hueshift=" .. math.floor(h * 360 / 255))
  huePickerUtil.serializeHue(h)
end

-- Gets the color from the selected widget.
function getSelectedHue()
  local hue = widget.getSliderValue(wHue)
  return math.floor(hue)
end

-- Loads the serialized color and updates the widget selection.
function loadSerializedHue()
  local h = huePickerUtil.getSerializedHue() or 0
  widget.setSliderValue(wHue, h)
  widget.setText("lblValue", h)
end
