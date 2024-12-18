ProximityInventory = ProximityInventory or {}

---@type { [number]: ItemContainer }
ProximityInventory.virtualContainers = ProximityInventory.virtualContainers or {}

---@param invSelf ISInventoryPage
function ProximityInventory.GetVirtualContainer(invSelf)
  local playerNum = invSelf.player --[[@as number]]

  if ProximityInventory.virtualContainers[playerNum] then
    return ProximityInventory.virtualContainers[playerNum]
  end

	ProximityInventory.virtualContainers[playerNum] = ItemContainer.new("proxInv", nil, nil, 10, 10)
  ProximityInventory.virtualContainers[playerNum]:setExplored(true)
  ProximityInventory.virtualContainers[playerNum]:setOnlyAcceptCategory("none")

	return ProximityInventory.virtualContainers[playerNum]
end

