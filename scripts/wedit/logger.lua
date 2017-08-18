--- Loggers can be used to log information with a prefix and write information to the log map.
Logger = {}
Logger.__index = Logger

function Logger.new(logPrefix, mapPrefix)
  local instance = {}
  setmetatable(instance, Logger)
  instance.logPrefix = logPrefix or ""
  instance.mapPrefix = mapPrefix or ""
  return instance
end

function Logger:log(logFunction, message, ...)
  message = self.logPrefix .. message
  logFunction(message, ...)
end

function Logger:logInfo(message, ...)
  self:log(sb.logInfo, message, ...)
end

function Logger:logWarn(message, ...)
  self:log(sb.logWarn, message, ...)
end

function Logger:logError(message, ...)
  self:log(sb.logError, message, ...)
end

function Logger:setLogMap(key, value)
  key = self.mapPrefix .. key
  sb.setLogMap(key, value)
end