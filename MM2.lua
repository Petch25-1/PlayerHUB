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
			local LOAD_TITLE = "PLAYERHUBMM2"
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
	local tpSpeedMultiplier = 250
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

		X = { Ticks = {}, toggles = {}, VERSION = "v4.5-MM2" }

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
		label(logo, { Size = UDim2.fromScale(1, 1), Text = "🔪", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center })

		local titleLbl = label(header, { Size = UDim2.fromOffset(140, 20), Position = UDim2.fromOffset(52, 8), Text = "PlayerHUB", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE })
		gradient(titleLbl, THEME.Accent1, THEME.Accent2, 0)
		label(header, { Size = UDim2.fromOffset(140, 14), Position = UDim2.fromOffset(52, 28), Text = "MM2 Edition", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.SubText })

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
		local BTN_FILE = "PlayerHUB_MM2_button.json"

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
			BackgroundColor3 = WHITE, Text = "🔪", TextSize = 22, Visible = true, AutoButtonColor = false, ZIndex = 20,
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
			local sameDrag = (input == btnInput) or (input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
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

		local TAB_NAMES = { "Stats", "Player", "Visuals", "MM2", "Settings" }
		local TAB_ICONS = { Stats = "📊", Player = "🚶", Visuals = "👁", MM2 = "🔪", Settings = "⚙️" }
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

	