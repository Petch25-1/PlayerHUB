local Success, Err = pcall(function()
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local TeleportService = game:GetService("TeleportService")
	local Lighting = game:GetService("Lighting")
	local StatsService = game:GetService("Stats")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end

	-- ====== LOADING SCREEN ======
	do
		local okLoad, errLoad = pcall(function()
			local LOAD_TITLE = "PLAYERHUBDUMPER"
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

	-- ====== ROOT GUI ======
	local gui, notify, X, window, userScale, updateScale, pages, tabButtons

	local function Section(name, fn, fatal)
		local ok, err = pcall(fn)
		if not ok then
			warn("Hub [" .. name .. "] " .. tostring(err))
			if fatal then error(err, 0) end
		end
	end

	Section("Shell", function()
		local old = playerGui:FindFirstChild("CustomHub")
		if old then old:Destroy() end

		gui = make("ScreenGui", { Name = "CustomHub", ResetOnSpawn = false, DisplayOrder = 100 }, playerGui)
		gui.Destroying:Connect(function() mainMaid:Clean() end)

		-- ====== TOAST ======
		local toastContainer = make("Frame", {
			Size = UDim2.fromOffset(270, 320), Position = UDim2.new(1, -282, 1, -332),
			BackgroundTransparency = 1, ZIndex = 50,
		}, gui)
		make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8) }, toastContainer)

		notify = function(title, msg, duration, kind)
			duration = duration or 2.5
			local kColor = (kind == "success" and THEME.Success) or (kind == "warn" and THEME.Warn) or THEME.Accent2

			local card = make("CanvasGroup", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0, GroupTransparency = 1 }, toastContainer)
			round(card, 12)
			stroke(card, kColor, 1.2, 0.35)
			make("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = kColor, BorderSizePixel = 0 }, card)
			label(card, { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(14, 8), Text = title, Font = Enum.Font.GothamBold, TextSize = 12 })
			label(card, { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(14, 28), Text = msg, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.SubText })

			tween(card, 0.2, { GroupTransparency = 0 })
			task.delay(duration, function()
				if card and card.Parent then
					local tw = tween(card, 0.3, { GroupTransparency = 1 })
					tw.Completed:Connect(function() card:Destroy() end)
				end
			end)
		end

		X = { Ticks = {}, toggles = {} }

		local WIN_W, FULL_H, HEADER_H = 350, 460, 46
		window = make("Frame", {
			Name = "Window", Size = UDim2.fromOffset(WIN_W, FULL_H), Position = UDim2.fromOffset(28, 60),
			BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.03, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
		}, gui)
		round(window, 14)
		local windowStroke = stroke(window, WHITE, 1.6, 0.15)
		gradient(windowStroke, THEME.Accent1, THEME.Accent2, 45)

		-- ระบบปรับสเกลขนาด UI
		local uiScale = make("UIScale", { Scale = 0.85 }, window) -- ค่าเริ่มต้นเล็กลง (0.85)
		userScale = 0.85
		updateScale = function(val)
			userScale = val
			uiScale.Scale = val
		end

		local header = make("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
		round(header, 14)
		local headerFiller = make("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, header)

		local logo = make("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(10, 9), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, header)
		round(logo, 8)
		gradient(logo, THEME.Accent1, THEME.Accent2, 45)
		label(logo, { Size = UDim2.fromScale(1, 1), Text = "⚡", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center })

		local titleLbl = label(header, { Size = UDim2.fromOffset(150, 18), Position = UDim2.fromOffset(46, 7), Text = "Advanced Hub", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE })
		gradient(titleLbl, THEME.Accent1, THEME.Accent2, 0)
		label(header, { Size = UDim2.fromOffset(150, 12), Position = UDim2.fromOffset(46, 25), Text = "Dumper & Stats Edition", Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = THEME.SubText })

		local minButton = make("TextButton", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -30, 0, 12), BackgroundColor3 = THEME.Card, Text = "–", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false }, header)
		round(minButton, 11)

		local minimized = false
		minButton.MouseButton1Click:Connect(function()
			minimized = not minimized
			minButton.Text = minimized and "+" or "–"
			headerFiller.Visible = not minimized
			tween(window, 0.22, { Size = UDim2.fromOffset(WIN_W, minimized and HEADER_H or FULL_H) })
		end)

		local dragging, dragStart, dragOrigin = false, nil, nil
		header.InputBegan:Connect(function(input)
			if isPress(input) then dragging = true; dragStart = input.Position; dragOrigin = window.Position end
		end)
		mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local d = (input.Position - dragStart)
				window.Position = UDim2.fromOffset(dragOrigin.X.Offset + d.X, dragOrigin.Y.Offset + d.Y)
			end
		end))
		mainMaid:Give(UserInputService.InputEnded:Connect(function(input) if isPress(input) then dragging = false end end))

		local TAB_NAMES = { "Stats", "Dumper", "Settings" }
		local TAB_ICONS = { Stats = "📊", Dumper = "💾", Settings = "⚙️" }
		local tabY = HEADER_H + 10
		local tabBar = make("Frame", { Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, tabY), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
		round(tabBar, 8)
		make("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, tabBar)
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

		local contentY = tabY + 36 + 6
		local content = make("Frame", { Size = UDim2.new(1, 0, 1, -contentY), Position = UDim2.fromOffset(0, contentY), BackgroundTransparency = 1 }, window)
		pages, tabButtons = {}, {}

		local function selectTab(name)
			for n, p in pairs(pages) do p.Visible = (n == name) end
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
			make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
			make("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }, page)
			pages[name] = page

			local btn = make("TextButton", {
				Size = UDim2.new(1 / #TAB_NAMES, -2, 1, 0), BackgroundColor3 = WHITE,
				BackgroundTransparency = (i == 1) and 0 or 1, Text = TAB_ICONS[name] .. " " .. name,
				Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = (i == 1) and WHITE or THEME.SubText,
				AutoButtonColor = false, LayoutOrder = i,
			}, tabBar)
			round(btn, 6)
			gradient(btn, THEME.Accent1, THEME.Accent2, 0)
			tabButtons[name] = btn
			btn.MouseButton1Click:Connect(function() selectTab(name) end)
		end
	end, true)

	local function section(page, text)
		local h = make("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, page)
		local bar = make("Frame", { Size = UDim2.fromOffset(3, 10), Position = UDim2.new(0, 0, 0.5, -5), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, h)
		round(bar, 2)
		gradient(bar, THEME.Accent1, THEME.Accent2, 90)
		label(h, { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(8, 0), Text = string.upper(text), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = THEME.SubText })
		return h
	end

	local function card(page, height)
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, page)
		round(row, 8)
		stroke(row, THEME.Stroke, 1, 0.45)
		return row
	end

	local function toggle(page, labelText, onToggle, initVal)
		local row = card(page, 38)
		label(row, { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), Text = labelText, Font = Enum.Font.GothamBold, TextSize = 11 })

		local track = make("Frame", { Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(track, 10)
		stroke(track, THEME.Stroke, 1, 0.3)
		local trackGrad = gradient(track, THEME.Accent1, THEME.Accent2, 0)
		trackGrad.Enabled = (initVal == true)
		local knob = make("Frame", { Size = UDim2.fromOffset(16, 16), Position = initVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
		round(knob, 8)

		local state = initVal == true
		local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, row)
		hit.MouseButton1Click:Connect(function()
			state = not state
			trackGrad.Enabled = state
			tween(track, 0.18, { BackgroundColor3 = state and WHITE or THEME.Panel })
			tween(knob, 0.18, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
			onToggle(state)
		end)
	end

	local function button(page, text, onClick, kind)
		kind = kind or "ghost"
		local btn = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = (kind == "primary") and WHITE or (kind == "danger" and THEME.Danger or THEME.Card),
			Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false,
		}, page)
		round(btn, 8)
		if kind == "primary" then gradient(btn, THEME.Accent1, THEME.Accent2, 0)
		elseif kind == "danger" then stroke(btn, THEME.Danger, 1, 0.4)
		else stroke(btn, THEME.Stroke, 1, 0.45) end
		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	-- ==========================================
	-- 📊 1. TAB: STATS
	-- ==========================================
	Section("Stats", function()
		local pStats = pages["Stats"]
		section(pStats, "Performance")
		local r1 = card(pStats, 38)
		label(r1, { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), Text = "FPS", Font = Enum.Font.GothamBold, TextSize = 11 })
		local fpsLbl = label(r1, { Size = UDim2.new(1, -20, 1, 0), Text = "60", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right })

		local r2 = card(pStats, 38)
		label(r2, { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), Text = "Players Online", Font = Enum.Font.GothamBold, TextSize = 11 })
		local onlineLbl = label(r2, { Size = UDim2.new(1, -20, 1, 0), Text = "1", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right })

		table.insert(X.Ticks, function()
			fpsLbl.Text = math.round(X.fps or 60)
			onlineLbl.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
		end)
	end)

	-- ==========================================
	-- 💾 2. TAB: DUMPER
	-- ==========================================
	Section("Dumper", function()
		local pDumper = pages["Dumper"]

		section(pDumper, "Output Configuration")
		local rFolder = card(pDumper, 46)
		label(rFolder, { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 4), Text = "Folder / File Output Name", Font = Enum.Font.GothamBold, TextSize = 10 })
		local folderBox = make("TextBox", {
			Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 20),
			BackgroundColor3 = THEME.Panel, TextColor3 = WHITE, Text = "PotassiumDump_" .. tostring(game.PlaceId),
			Font = Enum.Font.Gotham, TextSize = 10, ClearTextOnFocus = false,
		}, rFolder)
		round(folderBox, 5)
		stroke(folderBox, THEME.Stroke, 1, 0.4)
		make("UIPadding", { PaddingLeft = UDim.new(0, 5) }, folderBox)

		section(pDumper, "Scripts & Components")
		local dumperOpts = {
			LocalScript = true,
			ModuleScript = true,
			ClientScript = true,
			RemoteEvent = true,
			RemoteFunction = true,
			Bindables = false,
			ReplicatedFirst = true,
			StarterGui = true,
			StarterPack = true,
		}

		toggle(pDumper, "LocalScript", function(on) dumperOpts.LocalScript = on end, true)
		toggle(pDumper, "ModuleScript", function(on) dumperOpts.ModuleScript = on end, true)
		toggle(pDumper, "Script (Client Run)", function(on) dumperOpts.ClientScript = on end, true)
		toggle(pDumper, "RemoteEvent", function(on) dumperOpts.RemoteEvent = on end, true)
		toggle(pDumper, "RemoteFunction", function(on) dumperOpts.RemoteFunction = on end, true)
		toggle(pDumper, "Bindables", function(on) dumperOpts.Bindables = on end, false)
		toggle(pDumper, "ReplicatedFirst", function(on) dumperOpts.ReplicatedFirst = on end, true)
		toggle(pDumper, "StarterGui", function(on) dumperOpts.StarterGui = on end, true)
		toggle(pDumper, "StarterPack", function(on) dumperOpts.StarterPack = on end, true)

		section(pDumper, "Execution & Progress")
		local rProg = card(pDumper, 68)
		local statusLbl = label(rProg, { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 6), Text = "ready", TextSize = 10, TextColor3 = THEME.SubText })
		
		local progBg = make("Frame", { Size = UDim2.new(1, -20, 0, 6), Position = UDim2.fromOffset(10, 26), BackgroundColor3 = THEME.Panel }, rProg)
		round(progBg, 3)
		local progFill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE }, progBg)
		round(progFill, 3)
		gradient(progFill, THEME.Accent1, THEME.Accent2, 0)

		button(pDumper, "START DUMP", function()
			local folderName = folderBox.Text ~= "" and folderBox.Text or ("Dump_" .. game.PlaceId)
			statusLbl.Text = "กำลังดัมพ์ข้อมูลตามหมวดหมู่..."

			task.spawn(function()
				local targets = {}
				for _, v in ipairs(game:GetDescendants()) do
					if (dumperOpts.LocalScript and v:IsA("LocalScript")) or
					   (dumperOpts.ModuleScript and v:IsA("ModuleScript")) or
					   (dumperOpts.ClientScript and v:IsA("Script")) or
					   (dumperOpts.RemoteEvent and v:IsA("RemoteEvent")) or
					   (dumperOpts.RemoteFunction and v:IsA("RemoteFunction")) or
					   (dumperOpts.Bindables and (v:IsA("BindableEvent") or v:IsA("BindableFunction"))) then
						table.insert(targets, v)
					end
				end

				local total = #targets
				local count = 0

				if total == 0 then
					statusLbl.Text = "ไม่พบไฟล์ที่ตรงกับเงื่อนไข"
					notify("Dumper", "ไม่พบไฟล์ในหมวดหมู่ที่เลือก", 2, "warn")
					return
				end

				for _, v in ipairs(targets) do
					count = count + 1
					local percent = count / total
					tween(progFill, 0.1, { Size = UDim2.new(percent, 0, 1, 0) })
					statusLbl.Text = string.format("กำลังดัมพ์: %s (%d/%d)", v.Name, count, total)

					if v:IsA("LuaSourceContainer") then
						local stat, src = pcall(decompile, v)
						if stat and src then
							local subFolder = folderName .. "/" .. v.ClassName .. "s"
							if not isfolder(subFolder) then makefolder(subFolder) end
							pcall(function()
								writefile(subFolder .. "/" .. v.Name .. ".lua", src)
							end)
						end
					end
					task.wait(0.01)
				end

				statusLbl.Text = "dumped successfully! (" .. count .. " items)"
				notify("Success! 🎉", "บันทึกไฟล์ทั้งหมดลงโฟลเดอร์ '" .. folderName .. "' แล้ว", 4, "success")
			end)
		end, "primary")
	end)

	-- ==========================================
	-- ⚙️ 3. TAB: SETTINGS (มีตัวปรับขนาด UI เล็ก-ใหญ่)
	-- ==========================================
	Section("Settings", function()
		local pSettings = pages["Settings"]
		section(pSettings, "Interface Scale")
		local rScale = card(pSettings, 46)
		label(rScale, { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 6), Text = "UI Size Scale (เล็ก - ใหญ่)", Font = Enum.Font.GothamBold, TextSize = 10 })
		
		local scaleBox = make("TextBox", {
			Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -60, 0, 20),
			BackgroundColor3 = THEME.Panel, TextColor3 = WHITE, Text = "0.85",
			Font = Enum.Font.GothamBold, TextSize = 10, ClearTextOnFocus = false,
		}, rScale)
		round(scaleBox, 4)
		stroke(scaleBox, THEME.Stroke, 1, 0.4)

		scaleBox.FocusLost:Connect(function()
			local val = tonumber(scaleBox.Text)
			if val then
				val = math.clamp(val, 0.5, 1.5)
				scaleBox.Text = tostring(val)
				updateScale(val)
				notify("Settings", "ปรับขนาด UI เป็น " .. val, 1.5, "success")
			else
				scaleBox.Text = tostring(userScale)
			end
		end)

		section(pSettings, "Server Actions")
		button(pSettings, "🔄 Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
		button(pSettings, "🌐 Server Hop", function() TeleportService:Teleport(game.PlaceId, player) end)

		section(pSettings, "Utility")
		toggle(pSettings, "Anti-AFK", function(on)
			if on then
				local vu = game:GetService("VirtualUser")
				mainMaid:Give(player.Idled:Connect(function()
					vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					task.wait(1)
					vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end))
			end
		end, false)
	end)

	mainMaid:Give(RunService.RenderStepped:Connect(function(dt)
		X.fps = X.fps and (X.fps * 0.92 + (1 / math.max(dt, 0.001)) * 0.08) or 60
	end))

	notify("Hub", "โหลดสคริปต์เรียบร้อย", 3, "success")
end)

if not Success then
	warn("Hub Error: " .. tostring(Err))
end
