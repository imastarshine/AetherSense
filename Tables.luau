--!strict

local Tables = {}

function Tables.CountDictKeys(t: {[any]: any})
	local count = 0
	for _, __ in pairs(t) do
		count += 1
	end
	return count
end

function Tables.CountDictKeysTrue(t: {[any]: any})
	local count = 0
	for _, v in pairs(t) do
		if v then
			count += 1
		end
	end
	return count
end

function Tables.Merge<T>(...: {T}): {T}
	local result = {}
	for _, tbl in ipairs({...}) do
		for _, value in ipairs(tbl) do
			table.insert(result, value)
		end
	end
	return result
end

function Tables.ToDict(t: {string})
	local d = {} :: {[string]: boolean}
	for _, v in ipairs(t) do
		d[v] = true
	end
	return table.freeze(d)
end

return Tables
