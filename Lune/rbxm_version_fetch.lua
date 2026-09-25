--[[
    version-checker.luau — find versions inside .rbxm/.rbxmx files (Lune)

    Usage:
        lune run version-checker.luau <directory>

    Scans Source of every Script / LocalScript / ModuleScript,
    plus attributes of ALL instances in the model.

    Script developed via Kimi AI Instant Thinking in supermarket.
]]

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local SCRIPT_CLASSES = {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
}

local VERSION_PATTERNS = {
	[[version%s*[:=]?%s*["']?v?%d+[%d%.]*["']?]], -- version = "1.0.0", VERSION: 2, version 1.2.3
	[[ver%s*[:=]%s*["']?v?%d+[%d%.]*["']?]], -- ver: 1.0, ver = 2.1.0
	[["']v%s*[:=]%s*["']?%d+[%d%.]*["']?]], -- "v: 0", 'v = 1.2.3'
	[[v%s*[:=]%s*["']?%d+[%d%.]*["']?]], -- v: 0, v=1.0.0
	[[v%s*%.%s*%d+[%d%.]*]], -- v.1.0.0
	[["']v?%d+%.%d+%.%d+v?["']], -- "1.0.0", 1.0.0v, "v1.2.3"
	[[v?%d+%.%d+%.%d+v?]], -- 1.0.0, v1.0.0, 1.0.0v
	[["']%d+%.%d+["']], -- "1.2"
}

-- Scans text line by line: returns { {line = N, token = "..."}, ... }
local function scanText(text)
	local found, seen = {}, {}
	local lines = string.split(text, "\n")
	for lineNum, rawLine in ipairs(lines) do
		local lower = rawLine:gsub("\r", ""):lower()
		for _, pattern in ipairs(VERSION_PATTERNS) do
			for token in string.gmatch(lower, pattern) do
				local key = lineNum .. "|" .. token
				if not seen[key] then
					seen[key] = true
					table.insert(found, { line = lineNum, token = token })
				end
			end
		end
	end
	return found
end

-- Scans a single attribute value (no line info)
local function scanValue(value)
	local found, seen = {}, {}
	local text = tostring(value):lower()
	for _, pattern in ipairs(VERSION_PATTERNS) do
		for token in string.gmatch(text, pattern) do
			if not seen[token] then
				seen[token] = true
				table.insert(found, token)
			end
		end
	end
	return found
end

local function scanInstance(inst, hits)
	if SCRIPT_CLASSES[inst.ClassName] then
		local ok, source = pcall(function()
			return inst.Source
		end)
		if ok and type(source) == "string" then
			for _, hit in ipairs(scanText(source)) do
				table.insert(
					hits,
					string.format('📜 %s "%s" — line %d: %s', inst.ClassName, inst.Name, hit.line, hit.token)
				)
			end
		end
	end

	local okAttrs, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if okAttrs and type(attrs) == "table" then
		for attrName, attrValue in pairs(attrs) do
			if type(attrValue) == "string" or type(attrValue) == "number" then
				for _, token in ipairs(scanValue(attrValue)) do
					table.insert(
						hits,
						string.format(
							'🏷️ %s "%s" — attribute "%s": %s',
							inst.ClassName,
							inst.Name,
							attrName,
							token
						)
					)
				end
			end
		end
	end

	for _, child in ipairs(inst:GetChildren()) do
		scanInstance(child, hits)
	end
end

local dir = process.args[1] or "."

local okDir, entries = pcall(fs.readDir, dir)
if not okDir then
	print("❌ Failed to open directory: " .. tostring(dir))
	return
end
table.sort(entries)

local files = {}
for _, name in ipairs(entries) do
	local path = dir .. "/" .. name
	if fs.isFile(path) and (name:lower():match("%.rbxm$") or name:lower():match("%.rbxmx$")) then
		table.insert(files, { name = name, path = path })
	end
end

if #files == 0 then
	print("❌ No .rbxm/.rbxmx files found in: " .. dir)
	return
end

local totalWith, totalWithout = 0, 0

for _, file in ipairs(files) do
	local okRead, data = pcall(fs.readFile, file.path)
	if not okRead then
		print("⚠️ " .. file.name .. " — failed to read file")
		continue
	end
	local okDes, instances = pcall(roblox.deserializeModel, data)
	if not okDes or type(instances) ~= "table" then
		print("⚠️ " .. file.name .. " — failed to parse model")
		continue
	end

	local hits = {}
	for _, inst in ipairs(instances) do
		scanInstance(inst, hits)
	end

	if #hits > 0 then
		totalWith += 1
		print("✅ " .. file.name)
		for _, hit in ipairs(hits) do
			print("   " .. hit)
		end
	else
		totalWithout += 1
		print("❌ " .. file.name)
		print("   no version found")
	end
end

print(
	string.format("\nTotal: %d files | ✅ with version: %d | ❌ without version: %d", #files, totalWith, totalWithout)
)
