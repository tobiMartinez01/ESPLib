local ESPLib = {} --@class
ESPLib.__index = ESPLib

--// INSTANCES //--
local Camera = workspace.CurrentCamera :: Camera

local function Constructor(
	Check: (BasePart | Model) -> boolean,
	Configs: {
		TargetDir: Instance,
		Distance: number,

		Text: boolean,
		TextSize: number,

		Circle: boolean,
		Radius: number,

		Custom: { { Class: string, Adornee: string, Color: Color3 } | { Name: string, Adornee: string, Color: Color3 } },
		IgnorePlayer: boolean,

		Debug: boolean,
	}
)
	local self = setmetatable({}, ESPLib)
	self.ESPCache = {} :: {
		{
			Adornee: (BasePart | Model)?,
			Drawing: {
				Text: DrawingObject,
				Circle: DrawingObject,
			},
		}
	}

	self.ESPEnabled = true
	self.Check = Check

	self.IgnorePlayer = function(Object)
		local Character = game:GetService("Players").LocalPlayer.Character
			or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()

		return not self.Configs.IgnorePlayer or Character.Address ~= Object.Address
	end

	self.Configs = Configs

	return self
end

--// FUNCTIONS //--
local function Magnitude(Vector3: Vector3): number
	return math.sqrt(Vector3.X ^ 2 + Vector3.Y ^ 2 + Vector3.Z ^ 2)
end

local function isExist(Instance: Instance): boolean?
	return Instance and Instance:IsDescendantOf(game)
end

function ESPLib:CheckForCustom(Adornee)
	for _, data in pairs(self.Configs.Custom) do
		if (data.Class and Adornee:FindFirstChildOfClass(data.Class)) or (data.Name and Adornee.Name == data.Name) then
			return data
		end
	end

	return nil
end

function ESPLib:Scan()
	for _, object in pairs(self.Configs.TargetDir:GetChildren()) do
		if not ((self.Check(object) and self.IgnorePlayer(object)) and not self.ESPCache[object.Address]) then
			continue
		end

		local Adornee = object :: BasePart | Model
		local Color = Color3.fromRGB(255, 0, 0)
		local CustomData = self:CheckForCustom(Adornee)

		if #self.Configs.Custom > 0 and CustomData then
			Adornee = Adornee[CustomData.Adornee]
			Color = CustomData.Color
		end

		local Address = object.Address
		local Text = Drawing.new("Text")
		local Circle = Drawing.new("Circle")

		self.ESPCache[Address] = {
			Adornee = object,
			Drawing = {
				Text = Text,
				Circle = Circle,
			},
		}

		Text.Text = object.Name
		Text.Color = Color
		Text.Size = self.Configs.TextSize
		Text.Center = true

		Circle.Thickness = 2
		Circle.NumSides = 6
		Circle.Color = Color

		spawn(function()
			-- Update esp --
			while isExist(object) and isExist(object.Parent) do
				local screenPos, visible = WorldToScreen(Adornee.Position)
				local distance = Magnitude(Camera.Position - Adornee.Position)

				if screenPos and visible then
					local additionalOffset = Vector2.new()

					if Circle.Visible and distance then
						Circle.Radius = self.Configs.Radius * (self.Configs.Distance / distance)
						additionalOffset = Vector2.new(0, Circle.Radius + 2)
					end

					Text.Position = screenPos + additionalOffset
					Circle.Position = screenPos
				end

				if Text.Visible ~= visible then
					Text.Visible = visible and self.Configs.Text
					Circle.Visible = visible and self.Configs.Circle
				end

				task.wait()
			end

			-- Clean up --
			for _, drawing in pairs(self.ESPCache[Address].Drawing) do
				drawing:Remove()
			end

			self.ESPCache[Address] = nil
		end)
	end
end

function ESPLib:Debug()
	if not self.Configs.Debug then return end

	local Text = Drawing.new("Text")
	Text.Color = Color3.fromRGB(255, 255, 255)
	Text.Outline = true
	Text.Position = Vector2.new(0, Camera.ViewportSize.Y / 2)

	spawn(function()
		while true do
			local count = 0
			for _, data in pairs(self.ESPCache) do
				count += 1
			end

			Text.Text = "Threads: " .. count

			task.wait(1)
		end
	end)
end

--// METHODS //--
function ESPLib:Init()
	while self.ESPEnabled do
		self:Scan()
		self:Debug()
		task.wait(2)
	end
end

function ESPLib:Toggle()
	self.ESPEnabled = not self.ESPEnabled
	self:Init()
end

return Constructor
