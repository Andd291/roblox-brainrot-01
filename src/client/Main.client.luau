-- Main.client.luau — Brainrot Bazaar client bootstrap: wait for the shared
-- modules and the remotes, then start the HUD, the interactions and the
-- effects. The server owns all state; this side only shows it and asks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local remotes = Remotes.waitForRemotes()

local HudController = require(script.Parent.HudController)
local InteractionController = require(script.Parent.InteractionController)
local EffectsController = require(script.Parent.EffectsController)

EffectsController.init(remotes)
HudController.init(remotes)
InteractionController.init(remotes, HudController)

print("[Brainrot Bazaar] client started.")
