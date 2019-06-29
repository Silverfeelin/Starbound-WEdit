require "/scripts/messageutil.lua"

local Config = include("/scripts/wedit/helpers/config.lua")

local BrushHelper = {}
module = BrushHelper

function BrushHelper.getShape()
  return BrushHelper.userCfg.shape or BrushHelper.cfg.shape
end

function BrushHelper.getPencilSize()
  return BrushHelper.userCfg.pencilSize or BrushHelper.cfg.pencilSize
end

function BrushHelper.getBlockSize()
  return BrushHelper.userCfg.blockSize or BrushHelper.cfg.blockSize
end

function BrushHelper.getModSize()
  return BrushHelper.userCfg.modSize or BrushHelper.cfg.modSize
end

hook("init", function()
  BrushHelper.cfg = Config.fromFile("/scripts/wedit/wedit.config", true).data.brush
  BrushHelper.userCfg = Config.fromStatus("wedit.brush", {}).data

  message.setHandler("wedit.updateBrush", localHandler(function() 
    BrushHelper.userCfg = Config.fromStatus("wedit.brush", {}).data
  end))
end)