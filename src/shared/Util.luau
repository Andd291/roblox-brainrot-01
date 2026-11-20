-- Util.luau — small helpers every other module shares: money formatting,
-- weighted random picks, and time formatting for the HUD.

local Util = {}

-- "$1,234" with thousands separators; big amounts shorten to $12.5K / $3.2M.
function Util.formatMoney(amount)
	local n = math.floor(amount + 0.5)
	if n >= 1000000 then
		return string.format("$%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("$%.1fK", n / 1000)
	end
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

-- "$45/s" for an income rate.
function Util.formatRate(rate)
	return Util.formatMoney(rate) .. "/s"
end

-- "2:05" for a countdown in seconds.
function Util.formatTime(seconds)
	local s = math.max(0, math.floor(seconds + 0.5))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

-- Pick one entry from a list of { weight = number, value = anything }.
function Util.weightedChoice(entries)
	local total = 0
	for _, entry in ipairs(entries) do
		total = total + entry.weight
	end
	local roll = math.random() * total
	for _, entry in ipairs(entries) do
		roll = roll - entry.weight
		if roll <= 0 then
			return entry.value
		end
	end
	return entries[#entries].value
end

-- Clamp a number between two bounds.
function Util.clampNumber(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

return Util
