--// Smart UI Manager (For NEW Game Layout)
--// Auto detects Main.Gears & Main.Seeds and positions + scales them cleanly.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SETTINGS
local UI_SCALE = 0.9
local UI_PADDING = 25

-- Names to manage
local UI_NAMES = { "Gears", "Seeds" }

-- Store found UIs
local tracked = {}

local function debug(...)
	-- print("[NEW UI MANAGER]:", ...)
end

-- Wait for Main
local main = playerGui:WaitForChild("Main")

--// Detect & Store UI
local function registerUI(obj)
	for _, n in ipairs(UI_NAMES) do
		if obj.Name == n then
			if not table.find(tracked, obj) then
				table.insert(tracked, obj)

				obj.Visible = true

				local scale = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				scale.Parent = obj
				scale.Scale = UI_SCALE

				debug("Registered:", obj.Name)
			end
		end
	end
end

-- Initial find
for _, child in ipairs(main:GetChildren()) do
	registerUI(child)
end

-- Listen for future UI spawning
main.ChildAdded:Connect(registerUI)

-- Corner layout spots
local corners = {
	{anchor = Vector2.new(0, 0), pos = function(view) return UDim2.new(0, UI_PADDING, 0, UI_PADDING) end}, -- Top Left
	{anchor = Vector2.new(1, 0), pos = function(view) return UDim2.new(1, -UI_PADDING, 0, UI_PADDING) end}, -- Top Right
	{anchor = Vector2.new(0, 1), pos = function(view) return UDim2.new(0, UI_PADDING, 1, -UI_PADDING) end}, -- Bottom Left
	{anchor = Vector2.new(1, 1), pos = function(view) return UDim2.new(1, -UI_PADDING, 1, -UI_PADDING) end}, -- Bottom Right
}

--// Resize & Position Logic
local function updatePlacement()
	if #tracked == 0 then return end
	local cam = workspace.CurrentCamera
	if not cam then return end

	local view = cam.ViewportSize
	local width = math.floor(view.X * 0.33)
	local height = math.floor(view.Y * 0.42)

	for i, ui in ipairs(tracked) do
		local layout = corners[((i - 1) % #corners) + 1]

		ui.AnchorPoint = layout.anchor
		ui.Position = layout.pos(view)
		ui.Size = UDim2.new(0, width, 0, height)
	end
end

-- Run once and keep updating on resolution change
updatePlacement()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePlacement)

debug("NEW UI Manager Loaded Successfully.")
