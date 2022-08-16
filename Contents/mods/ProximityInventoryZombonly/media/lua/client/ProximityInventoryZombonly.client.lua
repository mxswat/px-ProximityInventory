require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

ProxInv.zombieTypes = {
	inventoryfemale = true,
	inventorymale = true,
}

ProxInv.canBeAdded = function (container)
	-- Only zombie Corpses
	return ProxInv.zombieTypes[container:getType()]
end
