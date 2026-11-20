-- Remotes.luau — every RemoteEvent the client and server share, by name, so
-- both sides agree on the channel without spelling the string twice.

local Remotes = {}

Remotes.NAMES = {
	"BuyBrainrot",
	"StealBrainrot",
	"ToggleLock",
	"RequestRebirth",
	"BuyUpgrade",
	"StateChanged",
	"PlayEffect",
}

-- Server side: create the folder and every RemoteEvent under it.
function Remotes.createRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in ipairs(Remotes.NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	return folder
end

-- Client side: wait for the folder and every RemoteEvent, return them by name.
function Remotes.waitForRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remotes = {}
	for _, name in ipairs(Remotes.NAMES) do
		remotes[name] = folder:WaitForChild(name)
	end
	return remotes
end

return Remotes
