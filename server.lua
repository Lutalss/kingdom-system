-- | Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

-- | ReplicatedStorage

local Events = ReplicatedStorage.Events -- where remote events are stored

--| Miscellaneous

local TeamChangeCooldown = 30 -- the time before you switch teams again after switching teams

local PreviousKingdom = {} -- used to store the previous kingdom of the player who switched kingdoms, to detect whether the kingdom is empty or not (this uses their userid to connect to the player)
local Debounce = {} -- uses the userid to detect if the 30 second timer has ended yet

math.randomseed(tick()) -- makes the random more random because nothing is truly random and this practically the closest you can get to random in roblox ¯\_(ツ)_/¯ idk how to explain it (this isnt necessary i just like to have it)

-- | Functions

local function RandomizeOwner(Kingdom : Folder)
	local Team = Teams:FindFirstChild(tostring(Kingdom)) -- looks for a team with the same name as the folder 

	if not Team then -- checks if team is nil (if it didnt find a team)
		return -- returns if you it doesnt find a team
	end
	
	local TeamPlayers = Team:GetPlayers() -- gets all players on a team and puts it in a table
	if #TeamPlayers == 0 then -- checks if the number of players on ther team is 0 (the # before the teamPlayers means it gets the number of items in a table)
		Team:SetAttribute("Claimed", false) -- sets that the specific team not claimed
		Team:SetAttribute("Owner", 0) -- removes the owner
		return -- returns so it doesnt continue the function
	end
	
	local RandomPlayer = TeamPlayers[math.random(1, #TeamPlayers)] -- chooses a random player from the team
	if RandomPlayer then -- checks to make sure it chose a random player
		Team:SetAttribute("Owner", RandomPlayer.UserId) -- sets the owner attribute to the userid of the player
	end
end

-- | Runtime

Events.Kingdom.OnServerEvent:Connect(function(Player : Player, Kingdom : Folder)
	if PreviousKingdom[Player.UserId] == Kingdom then -- makes sure they arent joining the same team (these are called checks by the way, theyre mostly used to make it so you dont have a ton of nested if statements and that your code is readable)
		return -- also readability is a big thing in programming, even if the code is just for yourself, its always good to make it look nice and make it much much easier to read (this is like the #1 rule in programming)
	end
	
	local PlayerGui = Player.PlayerGui
	local UserId = Player.UserId
	local Owner = Kingdom:GetAttribute("Owner") 
	local Claimed = Kingdom:GetAttribute("Claimed") 
	local Team = Teams:FindFirstChild(Kingdom.Name)
	
	local Previous = PreviousKingdom[UserId] -- gets the players kingdom that they were in before they swapped kingdoms
	
	--[[if Debounce[UserId] then -- looks for the debounce on the player 
		return -- returns if found
	end]]
	
	task.spawn(function() -- runs a function in a different thread (basically means that it wont stop other things from running, if i didnt have this, then all the statements below wouldnt run until the task.wait ended)
		Debounce[UserId] = true -- looks for the player in the debounces and sets their value to true
		task.wait(TeamChangeCooldown) -- waits 30 seconds, dont use wait() its deprecated
		Debounce[UserId] = nil -- always use nil over false, less memory (not really noticeable unless your making a big game or there are a lot of players, but its always good to start good habits who knows you might make a big game one day)
	end)
	
	if Player.Team then -- checks if the player is on a team
		Player.Team = nil -- removes the team, for whatever reason roblox just doesnt automatically do this when joining another team? i have no idea why so you have to do this manually
	end
	
	if Previous then  -- looks if the id is even found in the table
		local PreviousOwner = Teams[tostring(Previous)]:GetAttribute("Owner") -- for whatever reason Previous.Name just straight up doesnt work whenever i retrieve the folder from the table. i genuinely have no idea why so im using tostring()
		if PreviousOwner == UserId then -- btw the line above finds the team with the same name as the folder and gets the value of the owner attribute, and this line just makes sure that the previous owner is the current player
			RandomizeOwner(Previous)
		end
	end
	
	if Team and Owner and Owner ~= UserId then -- checks if it found a team with the same name as the kingdom and if there is an owner and if the owner is not the current user
		local CurrentOwner = Players:GetPlayerByUserId(Owner) -- checks if the owner is still in the game
		if not CurrentOwner or CurrentOwner.Team ~= Team then -- checks if there is not a current owner, or if the current owner is not on the team
			RandomizeOwner(Kingdom)
		end
	end
	
	PreviousKingdom[UserId] = Kingdom -- puts the user id into the table with a set value that goes with it
	
	if not Claimed then -- checks if the claimed attribute is false
		Team:SetAttribute("Claimed", true) -- sets the claimed value to true
		Team:SetAttribute("Owner", UserId) -- sets the owner
	end
	
	Player.Team = Team -- sets the team
	
	local Character = Player.Character -- defines the character
	if Character and Character:FindFirstChild("Humanoid") then -- checks if player isnt nil and if it has a humanoid
		Character.Humanoid.Died:Once(function() -- detects when player died
			Debounce[UserId] = nil -- removes debounce
			Player.Team = nil  -- removes team
			RandomizeOwner(Kingdom)
		end)
	end
end)

Events.Claimed.OnServerEvent:Connect(function(Player : Player, PlayerGui : PlayerGui, Kingdom : Team, Claimed : boolean)
	local Kingdoms = CollectionService:GetTagged("Kingdom")
	local KingdomGui = CollectionService:GetTagged("KingdomGui")
	
	for i, v in KingdomGui do -- loops through items that are tagged "KingdomGui"
		
		for _, button : TextButton in v:GetChildren() do -- you get what this does by now right
			if not button:IsA("TextButton") then -- checks if the value isnt a button
				continue -- continues looping through but ignores whatever isnt a button
			end
			
			if button.Parent.Name ~= Kingdom.Name then -- checks if the button's parent's name isnt the same as the kingdoms name
				continue -- continues looping through the table and ignores the value if so
			end
			
			if Claimed then -- checks if claimed
				button.Text = "Join\n(Claimed)" -- sets text
			else
				button.Text = "Claim" -- sets text
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) -- checks when player leaves the game
	RandomizeOwner(PreviousKingdom[player.UserId]) -- randomizes owner of previous known kingdom
	PreviousKingdom[player.UserId] = nil -- removes player from the table
end)
