--- https://github.com/Silverfeelin/Starbound-WEdit

weditInterface = {}

local widgets = {
  noclipBind = "weditScroll.noClipBind",
  noclipSpeed = "weditScroll.noClipSpeed",
  delay = "weditScroll.delay",
  doubleIterations = "weditScroll.doubleIterations",
  clearSchematics = "weditScroll.clearSchematics",
  lineSpacing = "weditScroll.lineSpacing",
  brushShape = "weditScroll.brushShape",
  pencilSize = "weditScroll.pencilSize",
  blockSize = "weditScroll.blockSize",
  matmodSize = "weditScroll.matmodSize"
}

local brushShapes = {
  square = -1,
  circle = 0
}

function init()
  widget.setText(widgets.noclipBind, weditInterface.getConfigData("noclipBind") or "specialTwo")
  widget.setText(widgets.noclipSpeed, weditInterface.getConfigData("noclipSpeed") or 0.75)
  widget.setText(widgets.delay, weditInterface.getConfigData("delay") or 15)
  widget.setChecked(widgets.doubleIterations, weditInterface.getConfigData("doubleIterations") or false)
  widget.setChecked(widgets.clearSchematics, false)
  widget.setText(widgets.lineSpacing, weditInterface.getConfigData("lineSpacing") or 1)
  widget.setSelectedOption(widgets.brushShape, weditInterface.getConfigData("brushShapeIndex") or -1)
  widget.setText(widgets.pencilSize, weditInterface.getConfigData("pencilSize") or 1)
  widget.setText(widgets.blockSize, weditInterface.getConfigData("blockSize") or 1)
  widget.setText(widgets.matmodSize, weditInterface.getConfigData("matmodSize") or 1)
end

function weditInterface.setConfigData(key, value)
  local config = status.statusProperty("wedit") or {}
  config[key] = value
  status.setStatusProperty("wedit", config)

  world.sendEntityMessage(player.id(), "wedit.updateConfig")
end

function weditInterface.getConfigData(key)
  local config = status.statusProperty("wedit") or {}
  return key == nil and config or config[key]
end

function weditInterface.changeNoClipBind()
  weditInterface.setConfigData("noclipBind", widget.getText(widgets.noclipBind))
end

function weditInterface.changeNoClipSpeed()
  local speed = tonumber(widget.getText(widgets.noclipSpeed)) or 0.75
  weditInterface.setConfigData("noclipSpeed", speed)
end

function weditInterface.changeDelay()
  local delay = tonumber(widget.getText(widgets.delay)) or 15
  weditInterface.setConfigData("delay", math.ceil(delay))
end

function weditInterface.changeDoubleIterations()
  weditInterface.setConfigData("doubleIterations", widget.getChecked(widgets.doubleIterations))
end

function weditInterface.changeClearSchematics()
  weditInterface.setConfigData("clearSchematics", widget.getChecked(widgets.clearSchematics))
end

function weditInterface.changeLineSpacing()
  local spacing = tonumber(widget.getText(widgets.lineSpacing)) or 1
  weditInterface.setConfigData("lineSpacing", spacing)
end

function weditInterface.changeBrushShape(_, data)
  weditInterface.setConfigData("brushShapeIndex", brushShapes[data])
  weditInterface.setConfigData("brushShape", data)
end

function weditInterface.changePencilSize()
  local size = tonumber(widget.getText(widgets.pencilSize)) or 1
  weditInterface.setConfigData("pencilSize", size)
end

function weditInterface.changeBlockSize()
  local size = tonumber(widget.getText(widgets.blockSize)) or 1
  weditInterface.setConfigData("blockSize", size)
end

function weditInterface.changeMatmodSize()
  local size = tonumber(widget.getText(widgets.matmodSize)) or 1
  weditInterface.setConfigData("matmodSize", size)
end
