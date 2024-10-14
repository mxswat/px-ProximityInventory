ProxInv = {}
ProxInv.isToggled = true
ProxInv.isHighlightEnable = true
ProxInv.isForceSelected = false
ProxInv.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProxInv.forceSelectIcon = getTexture("media/ui/Panel_Icon_Pin.png")
ProxInv.highlightIcon = getTexture("media/textures/Item_LightBulb.png")
ProxInv.toggleState = function()
	ProxInv.isToggled = not ProxInv.isToggled
	ISInventoryPage.dirtyUI() -- This calls refreshBackpacks()
end
ProxInv.setForceSelected = function()
	ProxInv.isForceSelected = not ProxInv.isForceSelected
	ISInventoryPage.dirtyUI()
end
ProxInv.setHighlightEnable = function()
	ProxInv.isHighlightEnable = not ProxInv.isHighlightEnable
	ISInventoryPage.dirtyUI()
end
ProxInv.isLocalContainerSelected = false
ProxInv.buttonCache = nil
ProxInv.containerCache = {}
ProxInv.resetContainerCache = function()
	ProxInv.containerCache = {}
end

ProxInv.getTooltip = function()
	if ProxInv.isToggled then
		return getText("IGUI_ProxInv_Tooltip_ToggleOn")
	else
		return getText("IGUI_ProxInv_Tooltip_ToggleOff")
	end
end

ProxInv.zombieTypes = {
	inventoryfemale = true,
	inventorymale = true,
}

ProxInv.canBeAdded = function(container, playerObj)
	-- Do not allow if it's a stove or washer or similiar "Active things"
	-- It can cause issues like the item stops cooking or stops drying
	-- Also don't allow to see inside containers locked to you
	local object = container:getParent()

	if SandboxVars.ProxInv.ZombieOnly then
		return ProxInv.zombieTypes[container:getType()]
	end

	if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
		return false
	end

	return true
end

ProxInv.populateContextMenuOptions = function(context)
	local toggleText = ProxInv.isToggled
		and getText("IGUI_ProxInv_Context_ToggleOn")
		or getText("IGUI_ProxInv_Context_ToggleOff")
	local optToggle = context:addOption(toggleText, nil, ProxInv.toggleState)
	optToggle.iconTexture = ProxInv.isToggled and ProxInv.inventoryIcon or nil

	local forceSelectedText = ProxInv.isForceSelected
		and getText("IGUI_ProxInv_Context_ForceSelectOn")
		or getText("IGUI_ProxInv_Context_ForceSelectOff")
	local optForce = context:addOption(forceSelectedText, nil, ProxInv.setForceSelected)
	optForce.iconTexture = ProxInv.isForceSelected and ProxInv.forceSelectIcon or nil

	local highlightText = ProxInv.isHighlightEnable
		and getText("IGUI_ProxInv_Context_HighlightOn")
		or getText("IGUI_ProxInv_Context_HighlightOff")
	local optHighlight = context:addOption(highlightText, nil, ProxInv.setHighlightEnable)
	optHighlight.iconTexture = ProxInv.isHighlightEnable and ProxInv.highlightIcon or nil
end

ProxInv.OnButtonsAdded = function(invSelf)
	local playerObj = getSpecificPlayer(invSelf.player)

	local localContainer = ISInventoryPage.GetLocalContainer(invSelf.player)
	localContainer:clear()

	local title = getText("IGUI_ProxInv_InventoryName")
	local proxInvButton = invSelf:addContainerButton(localContainer, ProxInv.inventoryIcon, title, ProxInv.getTooltip())
	proxInvButton.capacity = 0
	proxInvButton:setY(invSelf:titleBarHeight() - 1)
	ProxInv.buttonCache = proxInvButton
	ProxInv.resetContainerCache()

	-- Add All backpacks content except last which is proxInv
	for i = 1, (#invSelf.backpacks - 1) do
		local buttonToPatch = invSelf.backpacks[i]
		local invToAdd = invSelf.backpacks[i].inventory
		if ProxInv.canBeAdded(invToAdd, playerObj) then
			local items = invToAdd:getItems()
			proxInvButton.inventory:getItems():addAll(items)
			table.insert(ProxInv.containerCache, invToAdd)
		end
		-- Since I'm looping here I might aswell also take care of patching all the buttons Y position
		buttonToPatch:setY(buttonToPatch:getY() + buttonToPatch:getHeight())
	end

	if not ProxInv.isToggled then
		-- Remove the backpack from the list
		table.remove(invSelf.backpacks, #invSelf.backpacks)
		return
	end

	if ProxInv.isToggled and ProxInv.isForceSelected then
		invSelf:setForceSelectedContainer(ISInventoryPage.GetLocalContainer(invSelf.player))
	end

	if ProxInv.isAsFirst then
		-- TODO: Am I even using this code???
		-- Remove from last
		local proxInvButton = table.remove(invSelf.backpacks, #invSelf.backpacks)
		-- Rebuild table and put it as first
		invSelf.backpacks = { proxInvButton, table.unpack(invSelf.backpacks) }
	end
end

ProxInv.OnBeginRefresh = function(invSelf)
	-- This avoid the generation of multiple buttons when it's off
	-- Since childrens gets removed via #invSelf.backpacks, and when it's toggled off the button does not appear
	-- in the #invSelf.backpacks
	if ProxInv.isToggled then
		return
	end
	invSelf:removeChild(ProxInv.buttonCache)
end

ProxInv.OnRefreshInventoryWindowContainers = function(invSelf, state)
	local playerObj = getSpecificPlayer(invSelf.player)
	if invSelf.onCharacter or playerObj:getVehicle() then
		-- Ignore character containers, as usual
		-- Ignore in vehicles
		return
	end

	if state == "begin" then
		return ProxInv.OnBeginRefresh(invSelf)
	end

	if state == "buttonsAdded" then
		return ProxInv.OnButtonsAdded(invSelf)
	end
end

Events.OnRefreshInventoryWindowContainers.Add(ProxInv.OnRefreshInventoryWindowContainers)

local KEY_ForceSelected = {
	name = "ProxInv_Force_Selected",
	key = Keyboard.KEY_NUMPAD0,
}

if ModOptions and ModOptions.AddKeyBinding then
	ModOptions:AddKeyBinding("[ProximityInventory]", KEY_ForceSelected)
end

local function OnKeyPressed(keynum)
	local player = getSpecificPlayer(0)
	if not player or not ModOptions then
		return
	end

	if keynum == KEY_ForceSelected.key then
		ProxInv.setForceSelected()
		local text = ProxInv.isForceSelected
			and getText("IGUI_ProxInv_Text_ForceSelectOn")
			or getText("IGUI_ProxInv_Text_ForceSelectOff")
		HaloTextHelper.addText(player, text, HaloTextHelper.getColorWhite())
		return
	end
end

Events.OnKeyPressed.Add(OnKeyPressed)

local old_ISCraftingUI_getContainers = ISCraftingUI.getContainers
function ISCraftingUI:getContainers()
	local result = old_ISCraftingUI_getContainers(self)
	if not self.character or not ProxInv.isToggled then
		return result
	end

	-- If ProxInv is enabled:
	local localContainer = ISInventoryPage.GetLocalContainer(self.playerNum)
	self.containerList:remove(localContainer);
	return result
end

local old_ISInventoryPaneContextMenu_getContainers = ISInventoryPaneContextMenu.getContainers
ISInventoryPaneContextMenu.getContainers = function(character)
	if not character or not ProxInv.isToggled then
		return old_ISInventoryPaneContextMenu_getContainers(character)
	end

	local containerList = old_ISInventoryPaneContextMenu_getContainers(character)
	local localContainer = ISInventoryPage.GetLocalContainer(character:getPlayerNum())
	-- If ProxInv is enabled:
	containerList:remove(localContainer);

	return containerList;
end
