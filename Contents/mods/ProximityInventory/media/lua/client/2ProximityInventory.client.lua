function ISInventoryPage.GetLocalContainer(playerNum)
	if ISInventoryPage.localContainer == nil then
		ISInventoryPage.localContainer = {}
	end
	if ISInventoryPage.localContainer[playerNum+1] == nil then
		ISInventoryPage.localContainer[playerNum+1] = ItemContainer.new("local", nil, nil, 10, 10)
		ISInventoryPage.localContainer[playerNum+1]:setExplored(true)
		ISInventoryPage.localContainer[playerNum+1]:setOnlyAcceptCategory("none")
	end
	return ISInventoryPage.localContainer[playerNum+1]
end

local old_ISInventoryPage_onBackpackRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
function ISInventoryPage:onBackpackRightMouseDown(x, y)
	local result = old_ISInventoryPage_onBackpackRightMouseDown(self, x, y)
	local page = self.parent
	local container = self.inventory

	if container:getType() == "local" then
		local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())
		ProxInv.populateContextMenuOptions(context, self)
	end

	return result
end

local old_ISInventoryPage_update = ISInventoryPage.update
function ISInventoryPage:update()
	local result = old_ISInventoryPage_update(self)

	if self.onCharacter then
		return result
	end

	self.coloredProxInventories = self.coloredProxInventories or {}

	for _, container in ipairs(self.coloredProxInventories) do
		if container:getParent() then
			container:getParent():setHighlighted(false)
		end
	end
	table.wipe(self.coloredProxInventories)

	if ProxInv.isHighlightEnable and not self.isCollapsed and self.inventory:getType() == "local" then
		for _, container in ipairs(ProxInv.containerCache) do
			if container:getParent() and (instanceof(container:getParent(), "IsoObject") or instanceof(container:getParent(), "IsoDeadBody")) then
				container:getParent():setHighlighted(true, false)
				container:getParent():setHighlightColor(getCore():getObjectHighlitedColor())
				table.insert(self.coloredProxInventories, container)
			end
		end
	end

	return result
end