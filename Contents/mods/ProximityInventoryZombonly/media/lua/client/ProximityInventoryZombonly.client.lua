require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

ProximityInventory.zombieTypes = {
	inventoryfemale = true,
	inventorymale = true,
}

ProximityInventory.canBeAdded = function (container)
	-- Only zombie Corpses
	return ProximityInventory.zombieTypes[container:getType()]
end
