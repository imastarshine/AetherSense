--!strict

local MonetizationHelper = {
	Robux = ""
}

local MarketplaceService = game:GetService("MarketplaceService")

function MonetizationHelper.GetPrice(id: number, infoType: Enum.InfoType): number
	for i = 1, 10 do
		local success, result = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id, infoType)
		end)
		if success and result then
			return result.PriceInRobux or 0
		end
		task.wait(0.5)
	end
	return 0
end

return MonetizationHelper
