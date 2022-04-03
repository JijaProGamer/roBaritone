local PathfindingService = game:GetService("PathfindingService")

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(character)
	Character = character
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Humanoid = Character:WaitForChild("Humanoid")
end)

local function GetBushes()
	local Objects = EXTERNAL_PARAMETER_1:GetDescendants()
	local NewObjects = {}
	for index,object in ipairs(Objects) do
		if object.Name == "berryBush" and object.stage.Value >= 2 then 
			table.insert(NewObjects,object)
		end
	end

	table.sort(NewObjects,function(n,m)
		return math.abs((n.Position - HumanoidRootPart.Position).Magnitude) < math.abs((m.Position - HumanoidRootPart.Position).Magnitude)
	end)

	for index,object in ipairs(NewObjects) do
		if index >= 350 then 
			table.remove(NewObjects,index)
		end
	end

	return NewObjects
end

local function Pathfind(Object)
	local Path = PathfindingService:CreatePath()
	Path:ComputeAsync(HumanoidRootPart.Position,Object.Position)
	local Waypoints = Path:GetWaypoints()
	for index,Waypoint in ipairs(Waypoints) do
		Humanoid:MoveTo(Waypoint.Position)

		if Waypoint.Action == Enum.PathWaypointAction.Jump then
			Humanoid.Jump = true
		end

		Humanoid.MoveToFinished:Wait()
	end
end

local function Run()
	local Bushes = GetBushes()

	for index,Bush in ipairs(Bushes) do
		if math.abs((Bush.Position - HumanoidRootPart.Position).Magnitude) <= 25 then
			coroutine.wrap(function()
				game:GetService("ReplicatedStorage").rbxts_include.node_modules.net.out._NetManaged.CLIENT_HARVEST_CROP_REQUEST:InvokeServer({
					["player"] = Player,
					["player_tracking_category"] = "join_from_web",
					["model"] = Bush
				})
			end)()
			task.wait()
		else
			task.wait(10)
			Pathfind(Bush)
			Run()
		end
	end
end

Run()
