require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

local inventoryIcon = getTexture("media/ui/ProximityInventory.png")

ProximityInventory = {}
ProximityInventory.isToggled = false
ProximityInventory.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProximityInventory.bannedTypes = {
	stove = true,
	fridge = true,
	freezer = true,
	barbecue = true,
	fireplace = true,
	woodstove = true,
	microwave = true,
}

ProximityInventory.canBeAdded = function (container, playerObj)
	-- Do not allow if it's a stove or washer or similiar "Active things"
	-- It can cause issues like the item stops cooking or stops drying
	-- Also don't allow to see inside containers locked to you
	local object = container:getParent()
	if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
		return false
	end

	return not ProximityInventory.bannedTypes[container:getType()]
end

function ISInventoryPage:toggleProximityInv()
	ProximityInventory.isToggled = not ProximityInventory.isToggled
	self:refreshBackpacks()
end

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
	if self.onCharacter or not ProximityInventory.isToggled then
		return old_ISInventoryPage_addContainerButton(self, container, texture, name, tooltip)
	end

	local localContainer = ISInventoryPage.GetLocalContainer(self.player)
	if ISInventoryPage.canInjectButton then
		ISInventoryPage.canInjectButton = false

		local title = "Proximity Inventory"
		local containerButton = self:addContainerButton(localContainer, inventoryIcon, title, title)
		containerButton.capacity = 0
		self:setForceSelectedContainer(containerButton.inventory)
	end

	local playerObj = getSpecificPlayer(self.player)
	if container:getType() ~= "local" and ProximityInventory.canBeAdded(container, playerObj) then
		local localItems = localContainer:getItems()
		local items = container:getItems()
		localItems:addAll(items)
	end

	if container:getType() == "floor" then
		ISInventoryPage.canInjectButton = true
	end

	-- can't cache the result, otherwise the prox inv won't be the first item
	return old_ISInventoryPage_addContainerButton(self, container, texture, name, tooltip)
end

local old_ISInventoryPage_createChildren = ISInventoryPage.createChildren
function ISInventoryPage:createChildren()
	local result = old_ISInventoryPage_createChildren(self)

	if not self.onCharacter then
		local lootButtonHeight = self:titleBarHeight()
		local removeAllRight = self.removeAll:getRight();
		local toggleStoveRight = self.toggleStove:getRight();
		local rightOffset = math.max(removeAllRight, toggleStoveRight);

		self.toggleProximityInv = ISButton:new(self.lootAll:getRight() + rightOffset + 16, 0, 50, lootButtonHeight, 'Toggle Proximity Inventory', self, ISInventoryPage.toggleProximityInv);
        self.toggleProximityInv:initialise();
        self.toggleProximityInv.borderColor.a = 0.0;
        self.toggleProximityInv.backgroundColor.a = 0.0;
        self.toggleProximityInv.backgroundColorMouseOver.a = 0.7;
        self:addChild(self.toggleProximityInv);
        self.toggleProximityInv:setVisible(true);
	end

	return result
end
