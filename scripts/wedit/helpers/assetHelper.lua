local AssetHelper = {}
module = AssetHelper

function AssetHelper.fixPath(path, file)
  return not path and file
          or file:find("^/") and file
          or (path .. file):gsub("//", "/")
end
