--// Smart UI Manager (Updated: Bigger, Centered, Scroll Enabled)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SETTINGS
local UI_SCALE = 0.95
local UI_PADDING = 25
local SCROLL_SPEED = 0.15 -- speed of scroll
local SCROLL_PAUSE = 1.5  -- pause at top/bottom

-- Names to manage
local UI_NAMES = { "Gears", "Seeds" }

-- Track UIs & scroll frames
local tracked = {}
local scrollFrames = {}

local function debug(...)
	-- print("[UI MANAGER]:", ...)
end

-- Wait for Main
local main = playerGui:WaitForChild("Main")

-- Register UI
local function registerUI(obj)
	for _, n in ipairs(UI_NAMES) do
		if obj.Name == n then
			if not table.find(tracked, obj) then
				table.insert(tracked, obj)
				obj.Visible = true

				local scale = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				scale.Parent = obj
				scale.Scale = UI_SCALE

				-- enable scrolling if there is a ScrollingFrame inside
				for _, child in ipairs(obj:GetDescendants()) do
					if child:IsA("ScrollingFrame") then
						child.ScrollingEnabled = true
						child.ScrollBarThickness = 8
						table.insert(scrollFrames, child)
					end
				end

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

-- Corner layout (vertical offset moved to middle-ish)
local corners = {
	{anchor = Vector2.new(0, 0.5), pos = function(view) return UDim2.new(0, UI_PADDING, 0.5, 0) end}, -- Left Center
	{anchor = Vector2.new(1, 0.5), pos = function(view) return UDim2.new(1, -UI_PADDING, 0.5, 0) end}, -- Right Center
}

-- Resize & Position
local function updatePlacement()
	if #tracked == 0 then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local view = cam.ViewportSize

	local width = math.floor(view.X * 0.45)   -- bigger
	local height = math.floor(view.Y * 0.6)   -- bigger + more center

	for i, ui in ipairs(tracked) do
		local layout = corners[((i - 1) % #corners) + 1]
		ui.AnchorPoint = layout.anchor
		ui.Position = layout.pos(view)
		ui.Size = UDim2.new(0, width, 0, height)
	end
end

updatePlacement()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePlacement)

-- Auto Scroll
local scrollDir = 1
local scrollProgress = 0
local isPaused = false
local pauseTimer = 0

local function getMaxScroll(f)
	if not f then return 0 end
	if f.AbsoluteSize.Y <= 0 then return 0 end
	local contentHeight = f.CanvasSize.Y.Offset + f.CanvasSize.Y.Scale * f.AbsoluteSize.Y
	return math.max(0, contentHeight - f.AbsoluteSize.Y)
end

RunService.RenderStepped:Connect(function(dt)
	for _, sf in ipairs(scrollFrames) do
		if sf and sf.Parent and sf.AbsoluteSize.Y > 0 then
			local maxScroll = getMaxScroll(sf)
			if maxScroll > 0 then
				if isPaused then
					pauseTimer += dt
					if pauseTimer >= SCROLL_PAUSE then
						isPaused = false
						pauseTimer = 0
						scrollDir *= -1
					end
				else
					scrollProgress += dt * scrollDir * SCROLL_SPEED
					if scrollProgress >= 1 then
						scrollProgress = 1
						isPaused = true
					elseif scrollProgress <= 0 then
						scrollProgress = 0
						isPaused = true
					end
				end

				local y = math.clamp(scrollProgress * maxScroll, 0, maxScroll)
				sf.CanvasPosition = Vector2.new(0, y)
			end
		end
	end
end)

debug("NEW UI Manager with scrolling loaded!")
