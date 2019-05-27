local LiquidHelper = {
  names = {}
}
module = LiquidHelper

function LiquidHelper.getName(liquidId)
  if not LiquidHelper.names[liquidId] then
    local cfg = root.liquidConfig(liquidId)
    LiquidHelper.names[liquidId] = cfg and cfg.config.name
  end
  return LiquidHelper.names[liquidId]
end
