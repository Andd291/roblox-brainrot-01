-- BrainrotData.luau — the cast of Brainrot Bazaar: thirteen absurd characters of
-- our own, on a ladder of five rarities, plus the mutations a wild brainrot can
-- be born with. Every brainrot the game spawns comes from this one table.

local BrainrotData = {}

-- Rarities, weakest first. spawnWeight decides how often the belt rolls one;
-- multiplier scales both the money per second and the buy price.
BrainrotData.RARITIES = {
	Common = {
		order = 1,
		multiplier = 1,
		spawnWeight = 55,
		color = Color3.fromRGB(190, 190, 190),
	},
	Rare = {
		order = 2,
		multiplier = 2,
		spawnWeight = 25,
		color = Color3.fromRGB(80, 160, 255),
	},
	Epic = {
		order = 3,
		multiplier = 4,
		spawnWeight = 12,
		color = Color3.fromRGB(170, 80, 255),
	},
	Legendary = {
		order = 4,
		multiplier = 8,
		spawnWeight = 6,
		color = Color3.fromRGB(255, 170, 0),
	},
	Mythic = {
		order = 5,
		multiplier = 16,
		spawnWeight = 2,
		color = Color3.fromRGB(255, 60, 120),
	},
}

-- Mutations roll on top of a rarity and multiply rate and price again.
BrainrotData.MUTATIONS = {
	{ name = "None", multiplier = 1, chance = 0.86, color = nil },
	{ name = "Golden", multiplier = 2, chance = 0.10, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", multiplier = 4, chance = 0.03, color = Color3.fromRGB(185, 242, 255) },
	{ name = "Rainbow", multiplier = 8, chance = 0.01, color = Color3.fromRGB(255, 80, 200) },
}

-- The catalog. rate is the base money per second, cost the base buy price; the
-- rarity and mutation multipliers scale both. accessory names the extra part
-- the factory builds so each character reads at a glance.
BrainrotData.CATALOG = {
	{ id = "mie_goreng", name = "Mie Goreng Golem", rarity = "Common", rate = 1, cost = 50, color = Color3.fromRGB(255, 200, 80), size = 3, accessory = "noodles", blurb = "A noodle pile that learned to walk." },
	{ id = "es_teh", name = "Es Teh Manis Slime", rarity = "Common", rate = 2, cost = 100, color = Color3.fromRGB(200, 120, 60), size = 3, accessory = "cup", blurb = "Sweet tea, hold the ice, hold the legs." },
	{ id = "gorengan", name = "Gorengan Goblin", rarity = "Common", rate = 3, cost = 150, color = Color3.fromRGB(230, 170, 60), size = 3, accessory = "hat", blurb = "Crispy, greasy, and already at your base." },
	{ id = "durian", name = "Durian Raja", rarity = "Rare", rate = 4, cost = 200, color = Color3.fromRGB(120, 200, 70), size = 4, accessory = "spikes", blurb = "The king of fruit smells like victory." },
	{ id = "kopi", name = "Kopi Tubruk Titan", rarity = "Rare", rate = 6, cost = 300, color = Color3.fromRGB(90, 60, 40), size = 4, accessory = "cup", blurb = "Unfiltered coffee, unfiltered power." },
	{ id = "boba", name = "Boba Tea Beast", rarity = "Rare", rate = 8, cost = 400, color = Color3.fromRGB(210, 150, 200), size = 4, accessory = "straw", blurb = "Chewy pearls, chewier roar." },
	{ id = "cone", name = "Cone Traffic Samurai", rarity = "Epic", rate = 10, cost = 375, color = Color3.fromRGB(255, 120, 30), size = 4, accessory = "cone", blurb = "It directs traffic. It directs fate." },
	{ id = "nasi_padang", name = "Nasi Padang Dragon", rarity = "Epic", rate = 12, cost = 450, color = Color3.fromRGB(255, 220, 150), size = 5, accessory = "wings", blurb = "A dragon that serves itself with rendang." },
	{ id = "sate", name = "Sate Ayam Phoenix", rarity = "Epic", rate = 15, cost = 550, color = Color3.fromRGB(255, 150, 60), size = 5, accessory = "skewer", blurb = "Grilled once, reborn forever." },
	{ id = "rendang", name = "Rendang Raksasa", rarity = "Legendary", rate = 15, cost = 750, color = Color3.fromRGB(140, 70, 30), size = 5, accessory = "crown", blurb = "Slow-cooked for six hours. Worth every second." },
	{ id = "kecap", name = "Kecap Manis Kraken", rarity = "Legendary", rate = 22, cost = 1100, color = Color3.fromRGB(60, 40, 90), size = 6, accessory = "tentacles", blurb = "Eight arms, all of them pouring sweet soy." },
	{ id = "indomie", name = "Indomie Sultan", rarity = "Mythic", rate = 25, cost = 1250, color = Color3.fromRGB(255, 230, 100), size = 6, accessory = "crown", blurb = "Ruler of the midnight noodle drawer." },
	{ id = "gado_gado", name = "Gado-Gado God", rarity = "Mythic", rate = 50, cost = 2500, color = Color3.fromRGB(140, 220, 120), size = 6, accessory = "wings", blurb = "A salad so mixed it achieved divinity." },
}

-- Look up one catalog entry by id.
function BrainrotData.getEntry(entryId)
	for _, entry in ipairs(BrainrotData.CATALOG) do
		if entry.id == entryId then
			return entry
		end
	end
	return nil
end

-- The money per second and buy price of a brainrot, after rarity and mutation.
function BrainrotData.getRate(entry, mutation)
	local rarity = BrainrotData.RARITIES[entry.rarity]
	local mult = rarity and rarity.multiplier or 1
	return entry.rate * mult * mutation.multiplier
end

function BrainrotData.getCost(entry, mutation)
	local rarity = BrainrotData.RARITIES[entry.rarity]
	local mult = rarity and rarity.multiplier or 1
	return math.floor(entry.cost * mult * mutation.multiplier + 0.5)
end

-- Roll a rarity by its spawn weight, then a random character of that rarity.
function BrainrotData.rollCatalogEntry()
	local weights = {}
	for rarityName, rarity in pairs(BrainrotData.RARITIES) do
		table.insert(weights, { weight = rarity.spawnWeight, value = rarityName })
	end
	local rarityName = nil
	local total = 0
	for _, entry in ipairs(weights) do
		total = total + entry.weight
	end
	local roll = math.random() * total
	for _, entry in ipairs(weights) do
		roll = roll - entry.weight
		if roll <= 0 then
			rarityName = entry.value
			break
		end
	end
	rarityName = rarityName or "Common"
	local pool = {}
	for _, entry in ipairs(BrainrotData.CATALOG) do
		if entry.rarity == rarityName then
			table.insert(pool, entry)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation by its chance.
function BrainrotData.rollMutation()
	local roll = math.random()
	local running = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		running = running + mutation.chance
		if roll <= running then
			return mutation
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- The rarity order number, for sorting and for the next-tier progress.
function BrainrotData.getRarityOrder(rarityName)
	local rarity = BrainrotData.RARITIES[rarityName]
	return rarity and rarity.order or 0
end

-- The next rarity above the best one the player owns, or nil at the top.
function BrainrotData.getNextRarity(bestOrder)
	for rarityName, rarity in pairs(BrainrotData.RARITIES) do
		if rarity.order == bestOrder + 1 then
			return rarityName
		end
	end
	return nil
end

return BrainrotData
