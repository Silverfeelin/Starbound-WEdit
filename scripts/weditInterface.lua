weditInterface = {}

local widgets = {
  noclipBind = "weditScroll.noClipBind",
  noclipSpeed = "weditScroll.noClipSpeed",
  iterationDelay = "weditScroll.iterationDelay",
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

function weditInterface.init()
  mui.setTitle("^shadow;WEdit", "^shadow;Configure settings.")
  mui.setIcon("/interface/wedit/icon.png")

  if not root.getConfigurationPath("wedit") then root.setConfigurationPath("wedit", {}) end

  widget.setText(widgets.noclipBind, weditInterface.getConfigData("noclipBind") or "g")
  widget.setText(widgets.noclipSpeed, weditInterface.getConfigData("noclipSpeed") or 0.75)
  widget.setText(widgets.iterationDelay, weditInterface.getConfigData("iterationDelay") or 15)
  widget.setChecked(widgets.doubleIterations, weditInterface.getConfigData("doubleIterations") or false)
  widget.setChecked(widgets.clearSchematics, false)
  widget.setText(widgets.lineSpacing, weditInterface.getConfigData("lineSpacing") or 1)
  widget.setSelectedOption(widgets.brushShape, weditInterface.getConfigData("brushShapeIndex") or -1)
  widget.setText(widgets.pencilSize, weditInterface.getConfigData("pencilSize") or 1)
  widget.setText(widgets.blockSize, weditInterface.getConfigData("blockSize") or 1)
  widget.setText(widgets.matmodSize, weditInterface.getConfigData("matmodSize") or 1)
end

function weditInterface.setConfigData(key, value)
  root.setConfigurationPath("wedit." .. key, value)
  root.setConfigurationPath("wedit.updateConfig", true)
end

function weditInterface.getConfigData(key)
  return root.getConfigurationPath("wedit." .. key)
end

function weditInterface.changeNoClipBind()
  weditInterface.setConfigData("noclipBind", widget.getText(widgets.noclipBind))
end

function weditInterface.changeNoClipSpeed()
  local speed = tonumber(widget.getText(widgets.noclipSpeed)) or 0.75
  weditInterface.setConfigData("noclipSpeed", speed)
end

function weditInterface.changeIterationDelay()
  local delay = tonumber(widget.getText(widgets.iterationDelay)) or 15
  weditInterface.setConfigData("iterationDelay", math.ceil(delay))
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
