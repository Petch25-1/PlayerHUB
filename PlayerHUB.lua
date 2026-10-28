--[[
	PlayerHUB v3 (UI Redesign)
	วิธีใช้: วางเป็น LocalScript ใน StarterPlayerScripts หรือรันผ่าน Executor
	PC: กด RightShift เพื่อซ่อน/แสดงเมนู
--]]

local Success, Err = pcall(function()
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local TeleportService = game:GetService("TeleportService")
	local Lighting = game:GetService("Lighting")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end

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

	-- ====== MAID (เก็บ connection ไว้เคลียร์ตอนสคริปต์ถูกรันซ้ำ) ======
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
	local old = playerGui:FindFirstChild("PlayerHUB")
	if old then old:Destroy() end

	local gui = make("ScreenGui", { Name = "PlayerHUB", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
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

	local function notify(title, msg, duration, kind)
		duration = duration or 2.5
		local k = TOAST_KIND[kind or "info"] or TOAST_KIND.info

		-- จำกัดไม่เกิน 4 ใบพร้อมกัน
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

	-- ====== X: ที่เก็บระบบเสริมทั้งหมด (รวมไว้ในตารางเดียวเพื่อประหยัดตัวแปรของ Luau) ======
	local X = { Ticks = {}, toggles = {}, VERSION = "v4.0" }

	-- ====== DOCK: ปุ่มลอยกลางจอด้านล่าง (Back / Death Point / Stop ...) เรียงซ้อนไม่ทับกัน ======
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

		-- kind: "accent" (ม่วง-ฟ้า) | "danger" (แดง) / seconds = เวลาก่อนหายเอง (nil = ค้างไว้)
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

	-- ====== MAIN WINDOW ======
	local WIN_W, FULL_H, HEADER_H = 380, 580, 52
	local window = make("Frame", {
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
	local userScale = 1
	local function updateScale()
		local camera = workspace.CurrentCamera
		local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
		uiScale.Scale = math.clamp(math.min(vp.X, vp.Y) / 800, 0.7, 1) * userScale
	end
	updateScale()

	-- HEADER
	local header = make("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
	round(header, 16)
	local headerFiller = make("Frame", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, header)
	make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0 }, headerFiller)

	local logo = make("Frame", { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, header)
	round(logo, 9)
	gradient(logo, THEME.Accent1, THEME.Accent2, 45)
	label(logo, { Size = UDim2.fromScale(1, 1), Text = "🌌", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center })

	local titleLbl = label(header, { Size = UDim2.fromOffset(120, 20), Position = UDim2.fromOffset(52, 8), Text = "PlayerHUB", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE })
	gradient(titleLbl, THEME.Accent1, THEME.Accent2, 0)
	label(header, { Size = UDim2.fromOffset(120, 14), Position = UDim2.fromOffset(52, 28), Text = "Utility Menu v3", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.SubText })

	-- ตัวนับฟีเจอร์ที่เปิดอยู่
	local activeCount = 0
	local badgePill = make("Frame", { Size = UDim2.fromOffset(84, 22), Position = UDim2.new(1, -162, 0, 15), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, header)
	round(badgePill, 11)
	stroke(badgePill, THEME.Stroke, 1, 0.4)
	local badgeLabel = label(badgePill, { Size = UDim2.fromScale(1, 1), Text = "● 0 ON", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center })
	X.badgeBtn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 }, badgePill)
	X.badgeBtn.MouseEnter:Connect(function() tween(badgePill, 0.12, { BackgroundColor3 = THEME.CardHover }) end)
	X.badgeBtn.MouseLeave:Connect(function() tween(badgePill, 0.12, { BackgroundColor3 = THEME.Card }) end)
	local function updateBadge()
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
	local minButton = titleButton("–", -68, THEME.CardHover)
	local closeButton = titleButton("✕", -36, THEME.Danger)

	-- ปุ่มจรวด: ลากย้ายไปวางตรงไหนของจอก็ได้ อยู่ที่เดิมหลังปล่อย (จำตำแหน่งข้ามการรันบน Executor)
	local HttpService = game:GetService("HttpService")
	local BTN_SIZE, DRAG_THRESHOLD = 50, 6
	local BTN_FILE = "PlayerHUB_button.json"
	local btnLocked = false

	local function loadBtnData()
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(BTN_FILE)) end)
		if ok and type(data) == "table" and tonumber(data.x) and tonumber(data.y) then return data end
		return nil
	end
	local saved = loadBtnData()
	if saved then btnLocked = saved.locked == true end
	local layout = {
		rx = saved and tonumber(saved.rx) or nil, ry = saved and tonumber(saved.ry) or nil,
		snap = (saved == nil) or (saved.snap ~= false), seen = saved and saved.seen or nil,
	}

	local reopenButton = make("TextButton", {
		Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE),
		Position = saved and UDim2.fromOffset(saved.x, saved.y) or UDim2.fromOffset(28, 60),
		BackgroundColor3 = WHITE, Text = "🚀", TextSize = 22, Visible = false, AutoButtonColor = false, ZIndex = 20,
	}, gui)
	round(reopenButton, 25)
	gradient(reopenButton, THEME.Accent1, THEME.Accent2, 45)
	local reopenStroke = stroke(reopenButton, WHITE, 1.5, 0.6)
	local lockBadge = label(reopenButton, {
		Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -14, 0, -4), BackgroundTransparency = 0, BackgroundColor3 = THEME.Panel,
		Text = "🔒", TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21, Visible = btnLocked,
	})
	round(lockBadge, 9)

	local function clampBtn()
		local sz = gui.AbsoluteSize
		local x = math.clamp(reopenButton.Position.X.Offset, 0, math.max(sz.X - BTN_SIZE, 0))
		local y = math.clamp(reopenButton.Position.Y.Offset, 0, math.max(sz.Y - BTN_SIZE, 0))
		reopenButton.Position = UDim2.fromOffset(x, y)
	end
	local function saveBtnData(xo, yo)
		pcall(function()
			writefile(BTN_FILE, HttpService:JSONEncode({
				x = xo or reopenButton.Position.X.Offset, y = yo or reopenButton.Position.Y.Offset, locked = btnLocked, rx = layout.rx, ry = layout.ry,
				snap = layout.snap, seen = layout.seen,
			}))
		end)
	end

	-- จางลงเมื่อไม่ได้ใช้ (เมื่อเปิด Edge Snap) / ชัดขึ้นเมื่อแตะหรือเอาเมาส์ชี้
	local fadeToken = 0
	local function wakeBtn()
		fadeToken = fadeToken + 1
		local token = fadeToken
		tween(reopenButton, 0.15, { BackgroundTransparency = 0, TextTransparency = 0 })
		tween(reopenStroke, 0.15, { Transparency = 0.6 })
		if layout.snap then
			task.delay(2.5, function()
				if fadeToken == token and reopenButton.Visible then
					tween(reopenButton, 0.5, { BackgroundTransparency = 0.55, TextTransparency = 0.5 })
					tween(reopenStroke, 0.5, { Transparency = 0.9 })
				end
			end)
		end
	end
	reopenButton.MouseEnter:Connect(wakeBtn)

	-- ดูดปุ่มติดขอบซ้าย/ขวาที่ใกล้ที่สุด (คืนค่า x ปลายทาง)
	local function snapBtn()
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
		if vis then reopenButton.Visible = false end
		window.Visible = vis
		if not vis then
			clampBtn()
			reopenButton.Visible = true
			wakeBtn()
		end
	end
	closeButton.MouseButton1Click:Connect(function() setWindowVisible(false) end)

	-- แตะ = เปิดเมนู / ลาก = ย้ายปุ่ม (ถ้าล็อกไว้จะลากไม่ได้)
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
		if not btnInput or btnLocked then return end
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
			setWindowVisible(true)
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
		if isPress(input) then dragging = true; dragStart = input.Position; dragOrigin = window.Position end
	end)
	mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMove(input) then
			local d = (input.Position - dragStart) / uiScale.Scale
			window.Position = UDim2.fromOffset(dragOrigin.X.Offset + d.X, dragOrigin.Y.Offset + d.Y)
		end
	end))
	mainMaid:Give(UserInputService.InputEnded:Connect(function(input) if isPress(input) then dragging = false end end))

	-- SEARCH BAR
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

	-- TAB BAR
	local TAB_NAMES = { "Player", "Camera", "Visuals", "World", "Info", "Settings" }
	local TAB_ICONS = { Player = "🚶", Camera = "📷", Visuals = "👁", World = "🌍", Info = "ℹ️", Settings = "⚙️" }
	local tabY = HEADER_H + 10 + 34 + 8
	local tabBar = make("Frame", { Size = UDim2.new(1, -24, 0, 46), Position = UDim2.fromOffset(12, tabY), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, window)
	round(tabBar, 10)
	make("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, tabBar)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

	local contentY = tabY + 46 + 8
	local content = make("Frame", { Size = UDim2.new(1, 0, 1, -contentY), Position = UDim2.fromOffset(0, contentY), BackgroundTransparency = 1 }, window)
	local pages, tabButtons = {}, {}

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
			BackgroundTransparency = (i == 1) and 0 or 1, Text = '<font size="15">' .. TAB_ICONS[name] .. '</font>\n<font size="9">' .. name .. '</font>', RichText = true,
			Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = (i == 1) and WHITE or THEME.SubText,
			AutoButtonColor = false, LayoutOrder = i,
		}, tabBar)
		round(btn, 8)
		gradient(btn, THEME.Accent1, THEME.Accent2, 0)
		tabButtons[name] = btn
		btn.MouseButton1Click:Connect(function() selectTab(name) end)
	end

	for _, nm in ipairs({ "Camera", "Info" }) do
		local dot = make("Frame", { Name = "NewDot", Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -13, 0, 4), BackgroundColor3 = THEME.Warn, BorderSizePixel = 0, ZIndex = 5 }, tabButtons[nm])
		round(dot, 4)
	end

	-- ====== ACTIVE FEATURES: กดป้าย ● N ON เพื่อดู/ปิดฟีเจอร์ที่เปิดอยู่ ======
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

	-- ==========================================
	-- WIDGET HELPERS
	-- ==========================================
	local resetters = {} -- ฟังก์ชันรีเซ็ตของ slider/toggle ทุกตัว (ใช้กับปุ่ม Reset All Values)

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

	-- toggle(page, ชื่อ, callback, คำอธิบาย, ไม่ต้องรีเซ็ตตอนกด Reset All)
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

		-- แทร็ก
		local track = make("Frame", { Size = UDim2.new(1, -28, 0, 8), Position = UDim2.new(0, 14, 0, 46), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(track, 4)
		local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
		round(fill, 4)
		gradient(fill, THEME.Accent1, THEME.Accent2, 0)
		local knob = make("Frame", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, track)
		round(knob, 9)
		stroke(knob, THEME.Accent2, 2, 0.1)
		-- พื้นที่แตะกว้างกว่าแทร็ก (แตะง่ายบนมือถือ)
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
				page.ScrollingEnabled = false -- กันหน้าเลื่อนตอนลาก slider
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

	-- button(page, ข้อความ, callback, ชนิด: "primary" | "ghost" | "danger")
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

	-- ตัวเลือกแบบเลือกได้ทีละอัน (Segmented control)
	function X.segmented(page, titleText, options, defaultIdx, onChange)
		local row = card(page, 72)
		row:SetAttribute("Search", string.lower(titleText))
		label(row, { Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 8), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 12 })
		local holder = make("Frame", { Size = UDim2.new(1, -24, 0, 32), Position = UDim2.fromOffset(12, 32), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, row)
		round(holder, 9)
		make("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, holder)
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
		local btns, current = {}, defaultIdx
		local function paint()
			for i, b in ipairs(btns) do
				local on = (i == current)
				tween(b, 0.15, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and WHITE or THEME.SubText })
			end
		end
		for i, opt in ipairs(options) do
			local b = make("TextButton", {
				Size = UDim2.new(1 / #options, -3, 1, 0), Text = opt, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false,
				BorderSizePixel = 0, BackgroundColor3 = WHITE, BackgroundTransparency = 1, TextColor3 = THEME.SubText, LayoutOrder = i,
			}, holder)
			round(b, 7)
			gradient(b, THEME.Accent1, THEME.Accent2, 0)
			btns[i] = b
			b.MouseButton1Click:Connect(function() current = i; paint(); onChange(i) end)
		end
		paint()
		table.insert(resetters, function() current = defaultIdx; paint(); onChange(defaultIdx) end)
	end

	-- ปุ่มลูกศรขึ้น/ลงแบบวงกลม (ใช้กับ Fly และ Freecam)
	local function makePad(rightOffset, colorA, colorB, setUp, setDown)
		local pad = make("Frame", { Size = UDim2.fromOffset(60, 124), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -rightOffset, 1, -120), BackgroundTransparency = 1, Visible = false }, gui)
		local function arrow(text, y, setVal)
			local b = make("TextButton", {
				Size = UDim2.fromOffset(58, 58), Position = UDim2.fromOffset(0, y), Text = text, TextColor3 = WHITE,
				Font = Enum.Font.GothamBold, TextSize = 20, BackgroundColor3 = WHITE, AutoButtonColor = false,
			}, pad)
			round(b, 29)
			gradient(b, colorA, colorB, 90)
			stroke(b, WHITE, 1.5, 0.6)
			b.InputBegan:Connect(function(i) if isPress(i) then setVal(true); tween(b, 0.08, { BackgroundTransparency = 0.25 }) end end)
			b.InputEnded:Connect(function(i) if isPress(i) then setVal(false); tween(b, 0.12, { BackgroundTransparency = 0 }) end end)
		end
		arrow("▲", 0, setUp)
		arrow("▼", 66, setDown)
		return pad
	end

	-- ==========================================
	-- สถานะฟีเจอร์ทั้งหมด (ใช้ร่วมกับ main loop ตัวเดียวด้านล่าง)
	-- ==========================================
	local F = {
		cfSpeed = false, cfSpeedVal = 1,
		infStamina = false,
		mobHitbox = false, mobHitboxSize = 5,
		nameTags = false, playerHL = false, itemHL = false, mobEsp = false,
		fullbright = false, freecam = false, freecamSpeed = 120,
		radar = false,
	}

	-- ตั้งค่าเรดาร์ (ใช้ร่วมกับ scan และ main loop)
	local R = { range = 150, size = 140, rotate = true, players = true, mobs = true, items = true, mobCache = {}, itemCache = {} }

	local function getHumanoid() local char = player.Character return char and char:FindFirstChildOfClass("Humanoid") end
	local function getOrigin()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then return hrp.Position end
		local cam = workspace.CurrentCamera
		return cam and cam.CFrame.Position or Vector3.zero
	end

	-- หา BasePart ที่ใช้เป็นตำแหน่งของไอเทม/มอน
	local function getTargetPart(v)
		if v:IsA("BasePart") then return v end
		if v:IsA("Tool") then return v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart", true) end
		if v:IsA("Model") then return v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true) end
		return nil
	end

	-- ==========================================
	-- 🚶 1. TAB: PLAYER
	-- ==========================================
	local pPlayer = pages["Player"]
	local overrides = {}
	local function applyStats()
		local hum = getHumanoid()
		if hum then
			if overrides.walk then hum.WalkSpeed = overrides.walk end
			if overrides.jump then hum.UseJumpPower = true; hum.JumpPower = overrides.jump end
		end
	end

	local initHum = getHumanoid()
	local defWalk = initHum and initHum.WalkSpeed or 16
	local defJump = initHum and initHum.JumpPower or 50

	section(pPlayer, "Movement")
	slider(pPlayer, "Walk Speed", 0, 150, defWalk, 1, function(v) overrides.walk = v; applyStats() end)
	slider(pPlayer, "Jump Power", 0, 200, defJump, 1, function(v) overrides.jump = v; applyStats() end)

	local flySpeed = 50
	local flyUp, flyDown = false, false
	local flyOn = false
	local flyControls = makePad(20, THEME.Accent2, THEME.Accent1, function(v) flyUp = v end, function(v) flyDown = v end)

	local flyMaid = Maid.new()
	local function stopFly()
		flyMaid:Clean(); flyControls.Visible = false
		flyUp, flyDown = false, false
		local hum = getHumanoid(); if hum then hum.PlatformStand = false end
	end
	local function startFly()
		stopFly()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = getHumanoid()
		if not hrp or not hum then return end
		hum.PlatformStand = true; flyControls.Visible = true
		local bv = flyMaid:Give(Instance.new("BodyVelocity", hrp))
		bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
		local bg = flyMaid:Give(Instance.new("BodyGyro", hrp))
		bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
		flyMaid:Give(RunService.RenderStepped:Connect(function()
			local move = hum.MoveDirection
			if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
			if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
			bv.Velocity = move.Magnitude > 0 and (move.Unit * flySpeed) or Vector3.zero
			local cam = workspace.CurrentCamera
			if cam then bg.CFrame = cam.CFrame end
		end))
	end
	mainMaid:Give(function() flyMaid:Clean() end)

	toggle(pPlayer, "Fly Mode", function(on)
		flyOn = on
		if on then startFly() else stopFly() end
	end, "โหมดบิน (มีปุ่ม ▲▼ บนจอ)")
	slider(pPlayer, "Fly Speed", 10, 200, flySpeed, 5, function(v) flySpeed = v end)

	local infJumpOn = false
	mainMaid:Give(UserInputService.JumpRequest:Connect(function()
		if infJumpOn then local hum = getHumanoid(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
	end))
	toggle(pPlayer, "Infinite Jump", function(on) infJumpOn = on end, "กระโดดกลางอากาศไม่จำกัด")

	local noclipMaid = Maid.new()
	mainMaid:Give(function() noclipMaid:Clean() end)
	toggle(pPlayer, "Noclip", function(on)
		noclipMaid:Clean()
		if on then
			noclipMaid:Give(RunService.Stepped:Connect(function()
				local char = player.Character
				if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
			end))
		end
	end, "เดินทะลุกำแพง")

	toggle(pPlayer, "CFrame Speed", function(on) F.cfSpeed = on end, "เร่งความเร็วด้วยการเลื่อนพิกัด")
	slider(pPlayer, "CFrame Multiplier", 0.5, 5, 1, 0.1, function(v) F.cfSpeedVal = v end)

	section(pPlayer, "Character")

	-- Invisibility (จำค่า Transparency เดิมไว้คืนตอนปิด)
	local invisOn = false
	local invisOrig = setmetatable({}, { __mode = "k" })
	local function applyInvis()
		local char = player.Character
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if (p:IsA("BasePart") and p.Name ~= "HumanoidRootPart") or p:IsA("Decal") then
				if invisOn then
					if invisOrig[p] == nil then invisOrig[p] = p.Transparency end
					p.Transparency = 1
				elseif invisOrig[p] ~= nil then
					p.Transparency = invisOrig[p]
					invisOrig[p] = nil
				end
			end
		end
	end
	toggle(pPlayer, "Invisibility", function(on) invisOn = on; applyInvis() end, "ล่องหน")
	toggle(pPlayer, "Infinite Stamina", function(on) F.infStamina = on end, "พละกำลังไม่จำกัด (เกมที่มีค่า Stamina/Energy)")

	section(pPlayer, "Mob Hitbox")

	-- Mob Hitbox — จำขนาดเดิมไว้คืนตอนปิด
	local mobHitOrig = setmetatable({}, { __mode = "k" })
	local function expandPart(store, part, size)
		if not store[part] then store[part] = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide } end
		part.Size = Vector3.new(size, size, size); part.Transparency = 0.5; part.CanCollide = false
	end
	local function restoreParts(store)
		for part, o in pairs(store) do
			if part.Parent then part.Size = o.Size; part.Transparency = o.Transparency; part.CanCollide = o.CanCollide end
			store[part] = nil
		end
	end
	toggle(pPlayer, "Mob Hitbox Expander", function(on) F.mobHitbox = on; if not on then restoreParts(mobHitOrig) end end, "ขยายตัวมอนให้ตีโดนง่ายขึ้น")
	slider(pPlayer, "Mob Hitbox Size", 2, 25, F.mobHitboxSize, 1, function(v) F.mobHitboxSize = v end)

	-- ==========================================
	-- 🌍 สแกนโลก (cache มอน/ไอเทม — สแกนเป็นช่วงๆ แทนการวนทุกเฟรม)
	-- ==========================================
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

	-- คืนรายการ {obj, d} เรียงจากใกล้ไปไกล (สูงสุด n ชิ้น)
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
	-- 👁️ 2. TAB: VISUALS
	-- ==========================================
	local pVis = pages["Visuals"]

	section(pVis, "Lighting")

	-- Fullbright: จำค่าแสงเดิมไว้คืน
	local fbOrig
	toggle(pVis, "Fullbright", function(on)
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

	-- Remove Fog: จำ FogEnd เดิมไว้คืน
	local fogOrig
	toggle(pVis, "Remove Fog", function(on)
		if on then
			fogOrig = Lighting.FogEnd
			Lighting.FogEnd = 100000
		elseif fogOrig then
			Lighting.FogEnd = fogOrig
			fogOrig = nil
		end
	end, "ลบหมอก")

	-- Weather Remover: จำ parent เดิมไว้คืน
	local removedWeather = {}
	toggle(pVis, "Weather Remover", function(on)
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

	-- Wall Translucency
	local originalTrans = {}
	toggle(pVis, "Wall Translucency", function(on)
		if on then
			for _, part in ipairs(workspace:GetDescendants()) do
				if part:IsA("BasePart") and part.Anchored and part.Name ~= "Terrain" and not (part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")) then
					if originalTrans[part] == nil then originalTrans[part] = part.Transparency end
					part.Transparency = math.max(part.Transparency, 0.65)
				end
			end
		else
			for part, t in pairs(originalTrans) do
				if part.Parent then part.Transparency = t end
				originalTrans[part] = nil
			end
		end
	end, "มองทะลุตึก/กำแพง")

	section(pVis, "ESP")

	local nameTagGuis, playerHighlights, itemHighlights, mobHighlights = {}, {}, {}, {}
	local ITEM_HL_MAX, MOB_HL_MAX = 10, 10 -- Highlight มีลิมิตประมาณ 31 อันพร้อมกัน

	local function clearStore(store)
		for k, hl in pairs(store) do
			if hl then hl:Destroy() end
			store[k] = nil
		end
	end

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

	local mobCache = {}
	local function runScan()
		local radarMobs = F.radar and R.mobs
		local radarItems = F.radar and R.items
		local wantMobs = F.mobEsp or F.mobHitbox or radarMobs
		local wantItems = F.itemHL or radarItems
		if not (wantMobs or wantItems) then return end
		local mobs, items = scanWorld(wantMobs, wantItems)
		if wantMobs then mobCache = mobs end
		if radarMobs then
			local out = {}
			for i, e in ipairs(nearest(mobs, 60)) do out[i] = e.obj end
			R.mobCache = out
		end
		if radarItems then
			local out = {}
			for i, e in ipairs(nearest(items, 50)) do out[i] = e.obj end
			R.itemCache = out
		end
		if F.mobEsp then syncHighlights(mobHighlights, nearest(mobs, MOB_HL_MAX), Color3.fromRGB(255, 50, 50)) end
		if F.itemHL then syncHighlights(itemHighlights, nearest(items, ITEM_HL_MAX), Color3.fromRGB(255, 255, 255)) end
	end

	task.spawn(function()
		while gui.Parent do
			pcall(runScan)
			task.wait(1)
		end
	end)

	toggle(pVis, "NameTags & Distance", function(on) F.nameTags = on end, "แสดงชื่อและระยะทางผู้เล่น")
	toggle(pVis, "Player Highlight", function(on) F.playerHL = on end, "ไฮไลต์ผู้เล่น (เขียว)")
	toggle(pVis, "Item Highlights", function(on)
		F.itemHL = on
		if on then pcall(runScan) else clearStore(itemHighlights) end
	end, "ไฮไลต์ไอเทมใกล้ตัว (ขาว)")
	toggle(pVis, "Mob ESP", function(on)
		F.mobEsp = on
		if on then pcall(runScan) else clearStore(mobHighlights) end
	end, "ไฮไลต์มอนสเตอร์ใกล้ตัว (แดง)")

	-- ==========================================
	-- 🌍 3. TAB: WORLD
	-- ==========================================
	local pWorld = pages["World"]
	local tweenTp -- ใช้โดยปุ่ม TP ทุกปุ่ม (กำหนดค่าในบล็อก Back ด้านล่าง)
	local goBack
	do
		local BK = { cf = nil, dist = 0, btn = nil }
		local DP = { cf = nil, pending = false, btn = nil }

		local function moveTo(targetCF)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - targetCF.Position).Magnitude
				TweenService:Create(hrp, TweenInfo.new(math.clamp(dist / 250, 0.1, 4), Enum.EasingStyle.Linear), { CFrame = targetCF }):Play()
			end
		end

		local function refreshBackUI()
			local b = BK.btn
			if not b then return end
			if BK.cf then
				b.Text = "↩  Back to Previous  ·  " .. math.round(BK.dist) .. "m"
				b.TextTransparency = 0
			else
				b.Text = "↩  Back to Previous Position"
				b.TextTransparency = 0.5
			end
		end

		local function refreshDeathUI()
			local b = DP.btn
			if not b then return end
			if DP.cf then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local d = hrp and math.round((hrp.Position - DP.cf.Position).Magnitude) or 0
				b.Text = "💀  Return to Death Point  ·  " .. d .. "m"
				b.TextTransparency = 0
			else
				b.Text = "💀  Return to Death Point"
				b.TextTransparency = 0.5
			end
		end

		tweenTp = function(targetCF)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			BK.cf = hrp.CFrame
			BK.dist = (hrp.Position - targetCF.Position).Magnitude
			refreshBackUI()
			X.Dock.show("back", "↩  Back", function() goBack() end, 8)
			moveTo(targetCF)
		end

		-- กด Back แล้วสลับ: กดซ้ำจะกลับมาจุดที่เพิ่งออกมา
		goBack = function()
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp or not BK.cf then
				notify("Back", "ยังไม่มีจุดให้ย้อนกลับ", 1.5, "warn")
				return
			end
			local dest = BK.cf
			BK.dist = (hrp.Position - dest.Position).Magnitude
			BK.cf = hrp.CFrame
			X.Dock.hide("back")
			refreshBackUI()
			moveTo(dest)
			notify("Back", "ย้อนกลับจุดก่อนหน้าแล้ว", 1.5, "info")
		end

		local function goDeath()
			if not DP.cf then
				notify("Death Point", "ยังไม่เคยตายในรอบนี้", 1.5, "warn")
				return
			end
			X.Dock.hide("death")
			tweenTp(DP.cf)
			notify("Death Point", "กำลังกลับไปจุดที่ตาย", 1.5, "info")
		end

		-- จับจังหวะตาย: จำตำแหน่งไว้ แล้วโชว์ปุ่มลอยหลังเกิดใหม่
		local function watch(char)
			local hum = char:WaitForChild("Humanoid", 10)
			local root = char:WaitForChild("HumanoidRootPart", 10)
			if not hum or not root then return end
			hum.Died:Connect(function()
				DP.cf = root.CFrame
				DP.pending = true
				refreshDeathUI()
				notify("Death Point", "บันทึกจุดที่ตายไว้แล้ว", 2, "warn")
			end)
		end
		if player.Character then task.spawn(watch, player.Character) end
		mainMaid:Give(player.CharacterAdded:Connect(function(char)
			task.spawn(watch, char)
			if DP.pending and DP.cf then
				DP.pending = false
				task.delay(1.2, function()
					X.Dock.show("death", "💀  Return to Death Point", goDeath, 15, "danger")
				end)
			end
		end))
		X.Ticks[#X.Ticks + 1] = refreshDeathUI

		section(pWorld, "Teleport")
		BK.btn = button(pWorld, "↩  Back to Previous Position", function() goBack() end)
		DP.btn = button(pWorld, "💀  Return to Death Point", goDeath)
		refreshBackUI()
		refreshDeathUI()
	end

	-- กรอบรายการแบบเลื่อนได้
	local function listBox(page)
		local frame = make("Frame", { Size = UDim2.new(1, 0, 0, 160), BackgroundColor3 = THEME.Card, BorderSizePixel = 0 }, page)
		round(frame, 10)
		stroke(frame, THEME.Stroke, 1, 0.45)
		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Accent2, ScrollBarImageTransparency = 0.4,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, frame)
		make("UIListLayout", { Padding = UDim.new(0, 5) }, scroll)
		return scroll
	end
	local function clearList(scroll)
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	end
	local function emptyState(scroll, text)
		label(scroll, { Size = UDim2.new(1, 0, 0, 120), Text = text, TextSize = 11, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
	end
	local function listRow(scroll, iconText, iconColor)
		local r = make("Frame", { Size = UDim2.new(1, -2, 0, 38), BackgroundColor3 = THEME.CardHover, BorderSizePixel = 0 }, scroll)
		round(r, 8)
		local icon = label(r, {
			Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(7, 6), BackgroundTransparency = 0, BackgroundColor3 = iconColor,
			Text = iconText, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		})
		round(icon, 13)
		return r
	end
	local function miniButton(parent, text, color, rightOffset, width)
		local b = make("TextButton", {
			Size = UDim2.fromOffset(width, 26), Position = UDim2.new(1, -(rightOffset + width), 0.5, -13), BackgroundColor3 = color,
			Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
		}, parent)
		round(b, 7)
		b.MouseButton1Down:Connect(function() tween(b, 0.08, { BackgroundTransparency = 0.35 }) end)
		b.InputEnded:Connect(function(i) if isPress(i) then tween(b, 0.12, { BackgroundTransparency = 0 }) end end)
		return b
	end
	local function nameColor(name)
		local h = 0
		for i = 1, #name do h = (h * 31 + name:byte(i)) % 360 end
		return Color3.fromHSV(h / 360, 0.55, 0.8)
	end
	local function firstChar(name)
		local ok, ch = pcall(function() return name:sub(1, (utf8.offset(name, 2) or (#name + 1)) - 1) end)
		return (ok and ch ~= "") and ch or "?"
	end

	-- ==========================================
	-- 🖼 ภาพตัวอย่างในแถว (ViewportFrame) — ทยอยสร้างทีละอัน ไม่ให้เฟรมกระตุก
	-- ==========================================
	do
		local queue, busy = {}, false

		local function buildPreview(row, obj)
			local icon = row:FindFirstChildOfClass("TextLabel")
			if not icon then return end
			if #obj:GetDescendants() > 400 then return end -- โมเดลใหญ่เกินไป ใช้ไอคอนเดิม
			local clone = obj:Clone()
			if not clone then return end
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Light")
					or d:IsA("BillboardGui") or d:IsA("Highlight") then
					d:Destroy()
				end
			end
			local holder = Instance.new("Model")
			clone.Parent = holder
			local ok, cf, size = pcall(function() return holder:GetBoundingBox() end)
			if not ok or not size or size.Magnitude < 0.01 then
				holder:Destroy()
				return
			end
			local vp = make("ViewportFrame", {
				Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(5, 4), BackgroundColor3 = Color3.fromRGB(30, 30, 46),
				BorderSizePixel = 0, Ambient = Color3.fromRGB(170, 170, 185), LightColor = WHITE, LightDirection = Vector3.new(-1, -2, -1), ZIndex = 2,
			}, row)
			round(vp, 8)
			holder.Parent = vp
			local cam = Instance.new("Camera")
			cam.FieldOfView = 40
			local center = cf.Position
			local radius = math.max(size.Magnitude / 2, 0.5)
			local dist = radius / math.tan(math.rad(20)) * 1.1
			cam.CFrame = CFrame.lookAt(center + Vector3.new(1, 0.8, 1).Unit * dist, center)
			cam.Parent = vp
			vp.CurrentCamera = cam
			icon.Visible = false
		end

		function X.itemPreview(row, obj)
			queue[#queue + 1] = { row = row, obj = obj }
			if busy then return end
			busy = true
			task.spawn(function()
				while #queue > 0 do
					local job = table.remove(queue, 1)
					if job.row.Parent and job.obj.Parent then pcall(buildPreview, job.row, job.obj) end
					task.wait()
				end
				busy = false
			end)
		end
	end

	-- ==========================================
	-- 👁 SPECTATE (แถบลอย: ◀ ถัดไป/ก่อนหน้า ▶ และออก)
	-- ==========================================
	X.Spec = { target = nil }
	do
		local bar = make("Frame", {
			Size = UDim2.fromOffset(268, 52), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
			BackgroundColor3 = THEME.Panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, ZIndex = 40,
		}, gui)
		round(bar, 14)
		gradient(stroke(bar, WHITE, 1.4, 0.2), THEME.Accent1, THEME.Accent2, 0)
		local nameLbl = label(bar, { Size = UDim2.new(1, -152, 0, 20), Position = UDim2.fromOffset(52, 8), Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
		local infoLbl = label(bar, { Size = UDim2.new(1, -152, 0, 16), Position = UDim2.fromOffset(52, 28), Text = "", TextSize = 10, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })

		local function barBtn(text, pos, color)
			local b = make("TextButton", { Size = UDim2.fromOffset(38, 36), Position = pos, BackgroundColor3 = color, Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false }, bar)
			round(b, 10)
			b.MouseButton1Down:Connect(function() tween(b, 0.08, { BackgroundTransparency = 0.35 }) end)
			b.InputEnded:Connect(function(i) if isPress(i) then tween(b, 0.12, { BackgroundTransparency = 0 }) end end)
			return b
		end
		local prevBtn = barBtn("◀", UDim2.fromOffset(8, 8), THEME.Card)
		local nextBtn = barBtn("▶", UDim2.new(1, -88, 0, 8), THEME.Card)
		local exitBtn = barBtn("✕", UDim2.new(1, -46, 0, 8), THEME.Danger)

		local function candidates()
			local out = {}
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= player and pl.Character and pl.Character:FindFirstChildOfClass("Humanoid") then out[#out + 1] = pl end
			end
			table.sort(out, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
			return out
		end

		local function setTarget(pl)
			local cam = workspace.CurrentCamera
			X.Spec.target = pl
			if pl then
				if F.freecam and X.Cam and X.Cam.freecamToggle then X.Cam.freecamToggle.set(false, true) end
				if X.Cam and X.Cam.playing then X.Cam.stop() end
				local h = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
				if cam and h then cam.CameraSubject = h end
				nameLbl.Text = pl.DisplayName
				infoLbl.Text = ""
				bar.Visible = true
			else
				local myHum = getHumanoid()
				if cam and myHum then cam.CameraSubject = myHum end
				bar.Visible = false
			end
			if X.Spec.onChange then X.Spec.onChange() end
		end

		function X.Spec.toggle(pl)
			if X.Spec.target == pl then
				setTarget(nil)
				notify("Spectate", "ยกเลิกการสอดแนมแล้ว", 1.5, "off")
			else
				setTarget(pl)
				notify("Spectate", "กำลังสอดแนม: " .. pl.DisplayName, 2, "info")
			end
		end
		function X.Spec.stop() if X.Spec.target then setTarget(nil) end end
		function X.Spec.cycle(dir)
			local list = candidates()
			if #list == 0 then setTarget(nil); return end
			local idx = table.find(list, X.Spec.target) or 0
			idx = ((idx - 1 + dir) % #list) + 1
			setTarget(list[idx])
		end
		prevBtn.MouseButton1Click:Connect(function() X.Spec.cycle(-1) end)
		nextBtn.MouseButton1Click:Connect(function() X.Spec.cycle(1) end)
		exitBtn.MouseButton1Click:Connect(function() X.Spec.stop() end)

		-- ทุก 0.5 วินาที: ตามกล้องไปยังตัวละครใหม่หลังเป้าหมายเกิดใหม่ + อัปเดตระยะ/เลือด
		X.Ticks[#X.Ticks + 1] = function()
			local t = X.Spec.target
			if not t then return end
			if not t.Parent then setTarget(nil); return end
			local ch = t.Character
			local h = ch and ch:FindFirstChildOfClass("Humanoid")
			local cam = workspace.CurrentCamera
			if h and cam and cam.CameraSubject ~= h and not F.freecam then cam.CameraSubject = h end
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if h and root and mine then
				infoLbl.Text = math.round((root.Position - mine.Position).Magnitude) .. "m  ·  HP " .. math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)
			end
		end
		mainMaid:Give(function() X.Spec.stop() end)
	end

	-- ==========================================
	-- 🧭 NAVIGATION (Walk to Mark / Follow Player ด้วย Pathfinding)
	-- ==========================================
	X.Nav = { key = nil }
	do
		local PathfindingService = game:GetService("PathfindingService")
		local token = 0
		local function flat(a, b)
			local d = a - b
			return math.sqrt(d.X * d.X + d.Z * d.Z)
		end

		function X.Nav.stop(silent)
			token = token + 1
			local wasActive = X.Nav.key ~= nil
			X.Nav.key = nil
			X.Dock.hide("nav")
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local hum = getHumanoid()
			if hum and hrp then hum:MoveTo(hrp.Position) end
			if X.Nav.onChange then X.Nav.onChange() end
			if wasActive and not silent then notify("Navigation", "หยุดเดินแล้ว", 1.5, "off") end
		end

		-- opts: key, name, getPos() -> Vector3?, stopDist, follow(bool)
		function X.Nav.start(opts)
			if F.freecam then
				notify("Navigation", "ปิด Freecam ก่อน (ตัวละครถูกตรึงอยู่)", 2, "warn")
				return
			end
			X.Nav.stop(true)
			token = token + 1
			local my = token
			X.Nav.key = opts.key
			X.Dock.show("nav", "■  Stop: " .. opts.name, function() X.Nav.stop() end, nil, "danger")
			if X.Nav.onChange then X.Nav.onChange() end
			notify("Navigation", (opts.follow and "กำลังตาม: " or "กำลังเดินไป: ") .. opts.name, 2, "info")

			task.spawn(function()
				local waypoints, idx, lastTarget, lastCompute = nil, 1, nil, 0
				while token == my do
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if not hrp or not hum or hum.Health <= 0 then break end
					local tpos = opts.getPos()
					if not tpos then
						notify("Navigation", "เป้าหมายหายไปแล้ว", 2, "warn")
						break
					end
					if flat(hrp.Position, tpos) <= opts.stopDist then
						if opts.follow then
							hum:MoveTo(hrp.Position)
							waypoints = nil
							task.wait(0.3)
						else
							notify("Navigation", "ถึงเป้าหมายแล้ว", 2, "success")
							break
						end
					else
						local moved = lastTarget and (tpos - lastTarget).Magnitude or math.huge
						local since = os.clock() - lastCompute
						if not waypoints or not waypoints[idx] or (since > 1.5 and moved > 6) or since > 6 then
							local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
							local ok = pcall(function() path:ComputeAsync(hrp.Position, tpos) end)
							lastCompute, lastTarget = os.clock(), tpos
							if ok and path.Status == Enum.PathStatus.Success then
								waypoints = path:GetWaypoints()
								idx = 2
							else
								waypoints = nil
							end
						end
						if waypoints and waypoints[idx] then
							local wp = waypoints[idx]
							if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
							hum:MoveTo(wp.Position)
							local t0 = os.clock()
							while token == my and flat(hrp.Position, wp.Position) > 4 and os.clock() - t0 < 2.5 do
								task.wait(0.1)
								local np = opts.getPos()
								if np and lastTarget and (np - lastTarget).Magnitude > 10 then break end
							end
							idx = idx + 1
						else
							hum:MoveTo(tpos) -- ไม่มีเส้นทาง: เดินตรงไปหาเป้าหมาย
							task.wait(0.25)
						end
					end
				end
				if token == my then X.Nav.stop(true) end
			end)
		end

		function X.Nav.walkTo(obj)
			if not (obj.Parent and getTargetPart(obj)) then return end
			local isMob = obj:IsA("Model")
			X.Nav.start({
				key = "walk", name = obj.Name, stopDist = isMob and 7 or 4,
				getPos = function()
					local part = obj.Parent and getTargetPart(obj)
					return part and part.Position
				end,
			})
		end

		function X.Nav.follow(pl)
			if X.Nav.key == "follow:" .. pl.UserId then X.Nav.stop(); return end
			X.Nav.start({
				key = "follow:" .. pl.UserId, name = pl.DisplayName, follow = true, stopDist = 8,
				getPos = function()
					local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					return r and r.Position
				end,
			})
		end
		mainMaid:Give(function() X.Nav.stop(true) end)
	end

	section(pWorld, "Players")
	local plrScroll = listBox(pWorld)

	local function refreshPlrList(exclude)
		clearList(plrScroll)
		local found = false
		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= player and target ~= exclude then
				found = true
				local r = listRow(plrScroll, firstChar(target.DisplayName), nameColor(target.DisplayName))
				label(r, { Size = UDim2.new(1, -206, 1, 0), Position = UDim2.fromOffset(40, 0), Text = target.DisplayName, TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })

				local followOn = X.Nav.key == "follow:" .. target.UserId
				local followBtn = miniButton(r, followOn and "Stop" or "Follow", followOn and THEME.Danger or THEME.Success, 104, 52)
				followBtn.MouseButton1Click:Connect(function() X.Nav.follow(target) end)

				local specOn = X.Spec.target == target
				local specBtn = miniButton(r, specOn and "Unspec" or "Spec", THEME.Accent1, 52, 46)
				specBtn.MouseButton1Click:Connect(function()
					if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
						X.Spec.toggle(target)
					end
				end)

				local tpBtn = miniButton(r, "TP", THEME.Accent2, 8, 38)
				tpBtn.MouseButton1Click:Connect(function()
					if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
						tweenTp(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
					end
				end)
			end
		end
		if not found then emptyState(plrScroll, "ยังไม่มีผู้เล่นคนอื่นในห้อง") end
	end
	button(pWorld, "⟳  Refresh Players", function() refreshPlrList() end)
	X.Spec.onChange = function() refreshPlrList() end
	X.Nav.onChange = function() refreshPlrList() end

	section(pWorld, "Marked Targets")
	X.markScroll = listBox(pWorld)
	button(pWorld, "⟳  Refresh Marks", function() if X.refreshMarks then X.refreshMarks() end end)


	section(pWorld, "Items")
	local itemScroll = listBox(pWorld)

	-- Mark: ป้ายชื่อ + ระยะห่างของไอเทม กดซ้ำเพื่อยกเลิกได้
	local marks = {} -- [ไอเทม] = { gui, label, part }

	local function removeMark(obj)
		local m = marks[obj]
		if m then
			m.gui:Destroy(); marks[obj] = nil
			if X.onMarks then X.onMarks() end
		end
	end
	local function clearAllMarks()
		for obj in pairs(marks) do removeMark(obj) end
	end
	mainMaid:Give(clearAllMarks)

	-- คืน true = มาร์คแล้ว, false = ยกเลิกมาร์คแล้ว, nil = มาร์คไม่ได้
	local function toggleMark(obj)
		if marks[obj] then removeMark(obj); return false end
		local part = getTargetPart(obj)
		if not part then return nil end
		local bb = make("BillboardGui", { Size = UDim2.fromOffset(170, 26), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, Adornee = part }, gui)
		local pill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.2, BorderSizePixel = 0 }, bb)
		round(pill, 13)
		stroke(pill, THEME.Warn, 1.2, 0.2)
		local lbl = label(pill, {
			Size = UDim2.fromScale(1, 1), Text = "📍 " .. obj.Name, TextColor3 = Color3.fromRGB(255, 200, 120),
			Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		})
		marks[obj] = { gui = bb, label = lbl, part = part }
		if X.onMarks then X.onMarks() end
		return true
	end

	-- รายการเป้าหมายที่ Mark ไว้ (TP / Walk / ยกเลิก) — อัปเดตเองเมื่อ Mark เปลี่ยน
	do
		local pending = false
		local function refreshMarkList()
			clearList(X.markScroll)
			local origin = getOrigin()
			local arr = {}
			for obj, m in pairs(marks) do
				if obj.Parent and m.part.Parent then
					arr[#arr + 1] = { obj = obj, d = (m.part.Position - origin).Magnitude }
				end
			end
			table.sort(arr, function(a, b) return a.d < b.d end)
			for _, e in ipairs(arr) do
				local obj = e.obj
				local isMob = obj:IsA("Model")
				local r = listRow(X.markScroll, isMob and "👾" or "📍", isMob and Color3.fromRGB(120, 40, 50) or Color3.fromRGB(150, 90, 30))
				X.itemPreview(r, obj)
				label(r, { Size = UDim2.new(1, -194, 1, 0), Position = UDim2.fromOffset(40, 0), Text = obj.Name .. "  ·  " .. math.round(e.d) .. "m", TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })

				local unBtn = miniButton(r, "✕", THEME.Danger, 8, 30)
				unBtn.MouseButton1Click:Connect(function() removeMark(obj) end)

				local tpBtn = miniButton(r, "TP", THEME.Accent2, 44, 38)
				tpBtn.MouseButton1Click:Connect(function()
					local part = obj.Parent and getTargetPart(obj)
					if part then tweenTp(part.CFrame * CFrame.new(0, 2, isMob and 6 or 0)) end
				end)

				local walkBtn = miniButton(r, "Walk", THEME.Success, 88, 48)
				walkBtn.MouseButton1Click:Connect(function() X.Nav.walkTo(obj) end)
			end
			if #arr == 0 then emptyState(X.markScroll, "ยังไม่มีเป้าหมายที่ Mark\nกด Mark ที่ไอเทมหรือมอน แล้วจะมาอยู่ที่นี่") end
		end
		X.refreshMarks = refreshMarkList
		X.onMarks = function()
			if pending then return end
			pending = true
			task.defer(function()
				pending = false
				refreshMarkList()
			end)
		end
		refreshMarkList()
	end

	local function refreshItemList()
		clearList(itemScroll)
		local _, items = scanWorld(false, true)
		local shown = nearest(items, 40)
		for _, e in ipairs(shown) do
			local v = e.obj
			local r = listRow(itemScroll, "📦", Color3.fromRGB(80, 60, 40))
			X.itemPreview(r, v)
			label(r, { Size = UDim2.new(1, -158, 1, 0), Position = UDim2.fromOffset(40, 0), Text = v.Name .. "  ·  " .. math.round(e.d) .. "m", TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })

			local markBtn = miniButton(r, marks[v] and "Unmark" or "Mark", marks[v] and THEME.Danger or THEME.Warn, 8, 58)
			markBtn.MouseButton1Click:Connect(function()
				if not v.Parent then return end
				local state = toggleMark(v)
				if state == nil then return end
				markBtn.Text = state and "Unmark" or "Mark"
				markBtn.BackgroundColor3 = state and THEME.Danger or THEME.Warn
				notify("Mark", (state and "มาร์ค: " or "ยกเลิกมาร์ค: ") .. v.Name, 1.5, state and "warn" or "off")
			end)

			local tpBtn = miniButton(r, "TP", THEME.Accent2, 72, 38)
			tpBtn.MouseButton1Click:Connect(function()
				local part = v.Parent and getTargetPart(v)
				if part then tweenTp(part.CFrame * CFrame.new(0, 2, 0)) end
			end)
		end
		if #shown == 0 then emptyState(itemScroll, "ไม่พบไอเทมในแมพ\nกด Refresh เพื่อสแกนใหม่") end
	end

	button(pWorld, "⟳  Refresh Map Items", refreshItemList)
	button(pWorld, "✖  Clear All Marks", function()
		clearAllMarks()
		refreshItemList()
		notify("Mark", "ยกเลิกมาร์คทั้งหมดแล้ว", 1.5, "off")
	end)

	-- ==========================================
	-- 👾 MOB LIST (แท็บ World)
	-- ==========================================
	do
		section(pWorld, "Mobs")
		local mobScroll = listBox(pWorld)

		local function refreshMobList()
			clearList(mobScroll)
			local mobs = scanWorld(true, false)
			local alive = {}
			for _, m in ipairs(mobs) do
				local h = m:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 then alive[#alive + 1] = m end
			end
			local shown = nearest(alive, 40)
			for _, e in ipairs(shown) do
				local m = e.obj
				local h = m:FindFirstChildOfClass("Humanoid")
				local r = listRow(mobScroll, "👾", Color3.fromRGB(120, 40, 50))
				X.itemPreview(r, m)
				label(r, { Size = UDim2.new(1, -158, 0, 18), Position = UDim2.fromOffset(40, 4), Text = m.Name, TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })
				local hpText = h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) or "?"
				label(r, { Size = UDim2.new(1, -158, 0, 14), Position = UDim2.fromOffset(40, 20), Text = math.round(e.d) .. "m  ·  HP " .. hpText, TextSize = 9, TextColor3 = THEME.SubText, TextTruncate = Enum.TextTruncate.AtEnd })

				local markBtn = miniButton(r, marks[m] and "Unmark" or "Mark", marks[m] and THEME.Danger or THEME.Warn, 8, 58)
				markBtn.MouseButton1Click:Connect(function()
					if not m.Parent then return end
					local state = toggleMark(m)
					if state == nil then return end
					markBtn.Text = state and "Unmark" or "Mark"
					markBtn.BackgroundColor3 = state and THEME.Danger or THEME.Warn
					notify("Mark", (state and "มาร์ค: " or "ยกเลิกมาร์ค: ") .. m.Name, 1.5, state and "warn" or "off")
				end)

				local tpBtn = miniButton(r, "TP", THEME.Accent2, 72, 38)
				tpBtn.MouseButton1Click:Connect(function()
					local part = m.Parent and getTargetPart(m)
					if part then tweenTp(part.CFrame * CFrame.new(0, 2, 6)) end
				end)
			end
			if #shown == 0 then emptyState(mobScroll, "ไม่พบมอนสเตอร์ในแมพ\nกด Refresh เพื่อสแกนใหม่") end
		end
		button(pWorld, "⟳  Refresh Mobs", function() refreshMobList() end)
	end

	-- ==========================================
	-- 📡 RADAR (เรดาร์มุมจอ)
	-- ==========================================
	local radarAcc, updateRadar = 0, nil
	do
		local RADAR_COLORS = {
			player = Color3.fromRGB(80, 255, 130), mob = Color3.fromRGB(255, 70, 80),
			item = Color3.fromRGB(255, 230, 120), mark = THEME.Warn,
		}

		local radarFrame = make("Frame", {
			Name = "Radar", Size = UDim2.fromOffset(R.size, R.size), BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.2,
			BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 5,
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, radarFrame)
		local rStroke = stroke(radarFrame, WHITE, 2, 0.15)
		gradient(rStroke, THEME.Accent1, THEME.Accent2, 45)

		local function guiSize()
			local sz = gui.AbsoluteSize
			if sz.X < 10 or sz.Y < 10 then
				local cam = workspace.CurrentCamera
				sz = cam and cam.ViewportSize or Vector2.new(1280, 720)
			end
			return sz
		end
		local function clampRadar()
			local sz = guiSize()
			local x = math.clamp(radarFrame.Position.X.Offset, 0, math.max(sz.X - R.size, 0))
			local y = math.clamp(radarFrame.Position.Y.Offset, 0, math.max(sz.Y - R.size, 0))
			radarFrame.Position = UDim2.fromOffset(x, y)
		end
		if layout.rx and layout.ry then
			radarFrame.Position = UDim2.fromOffset(layout.rx, layout.ry)
		else
			radarFrame.Position = UDim2.fromOffset(math.max(guiSize().X - R.size - 12, 0), 64)
		end

		-- วงแหวนระยะ + เส้นกากบาท
		for _, scale in ipairs({ 0.66, 0.33 }) do
			local ringF = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = 5 }, radarFrame)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, ringF)
			stroke(ringF, THEME.Stroke, 1, 0.35)
		end
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5 }, radarFrame)
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = THEME.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5 }, radarFrame)

		local radarArrow = label(radarFrame, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16),
			Text = "▲", TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8,
		})
		local radarRangeLabel = label(radarFrame, {
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(60, 12),
			Text = R.range .. "m", TextSize = 9, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8,
		})

		-- ลากย้ายเรดาร์ (ถ้าล็อกไว้จะลากไม่ได้)
		local radarHandle = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 }, radarFrame)
		local rInput, rStart, rStartOffset
		radarHandle.InputBegan:Connect(function(input)
			if isPress(input) and not rInput and not btnLocked then
				rInput = input
				rStart = input.Position
				rStartOffset = Vector2.new(radarFrame.Position.X.Offset, radarFrame.Position.Y.Offset)
			end
		end)
		mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
			if not rInput then return end
			local same = (input == rInput) or (input.UserInputType == Enum.UserInputType.MouseMovement and rInput.UserInputType == Enum.UserInputType.MouseButton1)
			if not same then return end
			local d = input.Position - rStart
			radarFrame.Position = UDim2.fromOffset(rStartOffset.X + d.X, rStartOffset.Y + d.Y)
			clampRadar()
		end))
		mainMaid:Give(UserInputService.InputEnded:Connect(function(input)
			if not rInput then return end
			local same = (input == rInput) or (input.UserInputType == Enum.UserInputType.MouseButton1 and rInput.UserInputType == Enum.UserInputType.MouseButton1)
			if not same then return end
			rInput = nil
			layout.rx, layout.ry = radarFrame.Position.X.Offset, radarFrame.Position.Y.Offset
			saveBtnData()
		end))

		-- จุดบนเรดาร์ (pool ใช้ซ้ำ ไม่สร้างใหม่ทุกเฟรม)
		local radarDots = {}
		local function radarDot(i)
			local d = radarDots[i]
			if not d then
				d = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, ZIndex = 6 }, radarFrame)
				make("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
				radarDots[i] = d
			end
			return d
		end

		updateRadar = function(hrp, cam)
			local half = R.size / 2
			local range = R.range
			local k = (half - 6) / range
			local origin = hrp.Position
			local look = cam.CFrame.LookVector
			local fl = Vector3.new(look.X, 0, look.Z)
			fl = fl.Magnitude > 0.001 and fl.Unit or Vector3.new(0, 0, -1)
			local rt = Vector3.new(-fl.Z, 0, fl.X)
			radarArrow.Rotation = R.rotate and 0 or math.deg(math.atan2(look.X, -look.Z))

			local used = 0
			local function put(pos, color, size)
				local rel = pos - origin
				local x, y
				if R.rotate then x = rel:Dot(rt); y = -rel:Dot(fl) else x = rel.X; y = rel.Z end
				local dist = math.sqrt(x * x + y * y)
				local transp = 0
				if dist > range then x = x / dist * range; y = y / dist * range; transp = 0.55 end -- นอกระยะ: ปักที่ขอบ จางลง
				used = used + 1
				local d = radarDot(used)
				d.Size = UDim2.fromOffset(size, size)
				d.BackgroundColor3 = color
				d.BackgroundTransparency = transp
				d.Position = UDim2.fromOffset(half + x * k, half + y * k)
				d.Visible = true
			end

			if R.players then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player then
						local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if root then put(root.Position, RADAR_COLORS.player, 8) end
					end
				end
			end
			if R.mobs then
				for _, m in ipairs(R.mobCache) do
					if m.Parent and not marks[m] then
						local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
						if root then put(root.Position, RADAR_COLORS.mob, 7) end
					end
				end
			end
			if R.items then
				for _, obj in ipairs(R.itemCache) do
					if obj.Parent and not marks[obj] then
						local part = getTargetPart(obj)
						if part then put(part.Position, RADAR_COLORS.item, 6) end
					end
				end
			end
			for _, m in pairs(marks) do
				if m.part.Parent then put(m.part.Position, RADAR_COLORS.mark, 10) end
			end
			for i = used + 1, #radarDots do radarDots[i].Visible = false end
		end

		-- แถวชิป (เปิด/ปิดตัวเลือก ไม่นับในป้าย ON และไม่ถูกรีเซ็ต)
		local function chipRow(page, titleText, chips)
			local row = card(page, 66)
			row:SetAttribute("Search", string.lower(titleText))
			label(row, { Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 8), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 12 })
			local holder = make("Frame", { Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 30), BackgroundTransparency = 1 }, row)
			make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
			for i, c in ipairs(chips) do
				local on = c.default
				local b = make("TextButton", {
					Size = UDim2.new(1 / #chips, -5, 1, 0), Text = c.text, Font = Enum.Font.GothamBold, TextSize = 11,
					AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = WHITE, LayoutOrder = i,
				}, holder)
				round(b, 8)
				local g = gradient(b, THEME.Accent1, THEME.Accent2, 0)
				local function paint()
					g.Enabled = on
					b.BackgroundColor3 = on and WHITE or THEME.Panel
					b.TextColor3 = on and WHITE or THEME.SubText
				end
				paint()
				c.onChange(on)
				b.MouseButton1Click:Connect(function() on = not on; paint(); c.onChange(on) end)
			end
		end

		-- ตัวควบคุมอยู่แท็บ Visuals
		section(pVis, "Radar")
		toggle(pVis, "Radar", function(on)
			F.radar = on
			radarFrame.Visible = on
			if on then clampRadar(); pcall(runScan) end
		end, "เรดาร์มุมจอ แสดงผู้เล่น/มอน/ไอเทมรอบตัว (ลากย้ายได้)")
		slider(pVis, "Radar Range", 50, 500, R.range, 10, function(v)
			R.range = v
			radarRangeLabel.Text = v .. "m"
		end)
		slider(pVis, "Radar Size", 100, 220, R.size, 10, function(v)
			R.size = v
			radarFrame.Size = UDim2.fromOffset(v, v)
			clampRadar()
		end)
		chipRow(pVis, "Radar Options", {
			{ text = "Players", default = true, onChange = function(v) R.players = v end },
			{ text = "Mobs", default = true, onChange = function(v) R.mobs = v; if v and F.radar then pcall(runScan) end end },
			{ text = "Items", default = true, onChange = function(v) R.items = v; if v and F.radar then pcall(runScan) end end },
			{ text = "Rotate", default = true, onChange = function(v) R.rotate = v end },
		})
	end

	-- ==========================================
	-- 📷 5. TAB: CAMERA
	-- ==========================================
	local pCam = pages["Camera"]
	X.Cam = { path = {}, playing = false, t = 0, dur = 3, loop = false, playBtn = nil, freecamToggle = nil }

	-- ---------- Freecam ----------
	section(pCam, "Freecam")
	local freecamPos = Vector3.new()
	local fcUp, fcDown, fcYaw, fcPitch = false, false, 0, 0
	local fcControls = makePad(90, THEME.Accent1, THEME.Accent2, function(v) fcUp = v end, function(v) fcDown = v end)

	-- ตรึงตัวละครไว้ตอนใช้ Freecam (ไม่ให้เดินตามจอยสติ๊ก/WASD)
	local frozenRoot, frozenWas
	local function setCharFrozen(on)
		if on then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then frozenRoot = root; frozenWas = root.Anchored; root.Anchored = true end
		elseif frozenRoot then
			if frozenRoot.Parent then frozenRoot.Anchored = frozenWas or false end
			frozenRoot = nil
		end
	end
	mainMaid:Give(function() setCharFrozen(false) end)

	-- หมุนกล้อง: PC = กดเมาส์ขวาค้างแล้วลาก, มือถือ = ลากนิ้วบนหน้าจอ
	mainMaid:Give(UserInputService.InputChanged:Connect(function(input)
		if F.freecam and input.UserInputType == Enum.UserInputType.MouseMovement
			and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			fcYaw = fcYaw - input.Delta.X * 0.004
			fcPitch = math.clamp(fcPitch - input.Delta.Y * 0.004, -1.48, 1.48)
		end
	end))
	mainMaid:Give(UserInputService.TouchMoved:Connect(function(touch, processed)
		if F.freecam and not processed then
			fcYaw = fcYaw - touch.Delta.X * 0.005
			fcPitch = math.clamp(fcPitch - touch.Delta.Y * 0.005, -1.48, 1.48)
		end
	end))

	X.Cam.freecamToggle = toggle(pCam, "Freecam", function(on)
		F.freecam = on
		local cam = workspace.CurrentCamera
		if on then
			if X.Spec.target then X.Spec.stop() end
			if X.Cam.playing then X.Cam.stop() end
			if X.Nav.key then X.Nav.stop(true) end
			if cam then
				local rx, ry = cam.CFrame:ToOrientation()
				fcPitch, fcYaw = rx, ry
				freecamPos = cam.CFrame.Position
				cam.CameraType = Enum.CameraType.Scriptable
			end
			setCharFrozen(true)
		else
			if cam then cam.CameraType = Enum.CameraType.Custom end
			setCharFrozen(false)
			fcUp, fcDown = false, false
		end
		fcControls.Visible = on
	end, "ถอดกล้องอิสระ (ลากหมุนกล้อง)")
	slider(pCam, "Freecam Speed", 20, 300, F.freecamSpeed, 10, function(v) F.freecamSpeed = v end)
	button(pCam, "📍  TP Character to Camera", function()
		if not F.freecam then
			notify("Freecam", "เปิด Freecam ก่อน แล้วค่อยวาร์ปไปจุดที่กล้องอยู่", 2.5, "warn")
			return
		end
		tweenTp(CFrame.new(freecamPos))
		notify("Freecam", "วาร์ปแล้ว — ปิด Freecam เพื่อกลับไปควบคุมตัวละคร", 3, "success")
	end)

	-- ---------- Zoom & View ----------
	do
		local Z = { unlock = false, max = 400, mode = 1 } -- mode: 1 Default, 2 First Person, 3 Third Person
		local orig = { max = player.CameraMaxZoomDistance, min = player.CameraMinZoomDistance, mode = player.CameraMode }
		local function applyZoom()
			pcall(function()
				player.CameraMaxZoomDistance = Z.unlock and Z.max or orig.max
				local minZ = Z.unlock and 0.5 or orig.min
				if Z.mode == 3 then minZ = math.max(minZ, 8) end
				player.CameraMinZoomDistance = minZ
				player.CameraMode = (Z.mode == 2) and Enum.CameraMode.LockFirstPerson or orig.mode
			end)
		end
		mainMaid:Give(function() Z.unlock = false; Z.mode = 1; applyZoom() end)

		section(pCam, "Zoom & View")
		toggle(pCam, "Zoom Unlock", function(on) Z.unlock = on; applyZoom() end, "ซูมกล้องออกได้ไกลกว่าที่เกมกำหนด")
		slider(pCam, "Max Zoom Distance", 20, 2000, Z.max, 10, function(v)
			Z.max = v
			if Z.unlock then applyZoom() end
		end)
		X.segmented(pCam, "View Mode", { "Default", "1st Person", "3rd Person" }, 1, function(i)
			Z.mode = i
			applyZoom()
		end)
		slider(pCam, "Camera FOV", 50, 120, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, 1, function(v)
			if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
		end)
	end

	-- ---------- Camera Path ----------
	section(pCam, "Camera Path")

	X.Cam.stop = function(done)
		if not X.Cam.playing then return end
		X.Cam.playing = false
		local cam = workspace.CurrentCamera
		if cam then cam.CameraType = Enum.CameraType.Custom end
		X.Dock.hide("campath")
		if X.Cam.playBtn then X.Cam.playBtn.Text = "▶  Play Path" end
		if done == true then notify("Camera Path", "เล่นจบแล้ว", 2, "success") end
	end

	X.Cam.play = function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		if #X.Cam.path < 2 then
			notify("Camera Path", "ต้องมีอย่างน้อย 2 จุด", 2, "warn")
			return
		end
		if X.Spec.target then X.Spec.stop() end
		if F.freecam then X.Cam.freecamToggle.set(false, true) end
		X.Cam.playing = true
		X.Cam.t = 0
		cam.CameraType = Enum.CameraType.Scriptable
		X.Dock.show("campath", "■  Stop Camera Path", function() X.Cam.stop() end, nil, "danger")
		if X.Cam.playBtn then X.Cam.playBtn.Text = "■  Stop Path" end
	end

	-- เล่นตามเส้นทาง: ตำแหน่งใช้ Catmull-Rom (โค้งนุ่ม) / การหมุนใช้ Lerp
	X.Cam.step = function(dt, cam)
		local P = X.Cam.path
		local n = #P
		if n < 2 then X.Cam.stop(); return end
		local segs = X.Cam.loop and n or (n - 1)
		X.Cam.t = X.Cam.t + dt / X.Cam.dur
		if X.Cam.t >= segs then
			if X.Cam.loop then
				X.Cam.t = X.Cam.t - segs
			else
				X.Cam.stop(true)
				return
			end
		end
		local i = math.floor(X.Cam.t) + 1
		local a = X.Cam.t - (i - 1)
		local function at(k)
			if X.Cam.loop then return P[((k - 1) % n) + 1] end
			return P[math.clamp(k, 1, n)]
		end
		local c0, c1, c2, c3 = at(i - 1), at(i), at(i + 1), at(i + 2)
		local p0, p1, p2, p3 = c0.Position, c1.Position, c2.Position, c3.Position
		local a2, a3 = a * a, a * a * a
		local pos = 0.5 * ((2 * p1) + (p2 - p0) * a + (2 * p0 - 5 * p1 + 4 * p2 - p3) * a2 + (3 * p1 - p0 - 3 * p2 + p3) * a3)
		cam.CFrame = CFrame.new(pos) * c1.Rotation:Lerp(c2.Rotation, a)
	end
	mainMaid:Give(function() X.Cam.stop() end)

	local pathScroll
	local function refreshPathList()
		clearList(pathScroll)
		local P = X.Cam.path
		for i, cf in ipairs(P) do
			local r = listRow(pathScroll, tostring(i), Color3.fromRGB(70, 60, 130))
			local pp = cf.Position
			label(r, {
				Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(40, 0),
				Text = string.format("Point %d  ·  %d, %d, %d", i, math.round(pp.X), math.round(pp.Y), math.round(pp.Z)),
				TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local del = miniButton(r, "✕", THEME.Danger, 8, 30)
			del.MouseButton1Click:Connect(function()
				table.remove(X.Cam.path, i)
				refreshPathList()
			end)
			local view = miniButton(r, "View", THEME.Accent2, 44, 44)
			view.MouseButton1Click:Connect(function()
				if X.Cam.playing then X.Cam.stop() end
				if not F.freecam then X.Cam.freecamToggle.set(true, true) end
				local rx, ry = cf:ToOrientation()
				fcPitch, fcYaw = rx, ry
				freecamPos = cf.Position
			end)
		end
		if #P == 0 then emptyState(pathScroll, "ยังไม่มีจุดกล้อง\nกด Add Point เพื่อบันทึกมุมกล้องปัจจุบัน") end
	end

	button(pCam, "➕  Add Point (มุมกล้องปัจจุบัน)", function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		if #X.Cam.path >= 12 then
			notify("Camera Path", "เพิ่มได้สูงสุด 12 จุด", 2, "warn")
			return
		end
		table.insert(X.Cam.path, cam.CFrame)
		refreshPathList()
		notify("Camera Path", "เพิ่มจุดที่ " .. #X.Cam.path, 1.5, "success")
	end)
	pathScroll = listBox(pCam)
	refreshPathList()
	slider(pCam, "Segment Duration", 1, 10, 3, 0.5, function(v) X.Cam.dur = v end)
	toggle(pCam, "Loop Path", function(on) X.Cam.loop = on end, "เล่นวนซ้ำไม่จบ จนกว่าจะกด Stop")
	X.Cam.playBtn = button(pCam, "▶  Play Path", function()
		if X.Cam.playing then X.Cam.stop() else X.Cam.play() end
	end, "primary")
	button(pCam, "✖  Clear All Points", function()
		X.Cam.stop()
		X.Cam.path = {}
		refreshPathList()
		notify("Camera Path", "ล้างจุดทั้งหมดแล้ว", 1.5, "off")
	end)

	-- ==========================================
	-- ℹ️ 6. TAB: INFO
	-- ==========================================
	local pInfo = pages["Info"]
	do
		local MarketplaceService = game:GetService("MarketplaceService")
		local Stats = game:GetService("Stats")

		local CHANGES = {
			{ "📷", "Camera (แท็บใหม่)", "รวม Freecam และ FOV ไว้ที่เดียว พร้อมปุ่ม TP Character to Camera" },
			{ "🔭", "Zoom Unlock & View Mode", "ซูมกล้องออกไกลกว่าที่เกมกำหนด และล็อกมุมมองบุคคลที่ 1 / 3" },
			{ "🎞", "Camera Path", "บันทึกจุดกล้องแล้วเล่นไหลตามเส้นทางนุ่มๆ ปรับความเร็วและเล่นวนได้" },
			{ "💀", "Return to Death Point", "จำจุดที่ตาย กลับได้จากแท็บ World หรือปุ่มลอยหลังเกิดใหม่" },
			{ "👁", "Spectate ◀ ▶", "แถบลอยบนจอ สลับดูผู้เล่นคนถัดไป/ก่อนหน้าได้ทันที" },
			{ "🧭", "Walk to Mark / Follow Player", "เดินด้วย Pathfinding ไปหาเป้าหมายที่ Mark หรือเดินตามผู้เล่น มีปุ่ม Stop ลอย" },
			{ "🚀", "Rocket Edge-Snap", "ปุ่มจรวดดูดติดขอบจอและจางลงเมื่อไม่ได้ใช้ (ปิดได้ใน Settings)" },
			{ "ℹ️", "Info (แท็บใหม่)", "ข้อมูลเซิร์ฟเวอร์ + Rejoin / Server Hop และหน้าสรุปการอัปเดตนี้" },
			{ "🗂", "จัดหมวดใหม่", "Player · Camera · Visuals · World · Info · Settings" },
		}

		local function infoRow(page, key, value)
			local row = card(page, 34)
			row:SetAttribute("Search", string.lower(key))
			label(row, { Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(12, 0), Text = key, TextSize = 11, TextColor3 = THEME.SubText })
			return label(row, {
				Size = UDim2.new(0.6, -24, 1, 0), Position = UDim2.new(0.4, 12, 0, 0), Text = value or "—", TextSize = 11,
				Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
			})
		end

		local function noteCard(parent, icon, titleText, bodyText, order)
			local f = make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = THEME.Card, BorderSizePixel = 0, LayoutOrder = order or 0 }, parent)
			round(f, 10)
			stroke(f, THEME.Stroke, 1, 0.45)
			f:SetAttribute("Search", string.lower(titleText .. " " .. bodyText))
			make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, f)
			make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, f)
			label(f, { Size = UDim2.new(1, 0, 0, 16), Text = icon .. "  " .. titleText, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = 1 })
			label(f, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = bodyText, TextSize = 11, TextColor3 = THEME.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 })
			return f
		end

		local function copyText(txt, what)
			local ok = pcall(function() (setclipboard or toclipboard)(txt) end)
			if ok then
				notify("Copied", "คัดลอก " .. what .. " แล้ว", 1.8, "success")
			else
				notify("Copy", "Executor นี้ไม่รองรับการคัดลอก", 2.5, "warn")
			end
		end

		-- ---- Server ----
		section(pInfo, "Server")
		local vPlace = infoRow(pInfo, "Place", "กำลังโหลด...")
		local vPlayers = infoRow(pInfo, "Players", "—")
		local vAge = infoRow(pInfo, "Server Age", "—")
		local vPing = infoRow(pInfo, "Ping", "—")
		local vFps = infoRow(pInfo, "FPS", "—")
		infoRow(pInfo, "Place ID", tostring(game.PlaceId))
		infoRow(pInfo, "Job ID", game.JobId ~= "" and game.JobId or "Studio / Private")
		infoRow(pInfo, "Place Version", tostring(game.PlaceVersion))

		task.spawn(function()
			local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
			vPlace.Text = (ok and info and info.Name) or "—"
		end)

		X.Ticks[#X.Ticks + 1] = function()
			if not (pInfo.Visible and window.Visible) then return end
			vPlayers.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
			local t = math.floor(workspace.DistributedGameTime)
			vAge.Text = string.format("%d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60)
			local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			vPing.Text = ok and (math.round(ping) .. " ms") or "—"
			vFps.Text = X.fps and tostring(math.round(X.fps)) or "—"
		end

		button(pInfo, "📋  Copy Job ID", function() copyText(game.JobId, "Job ID") end)
		button(pInfo, "📋  Copy Place ID", function() copyText(tostring(game.PlaceId), "Place ID") end)
		button(pInfo, "🔄  Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
		button(pInfo, "🌐  Server Hop", function() TeleportService:Teleport(game.PlaceId, player) end)

		-- ---- What's New ----
		section(pInfo, "What's New · " .. X.VERSION)
		for i, c in ipairs(CHANGES) do noteCard(pInfo, c[1], c[2], c[3], i) end

		-- หน้าต่างป๊อปอัปสรุปอัปเดต (สร้างครั้งแรกที่เรียกใช้)
		local overlay
		function X.showWhatsNew()
			if not overlay then
				overlay = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60 }, gui)
				local box = make("Frame", { Size = UDim2.new(0, 310, 0.86, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = THEME.Panel, BorderSizePixel = 0 }, overlay)
				make("UISizeConstraint", { MaxSize = Vector2.new(310, 420), MinSize = Vector2.new(260, 220) }, box)
				round(box, 16)
				gradient(stroke(box, WHITE, 1.6, 0.15), THEME.Accent1, THEME.Accent2, 45)
				label(box, { Size = UDim2.new(1, -28, 0, 24), Position = UDim2.fromOffset(16, 14), Text = "✨ What's New · " .. X.VERSION, Font = Enum.Font.GothamBold, TextSize = 15 })
				label(box, { Size = UDim2.new(1, -28, 0, 16), Position = UDim2.fromOffset(16, 40), Text = "สิ่งที่เพิ่มและเปลี่ยนในเวอร์ชันนี้", TextSize = 11, TextColor3 = THEME.SubText })
				local list = make("ScrollingFrame", {
					Size = UDim2.new(1, -24, 1, -124), Position = UDim2.fromOffset(12, 64), BackgroundTransparency = 1, BorderSizePixel = 0,
					ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Accent2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, box)
				make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
				for i, c in ipairs(CHANGES) do noteCard(list, c[1], c[2], c[3], i) end
				local okBtn = make("TextButton", { Size = UDim2.new(1, -28, 0, 40), Position = UDim2.new(0, 14, 1, -52), BackgroundColor3 = WHITE, Text = "เข้าใจแล้ว", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false }, box)
				round(okBtn, 12)
				gradient(okBtn, THEME.Accent1, THEME.Accent2, 0)
				okBtn.MouseButton1Click:Connect(function()
					overlay.Visible = false
					layout.seen = X.VERSION
					saveBtnData()
				end)
			end
			overlay.Visible = true
		end
		button(pInfo, "✨  Show What's New Popup", function() X.showWhatsNew() end, "primary")

		-- เปิดป๊อปอัปอัตโนมัติครั้งเดียวต่อเวอร์ชัน (ถ้า Executor จำไฟล์ได้) ไม่งั้นแจ้งเตือนสั้นๆ แทน
		local persistent = type(writefile) == "function"
		if persistent and layout.seen ~= X.VERSION then
			task.delay(1.2, function() X.showWhatsNew() end)
		elseif not persistent then
			task.delay(1.5, function() notify("What's New " .. X.VERSION, "ดูสิ่งที่เพิ่มใหม่ได้ที่แท็บ Info", 4, "info") end)
		end
	end

	-- ==========================================
	-- ⚙️ 4. TAB: SETTINGS
	-- ==========================================
	local pSettings = pages["Settings"]

	section(pSettings, "Interface")
	slider(pSettings, "UI Size Scale", 0.6, 1.4, 1, 0.05, function(v) userScale = v; updateScale() end)
	local lockToggle = toggle(pSettings, "Lock Button & Radar Position", function(on)
		btnLocked = on
		lockBadge.Visible = on
		saveBtnData()
	end, "ล็อกปุ่มจรวดและเรดาร์ไว้ที่ตำแหน่งปัจจุบัน ไม่ให้ลากโดยไม่ตั้งใจ", true)
	if btnLocked then lockToggle.set(true, true) end
	local snapToggle = toggle(pSettings, "Edge Snap & Fade", function(on)
		layout.snap = on
		if on then snapBtn(); wakeBtn() end
		saveBtnData()
	end, "ปุ่มจรวดดูดติดขอบจอและจางลงเมื่อไม่ได้ใช้", true)
	if layout.snap then snapToggle.set(true, true) end

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
	end, "กันถูกเตะหลุดจากการ AFK", true) -- true = ไม่ปิดตอนกด Reset All
	mainMaid:Give(function() if antiAfkConn then antiAfkConn:Disconnect() end end)


	section(pSettings, "System")
	button(pSettings, "Reset All Values", function()
		for _, fn in ipairs(resetters) do pcall(fn) end -- slider กลับค่าเริ่มต้น + toggle ปิดทั้งหมด
		overrides = {}
		stopFly()
		clearAllMarks()
		pcall(function() X.Spec.stop(); X.Nav.stop(true); X.Cam.stop() end)
		notify("System", "รีเซ็ตค่าทั้งหมดแล้ว", 2, "success")
	end, "danger")

	-- ==========================================
	-- 🔁 MAIN LOOP (ตัวเดียว แทน RenderStepped หลายตัว)
	-- ==========================================
	mainMaid:Give(RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local cam = workspace.CurrentCamera

		X.fps = X.fps and (X.fps * 0.92 + (1 / math.max(dt, 0.001)) * 0.08) or 60

		-- Fullbright
		if F.fullbright then
			Lighting.Brightness = 2; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		end

		-- Freecam
		if F.freecam and cam and not X.Cam.playing then
			local rot = CFrame.fromOrientation(fcPitch, fcYaw, 0)
			local look, right = rot.LookVector, rot.RightVector
			local md = hum and hum.MoveDirection or Vector3.zero
			local flatLook = Vector3.new(look.X, 0, look.Z)
			local fwd = flatLook.Magnitude > 0.001 and md:Dot(flatLook.Unit) or 0
			local side = md:Dot(right)
			local move = look * fwd + right * side
			if fcUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
			if fcDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
			freecamPos = freecamPos + move * (F.freecamSpeed * dt)
			cam.CFrame = CFrame.new(freecamPos) * rot
		end

		-- Camera Path
		if X.Cam.playing and cam then X.Cam.step(dt, cam) end

		-- CFrame Speed
		if F.cfSpeed and hrp and hum and hum.MoveDirection.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + hum.MoveDirection * (F.cfSpeedVal * 0.4)
		end

		-- Infinite Stamina
		if F.infStamina and char then
			local stamina = char:FindFirstChild("Stamina") or char:FindFirstChild("Energy")
			if stamina and stamina:IsA("ValueBase") then stamina.Value = 100 end
		end

		-- Mob Hitbox
		if F.mobHitbox then
			for _, m in ipairs(mobCache) do
				if m.Parent then
					local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
					if root then expandPart(mobHitOrig, root, F.mobHitboxSize) end
				end
			end
		end

		-- ESP: NameTags & Player Highlight
		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= player and target.Character then
				local head = target.Character:FindFirstChild("Head")
				local thum = target.Character:FindFirstChildOfClass("Humanoid")

				if F.nameTags and head and thum and thum.Health > 0 then
					local bg = nameTagGuis[target]
					if not bg or bg.Parent ~= head then
						if bg then bg:Destroy() end
						bg = Instance.new("BillboardGui")
						bg.Size = UDim2.fromOffset(140, 22); bg.StudsOffset = Vector3.new(0, 2.6, 0); bg.AlwaysOnTop = true
						bg.Parent = head
						local pill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.25, BorderSizePixel = 0 }, bg)
						round(pill, 11)
						stroke(pill, THEME.Accent2, 1, 0.3)
						make("TextLabel", { Name = "L", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 11 }, pill)
						nameTagGuis[target] = bg
					end
					local lbl = bg:FindFirstChild("L", true)
					if lbl then
						local dist = hrp and math.round((hrp.Position - head.Position).Magnitude) or 0
						lbl.Text = target.DisplayName .. "  ·  " .. tostring(dist) .. "m"
					end
				elseif nameTagGuis[target] then
					nameTagGuis[target]:Destroy(); nameTagGuis[target] = nil
				end

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

		-- ตัวจับเวลา 0.5 วินาที (Spectate / Death Point / Server Info)
		X.tickAcc = (X.tickAcc or 0) + dt
		if X.tickAcc >= 0.5 then
			X.tickAcc = 0
			for _, fn in ipairs(X.Ticks) do pcall(fn) end
		end

		-- Radar (อัปเดต ~30 ครั้ง/วินาที)
		if F.radar and updateRadar and hrp and cam then
			radarAcc = radarAcc + dt
			if radarAcc >= 0.033 then
				radarAcc = 0
				updateRadar(hrp, cam)
			end
		end

		-- อัปเดตระยะของ Mark
		for obj, m in pairs(marks) do
			if not obj.Parent or not m.part.Parent then
				removeMark(obj)
			else
				local d = hrp and math.round((hrp.Position - m.part.Position).Magnitude) or 0
				m.label.Text = "📍 " .. obj.Name .. "  ·  " .. d .. "m"
			end
		end
	end))

	-- เคลียร์ของที่ผู้เล่นออกจากเกม + อัปเดตรายชื่ออัตโนมัติ
	mainMaid:Give(Players.PlayerRemoving:Connect(function(p)
		if nameTagGuis[p] then nameTagGuis[p]:Destroy(); nameTagGuis[p] = nil end
		if playerHighlights[p] then playerHighlights[p]:Destroy(); playerHighlights[p] = nil end
		if X.Spec.target == p then X.Spec.stop() end
		refreshPlrList(p)
	end))
	mainMaid:Give(Players.PlayerAdded:Connect(function()
		task.wait(0.5)
		refreshPlrList()
	end))

	-- ใช้ค่าที่ตั้งไว้ซ้ำหลังรีสปอว์น (ความเร็ว/กระโดด, บิน, ล่องหน, Freecam)
	mainMaid:Give(player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not hum or not root then return end
		task.wait(0.3)
		applyStats()
		if flyOn then startFly() end
		if F.freecam then frozenRoot = nil; setCharFrozen(true) end
		if invisOn then task.wait(1); applyInvis() end
	end))

	-- เคลียร์ของที่สร้างไว้ในแมพเมื่อ GUI ถูกลบ
	mainMaid:Give(function()
		clearStore(itemHighlights); clearStore(mobHighlights); clearStore(playerHighlights); clearStore(nameTagGuis)
		restoreParts(mobHitOrig)
	end)

	task.spawn(function()
		task.wait(0.5)
		refreshPlrList()
		refreshItemList()
	end)

	notify("PlayerHUB", "โหลดสคริปต์สำเร็จ", 3, "success")
end)

if not Success then
	warn("PlayerHUB Error: " .. tostring(Err))
end
