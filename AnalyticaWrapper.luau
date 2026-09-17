--!strict
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local AnalyticsWrapper = {}

export type CustomFields = { [string]: string }

local playerCooldowns: {[number]: {[string]: number}} = {}

local GLOBAL_COOLDOWN = 0.5
local EVENT_SPECIFIC_COOLDOWN = 4.0

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

function AnalyticsWrapper.LogEvent(player: Player, eventName: string, value: number?, customFields: CustomFields?)
	local success, exception = pcall(function()
		local userId = player.UserId
		local now = os.clock()

		if not playerCooldowns[userId] then
			playerCooldowns[userId] = {}
		end

		local lastCallAny = playerCooldowns[userId]["_LAST_ANY_"] or 0
		local lastCallThis = playerCooldowns[userId][eventName] or 0

		if now - lastCallAny < GLOBAL_COOLDOWN then
			return 
		end

		if now - lastCallThis < EVENT_SPECIFIC_COOLDOWN then
			return
		end

		local success = pcall(function()
			AnalyticsService:LogCustomEvent(player, eventName, value or 1, customFields)
		end)

		if success then
			playerCooldowns[userId]["_LAST_ANY_"] = now
			playerCooldowns[userId][eventName] = now
		end
	end)
	if not success then
		warn(`[AnalyticsWrapper.LogEvent] Failed to log event: {eventName}, error: {exception} | Player: {player.Name} ({player.UserId})`)
	end
end

return AnalyticsWrapper
