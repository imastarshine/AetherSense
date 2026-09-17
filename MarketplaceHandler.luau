--!strict

local MarketplaceHandler = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RegistredFunctions = {
	Products = {},
	Gamepasses = {}
}

export type ReceiptInfo = {
	PlayerId: number,
	PlaceIdPaid: number,
	ProductId: number,
	PurchaseId: string,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
}

function MarketplaceHandler.RegisterProduct(proudctId: number, callback: (player: Player, productId: number) -> (boolean))
	RegistredFunctions.Products[proudctId] = callback
end

function MarketplaceHandler.RegisterGamepass(gamepassId: number, callback: (player: Player, gamepassId: number) -> (boolean))
	RegistredFunctions.Gamepasses[gamepassId] = callback
end

function MarketplaceHandler.Init()
	MarketplaceService.ProcessReceipt = function(receiptInfo: ReceiptInfo)
		
		local playerId = receiptInfo.PlayerId
		local player = Players:GetPlayerByUserId((playerId::any))
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		
		local productId = receiptInfo.ProductId
		local productCallback = RegistredFunctions.Products[productId]
		if not productCallback then
			warn(`{productId} does not have a callback`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		else
			local success, result = pcall(productCallback, player, productId)
			if not success then
				warn(`an error occured while processing {productId} for {player.UserId} ({player.User.Id}, {player.Name}, {player.DisplayName}): {result}`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			else
				if not result then
					warn(`{productId} for {player.UserId} ({player.User.Id}, {player.Name}, {player.DisplayName}) was not processed due to {result} result`)
					return Enum.ProductPurchaseDecision.NotProcessedYet
				else
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end
	end
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Instance, gamePassId: number, wasPurchased: boolean) 
		if not wasPurchased then return end
		
		local cast: Player = (player::any)
		
		local isReallyPurchased = false
		for i = 1, 10 do
			local success, result = pcall(function()
				isReallyPurchased = MarketplaceService:UserOwnsGamePassAsync(cast.User, gamePassId)
			end)
			if not success then
				warn(`[MarketplaceHandler] Error while checking if player has pass: {result}`)
				task.wait(1)
			else
				break
			end
		end
		
		if isReallyPurchased then
			local gamepassCallback = RegistredFunctions.Gamepasses[gamePassId]
			if not gamepassCallback then
				warn(`{gamePassId} does not have a callback`)
				return
			else
				local success, result = pcall(gamepassCallback, cast, gamePassId)
				if not success then
					warn(`an error occured while processing {gamePassId} for {cast.UserId} ({cast.User.Id}, {cast.Name}, {cast.DisplayName}): {result}`)
				else
					if not result then
						warn(`{gamePassId} for {cast.UserId} ({cast.User.Id}, {cast.Name}, {cast.DisplayName}) was not processed due to {result} result`)
					end
				end
			end
		end
	end)
end

function MarketplaceHandler.StartLoop()
	
end

return MarketplaceHandler
