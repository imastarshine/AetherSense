local SoundPlayer = {}

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

type PositionTarget = Vector3 | BasePart

local function createTempPart(position: PositionTarget): Part
	local part = Instance.new("Part")
	part.Name = "TempSoundEmitter"
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = Vector3.new(1, 1, 1)

	if typeof(position) == "Vector3" then
		part.CFrame = CFrame.new(position)
	else
		part.CFrame = position.CFrame
	end

	part.Parent = workspace.Debris
	return part
end

function SoundPlayer.Play(soundTemplate: Sound)
	task.spawn(function()
		local sound = soundTemplate:Clone()
		sound.Parent = SoundService.Debris
		sound:Play()

		sound.Ended:Wait()
		sound:Destroy()
	end)
end

function SoundPlayer.PlayFadeIn(sound: Sound, volume: number, tweenInfo: TweenInfo?)
	sound.Volume = 0
	sound:Play()
	local newTweenInfo = if tweenInfo then tweenInfo else TweenInfo.new(1, Enum.EasingStyle.Cubic)
	TweenService:Create(sound, newTweenInfo, {Volume = volume}):Play()
end

function SoundPlayer.StopFadeOut(sound: Sound, tweenInfo: TweenInfo?)
	local newTweenInfo = if tweenInfo then tweenInfo else TweenInfo.new(1, Enum.EasingStyle.Cubic)
	TweenService:Create(sound, newTweenInfo, {Volume = 0}):Play()
	task.delay(newTweenInfo.Time, function()
		sound:Stop()
	end)
end

function SoundPlayer.PlayAtPosition(position: PositionTarget, soundTemplate: Sound)
	task.spawn(function()
		local emitter = createTempPart(position)
		local sound = soundTemplate:Clone()

		sound.Parent = emitter
		sound:Play()

		sound.Ended:Wait()
		sound:Destroy()
		emitter:Destroy()
	end)
end

function SoundPlayer.PlayInPart(targetPart: BasePart, soundTemplate: Sound)
	task.spawn(function()
		local sound = soundTemplate:Clone()
		sound.Parent = targetPart
		sound:Play()

		sound.Ended:Wait()
		sound:Destroy()
	end)
end

function SoundPlayer.PlayRandomFromFolderInPart(targetPart: BasePart, folder: Folder)
	task.spawn(function()
		local sounds = {}
		for _, child in folder:GetChildren() do
			if child:IsA("Sound") then
				table.insert(sounds, child)
			end
		end

		if #sounds == 0 then
			return
		end

		local soundTemplate = sounds[math.random(1, #sounds)]
		local sound = soundTemplate:Clone()

		sound.Parent = targetPart
		sound:Play()

		sound.Ended:Wait()
		sound:Destroy()
	end)
end

return SoundPlayer
