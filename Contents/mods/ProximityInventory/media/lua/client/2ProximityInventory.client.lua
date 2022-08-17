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

local old_ISInventoryPage_GetFloorContainer = ISInventoryPage.GetFloorContainer
function ISInventoryPage.GetFloorContainer(playerNum)
	local localContainer = ISInventoryPage.GetLocalContainer(playerNum)
	local container = localContainer
	container:removeItemsFromProcessItems()
	container:clear()

	return old_ISInventoryPage_GetFloorContainer(playerNum)
end

local old_ISInventoryPage_addContainerButton = ISInventoryPage.addContainerButton
ISInventoryPage.canInjectButton = true;
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
	local resultButton = old_ISInventoryPage_addContainerButton(self, container, texture, name, tooltip)
	local playerObj = getSpecificPlayer(self.player)
	-- Ignore all the other stuff and return
	if self.onCharacter or playerObj:getVehicle() then
		return resultButton
	end

	local localContainer = ISInventoryPage.GetLocalContainer(self.player)

	if container:getType() == "floor" then
		local title = "Proximity Inv"
		local proxInvButton = old_ISInventoryPage_addContainerButton(self, localContainer, ProxInv.inventoryIcon, title, ProxInv.getTooltip())
		proxInvButton.capacity = 0
		proxInvButton:setY(self:titleBarHeight() - 1)
		
		if ProxInv.isToggled then
			ProxInv.resetContainerCache()
			-- Add All backpacks content except last which is proxInv
			for i = 1, (#self.backpacks - 1) do
				local invToAdd = self.backpacks[i].inventory
				if ProxInv.canBeAdded(invToAdd) then
					local items = invToAdd:getItems()
					proxInvButton.inventory:getItems():addAll(items)
					table.insert(ProxInv.containerCache, invToAdd)
				end
			end
		else
			-- Remove the backpack from the list
			table.remove(self.backpacks, #self.backpacks)
		end
	end

	resultButton:setY(resultButton:getY() + self.buttonSize);

	return resultButton
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

	if ProxInv.isForceSelected then
		self:setForceSelectedContainer(ISInventoryPage.GetLocalContainer(self.player))
	end

	self.coloredProxInventories = self.coloredProxInventories or {}

	for _, container in ipairs(self.coloredProxInventories) do
		if container:getParent() then
			container:getParent():setHighlighted(false)
		end
	end
	table.wipe(self.coloredProxInventories)

	if not self.isCollapsed and self.inventory:getType() == "local" then
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