--!strict

local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

local DeviceAdapt = {}

local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui

local function getInitialInputType()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	elseif UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return "PC"
	end
	return "Unknown"
end

local function AdaptGuiForPC()
	
end

local function AdaptGuiForMobile()
	
end

function DeviceAdapt.Init()
	local currentDevice = getInitialInputType()
	if currentDevice == "Mobile" then
		AdaptGuiForMobile()
	end
	
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			AdaptGuiForMobile()
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			AdaptGuiForPC()
		end
	end)
end

function DeviceAdapt.StartLoop()
	
end

return DeviceAdapt
