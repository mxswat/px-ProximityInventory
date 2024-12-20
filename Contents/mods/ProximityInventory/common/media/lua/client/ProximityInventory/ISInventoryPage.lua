local old_ISInventoryPage_update = ISInventoryPage.update
function ISInventoryPage:update()
  old_ISInventoryPage_update(self)

  if not ProximityInventory.isEnabled:getValue() or self.onCharacter then return end

  -- I know I kept some good separation between the mod code and the game code, 
  -- but just injecting the table is is SOO much simpler, so I'll just inject it here
  self.coloredProxInventories = self.coloredProxInventories or {}

  for _, container in ipairs(self.coloredProxInventories) do
    local parent = container:getParent()
    if parent then
      parent:setHighlighted(false)
      parent:setOutlineHighlight(false);
      parent:setOutlineHlAttached(false);
    end
  end

  table.wipe(self.coloredProxInventories)

  if not ProximityInventory.isHighlightEnableOption:getValue() or self.isCollapsed or self.inventory:getType() ~= "proxInv" then return end

  for _, button in ipairs(self.backpacks) do
    local container = button.inventory
    local parent = container:getParent()
    if parent and (instanceof(parent, "IsoObject") or instanceof(parent, "IsoDeadBody")) then
      parent:setHighlighted(true, false)
      parent:setHighlightColor(getCore():getObjectHighlitedColor())
      table.insert(self.coloredProxInventories, container)
    end
  end
end
