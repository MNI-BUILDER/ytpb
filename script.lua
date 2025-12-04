--// UI Manager + Auto Scroll (Fixed Paths for Seeds & Gears)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SETTINGS
local UI_SCALE = 0.95
local SCROLL_SPEED = 0.06
local SCROLL_PAUSE = 1.5
local UI_PADDING = 25

-- Track UIs & scroll frames
local tracked = {}
local managedFrames = {}

local function debugLog(...)
	print("[UI MANAGER]:", ...)
end

-- Wait for Main
local main = playerGui:WaitForChild("Main")

-- Directly target the ScrollFrames
local function registerScrollFrame(uiName)
	local ui = main:FindFirstChild(uiName)
	if not ui then return end

	if not table.find(tracked, ui) then
		table.insert(tracked, ui)

		ui.Visible = true
		local scale = ui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		scale.Parent = ui
		scale.Scale = UI_SCALE

		local frame = ui:FindFirstChild("Frame")
		if frame then
			local sf = frame:FindFirstChildOfClass("ScrollingFrame")
			if sf then
				sf.ScrollingEnabled = true
				sf.ScrollBarThickness = 8

				local layout = sf:FindFirstChildOfClass("UIListLayout") or sf:FindFirstChildOfClass("UIGridLayout")
				table.insert(managedFrames, {frame = sf, listLayout = layout})

				debugLog("Attached scroll frame:", sf:GetFullName())
			end
		end

		debugLog("Registered UI:", ui.Name)
	end
end

-- Register both
registerScrollFrame("Gears")
registerScrollFrame("Seeds")

-- Corner layout (slightly tilted horizontally)
local corners = {
	{anchor = Vector2.new(0.5, 0.5), pos = function(view) return UDim2.new(0.3, 0, 0.5, 0) end},
	{anchor = Vector2.new(0.5, 0.5), pos = function(view) return UDim2.new(0.7, 0, 0.5, 0) end},
}

-- Resize & Position
local function updatePlacement()
	if #tracked == 0 then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local view = cam.ViewportSize

	local width = math.floor(view.X * 0.45)
	local height = math.floor(view.Y * 0.6)

	for i, ui in ipairs(tracked) do
		local layout = corners[((i - 1) % #corners) + 1]
		ui.AnchorPoint = layout.anchor
		ui.Position = layout.pos(view)
		ui.Size = UDim2.new(0, width, 0, height)
	end
end

updatePlacement()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePlacement)

-- ---------- Auto Scroll ----------
local scrollDir = 1
local scrollProgress = 0
local isPaused = false
local pauseTimer = 0

local function getContentHeight(entry)
	if entry.listLayout then
		return entry.listLayout.AbsoluteContentSize.Y
	end
	-- fallback
	return entry.frame.CanvasSize.Y.Offset
end

local function getMaxScroll(entry)
	local f = entry.frame
	if not f or f.AbsoluteSize.Y <= 0 then return 0 end
	local contentHeight = getContentHeight(entry)
	if not contentHeight then return 0 end
	return math.max(0, contentHeight - f.AbsoluteSize.Y)
end

RunService.RenderStepped:Connect(function(dt)
	for _, entry in ipairs(managedFrames) do
		local f = entry.frame
		if f and f.Parent and f.AbsoluteSize.Y > 0 then
			local maxScroll = getMaxScroll(entry)
			if maxScroll > 0 then
				if isPaused then
					pauseTimer += dt
					if pauseTimer >= SCROLL_PAUSE then
						isPaused = false
						pauseTimer = 0
						scrollDir *= -1
						debugLog(f.Name, "Scroll direction:", scrollDir)
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
				f.CanvasPosition = Vector2.new(0, y)
				debugLog(f.Name, "Scrolling to Y:", y, "MaxScroll:", maxScroll)
			end
		end
	end
end)

debugLog("UI Manager with fixed scroll paths loaded!")
