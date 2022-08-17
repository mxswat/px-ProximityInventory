require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

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

	if #self.backpacks == 0 then
		-- clean cache
		ProxInv.resetContainerCache()
	end

	local localContainer = ISInventoryPage.GetLocalContainer(self.player)

	if ProxInv.isToggled and container:getType() ~= "local" and ProxInv.canBeAdded(container, playerObj) then
		table.insert(ProxInv.containerCache, container)
		local localItems = localContainer:getItems()
		local items = container:getItems()
		localItems:addAll(items)
	end

	if container:getType() == "floor" then
		local title = "Proximity Inv"
		local proxInvButton = old_ISInventoryPage_addContainerButton(self, localContainer, ProxInv.inventoryIcon, title, ProxInv.getTooltip())
		proxInvButton.capacity = 0
		proxInvButton:setY(self:titleBarHeight() - 1)
		if not ProxInv.isToggled then
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

	ProxInv.isLocalContainerSelected = self.inventoryPane.inventory == ISInventoryPage.GetLocalContainer(self.player)

	if ProxInv.isForceSelected then
		self:setForceSelectedContainer(ISInventoryPage.GetLocalContainer(self.player))
	end

	return result
end

local function OnTick()
	if not ProxInv.isToggled or not ProxInv.isLocalContainerSelected then
		return
	end

	for _, container in ipairs(ProxInv.containerCache) do
		local isoObject = container:getParent()
		if isoObject then
			isoObject:setHighlighted(true);
			isoObject:setHighlightColor(getCore():getObjectHighlitedColor());
		end
	end
end

Events.OnTick.Add(OnTick)