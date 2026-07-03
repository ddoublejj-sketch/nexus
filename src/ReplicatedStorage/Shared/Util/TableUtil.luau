--!strict

local TableUtil = {}

function TableUtil.count(dictionary: { [any]: any }): number
	local total = 0

	for _ in dictionary do
		total += 1
	end

	return total
end

return TableUtil
