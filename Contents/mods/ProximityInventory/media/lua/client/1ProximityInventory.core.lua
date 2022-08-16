ProxInv = {}
ProxInv.isToggled = true
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
	-- This forces a refreshBackpacks call
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

ProxInv.populateContextMenuOptions = function (context, player)
	local toggleText = ProxInv.isToggled and "OFF" or "ON" 
	local option = context:addOption("Toggle "..toggleText, ProxInv.isToggled, ProxInv.toggleState)
	option.iconTexture = getTexture("media/ui/Panel_Icon_Gear.png");
end