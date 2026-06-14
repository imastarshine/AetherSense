local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local FAVORITES_FILE = "tuesday_favorites.json"

local parent = pcall(gethui) and gethui() or CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TuesdayScripts"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 1000
screenGui.ResetOnSpawn = false
screenGui.Parent = parent

local WINDOW_WIDTH = 420
local WINDOW_HEIGHT = 500
local TITLE_HEIGHT = 30

local C = {
	BG = Color3.fromRGB(15, 20, 35),
	TITLE_BG = Color3.fromRGB(22, 30, 50),
	ROW = Color3.fromRGB(28, 38, 58),
	ROW_HOVER = Color3.fromRGB(38, 50, 75),
	EXEC = Color3.fromRGB(40, 80, 140),
	EXEC_HOVER = Color3.fromRGB(50, 100, 170),
	TEXT = Color3.fromRGB(200, 210, 230),
	SCROLL = Color3.fromRGB(40, 55, 85),
	STAR_ON = Color3.fromRGB(255, 200, 50),
	STAR_OFF = Color3.fromRGB(100, 100, 120),
	CLOSE = Color3.fromRGB(224, 80, 80),
}

local favorites = {}
local function loadFavorites()
	if isfile(FAVORITES_FILE) then
		local s, d = pcall(function()
			return HttpService:JSONDecode(readfile(FAVORITES_FILE))
		end)
		if s and type(d) == "table" then
			favorites = d
		end
	end
end
local function saveFavorites()
	writefile(FAVORITES_FILE, HttpService:JSONEncode(favorites))
end
loadFavorites()

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Parent = screenGui
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
main.BackgroundColor3 = C.BG
main.BorderColor3 = Color3.fromRGB(40, 55, 85)
main.ClipsDescendants = true

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = main
titleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
titleBar.BackgroundColor3 = C.TITLE_BG
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = titleBar
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "tuesday_scripts.lua  [0]"
titleLabel.TextColor3 = C.TEXT
titleLabel.Font = Enum.Font.SourceSans
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 28, 1, 0)
closeBtn.Position = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = C.CLOSE
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

local restoreBtn = Instance.new("TextButton")
restoreBtn.Name = "RestoreButton"
restoreBtn.Parent = screenGui
restoreBtn.AnchorPoint = Vector2.new(0.5, 0)
restoreBtn.Position = UDim2.new(0.5, 0, 0, 0)
restoreBtn.Size = UDim2.new(0, 80, 0, 22)
restoreBtn.BackgroundColor3 = C.TITLE_BG
restoreBtn.BorderColor3 = Color3.fromRGB(40, 55, 85)
restoreBtn.Text = "☐ tuesday"
restoreBtn.TextColor3 = C.TEXT
restoreBtn.Font = Enum.Font.SourceSans
restoreBtn.TextSize = 13
restoreBtn.Visible = false
restoreBtn.ZIndex = 9999

restoreBtn.MouseButton1Click:Connect(function()
	restoreBtn.Visible = false
	main.Visible = true
end)

local minBtn = Instance.new("TextButton")
minBtn.Name = "MinimizeButton"
minBtn.Parent = titleBar
minBtn.Size = UDim2.new(0, 28, 1, 0)
minBtn.Position = UDim2.new(1, -56, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = C.TEXT
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 18

minBtn.MouseButton1Click:Connect(function()
	restoreBtn.Visible = true
	main.Visible = false
end)

local scriptList = Instance.new("ScrollingFrame")
scriptList.Name = "ScriptList"
scriptList.Parent = main
scriptList.Position = UDim2.new(0, 5, 0, TITLE_HEIGHT + 5)
scriptList.Size = UDim2.new(1, -10, 1, -(TITLE_HEIGHT + 10))
scriptList.BackgroundTransparency = 1
scriptList.BorderSizePixel = 0
scriptList.ScrollBarThickness = 6
scriptList.ScrollBarImageColor3 = C.SCROLL
scriptList.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scriptList
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scriptList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local function resort()
	local rows = {}
	for _, child in ipairs(scriptList:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(rows, child)
		end
	end
	table.sort(rows, function(a, b)
		local favA, favB = favorites[a.Name], favorites[b.Name]
		if favA and not favB then return true end
		if not favA and favB then return false end
		return a.Name:lower() < b.Name:lower()
	end)
	for order, row in ipairs(rows) do
		row.LayoutOrder = order
	end
end

local function createRow(fileName, filePath)
	local row = Instance.new("Frame")
	row.Name = fileName
	row.Parent = scriptList
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = C.ROW
	row.BorderSizePixel = 0

	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.ROW_HOVER
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = C.ROW
	end)

	local isFav = favorites[fileName]
	local starBtn = Instance.new("TextButton")
	starBtn.Name = "Star"
	starBtn.Parent = row
	starBtn.Size = UDim2.new(0, 26, 1, 0)
	starBtn.BackgroundTransparency = 1
	starBtn.Text = isFav and "★" or "☆"
	starBtn.TextColor3 = isFav and C.STAR_ON or C.STAR_OFF
	starBtn.Font = Enum.Font.SourceSans
	starBtn.TextSize = 18

	starBtn.MouseButton1Click:Connect(function()
		favorites[fileName] = not favorites[fileName]
		starBtn.Text = favorites[fileName] and "★" or "☆"
		starBtn.TextColor3 = favorites[fileName] and C.STAR_ON or C.STAR_OFF
		saveFavorites()
		resort()
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Parent = row
	nameLabel.Size = UDim2.new(1, -90, 1, 0)
	nameLabel.Position = UDim2.new(0, 26, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = fileName
	nameLabel.TextColor3 = C.TEXT
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local execBtn = Instance.new("TextButton")
	execBtn.Name = "Execute"
	execBtn.Parent = row
	execBtn.Size = UDim2.new(0, 60, 0, 24)
	execBtn.Position = UDim2.new(1, -64, 0.5, -12)
	execBtn.BackgroundColor3 = C.EXEC
	execBtn.BorderSizePixel = 0
	execBtn.Text = "Exec"
	execBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	execBtn.Font = Enum.Font.SourceSansBold
	execBtn.TextSize = 13
	execBtn.AutoButtonColor = false

	execBtn.MouseEnter:Connect(function()
		execBtn.BackgroundColor3 = C.EXEC_HOVER
	end)
	execBtn.MouseLeave:Connect(function()
		execBtn.BackgroundColor3 = C.EXEC
	end)
	execBtn.MouseButton1Down:Connect(function()
		execBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 110)
	end)
	execBtn.MouseButton1Up:Connect(function()
		execBtn.BackgroundColor3 = C.EXEC_HOVER
	end)

	execBtn.MouseButton1Click:Connect(function()
		local s, e = pcall(dofile, filePath)
		if not s then
			warn("[TuesdayScripts] Failed:", fileName, e)
		end
	end)

	return row
end

local loadedCount = 0

if isfolder("TuesdayScripts") then
	local files = listfiles("TuesdayScripts")
	for _, filePath in ipairs(files) do
		local fileName = filePath:match("[^\\/]+$")
		if not fileName then continue end
		createRow(fileName, filePath)
		loadedCount += 1
	end
end

resort()
titleLabel.Text = "tuesday_scripts.lua  [" .. loadedCount .. "]"

--credits: infinite yield
local function dragGUI(gui: Frame)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(gui, TweenInfo.new(0.05), { Position = newPos }):Play()
	end

	gui.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch)
			and CurrentlyDragging == nil
		then
			dragging = true
			CurrentlyDragging = gui

			dragStart = input.Position
			startPos = gui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					CurrentlyDragging = nil
				end
			end)
		end
	end)

	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and CurrentlyDragging == gui and input == dragInput then
			update(input)
		end
	end)
end

getgenv().CurrentlyDragging = nil
dragGUI(main)
