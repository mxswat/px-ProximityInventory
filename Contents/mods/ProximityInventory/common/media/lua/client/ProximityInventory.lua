ProximityInventory = ProximityInventory or {}

-- Consts
ProximityInventory.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProximityInventory.forceSelectIcon = getTexture("media/ui/Panel_Icon_Pin.png")
ProximityInventory.highlightIcon = getTexture("media/textures/Item_LightBulb.png")

---@type { [number]: ItemContainer? }
ProximityInventory.itemContainer = {}
---@type { [number]: ISButton? } -- Reference of the button in the UI for each player
ProximityInventory.inventoryButtonRef = {}
---@type { [number]: ItemContainer? } -- Reference of the containers added to the proxInv container, used for highlighting
ProximityInventory.highlightContainers = {}


---@param container ItemContainer
---@param playerObj IsoPlayer
function ProximityInventory.CanBeAdded(container, playerObj)
	local object = container:getParent()

	if SandboxVars.ProximityInventory.ZombieOnly then
		return container:getType() == "inventoryfemale" or container:getType() == "inventorymale"
	end

	-- Don't allow to see inside containers locked to you, for MP
	if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
		return false
	end

	return true
end

---@param invSelf ISInventoryPage
function ProximityInventory.GetItemContainer(invSelf)
	local playerNum = invSelf.player --[[@as number]]

	if ProximityInventory.itemContainer[playerNum] then
		return ProximityInventory.itemContainer[playerNum]
	end

	ProximityInventory.itemContainer[playerNum] = ItemContainer.new("proxInv", nil, nil, 10, 10)
	ProximityInventory.itemContainer[playerNum]:setExplored(true)
	ProximityInventory.itemContainer[playerNum]:setOnlyAcceptCategory("none") -- Ensures you can't put stuff in it

	return ProximityInventory.itemContainer[playerNum]
end

---@param invSelf ISInventoryPage
---@return ISButton
function ProximityInventory.AddProximityInventoryButton(invSelf)
	local itemContainer = ProximityInventory.GetItemContainer(invSelf)
	itemContainer:clear() -- We want to reset the proxinv between refreshes

	local title = getText("IGUI_ProxInv_InventoryName")

	local proxInvButton = invSelf:addContainerButton(
		itemContainer,
		ProximityInventory.inventoryIcon,
		title,
		'ProxInv.getTooltip()'
	)

	return proxInvButton
end

---Adds the button at the top of the list of the containers, so that it always appears as first
---@param invSelf ISInventoryPage
function ProximityInventory.OnBeginRefresh(invSelf)
	local proxInvButton = ProximityInventory.AddProximityInventoryButton(invSelf)

	-- We will need this ref for after the button are added
	ProximityInventory.inventoryButtonRef[invSelf.player] = proxInvButton
end

---TODO Maybe Re-work this? We I could hook into ISInventoryPage:addContainerButton and insert the items from there, it could save us some performance
---@param invSelf ISInventoryPage
function ProximityInventory.OnButtonsAdded(invSelf)
	local proximityButtonRef = ProximityInventory.inventoryButtonRef[invSelf.player]
	if not proximityButtonRef then return end -- something must have gone wrong if this returns here

	local playerObj = getSpecificPlayer(invSelf.player)

	-- Add All backpacks content except proxInv (TODO: Ensure the 'except proxInv' part)
	for i = 1, #invSelf.backpacks do
		local invToAdd = invSelf.backpacks[i].inventory
		if ProxInv.canBeAdded(invToAdd, playerObj) then
			local items = invToAdd:getItems()
			proximityButtonRef.inventory:getItems():addAll(items)
			table.insert(ProxInv.containerCache, invToAdd)
		end
	end
end

Events.OnRefreshInventoryWindowContainers.Add(function(invSelf, state)
	if invSelf.onCharacter then
		-- Ignore character containers, as usual, but I Wonder if instead it would be nice to have
		-- I did just enable proxinv for vehicles, so I'll need to wait for feedback
		return
	end

	if state == "begin" then
		return ProximityInventory.OnBeginRefresh(invSelf)
	end

	if state == "buttonsAdded" then
		return ProximityInventory.OnButtonsAdded(invSelf)
	end
end)
