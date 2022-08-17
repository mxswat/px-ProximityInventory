ProxInv = {}
ProxInv.isToggled = true
ProxInv.isHighlightToggled = false
ProxInv.isForceSelected = false
ProxInv.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProxInv.bannedTypes = {
	stove = true,
	fridge = true,
	freezer = true,
	barbecue = true,
	fireplace = true,
	woodstove = true,
	microwave = true,
}
ProxInv.toggleState = function ()
	ProxInv.isToggled = not ProxInv.isToggled
	ISInventoryPage.dirtyUI() -- This calls refreshBackpacks()
end
ProxInv.setHighlightToggled = function ()
	ProxInv.isHighlightToggled = not ProxInv.isHighlightToggled
	ISInventoryPage.dirtyUI() -- This calls refreshBackpacks()
end
ProxInv.setForceSelected = function ()
	ProxInv.isForceSelected = not ProxInv.isForceSelected
	-- This is handled Inventory side
	ISInventoryPage.dirtyUI()
end
ProxInv.isLocalContainerSelected = false
ProxInv.containerCache = {}
ProxInv.resetContainerCache = function ()
	-- Removes the hightlight
	for _, container in ipairs(ProxInv.containerCache) do
		local isoObject = container:getParent()
		if isoObject then
			isoObject:setHighlighted(false);
		end
	end
	-- Reset cache
	ProxInv.containerCache = {}
end

ProxInv.getTooltip = function ()
	local text = "Right click for settings"
	text = not ProxInv.isToggled and "Disabled - "..text or text
	return text
end

ProxInv.canBeAdded = function (container, playerObj)
	-- Do not allow if it's a stove or washer or similiar "Active things"
	-- It can cause issues like the item stops cooking or stops drying
	-- Also don't allow to see inside containers locked to you
	local object = container:getParent()
	if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
		return false
	end

	return not ProxInv.bannedTypes[container:getType()]
end

ProxInv.populateContextMenuOptions = function (context)
	local toggleText = ProxInv.isToggled and "OFF" or "ON" 
	local optToggle = context:addOption("Toggle "..toggleText, nil, ProxInv.toggleState)
	-- option.iconTexture = getTexture("media/ui/Panel_Icon_Gear.png");
	optToggle.iconTexture = ProxInv.inventoryIcon;

	local forceSelText = ProxInv.isForceSelected and "Disable" or "Enable" 
	local optForce = context:addOption(forceSelText.." Force Selected", nil, ProxInv.setForceSelected)
	optForce.iconTexture = ProxInv.inventoryIcon;

	local highlightToggleText = ProxInv.isHighlightToggled and "Disable" or "Enable" 
	local optHightlight = context:addOption(highlightToggleText.." Hightlight", nil, ProxInv.setHighlightToggled)
	optHightlight.iconTexture = ProxInv.inventoryIcon;
end