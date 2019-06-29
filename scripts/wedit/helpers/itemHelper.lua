local ItemHelper = {}
module = ItemHelper

function ItemHelper.oreParameters(shortDescription, description, category, inventoryIcon, rarity)
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

function ItemHelper.spawnOre(params)
  world.spawnItem("triangliumore", mcontroller.position(), 1, params)
end

function ItemHelper.setItemData(data)
  ItemHelper.itemData = data
end

function ItemHelper.getItemData()
  return ItemHelper.itemData
end
