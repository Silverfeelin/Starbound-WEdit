--- Loggers can be used to log information with a prefix or write information to the log map.
--
-- LICENSE
-- MIT License. https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

Logger = {}
Logger.__index = Logger

--- Instantates a new logger.
-- @param[opt=""] logPrefix Prefix for logged messages.  Should end with a space to separate prefix from message.
-- @param[opt=""] mapPrefix Prefix for setLogMap messages. Should end with a space to separate prefix from key.
-- @return Logger object.
function Logger.new(logPrefix, mapPrefix)
  local instance = {}
  setmetatable(instance, Logger)
  instance.logPrefix = logPrefix or ""
  instance.mapPrefix = mapPrefix or ""
  return instance
end

--- Logs a message using the given logging function after applying the logPrefix.
-- @param logFunction Function to log with, should support params (formatString, [formatValues ...]).
-- @param message Message to format.
-- @param [opt] ... Format values.
function Logger:log(logFunction, message, ...)
  message = self.logPrefix .. message
  logFunction(message, ...)
end

--- Logs a message using sb.logInfo.
-- @param message Message to format.
-- @param [opt] ... Format values.
-- @see Logger:log
function Logger:logInfo(message, ...)
  self:log(sb.logInfo, message, ...)
end

--- Logs a message using sb.logWarn
-- @param message Message to format.
-- @param [opt] ... Format values.
-- @see Logger:log
function Logger:logWarn(message, ...)
  self:log(sb.logWarn, message, ...)
end

--- Logs a message using sb.logError
-- @param message Message to format.
-- @param [opt] ... Format values.
-- @see Logger:log
function Logger:logError(message, ...)
  self:log(sb.logError, message, ...)
end

--- Adds a value to the log map under the given key, after applying the mapPrefix.
-- This should be called repeatedly to keep the value on the log map.
-- @param key Log map key. Should be unique per value, otherwise the previous value will be overwritten.
-- @param value Log map value.
function Logger:setLogMap(key, value)
  key = self.mapPrefix .. key
  sb.setLogMap(key, value)
end
