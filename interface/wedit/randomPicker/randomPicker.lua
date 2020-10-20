require "/interface/wedit/randomPicker/randomPickerUtil.lua"

local wPerc = "percentage"

local forceClosed = false

function init()
  if status.statusProperty("wedit.randomPicker.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.randomPicker.open", true)
  loadSerializedPercentage()
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.randomPicker.open", nil)
  end
end

function pickPercentage(_, data)
  local h = widget.getSliderValue(wPerc)
  widget.setText("lblValue", h)
  randomPickerUtil.serializePercentage(h)
end

-- Loads the serialized color and updates the widget selection.
function loadSerializedPercentage()
  local p = randomPickerUtil.getSerializedPercentage() or 0
  widget.setSliderValue(wPerc, p)
  widget.setText("lblValue", p)
end
