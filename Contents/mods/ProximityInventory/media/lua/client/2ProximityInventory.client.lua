require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

function ISInventoryPage:toggleProximityInv()
	ProxInv.isToggled = not ProxInv.isToggled
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
	if self.onCharacter then
		return old_ISInventoryPage_addContainerButton(self, container, texture, name, tooltip)
	end

	local localContainer = ISInventoryPage.GetLocalContainer(self.player)
	if ISInventoryPage.canInjectButton then
		ISInventoryPage.canInjectButton = false
		ProxInv.resetContainerCache()

		local title = "Proximity Inv"
		local tooltip = "Right click for settings"
		local containerButton = self:addContainerButton(localContainer, ProxInv.inventoryIcon, title, tooltip)
		containerButton.capacity = 0

		if not ProxInv.isToggled then
			containerButton.onclick = nil
			containerButton.onmousedown = nil
			containerButton:setOnMouseOverFunction(nil)
			containerButton:setOnMouseOutFunction(nil)
			containerButton.textureOverride = getTexture("media/ui/lock.png")
		end
	end

	local playerObj = getSpecificPlayer(self.player)
	if container:getType() ~= "local" and ProxInv.canBeAdded(container, playerObj) then
		table.insert(ProxInv.containerCache, container)
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

		self.toggleProximityInv = ISButton:new(self.lootAll:getRight() + 16, 0, 50, lootButtonHeight, 'Toggle Proximity Inventory', self, ISInventoryPage.toggleProximityInv);
        self.toggleProximityInv:initialise();
        self.toggleProximityInv.borderColor.a = 0.0;
        self.toggleProximityInv.backgroundColor.a = 0.0;
        self.toggleProximityInv.backgroundColorMouseOver.a = 0.7;
        self:addChild(self.toggleProximityInv);
        self.toggleProximityInv:setVisible(true);
	end

	return result
end

local old_ISInventoryPage_onBackpackRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
function ISInventoryPage:onBackpackRightMouseDown(x, y)
	local result = old_ISInventoryPage_onBackpackRightMouseDown(self, x, y)
	local page = self.parent
	local container = self.inventory

	if container:getType() == "local" then
		local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())
		ProxInv.populateContextMenuOptions(context, self.player)
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

	local removeAllRight = self.removeAll:getIsVisible() and self.removeAll:getRight() or 0;
	local toggleStoveRight = self.toggleStove:getIsVisible() and self.toggleStove:getRight() or 0;
	local rightOffset = Math.max(self.lootAll:getRight() + 16, removeAllRight + toggleStoveRight + 16)

	self.toggleProximityInv:setX(rightOffset)

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