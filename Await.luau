--!strict

local Await = {}
Await.__index = Await

export type Special = { s: {string} }

type AwaitClass = {
	new: (root: Instance) -> Await,
	special: (...string) -> Special,

	wait: (self: Await, child: string | Special, timeout: number?) -> Await,
	optional: (self: Await, child: string | Special, timeout: number?) -> Await,
	path: (self: Await, path: string, timeout: number?) -> Await,
	up: (self: Await) -> Await,
}

export type Await = {
	root: Instance,
	
	wait: (self: Await, child: string | Special, timeout: number?) -> Await,
	optional: (self: Await, child: string | Special, timeout: number?) -> Await,
	path: (self: Await, path: string, timeout: number?) -> Await,
	up: (self: Await) -> Await
}

local function fetch(root: Instance, name: string, timeout: number?, notOptinal: boolean): Instance?
	local found = root:WaitForChild(name, timeout or 10)
	if notOptinal then
		if not found then
			error(`Await: Child "{name}" not found in {root:GetFullName()}`, 2)
		end
	end
	return found
end

function Await.new(root: Instance): Await
	assert(typeof(root) == "Instance", "Await.new: root must be Instance")
	local self = setmetatable({} :: Await, Await) :: Await
	self.root = root
	
	return self
end

function Await.special(...: string): Special
	return { s = { ... } }
end

function Await:wait(child: string | Special, timeout: number?): Await
	if typeof(child) == "table" then
		for _, name in child.s do
			fetch(self.root, name, timeout, true)
		end
	else
		fetch(self.root, child, timeout, true)
	end
	return self
end

function Await:optional(child: string | Special, timeout: number?): Await
	if typeof(child) == "table" then
		for _, name in child.s do
			fetch(self.root, name, timeout, false)
		end
	else
		fetch(self.root, child, timeout, false)
	end
	return self
end

--[[
- Absolute path from game: "/ReplicatedStorage/Modules"
- Current directory: "./ChildName" or "ChildName/ChildName2" Equals to wait for child in current root
- Up one directory: "../ParentName/ChildName"
]]
function Await:path(path: string, timeout: number?): Await
	local segments = string.split(path, "/")
	local current = self.root

	for i, segment in segments do
		if segment == ".." then
			current = current.Parent or current
		elseif segment == "." or segment == "" then
			if i == 1 and path:sub(1,1) == "/" then
				current = game
			end
			continue
		else
			current = fetch(current, segment, timeout, true) :: Instance
		end
	end

	self.root = (current :: any)
	return self
end

function Await:up(): Await
	assert(self.root.Parent, "Await:up: root has no parent")
	self.root = self.root.Parent
	return self
end

return Await
