local Success, Err = pcall(function()
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local TeleportService = game:GetService("TeleportService")
	local Lighting = game:GetService("Lighting")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StatsService = game:GetService("Stats")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end

	-- ====== LOADING SCREEN ======
	do
		local okLoad, errLoad = pcall(function()
			local LOAD_TITLE = "PLAYERHUBROUTE06"
			local C1 = Color3.fromRGB(168, 85, 247)
			local C2 = Color3.fromRGB(56, 189, 248)
			local rng = Random.new()

			local function new(class, props, parent)
				local obj = Instance.new(class)
				for k, v in pairs(props) do obj[k] = v end
				obj.Parent = parent
				return obj
			end
			local function play(inst, info, goal)
				local t = TweenService:Create(inst, info, goal)
				t:Play()
				return t
			end

			local old = playerGui:FindFirstChild("HubLoadingScreen")
			if old then old:Destroy() end

			local lgui = new("ScreenGui", {
				Name = "HubLoadingScreen", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 999,
			}, playerGui)
			task.delay(20, function() if lgui.Parent then lgui:Destroy() end end)

			local bg = new("CanvasGroup", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
			}, lgui)
			local bgGrad = new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 20)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 16, 56)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 24, 40)),
				}),
			}, bg)
			play(bgGrad, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })

			-- floating particles
			for _ = 1, 30 do
				local size = rng:NextInteger(3, 8)
				local dot = new("Frame", {
					Size = UDim2.fromOffset(size, size),
					Position = UDim2.fromScale(rng:NextNumber(), 1.1),
					BackgroundColor3 = rng:NextNumber() > 0.5 and C1 or C2,
					BackgroundTransparency = rng:NextNumber(0.5, 0.85),
					BorderSizePixel = 0,
				}, bg)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
				task.spawn(function()
					task.wait(rng:NextNumber(0, 6))
					while lgui.Parent do
						local x = rng:NextNumber()
						dot.Position = UDim2.fromScale(x, 1.1)
						local t = play(dot, TweenInfo.new(rng:NextNumber(6, 12), Enum.EasingStyle.Linear), {
							Position = UDim2.fromScale(x + rng:NextNumber(-0.1, 0.1), -0.1),
						})
						t.Completed:Wait()
					end
				end)
			end

			local content = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			}, bg)
			local scale = new("UIScale", { Scale = 1 }, content)

			-- dual rings
			local function makeRing(size, color, duration, reverse)
				local ring = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38),
					Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1,
				}, content)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
				local stroke = new("UIStroke", { Thickness = 5, Color = color }, ring)
				local grad = new("UIGradient", {
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.45, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}, stroke)
				play(grad, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
					Rotation = reverse and -360 or 360,
				})
				return ring, stroke
			end
			local ring1, stroke1 = makeRing(120, C1, 1.2, false)
			local ring2, stroke2 = makeRing(90, C2, 0.9, true)

			-- title: typewriter + pulsing glow
			local title = new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55),
				Size = UDim2.fromOffset(500, 50), BackgroundTransparency = 1, Text = LOAD_TITLE,
				Font = Enum.Font.GothamBlack, TextSize = 40, TextColor3 = Color3.new(1, 1, 1),
				MaxVisibleGraphemes = 0,
			}, content)
			local glow = new("UIStroke", { Thickness = 2, Color = C1, Transparency = 0.2 }, title)
			play(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.85 })
			task.spawn(function()
				for i = 1, #LOAD_TITLE do
					if not lgui.Parent then return end
					title.MaxVisibleGraphemes = i
					task.wait(0.09)
				end
			end)

			local status = new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62),
				Size = UDim2.fromOffset(400, 22), BackgroundTransparency = 1, Text = "Starting",
				Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = Color3.fromRGB(170, 170, 190),
			}, content)

			-- progress bar with shimmer
			local barBg = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.68),
				Size = UDim2.fromOffset(340, 10), BackgroundColor3 = Color3.fromRGB(30, 30, 45), BorderSizePixel = 0,
			}, content)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, barBg)
			local fill = new("Frame", {
				Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0, ClipsDescendants = true,
			}, barBg)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
			new("UIGradient", { Color = ColorSequence.new(C1, C2) }, fill)
			local shine = new("Frame", {
				Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(-0.4, 0),
				BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
			}, fill)
			new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, shine)
			play(shine, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1), { Position = UDim2.fromScale(1.05, 0) })

			local percent = new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.725),
				Size = UDim2.fromOffset(100, 20), BackgroundTransparency = 1, Text = "0%",
				Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C2,
			}, content)

			-- animated dots + smooth percent
			local target, shown, baseText = 0, 0, "Starting"
			task.spawn(function()
				local d = 0
				while lgui.Parent do
					d = d % 3 + 1
					status.Text = baseText .. string.rep(".", d)
					task.wait(0.35)
				end
			end)
			local conn = RunService.Heartbeat:Connect(function(dt)
				shown += (target - shown) * math.min(dt * 6, 1)
				fill.Size = UDim2.fromScale(math.clamp(shown, 0, 1), 1)
				percent.Text = math.floor(shown * 100 + 0.5) .. "%"
			end)
			lgui.Destroying:Connect(function() conn:Disconnect() end)

			-- steps
			local STEPS = {
				{ "Loading assets", 0.5 },
				{ "Building interface", 0.5 },
				{ "Connecting", 0.4 },
				{ "Finalizing", 0.3 },
			}
			for i, s in ipairs(STEPS) do
				baseText = s[1]
				target = i / #STEPS
				task.wait(s[2])
			end
			baseText = "Ready"
			target = 1

			-- cinematic exit runs in background so the hub keeps loading
			task.spawn(function()
				local t0 = os.clock()
				while shown < 0.99 and os.clock() - t0 < 1 do task.wait() end
				percent.Text = "100%"
				task.wait(0.35)
				play(glow, TweenInfo.new(0.2), { Transparency = 0, Thickness = 5 })
				play(ring1, TweenInfo.new(0.8, Enum.EasingStyle.Quart), { Size = UDim2.fromOffset(700, 700) })
				play(ring2, TweenInfo.new(0.8, Enum.EasingStyle.Quart), { Size = UDim2.fromOffset(500, 500) })
				play(stroke1, TweenInfo.new(0.8), { Transparency = 1 })
				play(stroke2, TweenInfo.new(0.8), { Transparency = 1 })
				play(scale, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 1.4 })
				task.wait(0.3)
				local fade = play(bg, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
				fade.Completed:Wait()
				lgui:Destroy()
			end)
		end)
		if not okLoad then
			warn("LoadingScreen error: " .. tostring(errLoad))
			local g = playerGui:FindFirstChild("HubLoadingScreen")
			if g then g:Destroy() end
		end
	end


	-- ====== THEME ======
	local THEME = {
		Bg = Color3.fromRGB(10, 10, 18),
		Panel = Color3.fromRGB(17, 17, 28),
		Card = Color3.fromRGB(25, 25, 40),
		CardHover = Color3.fromRGB(34, 34, 54),
		Stroke = Color3.fromRGB(56, 56, 84),
		Text = Color3.fromRGB(240, 242, 255),
		SubText = Color3.fromRGB(135, 140, 175),
		Accent1 = Color3.fromRGB(168, 85, 247),
		Accent2 = Color3.fromRGB(56, 189, 248),
		Success = Color3.fromRGB(52, 211, 153),
		Warn = Color3.fromRGB(251, 146, 60),
		Danger = Color3.fromRGB(244, 63, 94),
	}
	local WHITE = Color3.fromRGB(255, 255, 255)

	-- ====== MAID ======
	local Maid = {}
	Maid.__index = Maid
	function Maid.new() return setmetatable({ _tasks = {} }, Maid) end
	function Maid:Give(item) table.insert(self._tasks, item); return item end
	function Maid:Clean()
		for _, item in ipairs(self._tasks) do
			if typeof(item) == "RBXScriptConnection" then item:Disconnect()
			elseif typeof(item) == "Instance" then item:Destroy()
			elseif type(item) == "function" then pcall(item) end
		end
		table.clear(self._tasks)
	end
	local mainMaid = Maid.new()

	-- ====== HELPER UI FUNCTIONS ======
	local function make(class, props, parent)
		local inst = Instance.new(class)
		for k, v in pairs(props) do inst[k] = v end
		inst.Parent = parent
		return inst
	end

	local function round(inst, radius)
		return make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, inst)
	end

	local function stroke(inst, color, thickness, transparency)
		return make("UIStroke", {
			Color = color or THEME.Stroke, Thickness = thickness or 1, Transparency = transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, inst)
	end

	local function gradient(inst, c1, c2, rotation)
		return make("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 0 }, inst)
	end

	local function tween(inst, t, props)
		local tw = TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		tw:Play()
		return tw
	end

	local function label(parent, props)
		local base = {
			BackgroundTransparency = 1,
			TextColor3 = THEME.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}
		for k, v in pairs(props) do base[k] = v end
		return make("TextLabel", base, parent)
	end

	local function isPress(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
	local function isMove(input) return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch end

	-- ====== CONFIGS & SETTINGS ======
	local uiLocked = false

	-- ====== ROOT GUI ======
	local gui, notify, X, window, userScale, updateScale, activeCount, updateBadge, layout, saveBtnData
	local wakeBtn, snapBtn, pages, tabButtons, reopenButton

	local function Section(name, fn, fatal)
		local ok, err = pcall(fn)
		if not ok then
			warn("PlayerHUB [" .. name .. "] " .. tostring(err))
			if fatal then error(err, 0) end
			pcall(function() notify("PlayerHUB", "โหลดส่วน " .. name .. " ไม่สำเร็จ (ดู Output)", 5, "warn") end)
		end
	end

	Section("Shell", function()
		local old = playerGui:FindFirstChild("PlayerHUB")
		if old then old:Destroy() end

		gui = make("ScreenGui", { Name = "PlayerHUB", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
		gui.Destroying:Connect(function() mainMaid:Clean() end)

		-- ====== TOAST ======
		local toastContainer = make("Frame", {
			Size = UDim2.fromOffset(270, 320),
			Position = UDim2.new(1, -282, 1, -332),
			BackgroundTransparency = 1,
			ZIndex = 50,
		}, gui)
		make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
		}, toastContainer)

		local TOAST_KIND = {
			info = { THEME.Accent2, "i" },
			success = { THEME.Success, "✓" },
			warn = { THEME.Warn, "!" },
			off = { THEME.SubText, "○" },
		}

		notify = function(title, msg, duration, kind)
			duration = duration or 2.5
			local k = TOAST_KIND[kind or "info"] or TOAST_KIND.info

			local existing = {}
			for _, c in ipairs(toastContainer:GetChildren()) do
				if c:IsA("CanvasGroup") then table.insert(existing, c) end
			end
			if #existing >= 4 then existing[1]:Destroy() end

			local card = make("CanvasGroup", {
				Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, GroupTransparency = 1,
			}, toastContainer)
			round(card, 12)
			stroke(card, k[1], 1.2, 0.35)
			make("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = k[1], BorderSizePixel = 0 }, card)
			local badge = label(card, {
				Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(14, 14), BackgroundTransparency = 0.8,
				BackgroundColor3 = k[1], Text = k[2], TextColor3 = k[1], Font = Enum.Font.GothamBold, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
			})
			round(badge, 13)
			label(card, { Size = UDim2.new(1, -58, 0, 18), Position = UDim2.fromOffset(48, 8), Text = title, Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd })
			label(card, { Size = UDim2.new(1, -58, 0, 16), Position = UDim2.fromOffset(48, 28), Text = msg, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.SubText, TextTruncate = Enum.TextTruncate.AtEnd })

			tween(card, 0.2, { GroupTransparency = 0 })
			task.delay(duration, function()
				if card and card.Parent then
					local tw = tween(card, 0.3, { GroupTransparency = 1 })
					tw.Completed:Connect(function() card:Destroy() end)
				end
			end)
		end

		X = { Ticks = {}, toggles = {}, VERSION = "v4.5" }

		do
			local dockFrame = make("Frame", {
				Size = UDim2.fromOffset(220, 10), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -150), BackgroundTransparency = 1, ZIndex = 30,
			}, gui)
			make("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
				HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6),
			}, dockFrame)
			local chips, tokens, handlers, order = {}, {}, {}, 0
			X.Dock = {}

			function X.Dock.hide(key)
				tokens[key] = (tokens[key] or 0) + 1
				local c = chips[key]
				if c then chips[key] = nil; c:Destroy() end
			end

			function X.Dock.show(key, text, onClick, seconds, kind)
				tokens[key] = (tokens[key] or 0) + 1
				local token = tokens[key]
				handlers[key] = onClick
				local c = chips[key]
				if not c then
					order = order + 1
					c = make("TextButton", {
						Size = UDim2.fromOffset(210, 38), BackgroundColor3 = WHITE, TextColor3 = WHITE, Font = Enum.Font.GothamBold,
						TextSize = 13, AutoButtonColor = false, LayoutOrder = order, ZIndex = 30,
					}, dockFrame)
					round(c, 19)
					if kind == "danger" then gradient(c, THEME.Danger, Color3.fromRGB(190, 60, 120), 0) else gradient(c, THEME.Accent1, THEME.Accent2, 0) end
					stroke(c, WHITE, 1.2, 0.55)
					c.MouseButton1Down:Connect(function() tween(c, 0.08, { BackgroundTransparency = 0.3 }) end)
					c.InputEnded:Connect(function(i) if isPress(i) then tween(c, 0.12, { BackgroundTransparency = 0 }) end end)
					c.MouseButton1Click:Connect(function() if handlers[key] then handlers[key]() end end)
					chips[key] = c
				end
				c.Text = text
				if seconds then
					task.delay(seconds, function()
						if tokens[key] == token then X.Dock.hide(key) end
					end)
				end
			end
		end

		local WIN_W, FULL_H, HEADER_H = 380, 580, 52
		window = make("Frame", {
			Name = "Window",
			Size = UDim2.fromOffset(WIN_W, FULL_H),
			Position = UDim2.fromOffset(28, 60),
			BackgroundColor3 = THEME.Bg,
			BackgroundTransparency = 0.03,
			BorderSizePixel = 0,
			Active = true,
			ClipsDescendants = true,
		}, gui)
		round(window, 16)
		local windowStroke = stroke(window, WHITE, 1.6, 0.15)
		gradient(windowStroke, THEME.Accent1, THEME.Accent2, 45)

		local uiScale = make("UIScale", { Scale = 1 }, window)
		userScale = 1
		updateScale = function()
			local camera = workspace.CurrentCamera
			local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
			uiScale.Scale = math.clamp(math.min(vp.X, vp.Y) / 800, 0.7, 1) * userScale
		end
		updateScale()

		local header = make("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
		round(header, 16)
		local headerFiller = make("Frame", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, header)
		make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0 }, headerFiller)

		local logo = make("Frame", { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, header)
		round(logo, 9)
		gradient(logo, THEME.Accent1, THEME.Accent2, 45)
		label(logo, { Size = UDim2.fromScale(1, 1), Text = "🧟", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center })

		local titleLbl = label(header, { Size = UDim2.fromOffset(120, 20), Position = UDim2.fromOffset(52, 8), Text = "PlayerHUB", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE })
		gradient(titleLbl, THEME.Accent1, THEME.Accent2, 0)
		label(header, { Size = UDim2.fromOffset(120, 14), Position = UDim2.fromOffset(52, 28), Text = "Utility Menu v4", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.SubText })

		activeCount = 0
		local badgePill = make("Frame", { Size = UDim2.fromOffset(84, 22), Position = UDim2.new(1, -126, 0, 15), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, header)
		round(badgePill, 11)
		stroke(badgePill, THEME.Stroke, 1, 0.4)
		local badgeLabel = label(badgePill, { Size = UDim2.fromScale(1, 1), Text = "● 0 ON", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center })
		X.badgeBtn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 }, badgePill)
		X.badgeBtn.MouseEnter:Connect(function() tween(badgePill, 0.12, { BackgroundColor3 = THEME.CardHover }) end)
		X.badgeBtn.MouseLeave:Connect(function() tween(badgePill, 0.12, { BackgroundColor3 = THEME.Card }) end)
		updateBadge = function()
			badgeLabel.Text = "● " .. activeCount .. " ON ▾"
			badgeLabel.TextColor3 = activeCount > 0 and THEME.Success or THEME.SubText
			if X.onActive then X.onActive() end
		end

		local function titleButton(text, xOffset, hoverColor)
			local b = make("TextButton", {
				Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, xOffset, 0, 13),
				BackgroundColor3 = THEME.Card, Text = text, TextColor3 = THEME.Text,
				Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
			}, header)
			round(b, 13)
			b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = hoverColor }) end)
			b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = THEME.Card }) end)
			return b
		end
		local minButton = titleButton("–", -36, THEME.CardHover)

		local HttpService = game:GetService("HttpService")
		local BTN_SIZE, DRAG_THRESHOLD = 50, 6
		local BTN_FILE = "PlayerHUB_button.json"

		local function loadBtnData()
			local ok, data = pcall(function() return HttpService:JSONDecode(readfile(BTN_FILE)) end)
			if ok and type(data) == "table" and tonumber(data.x) and tonumber(data.y) then return data end
			return nil
		end
		local saved = loadBtnData()
		layout = {
			rx = saved and tonumber(saved.rx) or nil, ry = saved and tonumber(saved.ry) or nil,
			snap = (saved == nil) or (saved.snap ~= false), seen = saved and saved.seen or nil,
		}

		reopenButton = make("TextButton", {
			Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE),
			Position = saved and UDim2.fromOffset(saved.x, saved.y) or UDim2.fromOffset(28, 60),
			BackgroundColor3 = WHITE, Text = "🧟", TextSize = 22, Visible = true, AutoButtonColor = false, ZIndex = 20,
		}, gui)
		round(reopenButton, 25)
		gradient(reopenButton, THEME.Accent1, THEME.Accent2, 45)
		local reopenStroke = stroke(reopenButton, WHITE, 1.5, 0.6)

		local function clampBtn()
			local sz = gui.AbsoluteSize
			local x = math.clamp(reopenButton.Position.X.Offset, 0, math.max(sz.X - BTN_SIZE, 0))
			local y = math.clamp(reopenButton.Position.Y.Offset, 0, math.max(sz.Y - BTN_SIZE, 0))
			reopenButton.Position = UDim2.fromOffset(x, y)
		end
		saveBtnData = function(xo, yo)
			pcall(function()
				writefile(BTN_FILE, HttpService:JSONEncode({
					x = xo or reopenButton.Position.X.Offset, y = yo or reopenButton.Position.Y.Offset, locked = false, rx = layout.rx, ry = layout.ry,
					snap = layout.snap, seen = layout.seen,
				}))
			end)
		end

		wakeBtn = function()
			tween(reopenButton, 0.15, { BackgroundTransparency = 0, TextTransparency = 0 })
			tween(reopenStroke, 0.15, { Transparency = 0.6 })
		end
		reopenButton.MouseEnter:Connect(wakeBtn)

		snapBtn = function()
			if not layout.snap then return nil end
			local sz = gui.AbsoluteSize
			local x = reopenButton.Position.X.Offset
			local y = reopenButton.Position.Y.Offset
			local toRight = (x + BTN_SIZE / 2) > sz.X / 2
			local tx = math.max(toRight and (sz.X - BTN_SIZE - 6) or 6, 0)
			TweenService:Create(reopenButton, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(tx, y) }):Play()
			return tx
		end

		local function setWindowVisible(vis)
			window.Visible = vis
			wakeBtn()
		end

		local btnInput, btnStartPos, btnStartOffset, btnMoved = nil, nil, nil, false
		reopenButton.InputBegan:Connect(function(input)
			if isPress(input) and not btnInput then
				btnInput = input
				btnStartPos = input.Position
				btnStartOffset = Vector2.new(reopenButton.Position.X.Offset, reopenButton.Position.Y.Offset)
				wakeBtn()
				btnMoved = false
			end
		end)
		mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
			if not btnInput then return end
			local sameDrag = (input == btnInput) or (input.UserInputType == Enum.UserInputType.MouseMovement and btnInput.UserInputType == Enum.UserInputType.MouseButton1)
			if not sameDrag then return end
			local d = input.Position - btnStartPos
			if not btnMoved and math.sqrt(d.X * d.X + d.Y * d.Y) > DRAG_THRESHOLD then
				btnMoved = true
				tween(reopenStroke, 0.12, { Transparency = 0.1 })
			end
			if btnMoved then
				reopenButton.Position = UDim2.fromOffset(btnStartOffset.X + d.X, btnStartOffset.Y + d.Y)
				clampBtn()
			end
		end))
		mainMaid:Give(UserInputService.InputEnded:Connect(function(input)
			if not btnInput then return end
			local sameDrag = (input == btnInput) or (input.UserInputType == Enum.UserInputType.MouseButton1 and btnInput.UserInputType == Enum.UserInputType.MouseButton1)
			if not sameDrag then return end
			local wasMoved = btnMoved
			btnInput, btnMoved = nil, false
			tween(reopenStroke, 0.15, { Transparency = 0.6 })
			if wasMoved then
				local fx = snapBtn()
				saveBtnData(fx)
				wakeBtn()
			else
				setWindowVisible(not window.Visible)
			end
		end))
		mainMaid:Give(UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.RightShift then setWindowVisible(not window.Visible) end
		end))

		local minimized = false
		minButton.MouseButton1Click:Connect(function()
			minimized = not minimized
			minButton.Text = minimized and "+" or "–"
			headerFiller.Visible = not minimized
			tween(window, 0.22, { Size = UDim2.fromOffset(WIN_W, minimized and HEADER_H or FULL_H) })
		end)

		local dragging, dragStart, dragOrigin = false, nil, nil
		header.InputBegan:Connect(function(input)
			if isPress(input) and not uiLocked then 
				dragging = true; dragStart = input.Position; dragOrigin = window.Position 
			end
		end)
		mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) and not uiLocked then
				local d = (input.Position - dragStart) / uiScale.Scale
				window.Position = UDim2.fromOffset(dragOrigin.X.Offset + d.X, dragOrigin.Y.Offset + d.Y)
			end
		end))
		mainMaid:Give(UserInputService.InputEnded:Connect(function(input) if isPress(input) then dragging = false end end))

		local searchWrap = make("Frame", { Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, HEADER_H + 10), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, window)
		round(searchWrap, 10)
		local searchStroke = stroke(searchWrap, THEME.Stroke, 1, 0.4)
		label(searchWrap, { Size = UDim2.fromOffset(28, 34), Position = UDim2.fromOffset(6, 0), Text = "🔍", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center })
		local searchBox = make("TextBox", {
			Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1,
			TextColor3 = THEME.Text, PlaceholderText = "ค้นหาฟังก์ชัน...", PlaceholderColor3 = THEME.SubText,
			Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
		}, searchWrap)
		searchBox.Focused:Connect(function() tween(searchStroke, 0.15, { Color = THEME.Accent2, Transparency = 0.1 }) end)
		searchBox.FocusLost:Connect(function() tween(searchStroke, 0.15, { Color = THEME.Stroke, Transparency = 0.4 }) end)

		-- ลำดับแท็บ: Stats, Route 06, Settings
		local TAB_NAMES = { "Stats", "Route 06", "Settings" }
		local TAB_ICONS = { Stats = "📊", ["Route 06"] = "🎯", Settings = "⚙️" }
		local tabY = HEADER_H + 10 + 34 + 8
		local tabBar = make("Frame", { Size = UDim2.new(1, -24, 0, 46), Position = UDim2.fromOffset(12, tabY), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
		round(tabBar, 10)
		make("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, tabBar)
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

		local contentY = tabY + 46 + 8
		local content = make("Frame", { Size = UDim2.new(1, 0, 1, -contentY), Position = UDim2.fromOffset(0, contentY), BackgroundTransparency = 1 }, window)
		pages, tabButtons = {}, {}

		local function selectTab(name)
			for n, p in pairs(pages) do p.Visible = (n == name) end
			local newDot = tabButtons[name] and tabButtons[name]:FindFirstChild("NewDot")
			if newDot then newDot:Destroy() end
			for n, b in pairs(tabButtons) do
				local active = (n == name)
				tween(b, 0.18, { BackgroundTransparency = active and 0 or 1, TextColor3 = active and WHITE or THEME.SubText })
			end
		end

		for i, name in ipairs(TAB_NAMES) do
			local page = make("ScrollingFrame", {
				Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
				ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Accent2, ScrollBarImageTransparency = 0.4,
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = (i == 1),
			}, content)
			make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
			make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }, page)
			pages[name] = page

			local btn = make("TextButton", {
				Size = UDim2.new(1 / #TAB_NAMES, -3, 1, 0), BackgroundColor3 = WHITE,
				BackgroundTransparency = (i == 1) and 0 or 1, Text = '<font size="14">' .. TAB_ICONS[name] .. '</font>\n<font size="8">' .. name .. '</font>', RichText = true,
				Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = (i == 1) and WHITE or THEME.SubText,
				AutoButtonColor = false, LayoutOrder = i,
			}, tabBar)
			round(btn, 8)
			gradient(btn, THEME.Accent1, THEME.Accent2, 0)
			tabButtons[name] = btn
			btn.MouseButton1Click:Connect(function() selectTab(name) end)
		end

		do
			local catcher = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 18 }, window)
			local panel = make("Frame", {
				Size = UDim2.fromOffset(264, 120), Position = UDim2.new(1, -276, 0, HEADER_H + 6),
				BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, Visible = false, ZIndex = 20,
			}, window)
			round(panel, 12)
			gradient(stroke(panel, WHITE, 1.4, 0.2), THEME.Accent1, THEME.Accent2, 45)
			local title = label(panel, { Size = UDim2.new(1, -110, 0, 20), Position = UDim2.fromOffset(12, 10), Text = "Active Features", Font = Enum.Font.GothamBold, TextSize = 12 })
			local offAll = make("TextButton", { Size = UDim2.fromOffset(88, 24), Position = UDim2.new(1, -98, 0, 8), BackgroundColor3 = THEME.Danger, Text = "Turn off all", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false }, panel)
			round(offAll, 8)
			local list = make("ScrollingFrame", {
				Size = UDim2.new(1, -16, 1, -46), Position = UDim2.fromOffset(8, 38), BackgroundTransparency = 1, BorderSizePixel = 0,
				ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Accent2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, panel)
			make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
			local open = false

			local function close()
				open = false
				panel.Visible = false
				catcher.Visible = false
			end

			local function refresh()
				for _, c in ipairs(list:GetChildren()) do
					if c:IsA("GuiObject") then c:Destroy() end
				end
				local n = 0
				for _, t in ipairs(X.toggles) do
					if not t.keep and t.api.get() then
						n = n + 1
						local r = make("Frame", { Size = UDim2.new(1, -2, 0, 34), BackgroundColor3 = THEME.Card, BorderSizePixel = 0, LayoutOrder = n }, list)
						round(r, 8)
						local go = make("TextButton", { Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, r)
						label(go, { Size = UDim2.new(1, -8, 0, 16), Position = UDim2.fromOffset(10, 3), Text = t.name, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd })
						label(go, { Size = UDim2.new(1, -8, 0, 12), Position = UDim2.fromOffset(10, 19), Text = "แท็บ " .. t.page.Name .. "  ·  แตะเพื่อไปที่ฟีเจอร์", TextSize = 9, TextColor3 = THEME.SubText })
						go.MouseButton1Click:Connect(function()
							close()
							selectTab(t.page.Name)
						end)
						local offBtn = make("TextButton", { Size = UDim2.fromOffset(40, 24), Position = UDim2.new(1, -46, 0.5, -12), BackgroundColor3 = THEME.CardHover, Text = "Off", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false }, r)
						round(offBtn, 7)
						offBtn.MouseButton1Click:Connect(function() t.api.set(false) end)
					end
				end
				title.Text = "Active Features  ·  " .. n
				offAll.Visible = n > 0
				if n == 0 then
					label(list, { Size = UDim2.new(1, 0, 0, 44), Text = "ยังไม่มีฟีเจอร์ที่เปิดอยู่", TextSize = 11, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center })
				end
				panel.Size = UDim2.fromOffset(264, math.clamp(54 + math.max(n, 1) * 38, 100, 330))
			end

			offAll.MouseButton1Click:Connect(function()
				for _, t in ipairs(X.toggles) do
					if not t.keep and t.api.get() then t.api.set(false, true) end
				end
				notify("Active Features", "ปิดฟีเจอร์ทั้งหมดแล้ว", 1.8, "success")
			end)
			catcher.MouseButton1Click:Connect(close)
			X.onActive = function() if open then refresh() end end
			X.badgeBtn.MouseButton1Click:Connect(function()
				if open then
					close()
				else
					open = true
					refresh()
					panel.Visible = true
					catcher.Visible = true
				end
			end)
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = string.lower(searchBox.Text)
			for _, page in pairs(pages) do
				for _, child in ipairs(page:GetChildren()) do
					if child:IsA("GuiObject") then
						if child:GetAttribute("IsHeader") then
							child.Visible = (q == "")
						else
							local s = child:GetAttribute("Search")
							child.Visible = (q == "") or (s ~= nil and string.find(s, q, 1, true) ~= nil)
						end
					end
				end
			end
		end)
	end, true)

	local resetters = {}

	local function section(page, text)
		local h = make("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, page)
		h:SetAttribute("IsHeader", true)
		local bar = make("Frame", { Size = UDim2.fromOffset(3, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, h)
		round(bar, 2)
		gradient(bar, THEME.Accent1, THEME.Accent2, 90)
		label(h, { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(10, 0), Text = string.upper(text), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = THEME.SubText })
		return h
	end

	local function card(page, height)
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, page)
		round(row, 10)
		local s = stroke(row, THEME.Stroke, 1, 0.45)
		return row, s
	end

	local function toggle(page, labelText, onToggle, desc, keepOnReset)
		local h = desc and 52 or 42
		local row, rowStroke = card(page, h)
		row:SetAttribute("Search", string.lower(labelText .. " " .. (desc or "")))

		label(row, {
			Size = UDim2.new(1, -72, 0, desc and 20 or h), Position = UDim2.fromOffset(12, desc and 8 or 0),
			Text = labelText, Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		if desc then
			label(row, { Size = UDim2.new(1, -72, 0, 16), Position = UDim2.fromOffset(12, 28), Text = desc, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.SubText, TextTruncate = Enum.TextTruncate.AtEnd })
		end

		local track = make("Frame", { Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -56, 0.5, -12), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(track, 12)
		stroke(track, THEME.Stroke, 1, 0.3)
		local trackGrad = gradient(track, THEME.Accent1, THEME.Accent2, 0)
		trackGrad.Enabled = false
		local knob = make("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = THEME.SubText, BorderSizePixel = 0 }, track)
		round(knob, 9)

		local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2 }, row)
		hit.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundColor3 = THEME.CardHover }) end)
		hit.MouseLeave:Connect(function() tween(row, 0.12, { BackgroundColor3 = THEME.Card }) end)

		local state = false
		local function apply(newState, silent)
			if newState ~= state and not keepOnReset then
				activeCount = activeCount + (newState and 1 or -1)
				updateBadge()
			end
			state = newState
			trackGrad.Enabled = state
			tween(track, 0.18, { BackgroundColor3 = state and WHITE or THEME.Panel })
			tween(knob, 0.18, {
				Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
				BackgroundColor3 = state and WHITE or THEME.SubText,
			})
			tween(rowStroke, 0.18, { Color = state and THEME.Accent2 or THEME.Stroke, Transparency = state and 0.2 or 0.45 })
			if not silent then
				notify(labelText, state and "เปิดใช้งานแล้ว" or "ปิดใช้งานแล้ว", 1.6, state and "success" or "off")
			end
			onToggle(state)
		end

		hit.MouseButton1Click:Connect(function() apply(not state) end)

		local api = {
			set = function(s, silent) if s ~= state then apply(s, silent) end end,
			get = function() return state end,
		}
		table.insert(X.toggles, { name = labelText, page = page, api = api, keep = keepOnReset })
		if not keepOnReset then
			table.insert(resetters, function() api.set(false, true) end)
		end
		return api
	end

	local function slider(page, text, minV, maxV, default, step, onChange)
		local row = card(page, 66)
		row:SetAttribute("Search", string.lower(text))
		label(row, { Size = UDim2.new(1, -120, 0, 22), Position = UDim2.fromOffset(12, 8), Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd })

		local boxWrap = make("Frame", { Size = UDim2.fromOffset(56, 24), Position = UDim2.new(1, -96, 0, 7), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(boxWrap, 7)
		stroke(boxWrap, THEME.Stroke, 1, 0.4)
		local box = make("TextBox", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextColor3 = THEME.Accent2, Font = Enum.Font.GothamBold,
			TextSize = 12, ClearTextOnFocus = false, Text = tostring(default),
		}, boxWrap)

		local resetBtn = make("TextButton", {
			Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, -36, 0, 7), BackgroundColor3 = THEME.Panel,
			TextColor3 = THEME.SubText, Font = Enum.Font.GothamBold, TextSize = 13, Text = "↺", AutoButtonColor = false,
		}, row)
		round(resetBtn, 7)
		resetBtn.MouseEnter:Connect(function() tween(resetBtn, 0.12, { TextColor3 = THEME.Accent2 }) end)
		resetBtn.MouseLeave:Connect(function() tween(resetBtn, 0.12, { TextColor3 = THEME.SubText }) end)

		local track = make("Frame", { Size = UDim2.new(1, -28, 0, 8), Position = UDim2.new(0, 14, 0, 46), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(track, 4)
		local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
		round(fill, 4)
		gradient(fill, THEME.Accent1, THEME.Accent2, 0)
		local knob = make("Frame", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, track)
		round(knob, 9)
		stroke(knob, THEME.Accent2, 2, 0.1)
		local area = make("TextButton", { Size = UDim2.new(1, 20, 0, 30), Position = UDim2.new(0, -10, 0.5, -15), BackgroundTransparency = 1, Text = "", ZIndex = 4 }, track)

		local value = default
		local function setValue(v, silent)
			v = math.clamp(math.round(v / step) * step, minV, maxV)
			v = tonumber(string.format("%.3f", v))
			value = v
			local p = math.clamp((v - minV) / (maxV - minV), 0, 1)
			fill.Size = UDim2.fromScale(p, 1)
			knob.Position = UDim2.fromScale(p, 0.5)
			box.Text = tostring(v)
			if not silent then onChange(v) end
		end

		local dragInput
		local function updateFromX(x)
			local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			setValue(minV + (maxV - minV) * p)
		end
		local function isSameDrag(input)
			if not dragInput then return false end
			if input == dragInput then return true end
			return dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1
		end

		area.InputBegan:Connect(function(input)
			if isPress(input) then
				dragInput = input
				page.ScrollingEnabled = false
				tween(knob, 0.1, { Size = UDim2.fromOffset(22, 22) })
				updateFromX(input.Position.X)
			end
		end)
		mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
			if dragInput and (input == dragInput or (input.UserInputType == Enum.UserInputType.MouseMovement and dragInput.UserInputType == Enum.UserInputType.MouseButton1)) then
				updateFromX(input.Position.X)
			end
		end))
		mainMaid:Give(UserInputService.InputEnded:Connect(function(input)
			if isSameDrag(input) then
				dragInput = nil
				page.ScrollingEnabled = true
				tween(knob, 0.1, { Size = UDim2.fromOffset(18, 18) })
			end
		end))

		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n then setValue(n) else box.Text = tostring(value) end
		end)

		resetBtn.MouseButton1Click:Connect(function() setValue(default) end)
		setValue(default, true)
		table.insert(resetters, function() setValue(default) end)
		return { reset = function() setValue(default) end, set = setValue }
	end

	local function button(page, text, onClick, kind)
		kind = kind or "ghost"
		local btn = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = (kind == "primary") and WHITE or (kind == "danger" and THEME.Danger or THEME.Card),
			Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
			BackgroundTransparency = (kind == "danger") and 0.15 or 0,
		}, page)
		btn:SetAttribute("Search", string.lower(text))
		round(btn, 10)
		if kind == "primary" then
			gradient(btn, THEME.Accent1, THEME.Accent2, 0)
		elseif kind == "danger" then
			stroke(btn, THEME.Danger, 1, 0.4)
		else
			stroke(btn, THEME.Stroke, 1, 0.45)
		end
		local baseColor = btn.BackgroundColor3
		if kind == "ghost" then
			btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = THEME.CardHover }) end)
			btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = baseColor }) end)
		end
		btn.MouseButton1Down:Connect(function() tween(btn, 0.08, { BackgroundTransparency = 0.3 }) end)
		btn.InputEnded:Connect(function(i)
			if isPress(i) then tween(btn, 0.12, { BackgroundTransparency = (kind == "danger") and 0.15 or 0 }) end
		end)
		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	local F = {
		cfSpeed = false, cfSpeedVal = 1,
		playerHL = false, itemHL = false, mobEsp = false,
		fullbright = false,
		zombieLock = false,
		zombieDetectRange = 100,
		zombieDist = 6,
		zombieCount = 3,
		killAura = false,
		killAuraRange = 45,
	}

	local function getHumanoid() local char = player.Character return char and char:FindFirstChildOfClass("Humanoid") end
	local function getOrigin()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then return hrp.Position end
		local cam = workspace.CurrentCamera
		return cam and cam.CFrame.Position or Vector3.zero
	end

	local function getTargetPart(v)
		if v:IsA("BasePart") then return v end
		if v:IsA("Tool") then return v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart", true) end
		if v:IsA("Model") then return v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true) end
		return nil
	end

	-- ==========================================
	-- 📊 1. TAB: STATS
	-- ==========================================
	Section("Stats", function()
		local pStats = pages["Stats"]

		section(pStats, "Server & Performance")
		local r1, _ = card(pStats, 42)
		label(r1, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "FPS: ...", Font = Enum.Font.GothamBold, TextSize = 12 })
		local fpsValLbl = label(r1, { Size = UDim2.new(1, -24, 1, 0), Text = "60 FPS", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local r2, _ = card(pStats, 42)
		label(r2, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Ping (Network Latency): ...", Font = Enum.Font.GothamBold, TextSize = 12 })
		local pingValLbl = label(r2, { Size = UDim2.new(1, -24, 1, 0), Text = "0 ms", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local rMemory, _ = card(pStats, 42)
		label(rMemory, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Memory Usage:", Font = Enum.Font.GothamBold, TextSize = 12 })
		local memoryValLbl = label(rMemory, { Size = UDim2.new(1, -24, 1, 0), Text = "0 MB", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local r3, _ = card(pStats, 42)
		label(r3, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Server Uptime / Time:", Font = Enum.Font.GothamBold, TextSize = 12 })
		local timeValLbl = label(r3, { Size = UDim2.new(1, -24, 1, 0), Text = "00:00:00", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local rTimeGame, _ = card(pStats, 42)
		label(rTimeGame, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "In-Game Time:", Font = Enum.Font.GothamBold, TextSize = 12 })
		local timeGameValLbl = label(rTimeGame, { Size = UDim2.new(1, -24, 1, 0), Text = "00:00", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local r4, _ = card(pStats, 42)
		label(r4, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Online Players:", Font = Enum.Font.GothamBold, TextSize = 12 })
		local onlineValLbl = label(r4, { Size = UDim2.new(1, -24, 1, 0), Text = "1 / 1", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		section(pStats, "Player Core Stats")
		local r5, _ = card(pStats, 42)
		label(r5, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Health Status:", Font = Enum.Font.GothamBold, TextSize = 12 })
		local hpValLbl = label(r5, { Size = UDim2.new(1, -24, 1, 0), Text = "100 / 100", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		local r6, _ = card(pStats, 42)
		label(r6, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Position (X, Y, Z):", Font = Enum.Font.GothamBold, TextSize = 12 })
		local posValLbl = label(r6, { Size = UDim2.new(1, -24, 1, 0), Text = "0, 0, 0", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

		table.insert(X.Ticks, function()
			fpsValLbl.Text = math.round(X.fps or 60) .. " FPS"
			local ping = 0
			pcall(function()
				ping = math.round(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			pingValLbl.Text = ping .. " ms"

			pcall(function()
				memoryValLbl.Text = math.round(StatsService:GetTotalMemoryUsageMb()) .. " MB"
			end)

			local totalSec = math.round(workspace.DistributedGameTime)
			local hrs = math.floor(totalSec / 3600)
			local mins = math.floor((totalSec % 3600) / 60)
			local secs = totalSec % 60
			timeValLbl.Text = string.format("%02d:%02d:%02d", hrs, mins, secs)

			local clockTime = Lighting.ClockTime
			local cHours = math.floor(clockTime)
			local cMins = math.floor((clockTime % 1) * 60)
			timeGameValLbl.Text = string.format("%02d:%02d", cHours, cMins)

			onlineValLbl.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers

			local hum = getHumanoid()
			if hum then
				hpValLbl.Text = math.round(hum.Health) .. " / " .. math.round(hum.MaxHealth)
			else
				hpValLbl.Text = "Dead / None"
			end

			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local p = hrp.Position
				posValLbl.Text = string.format("%d, %d, %d", math.round(p.X), math.round(p.Y), math.round(p.Z))
			else
				posValLbl.Text = "N/A"
			end
		end)
	end)

	local ITEM_KEYS = { "coin", "money", "gem", "cash", "gold", "drop", "item", "fruit", "box", "chest" }
	local function isItemInst(v)
		if v:IsA("Tool") then return true end
		if not (v:IsA("BasePart") or v:IsA("Model")) then return false end
		local n = v.Name:lower()
		for _, k in ipairs(ITEM_KEYS) do
			if n:find(k, 1, true) then return true end
		end
		return false
	end

	local function scanWorld(wantMobs, wantItems)
		local mobs, items = {}, {}
		local myChar = player.Character
		for _, obj in ipairs(workspace:GetDescendants()) do
			if wantMobs and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
				mobs[#mobs + 1] = obj
			end
			if wantItems and isItemInst(obj) then
				local parent = obj.Parent
				local inCharacter = parent and parent:FindFirstChildOfClass("Humanoid") ~= nil
				local dupOfParent = parent and obj:IsA("BasePart") and (parent:IsA("Tool") or (parent:IsA("Model") and isItemInst(parent)))
				if not inCharacter and not dupOfParent and not (myChar and obj:IsDescendantOf(myChar)) then
					items[#items + 1] = obj
				end
			end
		end
		return mobs, items
	end

	local function nearest(list, n)
		local origin = getOrigin()
		local arr = {}
		for _, obj in ipairs(list) do
			local part = getTargetPart(obj)
			if part then arr[#arr + 1] = { obj = obj, d = (part.Position - origin).Magnitude } end
		end
		table.sort(arr, function(a, b) return a.d < b.d end)
		local out = {}
		for i = 1, math.min(n, #arr) do out[i] = arr[i] end
		return out
	end

	-- ==========================================
	-- 🎯 2. TAB: ROUTE 06
	-- ==========================================
	local playerHighlights, itemHighlights, mobHighlights = {}, {}, {}

	local function clearStore(store)
		for k, hl in pairs(store) do
			if hl then hl:Destroy() end
			store[k] = nil
		end
	end

	Section("Route 06", function()
		local pR = pages["Route 06"]
		local mobCache, runScan

		section(pR, "Movement")
		toggle(pR, "CFrame Speed", function(on) F.cfSpeed = on end, "เร่งความเร็วด้วยการเลื่อนพิกัด")
		slider(pR, "CFrame Multiplier", 0.5, 5, 1, 0.1, function(v) F.cfSpeedVal = v end)

		section(pR, "Combat")
		toggle(pR, "Kill Aura", function(on)
			F.killAura = on
		end, "Route 06: กวาดล้างซอมบี้รอบตัวอัตโนมัติ")
		slider(pR, "Kill Aura Range", 10, 100, 45, 5, function(v)
			F.killAuraRange = v
		end)

		toggle(pR, "Mob Lock & Bring", function(on) F.zombieLock = on end, "ดึงมอนสเตอร์ที่อยู่ในระยะมาล็อกไว้ตรงหน้า")
		slider(pR, "Bring Detection Range (Studs)", 20, 500, 100, 10, function(v) F.zombieDetectRange = v end)
		slider(pR, "Lock Front Distance", 3, 25, 6, 1, function(v) F.zombieDist = v end)
		slider(pR, "Bring Count", 1, 10, 3, 1, function(v) F.zombieCount = v end)

		section(pR, "Lighting")

		local fbOrig
		toggle(pR, "Fullbright", function(on)
			F.fullbright = on
			if on then
				fbOrig = { Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient }
			elseif fbOrig then
				Lighting.Brightness = fbOrig.Brightness
				Lighting.GlobalShadows = fbOrig.GlobalShadows
				Lighting.OutdoorAmbient = fbOrig.OutdoorAmbient
				fbOrig = nil
			end
		end, "สว่างไร้เงา")

		local removedWeather = {}
		toggle(pR, "Weather Remover", function(on)
			if on then
				local function stash(inst)
					table.insert(removedWeather, { inst = inst, parent = inst.Parent })
					pcall(function() inst.Parent = ReplicatedStorage end)
				end
				for _, v in ipairs(Lighting:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Clouds") then stash(v) end
				end
				local terrain = workspace:FindFirstChildOfClass("Terrain")
				local clouds = terrain and terrain:FindFirstChildOfClass("Clouds")
				if clouds then stash(clouds) end
			else
				for _, r in ipairs(removedWeather) do
					pcall(function() r.inst.Parent = r.parent end)
				end
				table.clear(removedWeather)
			end
		end, "ลบสภาพอากาศ / เมฆ")

		section(pR, "ESP")

		local ITEM_HL_MAX, MOB_HL_MAX = 10, 10

		local function syncHighlights(store, entries, color)
			local keep = {}
			for _, e in ipairs(entries) do
				local obj = e.obj
				keep[obj] = true
				local hl = store[obj]
				if not hl or hl.Parent ~= obj then
					if hl then hl:Destroy() end
					hl = Instance.new("Highlight")
					hl.FillColor = color; hl.FillTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = obj
					store[obj] = hl
				end
			end
			for obj, hl in pairs(store) do
				if not keep[obj] then hl:Destroy(); store[obj] = nil end
			end
		end

		mobCache = {}
		runScan = function()
			local wantMobs = F.mobEsp or F.zombieLock or F.killAura
			local wantItems = F.itemHL
			if not (wantMobs or wantItems) then return end
			local mobs, items = scanWorld(wantMobs, wantItems)
			if wantMobs then mobCache = mobs end
			if F.mobEsp then syncHighlights(mobHighlights, nearest(mobs, MOB_HL_MAX), Color3.fromRGB(255, 50, 50)) end
			if F.itemHL then syncHighlights(itemHighlights, nearest(items, ITEM_HL_MAX), Color3.fromRGB(255, 255, 255)) end
		end

		task.spawn(function()
			while gui.Parent do
				pcall(runScan)
				task.wait(1)
			end
		end)

		toggle(pR, "Player Highlight", function(on) F.playerHL = on end, "ไฮไลต์ผู้เล่น (เขียว)")
		toggle(pR, "Item Highlights", function(on)
			F.itemHL = on
			if on then pcall(runScan) else clearStore(itemHighlights) end
		end, "ไฮไลต์ไอเทมใกล้ตัว (ขาว)")
		toggle(pR, "Mob ESP", function(on)
			F.mobEsp = on
			if on then pcall(runScan) else clearStore(mobHighlights) end
		end, "ไฮไลต์มอนสเตอร์ใกล้ตัว (แดง)")
	end)

	-- ==========================================
	-- ⚙️ 6. TAB: SETTINGS
	-- ==========================================
	Section("Settings", function()
		local pSettings = pages["Settings"]

		section(pSettings, "Server Actions")
		button(pSettings, "🔄  Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
		button(pSettings, "🌐  Server Hop", function() TeleportService:Teleport(game.PlaceId, player) end)

		section(pSettings, "Interface")
		slider(pSettings, "UI Size Scale", 0.6, 1.4, 1, 0.05, function(v) userScale = v; updateScale() end)
		
		toggle(pSettings, "Lock UI Position", function(on)
			uiLocked = on
		end, "ล็อกตำแหน่งหน้าต่าง UI ไม่ให้ขยับ", true)

		section(pSettings, "Connection")
		local antiAfkConn
		toggle(pSettings, "Anti-AFK", function(on)
			if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
			if on then
				local vu = game:GetService("VirtualUser")
				antiAfkConn = player.Idled:Connect(function()
					vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					task.wait(1)
					vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end)
			end
		end, "กันถูกเตะหลุดจากการ AFK", true)
		mainMaid:Give(function() if antiAfkConn then antiAfkConn:Disconnect() end end)

		section(pSettings, "System")
		button(pSettings, "Reset All Values", function()
			for _, fn in ipairs(resetters) do pcall(fn) end
			notify("System", "รีเซ็ตค่าทั้งหมดแล้ว", 2, "success")
		end, "danger")
	end)

	-- ==========================================
	-- 🔁 MAIN LOOP (RenderStepped)
	-- ==========================================
	mainMaid:Give(RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		X.fps = X.fps and (X.fps * 0.92 + (1 / math.max(dt, 0.001)) * 0.08) or 60

		if F.fullbright then
			Lighting.Brightness = 2; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		end

		if F.cfSpeed and hrp and hum and hum.MoveDirection.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + hum.MoveDirection * (F.cfSpeedVal * 0.4)
		end

		if F.zombieLock and hrp then
			local mobs = scanWorld(true, false)
			local alive = {}
			for _, m in ipairs(mobs) do
				local h = m:FindFirstChildOfClass("Humanoid")
				local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
				if h and root and h.Health > 0 then
					local dist = (root.Position - hrp.Position).Magnitude
					if dist <= F.zombieDetectRange then
						table.insert(alive, {Model = m, Hrp = root, Hum = h, Dist = dist})
					end
				end
			end
			table.sort(alive, function(a, b) return a.Dist < b.Dist end)
			local targetCF = hrp.CFrame * CFrame.new(0, 0, -F.zombieDist)
			for i = 1, math.min(F.zombieCount, #alive) do
				local z = alive[i]
				z.Hrp.CFrame = targetCF
				pcall(function()
					z.Hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					z.Hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					z.Hum:ChangeState(Enum.HumanoidStateType.Physics)
				end)
			end
		end

		-- ====== KILL AURA LOGIC (Route 06) ======
		if F.killAura and hrp then
			pcall(function()
				local mobs = scanWorld(true, false)
				for _, m in ipairs(mobs) do
					local zRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
					local zHum = m:FindFirstChildOfClass("Humanoid")
					if zRoot and zHum and zHum.Health > 0 then
						local dist = (zRoot.Position - hrp.Position).Magnitude
						if dist <= (F.killAuraRange or 45) then
							zRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
							zHum.Health = 0
						end
					end
				end
			end)
		end

		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= player and target.Character then
				local thum = target.Character:FindFirstChildOfClass("Humanoid")
				if F.playerHL and thum and thum.Health > 0 then
					if not playerHighlights[target] or playerHighlights[target].Parent ~= target.Character then
						if playerHighlights[target] then playerHighlights[target]:Destroy() end
						local hl = Instance.new("Highlight", target.Character)
						hl.FillColor = Color3.fromRGB(50, 255, 50); hl.FillTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						playerHighlights[target] = hl
					end
				elseif playerHighlights[target] then
					playerHighlights[target]:Destroy(); playerHighlights[target] = nil
				end
			end
		end

		X.tickAcc = (X.tickAcc or 0) + dt
		if X.tickAcc >= 0.5 then
			X.tickAcc = 0
			for _, fn in ipairs(X.Ticks) do pcall(fn) end
		end
	end))

	mainMaid:Give(Players.PlayerRemoving:Connect(function(p)
		if playerHighlights[p] then playerHighlights[p]:Destroy(); playerHighlights[p] = nil end
	end))

	mainMaid:Give(function()
		clearStore(itemHighlights); clearStore(mobHighlights); clearStore(playerHighlights)
	end)

	notify("PlayerHUB", "โหลดสคริปต์เรียบร้อย", 3, "success")
end)

if not Success then
	warn("PlayerHUB Error: " .. tostring(Err))
end
