local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

local function flipHorizontal(copy)
  for i=1, math.floor(#copy.blocks / 2) do
    for j,v in ipairs(copy.blocks[i]) do
      v.offset[1] = copy.size[1] - i
    end
    for j,v in ipairs(copy.blocks[#copy.blocks - i + 1]) do
      v.offset[1] = i - 1
    end
    copy.blocks[i], copy.blocks[#copy.blocks - i + 1] = copy.blocks[#copy.blocks - i + 1], copy.blocks[i]
  end

  -- Flip objects horizontally
  for i,v in ipairs(copy.objects) do
    v.offset[1] = copy.size[1] - v.offset[1]
    if v.parameters and v.parameters.direction then
      v.parameters.direction = v.parameters.direction == "right" and "left" or "right"
    end
  end

  copy.flipX = not copy.flipX
end

local function flipVertical(copy)
  for _,w in ipairs(copy.blocks) do
    for i=1, math.floor(#w / 2) do
      for j,v in ipairs(w[i]) do
        v.offset[1] = copy.size[1] - i
      end
      for j,v in ipairs(w[#w- i + 1]) do
        v.offset[1] = i - 1
      end
      w[i], w[#w- i + 1] = w[#w - i + 1], w[i]
    end
  end

  for i,v in ipairs(copy.objects) do
    v.offset[2] = copy.size[2] - v.offset[2]
  end

  copy.flipY = not copy.flipY
end

local function Flip()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Flip Tool")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Flip copy horizontally.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Flip copy vertically.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Flipping copies may cause issues with objects, matmods and liquids.", {0,-3})

  local c = storage.wedit_copy
  if not c then return end

  local msg = "^shadow;^yellow;Flipped: "
  local dir = c.flipX and c.flipY and "^red;Horizontally ^yellow;and ^red;Vertically"
           or c.flipX and "^red;Horizontally"
           or c.flipY and "^red;Vertically"
           or "None"
  DebugRenderer.info:drawPlayerText(msg .. dir, {0,-4})

  if InputHelper.isLocked() then return end
  if InputHelper.primary then
    InputHelper.lock()
    flipHorizontal(storage.wedit_copy)
  elseif InputHelper.alt then
    InputHelper.lock()
    flipVertical(storage.wedit_copy)
  end
end

module = {
  action = Flip,
  flipHorizontal = flipHorizontal,
  flipVertical = flipVertical
}
