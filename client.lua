-- | Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- | ReplicatedStorage

local Events = ReplicatedStorage.Events -- where remote events are stored

-- | Player

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui -- where all items from startergui get cloned to, unique for all players

-- | CollectionService

PlayerGui:WaitForChild("KingdomUI")  -- waits for the ui to load completely before running anything

local Kingdoms = CollectionService:GetTagged("Kingdom") -- gets all things tagged Kingdom and puts them in a table (all of the teams)
local KingdomGui = CollectionService:GetTagged("KingdomGui") -- gets all things tagged KingdomGui and puts them in a table 

-- | Runtime

for i, v in Kingdoms do -- does whatever for each instance in the table of kingdoms
	v:GetAttributeChangedSignal("Claimed"):Connect(function()  -- checks whenever the attribute, "Claimed" is changed (claimed is just )
		Events.Claimed:FireServer(PlayerGui, v, v:GetAttribute("Claimed")) -- fires a remote event, passes (automatically passes through the player), playergui, the instance, which in this case would be the team, and if the attribute was changed to true or false
	end)
end

for i, v in KingdomGui do -- does whatever for each instance that is tagged "KingdomGui"
	if not v:IsDescendantOf(PlayerGui) then -- detects whether the instance that is tagged is not inside of the playergui
		continue -- if it isnt inside the playergui, meaning its inside of the startergui, it continues looping through the table. if i wouldve put return it wouldve completely stopped the loop
	end
	
	for _, button : TextButton in v:GetChildren() do -- loops through the children of the folders in the kingdoms frame, the : textbutton means it treats it as if it knows it is a textbutton, i can explain it in more depth if you dont understand. just let me know
		
		if not button:IsA("TextButton") then -- checks if the instance is not a text button
			continue -- continues looping through the table if it isnt a textbutton
		end
		
		button.MouseButton1Click:Connect(function() -- checks when the button is pressed
			Events.Kingdom:FireServer(button.Parent) -- fires a remote event, and passes through the folder, which has the same name as the corresponding team
		end)
	end
end
