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
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
	local result = old_ISInventoryPage_addContainerButton(self, container, texture, name, tooltip)
	
	local localContainer = ISInventoryPage.GetLocalContainer(self.player)

	if not self.onCharacter and container:getType() ~= "local" then
		local localItems = localContainer:getItems()
		local items = container:getItems()
		localItems:addAll(items)
	end

	if container:getType() == "floor" then
		localContainer = ISInventoryPage.GetLocalContainer(self.player)
		local title = "Proximity Inventory"
		local containerButton = self:addContainerButton(localContainer, getTexture("media/ui/ProximityInventory.png"), title, title)
		containerButton.capacity = 0
	end

	return result
end