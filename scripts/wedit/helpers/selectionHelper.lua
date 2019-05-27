require "/scripts/wedit/libs/scriptHooks.lua"

local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")

local SelectionHelper = {}
module = SelectionHelper

SelectionHelper.selection = nil

function SelectionHelper.isValid()
  return not not SelectionHelper.selection
end

function SelectionHelper.get()
  return SelectionHelper.selection
end

function SelectionHelper.getStart()
  return SelectionHelper.selection and SelectionHelper.selection.bl
end

function SelectionHelper.getEnd()
  return SelectionHelper.selection and SelectionHelper.selection.tr
end

function SelectionHelper.set(rect)
  SelectionHelper.selection = rect
end

function SelectionHelper.clear()
  SelectionHelper.selection = nil
end

hook("update", function()
  if not SelectionHelper.isValid() then return end
  local s, e = SelectionHelper.getStart(), SelectionHelper.getEnd()
  DebugRenderer.instance:drawRectangle(s, e)
  DebugRenderer.instance:drawText(
    string.format("^shadow;WEdit Selection (%sx%s)", e[1] - s[1] + 1, e[2] - s[2] + 1),
    { s[1], e[2] + 1 },
    "green"
  )
end)
