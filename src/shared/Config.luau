-- Config.luau — every tuning number for Brainrot Bazaar lives here, in one place,
-- so a balance change is one edit and the whole game reads the same values.

local Config = {}

-- Money and starting state.
Config.START_MONEY = 150
Config.REBIRTH_START_MONEY = 150

-- Bases: eight plots ring the plaza, one per player, first come first served.
Config.MAX_BASES = 8
Config.BASE_RADIUS = 62
Config.BASE_SIZE = 18
Config.PLOTS_PER_BASE = 6
Config.MAX_PLOT_UPGRADES = 3
Config.PLOT_UPGRADE_BONUS = 2

-- The conveyor belt where wild brainrots walk past and can be bought.
Config.CONVEYOR_SPAWN_INTERVAL = 4
Config.CONVEYOR_SPEED = 6
Config.CONVEYOR_START_X = -90
Config.CONVEYOR_END_X = 90
Config.CONVEYOR_Z = -40
Config.CONVEYOR_Y = 3

-- Base lock: stops every steal while it lasts, then needs a cooldown.
Config.LOCK_DURATION = 60
Config.LOCK_COOLDOWN = 180

-- The tsunami: a warning, then a wall of water sweeps the map.
Config.WAVE_INTERVAL = 150
Config.FIRST_WAVE_DELAY = 60
Config.WAVE_WARNING = 10
Config.WAVE_SWEEP_TIME = 10
Config.WAVE_START_Z = -150
Config.WAVE_END_Z = 150

-- Rebirth: spend money and give up your brainrots for a permanent income boost.
Config.REBIRTH_BASE_COST = 2500
Config.REBIRTH_MIN_BRAINROTS = 3
Config.REBIRTH_MULTIPLIER_PER = 0.5

-- Upgrades, bought with money from the Upgrades panel.
Config.UPGRADES = {
	capacity = {
		name = "Base Capacity",
		description = "+2 brainrot plots on your base",
		baseCost = 500,
		maxLevel = 3,
	},
	income = {
		name = "Income Boost",
		description = "+15% money from every brainrot",
		baseCost = 800,
		maxLevel = 5,
	},
	speed = {
		name = "Speed Boots",
		description = "+4 walk speed, outrun the wave",
		baseCost = 300,
		maxLevel = 5,
	},
}

-- Upgrade cost grows with the level already owned: baseCost * (level + 1) ^ 2.
function Config.getUpgradeCost(upgradeId, level)
	local upgrade = Config.UPGRADES[upgradeId]
	if not upgrade then
		return nil
	end
	return upgrade.baseCost * (level + 1) * (level + 1)
end

-- Rebirth cost grows with the rebirths already owned: base * (rebirths + 1) ^ 2.
function Config.getRebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (rebirths + 1) * (rebirths + 1)
end

-- How many plots a base holds once its owner bought capacity upgrades.
function Config.getPlotCapacity(capacityLevel)
	return Config.PLOTS_PER_BASE + capacityLevel * Config.PLOT_UPGRADE_BONUS
end

-- The income multiplier from rebirths and the income upgrade.
function Config.getIncomeMultiplier(rebirths, incomeLevel)
	return 1 + rebirths * Config.REBIRTH_MULTIPLIER_PER + incomeLevel * 0.15
end

-- Walk speed from the speed upgrade (base 16).
function Config.getWalkSpeed(speedLevel)
	return 16 + speedLevel * 4
end

return Config
