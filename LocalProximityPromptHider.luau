local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local PROMPT_CHECK_INTERVAL = 1

local function removePromptsFromHRP(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("HumanoidRootPart not found for", character.Name)
		return
	end

	for _, prompt in ipairs(hrp:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt:Destroy()
		end
	end

	hrp.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end)

	task.spawn(function()
		while character and character.Parent do
			for _, prompt in ipairs(hrp:GetDescendants()) do
				if prompt:IsA("ProximityPrompt") then
					prompt:Destroy()
				end
			end
			task.wait(PROMPT_CHECK_INTERVAL)
		end
	end)
end

local function onCharacterAdded(character)
	task.defer(function()
		removePromptsFromHRP(character)
	end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
