local AssetHelper = {}
module = AssetHelper

function AssetHelper.fixPath(path, file)
  return not path and file
          or file:find("^/") and file
          or (path .. file):gsub("//", "/")
end

function AssetHelper.oreParameters(shortDescription, description, category, inventoryIcon, rarity)
  rarity = rarity or "common"
   return {
     itemTags = jarray(),
     radioMessagesOnPickup = jarray(),
     learnBlueprintsOnPickup = jarray(),
     twoHanded = true,
     shortdescription = shortDescription,
     category = category,
     description = description,
     inventoryIcon = inventoryIcon,
     rarity = rarity
   }
end
