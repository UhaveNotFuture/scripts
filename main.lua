local __SegoeUIRegular = nil
local __SegoeUISemibold = nil
local __SegoeUIBold = nil

pcall(function()
	__SegoeUIRegular  = Font.fromName("SegoeUI", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	__SegoeUISemibold = Font.fromName("SegoeUI", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)
	__SegoeUIBold     = Font.fromName("SegoeUI", Enum.FontWeight.Heavy,    Enum.FontStyle.Normal)
end)

if not __SegoeUIRegular then
	pcall(function() __SegoeUIRegular = Font.fromEnum(Enum.Font.GothamSemibold) end)
end
if not __SegoeUISemibold then
	pcall(function() __SegoeUISemibold = Font.fromEnum(Enum.Font.GothamBold) end)
end
if not __SegoeUIBold then
	pcall(function() __SegoeUIBold = __SegoeUISemibold or Font.fromEnum(Enum.Font.GothamBlack) end)
end

local UI = (function()
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	pcall(function() UserInputService.MouseIcon = "" end)
	local SoundService = game:GetService("SoundService")
	local Debris = game:GetService("Debris")
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")

	local Fluent = nil
	pcall(function()
		local source = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/download/1.1.0/main.lua")
		Fluent = loadstring(source)()
	end)

	local UI = {}

	local Theme = {
		Background = Color3.fromRGB(15, 18, 23),
		Background2 = Color3.fromRGB(21, 26, 33),
		Titlebar = Color3.fromRGB(20, 24, 31),
		Sidebar = Color3.fromRGB(18, 22, 28),
		Element = Color3.fromRGB(29, 35, 44),
		ElementHover = Color3.fromRGB(38, 46, 58),
		Text = Color3.fromRGB(255, 255, 255),
		SubText = Color3.fromRGB(205, 212, 222),
		Muted = Color3.fromRGB(155, 165, 179),
		Off = Color3.fromRGB(71, 80, 93),
		Outline = Color3.fromRGB(70, 80, 95),
		Popup = Color3.fromRGB(29, 35, 44),
		Danger = Color3.fromRGB(224, 96, 84),
		Font = Enum.Font.GothamBold,
		FontBold = Enum.Font.GothamBold,
	}
	local DEFAULT_ACCENT = Color3.fromRGB(0, 122, 255)
	local UI_SOUND_ID = "rbxassetid://113397864512278"
	local UI_SOUNDS_ENABLED = true

	local function PlayUISound(pitch, volume)
		UI_SOUNDS_ENABLED = true
		local ok, sound = pcall(function()
			local s = Instance.new("Sound")
			s.Name = "Netspend_UISound"
			s.SoundId = UI_SOUND_ID
			s.Volume = math.clamp(volume or 0.075, 0.025, 0.12)
			s.PlaybackSpeed = pitch or 1
			s.RollOffMode = Enum.RollOffMode.Linear
			s.Parent = SoundService
			return s
		end)
		if not ok or not sound then return end
		pcall(function()
			SoundService:PlayLocalSound(sound)
		end)
		Debris:AddItem(sound, 1.25)
	end

	local function IsPrimaryPointerInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local function New(class, props, children)
		local inst = Instance.new(class)
		local parent = nil
		if props then
			for k, v in pairs(props) do
				if k == "Parent" then parent = v else pcall(function() inst[k] = v end) end
			end
		end
		if children then
			for _, c in ipairs(children) do
				if c:IsA("UICorner") then
					inst.ClipsDescendants = true
				end
				c.Parent = inst
			end
		end
		if inst:IsA("GuiButton") then
			pcall(function()
				inst.AutoButtonColor = false
				inst.Selectable = false
				inst.Interactable = true
			end)
		end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			pcall(function()
				inst:SetAttribute("__NetspendFontApplied", true)
				if props and props.FontFace then return end
				if props and props.Font == Theme.FontBold then
					inst.FontFace = __SegoeUISemibold or __SegoeUIBold
				else
					inst.FontFace = __SegoeUIRegular or Font.fromEnum(Enum.Font.Gotham)
				end
			end)
		end
		if parent then inst.Parent = parent end
		return inst
	end

	local function Corner(radius)
		radius = math.max(0, tonumber(radius) or 10)
		return New("UICorner", { CornerRadius = UDim.new(0, radius) })
	end

	local function Stroke(parent, color, transparency, thickness)
		return New("UIStroke", {
			Color = color or Theme.Outline,
			Transparency = transparency or 0,
			Thickness = thickness or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = parent,
		})
	end

	local function Tween(inst, info, goal)
		local ok, tw = pcall(function() return TweenService:Create(inst, info, goal) end)
		if ok and tw then tw:Play(); return tw end
		return nil
	end

	local TI_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local TI_MED = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local TI_SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local TI_PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function Lighten(c, a) return c:Lerp(Color3.new(1, 1, 1), a) end
	local function Darken(c, a) return c:Lerp(Color3.new(0, 0, 0), a) end

	local function AddShadow(parent, radius, spread)
		local s = spread or 18
		return New("Frame", {
			Name = "Shadow",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 4),
			Size = UDim2.new(1, s, 1, s),
			ZIndex = math.max(parent.ZIndex - 1, 0),
			Parent = parent,
		}, { Corner((radius or 12) + s / 2) })
	end

	local function AttachSquish(hit, target, conns)
		if not hit or not target then return end
		local scale = target:FindFirstChild("__PressScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = "__PressScale"
			scale.Scale = 1
			scale.Parent = target
		end
		local pressed = false
		local function press()
			if pressed or not target.Parent then return end
			pressed = true
			Tween(scale, TI_PRESS, { Scale = 0.975 })
		end
		local function release()
			if not pressed then return end
			pressed = false
			Tween(scale, TI_SPRING, { Scale = 1 })
		end
		table.insert(conns, hit.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then press() end
		end))
		table.insert(conns, hit.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then release() end
		end))
		table.insert(conns, hit.MouseLeave:Connect(release))
	end

	local function MakeSquishHost(parent, height)
		local host = New("Frame", { Name = "Host", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), Parent = parent })
		local body = New("Frame", {
			Name = "Body", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.24, BorderSizePixel = 0, Parent = host,
		}, { Corner(12) })
		return host, body
	end

	local Icons = {
		main = "rbxassetid://7733970318",
		combat = "rbxassetid://7733765307",
		misc = "rbxassetid://7734058803",
	}

	function UI:CreateWindow(config)
		config = config or {}
		local cfg = config
		local Window = {}
		local conns = {}
		local tabs = {}
		local elements = {}
		local accent = cfg.Accent or DEFAULT_ACCENT
		local accentObjects = {}
		local accentHooks = {}
		local destroyed = false

		local function Bind(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end
		local function BindPrimaryClick(button, callback)
			return Bind(button.Activated, function()
				task.defer(callback)
			end)
		end
		local function TrackAccent(obj, prop)
			table.insert(accentObjects, { obj = obj, prop = prop })
			pcall(function() obj[prop] = accent end)
		end

		local parent = cfg.Parent
		if not parent then
			local lp = Players.LocalPlayer
			if lp then parent = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5) end
		end
		if not parent then
			local ok, cg = pcall(function() return game:GetService("CoreGui") end)
			if ok then parent = cg end
		end

		local gui = New("ScreenGui", {
			Name = "CustomUI_" .. tostring(cfg.Title or "Window"),
			ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true, DisplayOrder = 100, Parent = parent,
		})
		Window.Gui = gui

		local defaultSize = cfg.Size or UDim2.fromOffset(640, 470)

		local root = New("Frame", {
			Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = defaultSize, BackgroundTransparency = 1, Visible = cfg.StartHidden ~= true, Parent = gui,
		})

		local function ApplyPlainTextStyle(obj)
			if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
				return
			end
			pcall(function() obj.TextTransparency = 0 end)
			pcall(function() obj.TextStrokeTransparency = 1 end)
			pcall(function()
				if not obj:GetAttribute("__NetspendFontApplied") then
					obj.FontFace = __SegoeUIRegular or Font.fromEnum(Enum.Font.Gotham)
				end
			end)
		end

		local function ApplyPlainTextTree(parent)
			ApplyPlainTextStyle(parent)
			for _, obj in ipairs(parent:GetDescendants()) do
				ApplyPlainTextStyle(obj)
			end
		end

		table.insert(conns, gui.DescendantAdded:Connect(function(obj)
			task.defer(function()
				if obj and obj.Parent then
					ApplyPlainTextStyle(obj)
				end
			end)
		end))

		local main = New("Frame", {
			Name = "Main", Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = root,
		}, { Corner(18) })
		Stroke(main, Theme.Outline, 0.55, 1)

		local TITLE_H = 50
		local titlebar = New("Frame", {
			Name = "Titlebar", Size = UDim2.new(1, 0, 0, TITLE_H),
			BackgroundColor3 = Theme.Titlebar, BackgroundTransparency = 0.02,
			BorderSizePixel = 0, ClipsDescendants = true, Parent = main,
		}, { Corner(16) })

		New("Frame", {
			Name = "TopHighlight", Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -32, 0, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = titlebar,
		})
		New("TextLabel", {
			Name = "Title", BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 0), Size = UDim2.new(0.5, 0, 1, 0),
			Font = Theme.FontBold, Text = tostring(cfg.Title or "Window"),
			TextColor3 = Theme.Text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, Parent = titlebar,
		})

		local fluentProbe = nil
		if Fluent then
			pcall(function()
				fluentProbe = Fluent:CreateWindow({
					Title = "",
					Size = UDim2.fromOffset(1, 1),
					TabWidth = 1,
				})
				if fluentProbe and fluentProbe.Root then
					fluentProbe.Root.Visible = false
				end
			end)
		end

		local function MakeFluentButton(kind, xOffset)
			local button
			if fluentProbe and fluentProbe.TitleBar then
				local sourceButton = kind == "close" and fluentProbe.TitleBar.CloseButton.Frame
					or kind == "minimize" and fluentProbe.TitleBar.MinButton.Frame
					or fluentProbe.TitleBar.MaxButton.Frame
				if sourceButton then
					button = sourceButton:Clone()
				end
			end

			if not button then
				button = New("TextButton", {
					Name = "Fluent_" .. kind,
					BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
				}, { Corner(7) })
			end

			button.Name = "Fluent_" .. kind
			button.AnchorPoint = Vector2.new(1, 0)
			button.Position = UDim2.new(1, xOffset, 0, 4)
			button.Size = UDim2.new(0, 34, 1, -8)
			button.BackgroundTransparency = 1
			button.AutoButtonColor = false
			button.Text = ""
			button.ZIndex = 20
			pcall(function()
				button.Selectable = false
				button.Interactable = true
			end)
			button.Parent = titlebar

			local function setHover(on, pressed)
				if pressed then
					Tween(button, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.96 })
				elseif on then
					Tween(button, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.94 })
				else
					Tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
				end
			end

			Bind(button.MouseEnter, function() setHover(true, false) end)
			Bind(button.MouseLeave, function() setHover(false, false) end)
			Bind(button.InputBegan, function(input)
				if IsPrimaryPointerInput(input) then setHover(true, true) end
			end)
			Bind(button.InputEnded, function(input)
				if IsPrimaryPointerInput(input) then setHover(true, false) end
			end)
			return button
		end

		local btnClose = MakeFluentButton("close", -4)
		local btnFull = MakeFluentButton("maximize", -40)
		local btnMin = MakeFluentButton("minimize", -76)
		if Fluent and fluentProbe then
			pcall(function() Fluent:Destroy() end)
		end

		local SIDE_W = 78
		local sidebar = New("Frame", {
			Name = "Sidebar", Position = UDim2.fromOffset(0, TITLE_H),
			Size = UDim2.new(0, SIDE_W, 1, -TITLE_H),
			BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 0.06,
			BorderSizePixel = 0, ClipsDescendants = true, Parent = main,
		}, { Corner(14) })

		New("UIGradient", {
			Name = "SidebarGradient", Rotation = 0,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 29, 37)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 29)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.10),
				NumberSequenceKeypoint.new(1, 0.28),
			}),
			Parent = sidebar,
		})

		New("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })
		New("UIPadding", { PaddingTop = UDim.new(0, 14), Parent = sidebar })

		local content = New("Frame", {
			Name = "Content", Position = UDim2.fromOffset(SIDE_W, TITLE_H),
			Size = UDim2.new(1, -SIDE_W, 1, -TITLE_H),
			BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
		})

		local tooltip = New("Frame", {
			Name = "Tooltip", Visible = false, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 26), BackgroundColor3 = Color3.fromRGB(53, 61, 73),
			BorderSizePixel = 0, ZIndex = 50, Parent = main,
		}, { Corner(7), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
		local tooltipLabel = New("TextLabel", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 26), Font = Theme.Font, Text = "",
			TextColor3 = Theme.Text, TextSize = 13, ZIndex = 51, Parent = tooltip,
		})
		local function ShowTooltip(text, anchor)
			tooltipLabel.Text = text
			local ap = anchor.AbsolutePosition - main.AbsolutePosition
			tooltip.Position = UDim2.fromOffset(SIDE_W + 6, ap.Y + (anchor.AbsoluteSize.Y - 26) / 2)
			tooltip.BackgroundTransparency = 1; tooltipLabel.TextTransparency = 1; tooltip.Visible = true
			Tween(tooltip, TI_FAST, { BackgroundTransparency = 0 })
			Tween(tooltipLabel, TI_FAST, { TextTransparency = 0 })
		end
		local function HideTooltip() tooltip.Visible = false end

		local notifyHolder = New("Frame", {
			Name = "Notifications", AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(300, 420),
			BackgroundTransparency = 1, ZIndex = 1000, Parent = gui,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Parent = notifyHolder })

		local ClosePopup = function() end
		local maximized = false
		local minimized = false
		local restoreSize = defaultSize
		local restorePos = UDim2.fromScale(0.5, 0.5)

		do
			local dragging = false
			local dragStart, startPos
			local function pointInside(obj, point)
				local p, size = obj.AbsolutePosition, obj.AbsoluteSize
				return point.X >= p.X and point.X <= p.X + size.X and point.Y >= p.Y and point.Y <= p.Y + size.Y
			end

			Bind(titlebar.InputBegan, function(input)
				if maximized then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if pointInside(btnClose, input.Position) or pointInside(btnMin, input.Position) or pointInside(btnFull, input.Position) then return end
					dragging = true; dragStart = input.Position; startPos = root.Position
				end
			end)
			Bind(UserInputService.InputChanged, function(input)
				if not dragging or not dragStart or not startPos then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					local d = input.Position - dragStart
					root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end)
			Bind(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end)
		end

		local function ToggleFullscreen()
			if minimized then return end
			maximized = not maximized
			if maximized then
				restoreSize = root.Size; restorePos = root.Position
				Tween(root, TI_MED, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5) })
			else
				Tween(root, TI_MED, { Size = restoreSize, Position = restorePos })
			end
		end

		local MINI_Y = 10
		local miniPill = New("TextButton", {
			Name = "MinPill", Visible = false,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, MINI_Y),
			Size = UDim2.fromOffset(200, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			ZIndex = 20, Parent = gui,
		})

		local pillBg = New("Frame", {
			Name = "PillBg",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Titlebar,
			BorderSizePixel = 0,
			ZIndex = 20,
			Parent = miniPill,
		}, { Corner(15) })

		local pillSquare = New("Frame", {
			Name = "PillSquare",
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = Theme.Titlebar,
			BorderSizePixel = 0,
			ZIndex = 21,
			Parent = miniPill,
		})

		local miniLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Font = Theme.FontBold,
			Text = "FPS: --  |  Ping: -- ms",
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 22,
			Parent = miniPill,
		})

		local fpsAccum = 0
		local fpsFrames = 0
		local currentFPS = 0
		local currentPing = 0

		local function RefreshPillText()
			miniLabel.Text = string.format("FPS: %d  |  Ping: %d ms", currentFPS, currentPing)
		end

		Bind(RunService.RenderStepped, function(dt)
			fpsAccum += dt
			fpsFrames += 1
			if fpsAccum >= 0.5 then
				currentFPS = math.floor(fpsFrames / fpsAccum + 0.5)
				fpsAccum = 0
				fpsFrames = 0
				pcall(function()
					local stat = Stats.Network.ServerStatsItem["Data Ping"]
					if stat then
						currentPing = math.floor(stat:GetValue() + 0.5)
					end
				end)
				if miniPill.Visible then
					RefreshPillText()
				end
			end
		end)

		local function SetMinimized(on)
			if on == minimized then return end
			minimized = on; ClosePopup(); HideTooltip()
			if on then
				Tween(root, TI_MED, { Size = UDim2.fromOffset(0, 0), Position = UDim2.new(0.5, 0, 0, MINI_Y + 15) })
				task.delay(0.25, function()
					if minimized and not destroyed then
						root.Visible = false
						RefreshPillText()
						miniPill.Visible = true
					end
				end)
			else
				miniPill.Visible = false; root.Visible = true
				Tween(root, TI_MED, { Size = maximized and UDim2.fromScale(1, 1) or restoreSize, Position = maximized and UDim2.fromScale(0.5, 0.5) or restorePos })
			end
		end
		local function ToggleMinimize()
			if not minimized and not maximized then restoreSize = root.Size; restorePos = root.Position end
			SetMinimized(not minimized)
		end
		BindPrimaryClick(miniPill, function() SetMinimized(false) end)

		local closeDialog = nil
		local closeDialogOpen = false
		local function ShowCloseDialog()
			if destroyed or closeDialogOpen then return end
			closeDialogOpen = true

			local overlay = New("TextButton", {
				Name = "CloseConfirmOverlay", Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
				BorderSizePixel = 0, Text = "", AutoButtonColor = false,
				ZIndex = 900, Parent = gui,
			})

			local card = New("Frame", {
				Name = "CloseConfirm", AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 156),
				BackgroundColor3 = Theme.Popup, BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 901, Parent = overlay,
			}, { Corner(12) })

			if not card:FindFirstChildOfClass("UIStroke") then
				Stroke(card, Theme.Outline, 0.35, 1)
			end

			local scale = New("UIScale", { Scale = 0.92, Parent = card })
			local title = New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 18),
				Size = UDim2.new(1, -40, 0, 26), Text = "Close Netspend?",
				TextColor3 = Theme.Text, TextSize = 20, Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 902, Parent = card,
			})
			local message = New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 48),
				Size = UDim2.new(1, -40, 0, 38), Text = "Are you sure you want to close this window?",
				TextColor3 = Theme.SubText, TextSize = 15, Font = Theme.Font,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 902, Parent = card,
			})

			local cancel = New("TextButton", {
				Name = "Cancel", AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -102, 1, -16), Size = UDim2.fromOffset(82, 32),
				BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.05,
				BorderSizePixel = 0, Text = "Cancel", TextColor3 = Theme.Text,
				TextSize = 14, Font = Theme.FontBold, AutoButtonColor = false, ZIndex = 903, Parent = card,
			}, { Corner(8) })
			local confirm = New("TextButton", {
				Name = "Confirm", AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(82, 32),
				BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.02,
				BorderSizePixel = 0, Text = "Close", TextColor3 = Color3.new(1, 1, 1),
				TextSize = 14, Font = Theme.FontBold, AutoButtonColor = false, ZIndex = 903, Parent = card,
			}, { Corner(8) })

			local function buttonAnim(button, base, hover)
				Bind(button.MouseEnter, function() Tween(button, TI_FAST, { BackgroundColor3 = hover }) end)
				Bind(button.MouseLeave, function() Tween(button, TI_FAST, { BackgroundColor3 = base }) end)
				Bind(button.InputBegan, function(input)
					if IsPrimaryPointerInput(input) then
						Tween(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(78, 30) })
					end
				end)
				Bind(button.InputEnded, function(input)
					if IsPrimaryPointerInput(input) then
						Tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(82, 32) })
					end
				end)
			end
			buttonAnim(cancel, Theme.Element, Theme.ElementHover)
			buttonAnim(confirm, Theme.Danger, Color3.fromRGB(239, 111, 98))

			local function closeDialogAnimated()
				if not closeDialogOpen then return end
				closeDialogOpen = false
				Tween(overlay, TI_MED, { BackgroundTransparency = 1 })
				Tween(card, TI_MED, { BackgroundTransparency = 1 })
				Tween(scale, TI_MED, { Scale = 0.92 })
				task.delay(0.18, function() if overlay.Parent then overlay:Destroy() end end)
				closeDialog = nil
			end
			closeDialog = closeDialogAnimated

			BindPrimaryClick(overlay, closeDialogAnimated)
			BindPrimaryClick(cancel, closeDialogAnimated)
			BindPrimaryClick(confirm, function()
				closeDialogAnimated()
				task.delay(0.05, function() if not destroyed then Window:Destroy() end end)
			end)

			Tween(overlay, TI_MED, { BackgroundTransparency = 0.38 })
			Tween(card, TI_MED, { BackgroundTransparency = 0 })
			Tween(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		end

		BindPrimaryClick(btnClose, ShowCloseDialog)
		BindPrimaryClick(btnMin, ToggleMinimize)
		BindPrimaryClick(btnFull, ToggleFullscreen)
		Bind(UserInputService.InputBegan, function(input)
			if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
				if UserInputService:GetFocusedTextBox() then return end
				ToggleMinimize()
			end
		end)

		local popupLayer = New("Frame", { Name = "PopupLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 500, Parent = gui })
		local activePopup = nil
		ClosePopup = function()
			if activePopup then local p = activePopup; activePopup = nil; p.close() end
		end
		Bind(UserInputService.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and activePopup then
				task.defer(function()
					if activePopup and activePopup.shouldClose and activePopup.shouldClose(input.Position) then ClosePopup() end
				end)
			end
		end)

		local activeTab = nil

		local function CreateTab(tabConfig)
			local Tab = {}
			local tabIndex = #tabs + 1

			local tabBtn = New("TextButton", {
				Name = "Tab" .. tabIndex, Size = UDim2.fromOffset(52, 52),
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
				LayoutOrder = tabIndex, Parent = sidebar,
			})

			local pill = New("Frame", {
				Name = "Pill",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(46, 46),
				BackgroundColor3 = Color3.fromRGB(235, 241, 248),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = tabBtn,
			}, { Corner(13) })

			local pillStroke = Stroke(pill, Color3.fromRGB(224, 231, 240), 1, 1)
			local pillScale = New("UIScale", { Name = "GlassScale", Scale = 0.90, Parent = pill })

			local glassGradient = New("UIGradient", {
				Name = "GlassGradient",
				Rotation = 135,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.38, Color3.fromRGB(240, 246, 252)),
					ColorSequenceKeypoint.new(0.72, Color3.fromRGB(206, 216, 229)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0.00, 0.80),
					NumberSequenceKeypoint.new(0.45, 0.90),
					NumberSequenceKeypoint.new(1.00, 0.78),
				}),
				Offset = Vector2.new(-0.15, 0),
				Parent = pill,
			})

			local glassHighlight = New("Frame", {
				Name = "GlassHighlight",
				Position = UDim2.fromScale(-0.15, -0.15),
				Size = UDim2.fromScale(0.72, 1.30),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Rotation = 16,
				ZIndex = 2,
				Parent = pill,
			}, { Corner(20) })

			local highlightGradient = New("UIGradient", {
				Name = "HighlightGradient",
				Rotation = 0,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0.00, 1),
					NumberSequenceKeypoint.new(0.42, 0.98),
					NumberSequenceKeypoint.new(0.50, 0.72),
					NumberSequenceKeypoint.new(0.58, 0.98),
					NumberSequenceKeypoint.new(1.00, 1),
				}),
				Parent = glassHighlight,
			})

			local iconHolder = New("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Image = Icons[tostring(tabConfig.Icon or "")] or Icons.main,
				ImageColor3 = Theme.SubText,
				ImageTransparency = 0.08,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
				Parent = tabBtn,
			})
			New("UIAspectRatioConstraint", { AspectRatio = 1, Parent = iconHolder })
			AttachSquish(tabBtn, iconHolder, conns)
			local iconActiveScale = New("UIScale", { Name = "ActiveScale", Scale = 0.94, Parent = iconHolder })

			local scroll = New("ScrollingFrame", {
				Name = "Tab" .. tabIndex .. "Content", Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Off, CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
				Visible = false, Parent = content,
			})
			local pageScale = New("UIScale", { Name = "PageScale", Scale = 1, Parent = scroll })
			local layout = New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
			New("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), Parent = scroll })
			Bind(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 24)
			end)

			local order = 0
			local function NextOrder() order += 1; return order end

			Tab.Title = tostring(tabConfig.Title or "")
			Tab._active = false
			Tab._transitionToken = 0

			function Tab:_SetActive(on, direction, animate)
				direction = direction or 1
				animate = animate ~= false
				Tab._active = on
				Tab._transitionToken = (Tab._transitionToken or 0) + 1
				local token = Tab._transitionToken

				local enterX = direction >= 0 and 18 or -18
				local ENTER = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

				if on then
					scroll.Visible = true
					if animate then
						scroll.Position = UDim2.new(0, enterX, 0, 0)
						pageScale.Scale = 0.985
						Tween(scroll, ENTER, { Position = UDim2.new(0, 0, 0, 0) })
						Tween(pageScale, ENTER, { Scale = 1 })
					else
						scroll.Position = UDim2.new(0, 0, 0, 0)
						pageScale.Scale = 1
					end

					Tween(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.78,
					})
					Tween(pillScale, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						Scale = 1,
					})
					Tween(pillStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 0.42,
					})
					Tween(iconActiveScale, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						Scale = 1.05,
					})
					Tween(iconHolder, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						ImageTransparency = 0,
					})

					glassGradient.Offset = Vector2.new(-0.12, 0)
					Tween(glassGradient, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Offset = Vector2.new(0.12, 0),
					})
					Tween(glassHighlight, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.fromScale(0.55, -0.15),
						BackgroundTransparency = 0.94,
					})
				else
					scroll.Visible = false
					scroll.Position = UDim2.new(0, 0, 0, 0)
					pageScale.Scale = 1

					Tween(pill, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1,
					})
					Tween(pillScale, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Scale = 0.90,
					})
					Tween(pillStroke, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1,
					})
					Tween(iconActiveScale, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Scale = 0.94,
					})
					Tween(iconHolder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						ImageColor3 = Theme.SubText,
						ImageTransparency = 0.08,
					})
					Tween(glassHighlight, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.fromScale(-0.15, -0.15),
						BackgroundTransparency = 1,
					})
				end
			end

			Bind(tabBtn.MouseEnter, function()
				if not Tab._active then
					Tween(pill, TI_FAST, { BackgroundTransparency = 0.93 })
					Tween(pillScale, TI_FAST, { Scale = 0.96 })
					Tween(pillStroke, TI_FAST, { Transparency = 0.72 })
				end
				ShowTooltip(Tab.Title, tabBtn)
			end)

			Bind(tabBtn.MouseLeave, function()
				if not Tab._active then
					Tween(pill, TI_FAST, { BackgroundTransparency = 1 })
					Tween(pillScale, TI_FAST, { Scale = 0.90 })
					Tween(pillStroke, TI_FAST, { Transparency = 1 })
				end
				HideTooltip()
			end)

			BindPrimaryClick(tabBtn, function()
				PlayUISound(0.98, 0.07)
				Window:SelectTab(tabIndex)
			end)

			function Tab:AddSection(text)
				local h = New("Frame", { Name = "Section", Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = scroll })
				New("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 4), Size = UDim2.new(1, -4, 1, -4),
					Font = Theme.FontBold, Text = string.upper(tostring(text)), TextColor3 = Theme.SubText,
					TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = h,
				})
				return h
			end

			function Tab:AddParagraph(opts)
				local h = New("Frame", {
					Name = "Paragraph", AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Theme.Element, BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = scroll,
				}, {
					Corner(10),
					New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
					New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				Stroke(h, Theme.Outline, 0.45, 1)
				local tl = New("TextLabel", {
					BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					Font = Theme.FontBold, Text = tostring(opts.Title or ""), TextColor3 = Theme.Text,
					TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = h,
				})
				local bl = New("TextLabel", {
					BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					Font = Theme.Font, Text = tostring(opts.Content or ""), TextColor3 = Theme.SubText,
					TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = h,
				})
				local o = {}
				function o:SetTitle(t) tl.Text = t end
				function o:SetContent(t) bl.Text = t end
				return o
			end

			function Tab:AddTextBox(id, opts)
				opts = opts or {}
				local host = New("Frame", {
					Name = "TextBoxHost", Size = UDim2.new(1, 0, 0, (opts.Height or 120) + 44),
					BackgroundColor3 = Theme.Element, BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = scroll,
				}, {
					Corner(12),
					New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
				})
				Stroke(host, Theme.Outline, 0.45, 1)

				New("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
					Font = Theme.FontBold, Text = tostring(opts.Title or ""), TextColor3 = Theme.Text,
					TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = host,
				})

				local box = New("TextBox", {
					Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, opts.Height or 120),
					BackgroundColor3 = Theme.Background2, BorderSizePixel = 0, ClearTextOnFocus = false,
					Font = Theme.Font, Text = tostring(opts.Default or ""), TextColor3 = Theme.Text,
					PlaceholderText = tostring(opts.Placeholder or ""), PlaceholderColor3 = Theme.Muted,
					TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top, MultiLine = true, Parent = host,
				})
				Corner(10).Parent = box
				Stroke(box, Theme.Outline, 0.35, 1)

				local api = { Type = "TextBox" }
				function api:SetValue(value) box.Text = tostring(value or "") end
				function api:GetValue() return box.Text end
				function api:Clear() box.Text = "" end
				box.FocusLost:Connect(function()
					if opts.Callback then task.spawn(function() pcall(opts.Callback, box.Text) end) end
				end)
				if id then elements[id] = api end
				return api
			end

			function Tab:AddButton(opts)
				local variant = tostring(opts.Variant or "default")
				local host, body = MakeSquishHost(scroll, 38)
				host.LayoutOrder = NextOrder()
				local baseColor = Theme.Element
				if variant == "danger" then baseColor = Darken(Theme.Danger, 0.35)
				elseif variant == "accent" then baseColor = accent end
				body.BackgroundColor3 = baseColor

				local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = host })
				local lbl = New("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Theme.FontBold,
					Text = tostring(opts.Title or ""),
					TextColor3 = variant == "danger" and Color3.fromRGB(255, 200, 200) or Theme.Text,
					TextSize = 15, Parent = body,
				})
				if variant == "accent" then TrackAccent(body, "BackgroundColor3") end
				Bind(hit.MouseEnter, function() Tween(body, TI_FAST, { BackgroundColor3 = Lighten(body.BackgroundColor3, 0.06) }) end)
				Bind(hit.MouseLeave, function()
					local t = baseColor
					if variant == "accent" then t = accent end
					Tween(body, TI_FAST, { BackgroundColor3 = t })
				end)
				AttachSquish(hit, body, conns)
				BindPrimaryClick(hit, function()
					PlayUISound(1.0, 0.11)
					if opts.Callback then task.spawn(function() pcall(opts.Callback) end) end
				end)
				local o = {}
				function o:SetTitle(t) lbl.Text = t end
				return o
			end

			local function MakeRow(title, height)
				local host, body = MakeSquishHost(scroll, height or 42)
				host.LayoutOrder = NextOrder()
				New("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.6, 0, 1, 0),
					Font = Theme.Font, Text = title, TextColor3 = Color3.fromRGB(232, 236, 242), TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = body,
				})
				return host, body
			end

			function Tab:AddToggle(id, opts)
				opts = opts or {}

				local state = opts.Default == true
				local UI_FONT = __SegoeUIRegular or Theme.Font

				local MOVE = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				local COLOR = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

				local COL_OFF = Color3.fromRGB(58, 58, 60)
				local COL_ON = Color3.fromRGB(48, 105, 237)
				local KNOB_COLOR = Color3.fromRGB(247, 247, 248)

				local ROW_H = 44
				local TRACK_W = 44
				local TRACK_H = 28
				local KNOB = 24
				local PAD = 2
				local KNOB_OFF = PAD
				local KNOB_ON = TRACK_W - KNOB - PAD

				local host = New("Frame", {
					Name = "ToggleHost",
					Size = UDim2.new(1, 0, 0, ROW_H),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = NextOrder(),
					Parent = scroll,
				})

				local lbl = New("TextLabel", {
					Name = "Label",
					Text = tostring(opts.Title or ""),
					FontFace = UI_FONT,
					TextSize = 15,
					TextColor3 = Color3.fromRGB(235, 235, 240),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -(TRACK_W + 16), 1, 0),
					Parent = host,
				})

				local track = New("Frame", {
					Name = "Track",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Size = UDim2.fromOffset(TRACK_W, TRACK_H),
					BackgroundColor3 = COL_OFF,
					BorderSizePixel = 0,
					Parent = host,
				}, { Corner(TRACK_H / 2) })

				local knob = New("Frame", {
					Name = "Thumb",
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(KNOB, KNOB),
					Position = UDim2.new(0, KNOB_OFF, 0.5, 0),
					BackgroundColor3 = KNOB_COLOR,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = track,
				}, { Corner(KNOB / 2) })

				Stroke(knob, Color3.fromRGB(255, 255, 255), 0.72, 1)

				local btn = New("TextButton", {
					Name = "Hitbox",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 1, 0.5, 0),
					Size = UDim2.fromOffset(TRACK_W + 14, TRACK_H + 14),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Selectable = false,
					ZIndex = 10,
					Parent = host,
				})

				local function setVisual(on, animate)
					local targetX = on and KNOB_ON or KNOB_OFF
					local targetBG = on and COL_ON or COL_OFF

					if animate then
						Tween(knob, MOVE, {
							Position = UDim2.new(0, targetX, 0.5, 0),
						})
						Tween(track, COLOR, { BackgroundColor3 = targetBG })
					else
						knob.Position = UDim2.new(0, targetX, 0.5, 0)
						track.BackgroundColor3 = targetBG
					end

					knob.BackgroundColor3 = KNOB_COLOR
					knob.BackgroundTransparency = 0
				end

				BindPrimaryClick(btn, function()
					state = not state
					PlayUISound(state and 1.03 or 0.99, 0.11)
					setVisual(state, true)
					if opts.Callback then
						task.spawn(function() pcall(opts.Callback, state) end)
					end
				end)

				setVisual(state, false)

				local api = {
					Type = "Toggle",
					Value = state,
				}

				function api:SetValue(v)
					state = v == true
					api.Value = state
					setVisual(state, true)
					if opts.Callback then
						task.spawn(function() pcall(opts.Callback, state) end)
					end
				end

				function api:GetValue()
					return state
				end

				if id then
					elements[id] = api
				end

				return api
			end

			function Tab:AddSlider(id, opts)
				opts = opts or {}
				local minV = tonumber(opts.Min) or 0
				local maxV = tonumber(opts.Max) or 100
				local rounding = tonumber(opts.Rounding) or 0
				if maxV < minV then minV, maxV = maxV, minV end

				local range = maxV - minV
				local value = math.clamp(tonumber(opts.Default) or minV, minV, maxV)

				local host, body = MakeSquishHost(scroll, 58)
				host.LayoutOrder = NextOrder()
				body.BackgroundTransparency = 0.16
				body.ZIndex = 2

				New("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 6),
					Size = UDim2.new(0.64, 0, 0, 20),
					Font = Theme.Font,
					Text = tostring(opts.Title or ""),
					TextColor3 = Color3.fromRGB(238, 241, 246),
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = body,
				})

				local valuePill = New("Frame", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -10, 0, 5),
					Size = UDim2.fromOffset(54, 22),
					BackgroundColor3 = accent:Lerp(Color3.new(0, 0, 0), 0.60),
					BorderSizePixel = 0,
					Parent = body,
				}, { Corner(8) })
				Stroke(valuePill, accent, 0.55, 1)

				local valueLbl = New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Theme.FontBold,
					TextColor3 = Theme.Text,
					TextSize = 13,
					Text = "",
					Parent = valuePill,
				})

				local rail = New("Frame", {
					Name = "Rail",
					Position = UDim2.new(0, 12, 1, -18),
					Size = UDim2.new(1, -24, 0, 8),
					BackgroundColor3 = Color3.fromRGB(47, 55, 68),
					BorderSizePixel = 0,
					ClipsDescendants = false,
					ZIndex = 8,
					Parent = body,
				}, { Corner(4) })
				Stroke(rail, Color3.fromRGB(100, 112, 130), 0.72, 1)

				local function Format(v)
					if rounding <= 0 then
						return tostring(math.floor(v + 0.5))
					end
					return string.format("%." .. rounding .. "f", v)
				end

				local initialAlpha = range > 0 and ((value - minV) / range) or 0

				local fill = New("Frame", {
					Name = "Fill",
					Size = UDim2.fromScale(initialAlpha, 1),
					BackgroundColor3 = accent,
					BorderSizePixel = 0,
					ZIndex = 9,
					Parent = rail,
				}, {
					Corner(4),
					New("UIGradient", {
						Rotation = 0,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Lighten(accent, 0.16)),
							ColorSequenceKeypoint.new(1, accent),
						}),
					}),
				})

				local glow = New("Frame", {
					Name = "Glow",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(initialAlpha, 0, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = accent,
					BackgroundTransparency = 0.86,
					BorderSizePixel = 0,
					ZIndex = 10,
					Parent = rail,
				}, { Corner(8) })

				local handle = New("Frame", {
					Name = "Handle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(initialAlpha, 0, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = Color3.fromRGB(250, 251, 253),
					BorderSizePixel = 0,
					ZIndex = 12,
					Parent = rail,
				}, { Corner(8) })
				Stroke(handle, accent, 0.20, 1)

				local handleScale = New("UIScale", { Scale = 1, Parent = handle })
				local glowScale = New("UIScale", { Scale = 1, Parent = glow })

				local hit = New("TextButton", {
					Name = "SliderHitbox",
					Position = UDim2.new(0, 8, 1, -34),
					Size = UDim2.new(1, -16, 0, 32),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 20,
					Parent = host,
				})

				local function SetVisual(alpha, animate)
					alpha = math.clamp(alpha, 0, 1)
					local pos = UDim2.new(alpha, 0, 0.5, 0)
					if animate then
						Tween(fill, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Size = UDim2.fromScale(alpha, 1)
						})
						Tween(handle, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Position = pos
						})
						Tween(glow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Position = pos
						})
					else
						fill.Size = UDim2.fromScale(alpha, 1)
						handle.Position = pos
						glow.Position = pos
					end
				end

				local function SetFromValue(v, fire, animate)
					local mult = 10 ^ rounding
					v = math.clamp(math.floor(v * mult + 0.5) / mult, minV, maxV)
					local changed = v ~= value
					value = v
					local alpha = range > 0 and ((v - minV) / range) or 0
					SetVisual(alpha, animate == true)
					valueLbl.Text = Format(v)

					if fire and changed and opts.Callback then
						task.spawn(function() pcall(opts.Callback, v) end)
					end
				end

				SetFromValue(value, false, false)

				local dragging = false
				local function UpdateFromX(x)
					local alpha = math.clamp(
						(x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1),
						0, 1
					)
					local raw = range > 0 and (minV + range * alpha) or minV
					SetFromValue(raw, true, true)
				end

				Bind(hit.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						PlayUISound(1.0, 0.10)
						UpdateFromX(input.Position.X)
						Tween(handleScale, TI_SPRING, { Scale = 1.18 })
						Tween(glowScale, TI_SPRING, { Scale = 1.25 })
					end
				end)

				Bind(UserInputService.InputChanged, function(input)
					if dragging and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					) then
						UpdateFromX(input.Position.X)
					end
				end)

				Bind(UserInputService.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						if dragging then
							dragging = false
							Tween(handleScale, TI_SPRING, { Scale = 1 })
							Tween(glowScale, TI_SPRING, { Scale = 1 })
						end
					end
				end)

				local api = { Type = "Slider" }
				function api:SetValue(v) SetFromValue(v, true, true) end
				function api:GetValue() return value end

				table.insert(accentHooks, function()
					if fill.Parent then fill.BackgroundColor3 = accent end
					if glow.Parent then glow.BackgroundColor3 = accent end
					if valuePill.Parent then
						valuePill.BackgroundColor3 = accent:Lerp(Color3.new(0, 0, 0), 0.60)
						local s = valuePill:FindFirstChildOfClass("UIStroke")
						if s then s.Color = accent end
					end
					local hs = handle:FindFirstChildOfClass("UIStroke")
					if hs then hs.Color = accent end
				end)

				if id then elements[id] = api end
				return api
			end

			function Tab:AddKeybind(id, opts)
				local host, body = MakeRow(tostring(opts.Title or ""), 44)
				local key = opts.Default
				local mode = opts.Mode or "Press"
				local listening = false
				local holdState = false
				local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = host })
				local chip = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(72, 26), BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = body,
				}, { Corner(10) })
				local chipLbl = New("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Theme.FontBold,
					Text = key and key.Name or "None", TextColor3 = Theme.Text, TextSize = 14, Parent = chip,
				})
				AttachSquish(hit, chip, conns)
				local function SetKey(k) key = k; chipLbl.Text = k and k.Name or "None" end
				BindPrimaryClick(hit, function()
					if listening then return end
					PlayUISound(1.02, 0.08)
					listening = true; chipLbl.Text = "..."
					Tween(chip, TI_FAST, { BackgroundColor3 = accent })
				end)
				Bind(UserInputService.InputBegan, function(input, gpe)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							if input.KeyCode == Enum.KeyCode.Escape then SetKey(nil) else SetKey(input.KeyCode) end
							Tween(chip, TI_FAST, { BackgroundColor3 = Theme.Off })
						end
						return
					end
					if gpe and not opts.IgnoreGameProcessed then return end
					if key and input.KeyCode == key then
						if mode == "Toggle" then holdState = not holdState
						elseif mode == "Hold" then holdState = true end
						if opts.Callback then task.spawn(function() pcall(opts.Callback, holdState) end) end
					end
				end)
				Bind(UserInputService.InputEnded, function(input)
					if mode == "Hold" and key and input.KeyCode == key then
						holdState = false
						if opts.Callback then task.spawn(function() pcall(opts.Callback, false) end) end
					end
				end)
				local api = { Type = "Keybind" }
				function api:SetValue(k) SetKey(k) end
				function api:GetValue() return key end
				if id then elements[id] = api end
				return api
			end

			function Tab:AddDropdown(id, opts)
				local host, body = MakeRow(tostring(opts.Title or ""), 44)
				local values = opts.Values or {}
				local selected = opts.Default
				local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = host })
				local chip = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(120, 26), BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = body,
				}, { Corner(10) })
				local chipLbl = New("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -28, 1, 0),
					Font = Theme.Font, Text = selected or "-", TextColor3 = Theme.Text, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = chip,
				})
				local arrow = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -13, 0.5, -1),
					Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, Rotation = 45, Parent = chip,
				})
				New("Frame", { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 1.5), BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = arrow })
				New("Frame", { Position = UDim2.fromOffset(3, 0), Size = UDim2.new(0, 1.5, 1, 0), BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = arrow })
				AttachSquish(hit, chip, conns)
				local api = { Type = "Dropdown" }
				local function Select(v, fire)
					selected = v; chipLbl.Text = tostring(v)
					if fire and opts.Callback then task.spawn(function() pcall(opts.Callback, v) end) end
				end
				local function OpenList()
					ClosePopup()
					local itemH = 32
					local listH = math.min(#values * itemH + 8, 180)
					local abs = chip.AbsolutePosition
					local sz = chip.AbsoluteSize
					local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
					local popupW = 180
					local x = math.clamp(abs.X + sz.X - popupW, 8, math.max(8, viewport.X - popupW - 8))
					local y = abs.Y + sz.Y + 6
					if y + listH > viewport.Y - 8 then y = math.max(8, abs.Y - listH - 6) end
					local panel = New("Frame", {
						Position = UDim2.fromOffset(x, y),
						Size = UDim2.fromOffset(popupW, 0), BackgroundColor3 = Theme.Popup,
						BorderSizePixel = 0, ClipsDescendants = true, Active = true, ZIndex = 500, Parent = popupLayer,
					}, { Corner(14) })
					AddShadow(panel, 10, 14).ZIndex = 499
					local sf = New("ScrollingFrame", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
						ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Off, ScrollingEnabled = true, Active = true,
						AutomaticCanvasSize = Enum.AutomaticSize.None, CanvasSize = UDim2.fromOffset(0, #values * (itemH + 2) + 8),
						ZIndex = 501, Parent = panel,
					}, {
						New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
						New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
					})
					local popupConns = {}
					for i, v in ipairs(values) do
						local item = New("TextButton", {
							Size = UDim2.new(1, 0, 0, itemH), BackgroundColor3 = Theme.ElementHover,
							BackgroundTransparency = 1, AutoButtonColor = false, Font = Theme.Font, Active = true, Selectable = true,
							Text = "  " .. tostring(v), TextColor3 = (v == selected) and accent or Theme.Text,
							TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = i, ZIndex = 502, Parent = sf,
						}, { Corner(7) })
						table.insert(popupConns, item.MouseEnter:Connect(function() Tween(item, TI_FAST, { BackgroundTransparency = 0 }) end))
						table.insert(popupConns, item.MouseLeave:Connect(function() Tween(item, TI_FAST, { BackgroundTransparency = 1 }) end))
						local clicked = false
						local function choose()
							if clicked or not item.Parent then return end
							clicked = true
							PlayUISound(1.03, 0.08)
							Select(v, true)
							ClosePopup()
						end
						table.insert(popupConns, item.InputBegan:Connect(function(input)
							if IsPrimaryPointerInput(input) then
								task.defer(choose)
							end
						end))
					end
					Stroke(panel, Theme.Outline, 0.28, 1)
					Tween(panel, TI_MED, { Size = UDim2.fromOffset(popupW, listH) })
					activePopup = {
						close = function()
							for _, c in ipairs(popupConns) do c:Disconnect() end
							Tween(panel, TI_FAST, { Size = UDim2.fromOffset(popupW, 0) })
							task.delay(0.16, function() panel:Destroy() end)
						end,
						shouldClose = function(point)
							local mp = point or UserInputService:GetMouseLocation()
							local function inside(obj)
								local pa, ps = obj.AbsolutePosition, obj.AbsoluteSize
								return mp.X >= pa.X and mp.X <= pa.X + ps.X and mp.Y >= pa.Y and mp.Y <= pa.Y + ps.Y
							end
							return not inside(panel) and not inside(chip)
						end,
					}
				end
				BindPrimaryClick(hit, function()
					PlayUISound(1.0, 0.11)
					OpenList()
				end)
				function api:SetValue(v) Select(v, true) end
				function api:GetValue() return selected end
				function api:SetValues(list)
					values = list
					if selected and not table.find(values, selected) then selected = nil; chipLbl.Text = "-" end
				end
				function api:GetIndex()
					for i, v in ipairs(values) do
						if v == selected then return i end
					end
					return nil
				end
				function api:SetIndex(i)
					local v = values[i]
					if v ~= nil then Select(v, true) end
				end
				if id then elements[id] = api end
				return api
			end

			function Tab:AddColorpicker(id, opts)
				local host, body = MakeRow(tostring(opts.Title or ""), 42)
				local color = opts.Default or Color3.new(1, 1, 1)
				local h, s, v = color:ToHSV()
				local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = host })
				local swatch = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(40, 24), BackgroundColor3 = color, BorderSizePixel = 0, Parent = body,
				}, { Corner(7) })
				AttachSquish(hit, swatch, conns)
				local api = { Type = "Colorpicker" }
				local function Commit(fire)
					color = Color3.fromHSV(h, s, v); swatch.BackgroundColor3 = color
					if fire and opts.Callback then task.spawn(function() pcall(opts.Callback, color) end) end
				end
				local function OpenPicker()
					ClosePopup()
					local abs = swatch.AbsolutePosition
					local W, H = 206, 182
					local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
					local x = math.clamp(abs.X + swatch.AbsoluteSize.X - W, 8, math.max(8, viewport.X - W - 8))
					local y = abs.Y + swatch.AbsoluteSize.Y + 6
					if y + H > viewport.Y - 8 then y = math.max(8, abs.Y - H - 6) end
					local panel = New("Frame", {
						Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(W, H),
						BackgroundColor3 = Theme.Popup, BorderSizePixel = 0, ZIndex = 90, Parent = popupLayer,
					}, { Corner(14) })
					AddShadow(panel, 12, 16).ZIndex = 89
					Stroke(panel, Theme.Outline, 0.28, 1)
					local popupConns = {}
					local sv = New("Frame", {
						Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(W - 20 - 22, H - 20),
						BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ZIndex = 91, Parent = panel,
					}, { Corner(8) })
					New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 92, Parent = sv }, {
						Corner(8),
						New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
					})
					New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 93, Parent = sv }, {
						Corner(8),
						New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
					})
					local svKnob = New("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v),
						Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 95, Parent = sv,
					}, { Corner(6), New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })
					local hueBar = New("Frame", {
						Position = UDim2.new(1, -30, 0, 10), Size = UDim2.fromOffset(20, H - 20),
						BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 91, Parent = panel,
					}, {
						Corner(8),
						New("UIGradient", {
							Rotation = 90,
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
								ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
								ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
								ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
								ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
								ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
								ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
							}),
						}),
					})
					local hueKnob = New("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, h),
						Size = UDim2.new(1, 4, 0, 6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 95, Parent = hueBar,
					}, { Corner(3) })
					local function Refresh()
						sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
						svKnob.Position = UDim2.fromScale(s, 1 - v)
						hueKnob.Position = UDim2.fromScale(0.5, h)
					end
					local draggingSV, draggingH = false, false
					local function UpdSV(pos)
						s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
						v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
						Refresh(); Commit(true)
					end
					local function UpdH(pos)
						h = math.clamp((pos.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 0.999)
						Refresh(); Commit(true)
					end
					table.insert(popupConns, sv.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingSV = true; UpdSV(i.Position) end
					end))
					table.insert(popupConns, hueBar.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingH = true; UpdH(i.Position) end
					end))
					table.insert(popupConns, UserInputService.InputChanged:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
							if draggingSV then UpdSV(i.Position) elseif draggingH then UpdH(i.Position) end
						end
					end))
					table.insert(popupConns, UserInputService.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingSV, draggingH = false, false end
					end))
					panel.BackgroundTransparency = 1
					Tween(panel, TI_FAST, { BackgroundTransparency = 0 })
					activePopup = {
						close = function()
							for _, c in ipairs(popupConns) do c:Disconnect() end
							panel:Destroy()
						end,
						shouldClose = function(point)
							if draggingSV or draggingH then return false end
							local mp = point or UserInputService:GetMouseLocation()
							local function inside(obj)
								local pa, ps = obj.AbsolutePosition, obj.AbsoluteSize
								return mp.X >= pa.X and mp.X <= pa.X + ps.X and mp.Y >= pa.Y and mp.Y <= pa.Y + ps.Y
							end
							return not inside(panel) and not inside(swatch)
						end,
					}
				end
				BindPrimaryClick(hit, function()
					PlayUISound(1.02, 0.08)
					OpenPicker()
				end)
				function api:SetValue(c) h, s, v = c:ToHSV(); Commit(true) end
				function api:GetValue() return color end
				if id then elements[id] = api end
				return api
			end

			return Tab
		end

		ApplyPlainTextTree(root)

		function Window:AddTab(tabConfig)
			local tab = CreateTab(tabConfig or {})
			table.insert(tabs, tab)
			if #tabs == 1 then Window:SelectTab(1) end
			return tab
		end
		function Window:SelectTab(index)
			local tab = tabs[index]
			if not tab then return end
			ClosePopup()

			local previous = activeTab
			if previous == tab then
				tab:_SetActive(true, 1, false)
				return
			end

			local previousIndex = nil
			if previous then
				for i, candidate in ipairs(tabs) do
					if candidate == previous then
						previousIndex = i
						break
					end
				end
			end

			local direction = (previousIndex and index < previousIndex) and -1 or 1

			if previous then
				previous:_SetActive(false, direction, false)
			end

			activeTab = tab
			tab:_SetActive(true, direction, true)
		end
		function Window:SetAccent(color)
			accent = color
			for _, e in ipairs(accentObjects) do if e.obj and e.obj.Parent then Tween(e.obj, TI_MED, { [e.prop] = color }) end end
			for _, h in ipairs(accentHooks) do pcall(h) end
		end
		function Window:SetUISounds(enabled)
			UI_SOUNDS_ENABLED = true
		end
		function Window:PlayUISound(pitch, volume)
			PlayUISound(pitch, volume)
		end
		function Window:GetElement(id) return elements[id] end
		function Window:Notify(opts)
			opts = opts or {}
			PlayUISound(opts.SoundPitch or 1.01, opts.SoundVolume or 0.08)
			local duration = opts.Duration or 3
			local card = New("Frame", {
				Size = UDim2.fromOffset(280, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Popup, BorderSizePixel = 0,
				BackgroundTransparency = 1, ZIndex = 1001, Parent = notifyHolder,
			}, {
				Corner(14),
				New("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
				New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
			})
			Stroke(card, Theme.Outline, 0.28, 1)
			local t = New("TextLabel", {
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
				Font = Theme.FontBold, Text = tostring(opts.Title or ""), TextColor3 = Theme.Text,
				TextSize = 15, TextTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 1002, Parent = card,
			})
			local c = New("TextLabel", {
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
				Font = Theme.Font, Text = tostring(opts.Content or ""), TextColor3 = Theme.SubText,
				TextSize = 14, TextTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = 1002, Parent = card,
			})
			Tween(card, TI_MED, { BackgroundTransparency = 0 })
			Tween(t, TI_MED, { TextTransparency = 0 })
			Tween(c, TI_MED, { TextTransparency = 0 })
			task.delay(duration, function()
				if destroyed or not card.Parent then return end
				Tween(t, TI_MED, { TextTransparency = 1 })
				Tween(c, TI_MED, { TextTransparency = 1 })
				Tween(card, TI_MED, { BackgroundTransparency = 1 })
				task.delay(0.26, function() if card.Parent then card:Destroy() end end)
			end)
		end
		function Window:SetVisible(on)
			if destroyed then return end
			root.Visible = on == true
			if not root.Visible then
				ClosePopup()
				HideTooltip()
			end
		end
		function Window:Destroy()
			if destroyed then return end
			destroyed = true
			ClosePopup()
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
			table.clear(conns); table.clear(tabs); table.clear(elements); table.clear(accentObjects); table.clear(accentHooks)
			if gui then gui:Destroy() end
		end
		return Window
	end
	return UI
end)()

local CurrentLanguage = "en"

local function CleanEntryText(root)
    if not root then return end
    local function clean(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            return
        end
        pcall(function() obj.TextTransparency = 0 end)
        pcall(function() obj.TextStrokeTransparency = 1 end)
        pcall(function() obj.TextStrokeColor3 = Color3.fromRGB(255, 255, 255) end)
        pcall(function() if __SegoeUIBold then obj.FontFace = __SegoeUIBold else obj.Font = Enum.Font.GothamBold end end)
    end
    clean(root)
    for _, obj in ipairs(root:GetDescendants()) do
        clean(obj)
    end
end

local I18N = {
    en = {
        languageTitle = "Select language",
        languageHint = "Choose your language",
        english = "English",
        russian = "Russian",
        loaderPreparing = "Preparing the best experience",
        loaderSetup = "Setting things up",
        loaderAlmost = "Almost ready",
        loaderDone = "Done",
        ready = "Ready",
        tabMain = "Main",
        tabCombat = "Combat",
        tabMisc = "Misc",
        tabConfigs = "Configs",
        sectionESP = "ESP",
        playerESP = "Player ESP",
        customColor = "Custom color",
        sectionGuns = "Guns",
        autoGrabGun = "Auto Grab Gun",
        sectionNotifications = "Notifications",
        notifyGunDrop = "Notify: Gun Dropped",
        notifySheriffDeath = "Notify: Sheriff Death",
        sectionVisuals = "Visuals",
        lightningVisuals = "Death Lightning",
        stormDarkness = "Storm Darkness",
        sectionCustomization = "Customization",
        uiSounds = "UI Sounds",
        accentColor = "Accent Color",
        gunDroppedTitle = "Gun Dropped",
        gunDroppedContent = "The Sheriff's pistol is on the ground.",
        sheriffDownTitle = "Sheriff Down",
        sheriffDownContent = "Sheriff died.",
        sectionSafePlatform = "Safe Platform",
        sectionInvisibility = "Invisibility",
        invisibility = "Invisibility",
        tpSafe = "TP to Safe",
        tpMap = "TP to Map",
        tpSafeMap = "TP Safe / Map",
        sectionSilentAim = "Silent Aim",
        silentAim = "Silent Aim",
        silentFire = "Fire (Silent)",
        sectionAimbot = "Aimbot",
        aimbot = "Aimbot",
        aimbotPart = "Target Part",
        aimbotHead = "Head",
        aimbotTorso = "Torso",
        sectionKillAll = "Kill All",
        killAll = "Kill All",
        autoKillAll = "Auto Kill All",
        sectionRush = "Rush",
        behindMurderer = "Behind Murderer",
        sectionDefense = "Defense",
        antiFling = "Anti-Fling",
        sectionFling = "Fling",
        autoFlingMurderer = "Auto Fling Murderer",
        autoFlingSheriff = "Auto Fling Sheriff",
        flingMurderer = "Fling Murderer",
        flingSheriff = "Fling Sheriff",
        sectionMovement = "Movement",
        walkSpeed = "WalkSpeed",
        jumpPower = "JumpPower",
        noclip = "Noclip",
        sectionSpin = "Spin",
        spin = "Spin",
        spinSpeed = "Spin Speed (deg/s)",
        sectionAnimations = "Character Animations",
        animationPack = "Animation pack",
        resetOriginal = "Reset to Original",
        killAllTitle = "Kill All",
        notMurderer = "You are not the Murderer",
        knifeNotFound = "Knife not found",
        knifeEquipFailed = "Could not equip the knife",

        forceShoot = "Force Shoot",
        forceShootNoGun = "No gun equipped",
        forceShootNoTarget = "No murderer target",
        forceShootNoHook = "Hook unavailable",

        sectionConfigs = "Configurations",
        sectionSaved = "Saved configs",
        configName = "Config name",
        configNamePlaceholder = "e.g. main",
        saveConfig = "Save config",
        selectConfig = "Select config",
        loadConfig = "Load config",
        deleteConfig = "Delete config",
        refreshConfigs = "Refresh list",
        configSaved = "Config saved",
        configLoaded = "Config loaded",
        configDeleted = "Config deleted",
        configRefreshed = "List refreshed",
        configSelectFirst = "Select a config first",
        configNoAccess = "File access unavailable",
        configInvalidName = "Invalid name",
    },
    ru = {
        languageTitle = "Выберите язык",
        languageHint = "Выберите язык интерфейса",
        english = "Английский",
        russian = "Русский",
        loaderPreparing = "Подготавливаем интерфейс",
        loaderSetup = "Настраиваем всё",
        loaderAlmost = "Почти готово",
        loaderDone = "Готово",
        ready = "Готово",
        tabMain = "Главная",
        tabCombat = "Бой",
        tabMisc = "Разное",
        tabConfigs = "Конфиги",
        sectionESP = "ESP",
        playerESP = "ESP игроков",
        customColor = "Свой цвет",
        sectionGuns = "Оружие",
        autoGrabGun = "Автоподбор оружия",
        sectionNotifications = "Уведомления",
        notifyGunDrop = "Уведомлять: выпал пистолет",
        notifySheriffDeath = "Уведомлять: умер шериф",
        sectionVisuals = "Визуал",
        lightningVisuals = "Молния при смерти",
        stormDarkness = "Затемнение грозы",
        sectionCustomization = "Кастомизация",
        uiSounds = "Звуки интерфейса",
        accentColor = "Цвет акцента",
        gunDroppedTitle = "Пистолет выпал",
        gunDroppedContent = "Пистолет шерифа лежит на земле.",
        sheriffDownTitle = "Шериф погиб",
        sheriffDownContent = "Шериф погиб.",
        sectionSafePlatform = "Безопасная платформа",
        sectionInvisibility = "Невидимость",
        invisibility = "Невидимость",
        tpSafe = "Телепорт к платформе",
        tpMap = "Телепорт на карту",
        tpSafeMap = "Платформа / Карта",
        sectionSilentAim = "Бесшумное прицеливание",
        silentAim = "Бесшумное прицеливание",
        silentFire = "Выстрел",
        sectionAimbot = "Аимбот",
        aimbot = "Аимбот",
        aimbotPart = "Часть цели",
        aimbotHead = "Голова",
        aimbotTorso = "Торс",
        sectionKillAll = "Устранение всех",
        killAll = "Устранить всех",
        autoKillAll = "Авто-устранение всех",
        sectionRush = "Рывок",
        behindMurderer = "За спину убийце",
        sectionDefense = "Защита",
        antiFling = "Анти-флинг",
        sectionFling = "Флинг",
        autoFlingMurderer = "Авто-флинг убийцы",
        autoFlingSheriff = "Авто-флинг шерифа",
        flingMurderer = "Флинг убийцы",
        flingSheriff = "Флинг шерифа",
        sectionMovement = "Движение",
        walkSpeed = "Скорость ходьбы",
        jumpPower = "Сила прыжка",
        noclip = "Ноклип",
        sectionSpin = "Вращение",
        spin = "Вращение",
        spinSpeed = "Скорость вращения (град/с)",
        sectionAnimations = "Анимации персонажа",
        animationPack = "Пак анимаций",
        resetOriginal = "Вернуть оригинальные",
        killAllTitle = "Устранение всех",
        notMurderer = "Вы не убийца",
        knifeNotFound = "Нож не найден",
        knifeEquipFailed = "Не удалось экипировать нож",

        forceShoot = "Форс-выстрел",
        forceShootNoGun = "Оружие не экипировано",
        forceShootNoTarget = "Цель не найдена",
        forceShootNoHook = "Хук недоступен",

        sectionConfigs = "Конфигурации",
        sectionSaved = "Сохранённые конфиги",
        configName = "Имя конфига",
        configNamePlaceholder = "Например: main",
        saveConfig = "Сохранить конфиг",
        selectConfig = "Выбрать конфиг",
        loadConfig = "Загрузить",
        deleteConfig = "Удалить",
        refreshConfigs = "Обновить список",
        configSaved = "Конфиг сохранён",
        configLoaded = "Конфиг загружен",
        configDeleted = "Конфиг удалён",
        configRefreshed = "Список обновлён",
        configSelectFirst = "Сначала выберите конфиг",
        configNoAccess = "Нет доступа к файлам",
        configInvalidName = "Некорректное имя",
    },
}

local function T(key)
    local lang = I18N[CurrentLanguage] or I18N.en
    return lang[key] or I18N.en[key] or tostring(key)
end

function UI:CreateLoader(config)
	config = config or {}
	local players = game:GetService("Players")
	local tween = game:GetService("TweenService")
	local parent = config.Parent
	if not parent then
		local lp = players.LocalPlayer
		if lp then parent = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5) end
	end
	if not parent then return { Finish = function() end } end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NetspendLoader"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
	pcall(function() gui.ClipToDeviceSafeArea = false end)
	gui.Parent = parent

	local backdrop = Instance.new("Frame")
	backdrop.AnchorPoint = Vector2.zero
	backdrop.Position = UDim2.fromScale(0, 0)
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 100000
	backdrop.Parent = gui

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(420, 92)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 100001
	holder.Parent = backdrop

	local barBack = Instance.new("Frame")
	barBack.AnchorPoint = Vector2.new(0.5, 0)
	barBack.Position = UDim2.new(0.5, 0, 0, 10)
	barBack.Size = UDim2.fromOffset(320, 3)
	barBack.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
	barBack.BorderSizePixel = 0
	barBack.ZIndex = 100002
	barBack.Parent = holder
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 2)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0.08, 1)
	bar.BackgroundColor3 = config.Accent or Color3.fromRGB(232, 232, 236)
	bar.BorderSizePixel = 0
	bar.ZIndex = 100003
	bar.Parent = barBack
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

	local function LT(key)
		local lang = I18N[CurrentLanguage] or I18N.en
		return lang[key] or I18N.en[key] or tostring(key)
	end

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 41)
	label.Size = UDim2.fromOffset(420, 30)
	label.BackgroundTransparency = 1
	label.FontFace = __SegoeUIBold
	label.TextSize = 15
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 1
	label.TextTransparency = 0
	label.Text = LT("loaderPreparing")
	label.ZIndex = 100003
	label.Parent = holder

	local destroyed = false
	local function setStage(text, progress)
		if destroyed then return end
		local oldText = label.Text
		if oldText == text then
			tween:Create(bar, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(progress, 1) }):Play()
			return
		end
		tween:Create(label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
		task.wait(0.12)
		if destroyed then return end
		label.Text = text
		tween:Create(label, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
		tween:Create(bar, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(progress, 1) }):Play()
	end

	local api = {}
	function api:SetStage(text, progress)
		setStage(tostring(text or ""), math.clamp(tonumber(progress) or 0, 0, 1))
	end

	function api:Finish(callback)
		if destroyed then return end
		task.spawn(function()
			setStage(LT("loaderPreparing"), 0.12)
			task.wait(0.58)
			setStage(LT("loaderSetup"), 0.39)
			task.wait(0.62)
			setStage(LT("loaderAlmost"), 0.73)
			task.wait(0.62)
			setStage(LT("loaderDone"), 1)
			task.wait(0.52)
			if type(callback) == "function" then pcall(callback) end
			tween:Create(label, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			tween:Create(holder, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0.5, -5) }):Play()
			task.wait(0.08)
			tween:Create(backdrop, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			task.wait(0.34)
			if not destroyed then
				destroyed = true
				gui:Destroy()
			end
		end)
	end

	return api
end
function UI:ChooseLanguage(config)
    config = config or {}
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer
    local parent = config.Parent or (player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)))
    if not parent then
        CurrentLanguage = "en"
        return CurrentLanguage
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LanguageSelector"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10001
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
    pcall(function() gui.ClipToDeviceSafeArea = false end)
    gui.Parent = parent

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
    backdrop.BackgroundTransparency = 0.16
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(420, 238)
    card.BackgroundColor3 = Color3.fromRGB(34, 40, 51)
    card.BackgroundTransparency = 0.14
    card.BorderSizePixel = 0
    card.Parent = backdrop
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(82, 93, 109)
    stroke.Transparency = 0.2
    stroke.Parent = card

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0, 30)
    title.Size = UDim2.new(1, -40, 0, 28)
    title.FontFace = __SegoeUIBold
    title.TextSize = 21
    title.TextColor3 = Color3.fromRGB(240, 242, 247)
    title.Text = "Select language / Выберите язык"
    title.Parent = card

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.AnchorPoint = Vector2.new(0.5, 0)
    hint.Position = UDim2.new(0.5, 0, 0, 64)
    hint.Size = UDim2.new(1, -40, 0, 20)
    hint.FontFace = __SegoeUIBold
    hint.TextSize = 13
    hint.TextColor3 = Color3.fromRGB(255, 255, 255)
    hint.Text = "English or Russian / Английский или русский"
    hint.Parent = card

    local selected
    local function makeButton(text, lang, x)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0.5, 0)
        b.Position = UDim2.new(x, 0, 0, 116)
        b.Size = UDim2.fromOffset(148, 56)
        b.BackgroundTransparency = 1
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.FontFace = __SegoeUIBold
        b.TextSize = 15
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextTransparency = 0
        b.TextStrokeTransparency = 1
        b.Text = text
        b.ZIndex = 20
        b.Active = true
        b.Selectable = false
        pcall(function()
            b.AutoButtonColor = false
            b.Interactable = true
        end)
        b.Parent = card

        local bg = Instance.new("Frame")
        bg.Name = "LanguageGlass"
        bg.Position = b.Position
        bg.AnchorPoint = b.AnchorPoint
        bg.Size = b.Size
        bg.BackgroundColor3 = Color3.fromRGB(62, 72, 88)
        bg.BackgroundTransparency = 0.20
        bg.BorderSizePixel = 0
        bg.Active = false
        bg.ZIndex = 5
        bg.Parent = card
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 14)

        local bs = Instance.new("UIStroke")
        bs.Color = Color3.fromRGB(166, 178, 196)
        bs.Transparency = 0.52
        bs.Thickness = 1
        bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        bs.Parent = bg

        local fill = Instance.new("UIGradient")
        fill.Rotation = -12
        fill.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 122, 255)),
            ColorSequenceKeypoint.new(0.38, Color3.fromRGB(64, 156, 255)),
            ColorSequenceKeypoint.new(0.68, Color3.fromRGB(255, 196, 126)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 102, 230)),
        })
        fill.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1),
            NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1),
        })
        fill.Parent = bg

        local bsScale = Instance.new("UIScale")
        bsScale.Parent = b
        local hovering, pressed = false, false

        local function idleLanguage()
            TweenService:Create(bg, TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(62, 72, 88), BackgroundTransparency = 0.20,
            }):Play()
            TweenService:Create(bs, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(166, 178, 196), Transparency = 0.52, Thickness = 1,
            }):Play()
            fill.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1),
                NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1),
            })
        end
        b.MouseEnter:Connect(function()
            hovering = true
            TweenService:Create(bs, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(0, 122, 255), Transparency = 0.02, Thickness = 1.6,
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            hovering = false
            if not pressed then idleLanguage() end
        end)
        b.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            pressed = true
            TweenService:Create(bsScale, TweenInfo.new(0.08, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 0.975 }):Play()
            TweenService:Create(bg, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(94, 66, 46), BackgroundTransparency = 0.08,
            }):Play()
            TweenService:Create(bs, TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(255, 174, 107), Transparency = 0.01, Thickness = 1.7,
            }):Play()
            TweenService:Create(fill, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Offset = Vector2.new(0.48, 0), Rotation = 10,
            }):Play()
            fill.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.42, 0.70),
                NumberSequenceKeypoint.new(0.58, 0.72), NumberSequenceKeypoint.new(1, 0.86),
            })
        end)
        b.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            pressed = false
            TweenService:Create(bsScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            if hovering then
                TweenService:Create(bs, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Color = Color3.fromRGB(0, 122, 255), Transparency = 0.02, Thickness = 1.6,
                }):Play()
            else
                idleLanguage()
            end
            task.delay(0.16, function()
                if b.Parent and not pressed then idleLanguage() end
            end)
        end)
        b.Activated:Connect(function()
            selected = lang
            TweenService:Create(bsScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.02 }):Play()
            task.delay(0.08, function()
                if b.Parent then
                    TweenService:Create(bsScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
                end
            end)
        end)
    end

    makeButton(I18N.en.english, "en", 0.30)
    makeButton(I18N.ru.russian, "ru", 0.70)

    CleanEntryText(card)

    title.Text = "Select language / Выберите язык"
    hint.Text = "English or Russian / Английский или русский"

    while not selected and gui.Parent do
        RunService.RenderStepped:Wait()
    end

    CurrentLanguage = selected or "en"
    if gui.Parent then
        TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 0.54) }):Play()
        TweenService:Create(backdrop, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        task.wait(0.22)
        gui:Destroy()
    end
    return CurrentLanguage
end

UI:ChooseLanguage()

local Loader = UI:CreateLoader({
    Accent = Color3.fromRGB(0, 122, 255),
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local WeaponService = nil
do
    local ok, service = pcall(function()
        return require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService"))
    end)
    if ok then
        WeaponService = service
    end
end

local LP = Players.LocalPlayer

local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function alive(plr)
    if not plr or plr == LP then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function hasGunWord(name)
    local n = tostring(name):lower()
    return n:find("gun", 1, true) ~= nil
        or n:find("revolver", 1, true) ~= nil
        or n:find("pistol", 1, true) ~= nil
        or n:find("handgun", 1, true) ~= nil
end

local function showMessage(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title or "Netspend"),
            Text = tostring(text or ""),
            Duration = duration or 3,
        })
    end)
end

local function getFTI()
    if type(firetouchinterest) == "function" then return firetouchinterest end
    local env = type(getgenv) == "function" and getgenv() or nil
    return env and type(env.firetouchinterest) == "function" and env.firetouchinterest or nil
end

local function getFClick()
    if type(fireclickdetector) == "function" then return fireclickdetector end
    local env = type(getgenv) == "function" and getgenv() or nil
    return env and type(env.fireclickdetector) == "function" and env.fireclickdetector or nil
end

local function getFPrompt()
    if type(fireproximityprompt) == "function" then return fireproximityprompt end
    local env = type(getgenv) == "function" and getgenv() or nil
    return env and type(env.fireproximityprompt) == "function" and env.fireproximityprompt or nil
end

local roleCache = {}
local ROLE_ALIASES = {
    Murderer="Murderer", Mur="Murderer", Assassin="Murderer",
    Sheriff="Sheriff", Hero="Sheriff", Innocent="Innocent",
    Survivor="Survivor", Zombie="Zombie", Freezer="Freezer",
    Runner="Runner", Juggernaut="Juggernaut", Gladiator="Gladiator",
}

local function normalizeRoleString(value)
    if value == nil then return nil end
    local s = tostring(value):lower()
    for key, canonical in pairs(ROLE_ALIASES) do
        if s == tostring(key):lower() then return canonical end
    end
    if s:find("murder", 1, true) or s == "assassin" then return "Murderer" end
    if s:find("sheriff", 1, true) or s == "hero" then return "Sheriff" end
    if s:find("innocent", 1, true) then return "Innocent" end
    if s:find("surviv", 1, true) then return "Survivor" end
    if s:find("zombie", 1, true) then return "Zombie" end
    if s:find("freezer", 1, true) then return "Freezer" end
    if s:find("runner", 1, true) then return "Runner" end
    if s:find("jugger", 1, true) then return "Juggernaut" end
    if s:find("gladiator", 1, true) then return "Gladiator" end
    return nil
end

local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(235, 70, 70) end
    if role == "Sheriff" then return Color3.fromRGB(75, 155, 255) end
    if role == "Innocent" then return Color3.fromRGB(80, 220, 115) end
    if role == "Survivor" then return Color3.fromRGB(55, 175, 245) end
    if role == "Zombie" then return Color3.fromRGB(90, 210, 80) end
    if role == "Freezer" then return Color3.fromRGB(155, 220, 255) end
    if role == "Runner" then return Color3.fromRGB(65, 215, 140) end
    if role == "Juggernaut" then return Color3.fromRGB(205, 90, 255) end
    if role == "Gladiator" then return Color3.fromRGB(255, 170, 65) end
    return nil
end

local function setRole(plr, role, source)
    if not plr or not role then return end
    local canonical = normalizeRoleString(role)
    if not canonical then return end
    roleCache[plr] = {
        role = canonical,
        time = os.clock(),
        confirmed = true,
        source = source or "unknown",
        character = plr.Character,
    }
end

local function clearRole(plr)
    if plr then roleCache[plr] = nil end
end

local function clearAllRoles()
    for plr in pairs(roleCache) do
        roleCache[plr] = nil
    end
end

local function scanInventory(plr)
    if not plr then return nil end
    local containers = { plr.Character, plr:FindFirstChildOfClass("Backpack") }
    local hasGun = false
    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    local n = tostring(obj.Name):lower()
                    if n:find("knife",1,true) or n:find("blade",1,true) or n:find("sword",1,true) then
                        return "Murderer"
                    end
                    if n:find("gun",1,true) or n:find("revolver",1,true)
                        or n:find("pistol",1,true) or n:find("handgun",1,true) then
                        hasGun = true
                    end
                end
            end
        end
    end
    return hasGun and "Sheriff" or nil
end

local function scanAttributes(plr)
    if not plr then return nil end
    local attributes = {"Role","role","RoleName","roleName","IsMurderer","isMurderer","Murderer","IsSheriff","isSheriff","Sheriff","TeamRole"}
    for _, attrName in ipairs(attributes) do
        local ok, value = pcall(function() return plr:GetAttribute(attrName) end)
        if ok and value ~= nil then
            if type(value) == "boolean" then
                if value and attrName:lower():find("murder",1,true) then return "Murderer" end
                if value and attrName:lower():find("sheriff",1,true) then return "Sheriff" end
            else
                local role = normalizeRoleString(value)
                if role then return role end
            end
        end
    end
    local ok, attrs = pcall(function() return plr:GetAttributes() end)
    if ok and attrs then
        for name, value in pairs(attrs) do
            local role = normalizeRoleString(value)
            if role then return role end
            if type(value) == "boolean" and value then
                local n = tostring(name):lower()
                if n:find("murder",1,true) then return "Murderer" end
                if n:find("sheriff",1,true) or n:find("hero",1,true) then return "Sheriff" end
            end
        end
    end
    return nil
end

local function scanReplicatedRoleMarkers(plr)
    if not plr then return nil end
    local containers = {plr, plr.Character, plr:FindFirstChildOfClass("Backpack"), plr:FindFirstChildOfClass("PlayerGui")}
    for _, root in ipairs(containers) do
        if root then
            local objects = {root}
            pcall(function()
                for _, obj in ipairs(root:GetDescendants()) do objects[#objects + 1] = obj end
            end)
            for _, obj in ipairs(objects) do
                if obj:IsA("StringValue") then
                    local n = obj.Name:lower()
                    if n == "role" or n == "rolename" or n == "teamrole" or n:find("role",1,true) then
                        local role = normalizeRoleString(obj.Value)
                        if role then return role end
                    end
                elseif obj:IsA("BoolValue") and obj.Value then
                    local n = obj.Name:lower()
                    if n:find("murder",1,true) then return "Murderer" end
                    if n:find("sheriff",1,true) or n:find("hero",1,true) then return "Sheriff" end
                end
            end
        end
    end
    return nil
end

local function scanCharacterRoleValues(plr)
    local char = plr and plr.Character
    if not char then return nil end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("StringValue") and (obj.Name:lower()=="role" or obj.Name:lower()=="rolename") then
            local role = normalizeRoleString(obj.Value)
            if role then return role end
        elseif obj:IsA("BoolValue") and obj.Value then
            local n=obj.Name:lower()
            if n:find("murder",1,true) then return "Murderer" end
            if n:find("sheriff",1,true) or n:find("hero",1,true) then return "Sheriff" end
        end
    end
    return nil
end

local function scanTeam(plr)
    local ok, team = pcall(function() return plr.Team end)
    if ok and team then return normalizeRoleString(team.Name) end
    return nil
end

local function getRole(plr)
    if not plr then return "Unknown" end
    local cached = roleCache[plr]
    if cached and cached.confirmed then
        local currentChar = plr.Character
        if cached.character ~= nil and cached.character ~= currentChar then
            roleCache[plr] = nil
        else
            return cached.role
        end
    end
    local role = scanReplicatedRoleMarkers(plr)
        or scanCharacterRoleValues(plr)
        or scanAttributes(plr)
        or scanTeam(plr)
        or scanInventory(plr)
    if role then setRole(plr, role, "fallback"); return role end
    return "Unknown"
end

Players.PlayerRemoving:Connect(function(plr)
    clearRole(plr)
end)


local State = {
    PlayerESP = false,
    AutoGun = false,
    KillAll = false,
    FlingM = false,
    FlingS = false,
    SilentAim = false,
    Aimbot = false,
    AimbotPart = "Head",
    Invisibility = false,
    AntiFling = false,
    Noclip = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Spin = false,
    SpinSpeed = 500,

    NotifyGunDrop = false,
    NotifySheriffDeath = false,
    LightningVisuals = false,
    StormDarkness = 72,
    UISounds = true,
}


local Ghost = {
    Active = false,
    active = false,

    Platform = nil,
    Proxy = nil,
    ProxyHRP = nil,
    ProxyAnimator = nil,
    OriginalCF = nil,

    RenderConn = nil,
    CharConn = nil,
    InputConn = nil,

    LastPos = nil,
    TargetPos = nil,
    LastLook = nil,
    JumpVel = 0,
    JumpOff = 0,
    Grounded = true,
    WasJumping = false,

    LocalTransCache = {},
    NetworkTransCache = {},
    transparency = {},
    mapCFrame = nil,
    safeCFrame = nil,
    camera = nil,
}

local function setInvisibilityState(value)
    value = value == true
    Ghost.Active = value
    Ghost.active = value
    State.Invisibility = value
end

local EXACT_GUN = {
    ["gun"] = true, ["revolver"] = true, ["pistol"] = true,
    ["handgun"] = true, ["gundrop"] = true, ["droppedgun"] = true,
    ["dropped_revolver"] = true,
}

local function normalizeName(name) return tostring(name):lower():gsub("[%s_%-]", "") end

local function isGunName(name)
    local raw = tostring(name):lower()
    local normalized = normalizeName(name)
    if EXACT_GUN[raw] or EXACT_GUN[normalized] then return true end
    if raw:find("gundrop", 1, true) then return true end
    if raw:find("droppedgun", 1, true) then return true end
    if raw:find("gun", 1, true) then return true end
    if raw:find("revolver", 1, true) then return true end
    if raw:find("pistol", 1, true) then return true end
    if raw:find("handgun", 1, true) then return true end
    return false
end

local noclipConn = nil
local noclipOriginal = setmetatable({}, { __mode = "k" })

local function applyNoclip(character)
    if not character then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            if noclipOriginal[obj] == nil then noclipOriginal[obj] = obj.CanCollide end
            obj.CanCollide = false
        end
    end
end

local function restoreNoclip(character)
    if not character then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            local old = noclipOriginal[obj]
            if old ~= nil then obj.CanCollide = old; noclipOriginal[obj] = nil end
        end
    end
end

local function setNoclip(enabled)
    if enabled then
        if noclipConn then return end
        noclipOriginal = setmetatable({}, { __mode = "k" })
        applyNoclip(LP.Character)
        noclipConn = RunService.Stepped:Connect(function() applyNoclip(LP.Character) end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        restoreNoclip(LP.Character)
        local hum = getHum()
        if hum then hum.PlatformStand = false; hum.AutoRotate = true; hum.Sit = false end
    end
end
local antiFling = {
    connection = nil, charConnection = nil, lastSafeCFrame = nil,
    originalCollide = setmetatable({}, { __mode = "k" }),
}

local function applyAntiFlingCollision(character)
    if not character then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            if antiFling.originalCollide[obj] == nil then antiFling.originalCollide[obj] = obj.CanCollide end
            obj.CanCollide = false
        end
    end
end

local function restoreAntiFlingCollision(character)
    if character then
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                local old = antiFling.originalCollide[obj]
                if old ~= nil then obj.CanCollide = old end
            end
        end
    end
    antiFling.originalCollide = setmetatable({}, { __mode = "k" })
end

local function resetCharacterPhysics()
    local hum = getHum()
    local root = getRoot()
    if hum then
        hum.PlatformStand = false; hum.Sit = false; hum.AutoRotate = true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local function antiFlingTick()
    if not State.AntiFling then return end
    local char = LP.Character
    local root = getRoot()
    local hum = getHum()
    if not root or not hum or hum.Health <= 0 then antiFling.lastSafeCFrame = nil; return end
    applyAntiFlingCollision(char)
    local linear = root.AssemblyLinearVelocity.Magnitude
    local angular = root.AssemblyAngularVelocity.Magnitude
    if linear ~= linear or angular ~= angular or linear > 60 or angular > 60 then
        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity")
                or obj:IsA("BodyForce") or obj:IsA("BodyThrust")
                or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") then
                pcall(function() obj:Destroy() end)
            end
        end
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if antiFling.lastSafeCFrame then root.CFrame = antiFling.lastSafeCFrame end
        end)
    elseif linear < 40 then
        antiFling.lastSafeCFrame = root.CFrame
    end
end

local function startAntiFling()
    if antiFling.connection then return end
    antiFling.lastSafeCFrame = nil
    antiFling.originalCollide = setmetatable({}, { __mode = "k" })
    applyAntiFlingCollision(LP.Character)
    antiFling.connection = RunService.Heartbeat:Connect(function() pcall(antiFlingTick) end)
    if not antiFling.charConnection then
        antiFling.charConnection = LP.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            if State.AntiFling then applyAntiFlingCollision(char) end
        end)
    end
end

local function stopAntiFling()
    if antiFling.connection then antiFling.connection:Disconnect(); antiFling.connection = nil end
    if antiFling.charConnection then antiFling.charConnection:Disconnect(); antiFling.charConnection = nil end
    antiFling.lastSafeCFrame = nil
    restoreAntiFlingCollision(LP.Character)
    resetCharacterPhysics()
end
local SafeZone = { platform = nil, lastMapCFrame = nil, active = false }

local function createSafePlatform()
    if SafeZone.platform and SafeZone.platform.Parent then return SafeZone.platform end
    local platform = Instance.new("Part")
    platform.Name = "Netspend_SafeZone"
    platform.Size = Vector3.new(40, 4, 40)
    platform.Position = Vector3.new(0, 10000, 0)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(0, 170, 255)
    platform.Transparency = 0.35
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Parent = workspace
    local selection = Instance.new("SelectionBox")
    selection.Adornee = platform
    selection.LineThickness = 0.15
    selection.Color3 = Color3.fromRGB(0, 220, 255)
    selection.Parent = platform
    SafeZone.platform = platform
    return platform
end

local function tpToSafe()
    local root = getRoot()
    if not root then return end
    if not SafeZone.active then SafeZone.lastMapCFrame = root.CFrame end
    local platform = createSafePlatform()
    SafeZone.active = true
    pcall(function()
        root.CFrame = CFrame.new(platform.Position + Vector3.new(0, 6, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function tpToMap()
    if Ghost and Ghost.active then
        stopInvisibility()
        return
    end
    local root = getRoot()
    if not root then return end
    local destination = SafeZone.lastMapCFrame or CFrame.new(0, 20, 0)
    pcall(function()
        root.CFrame = destination
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    SafeZone.active = false
end


local function getGhostProxyRoot()
    local proxy = Ghost.Proxy
    if not proxy or not proxy.Parent then return nil end
    return proxy:FindFirstChild("HumanoidRootPart") or proxy.PrimaryPart
end

local function getGhostShotOrigin()
    if not Ghost.active then return nil end
    local proxyRoot = getGhostProxyRoot()
    if not proxyRoot then return nil end

    local realRoot = getRoot()
    local realAttachment = realRoot and realRoot:FindFirstChild("GunRaycastAttachment")
    if realAttachment then
        return CFrame.new(proxyRoot.Position, proxyRoot.Position + proxyRoot.CFrame.LookVector)
    end

    local camera = workspace.CurrentCamera
    if camera then
        return CFrame.new(proxyRoot.Position, proxyRoot.Position + camera.CFrame.LookVector)
    end
    return CFrame.new(proxyRoot.Position)
end

local INVIS_CFG = {
    SafeHeight = 9000,
    PlatformSize = Vector3.new(50, 4, 50),
    ToggleKey = Enum.KeyCode.X,
    ProxyAlpha = 0,
}

local function ensureInvisPlatform()
    if Ghost.Platform and Ghost.Platform.Parent then
        return Ghost.Platform
    end

    local p = Instance.new("Part")
    p.Name = "Netspend_InvisPlatform"
    p.Size = INVIS_CFG.PlatformSize
    p.Position = Vector3.new(0, INVIS_CFG.SafeHeight, 0)
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.SmoothPlastic
    p.Color = Color3.fromRGB(30, 30, 35)
    p.Transparency = 0.5
    p.Parent = workspace

    Ghost.Platform = p
    return p
end

local function removeInvisPlatform()
    if Ghost.Platform and Ghost.Platform.Parent then
        pcall(function() Ghost.Platform:Destroy() end)
    end
    Ghost.Platform = nil
end

local function hideLocalCharacter(character)
    if not character then return end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            if Ghost.LocalTransCache[obj] == nil then
                Ghost.LocalTransCache[obj] = obj.LocalTransparencyModifier
            end
            obj.LocalTransparencyModifier = 1
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if Ghost.LocalTransCache[obj] == nil then
                Ghost.LocalTransCache[obj] = obj.Transparency
            end
            obj.Transparency = 1
        end
    end
end

local function restoreLocalCharacter(character)
    for obj, value in pairs(Ghost.LocalTransCache) do
        if obj and obj.Parent then
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = value
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = value
                end
            end)
        end
    end
    table.clear(Ghost.LocalTransCache)
end

local function buildInvisProxy(character, atCFrame)
    if not character then return nil end

    local oldArchivable = character.Archivable
    character.Archivable = true
    local ok, proxy = pcall(function() return character:Clone() end)
    character.Archivable = oldArchivable
    if not ok or not proxy then return nil end

    proxy.Name = "Netspend_InvisProxy"

    for _, obj in ipairs(proxy:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
            obj:Destroy()
        elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            obj:Destroy()
        elseif obj:IsA("Tool") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Anchored = false
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.Massless = true
            obj.CastShadow = false
            obj.LocalTransparencyModifier = INVIS_CFG.ProxyAlpha
        end
    end

    proxy.Parent = workspace
    pcall(function() proxy:PivotTo(atCFrame) end)

    local proxyHRP = proxy:FindFirstChild("HumanoidRootPart")
    if proxyHRP then
        proxyHRP.Anchored = true
        for _, part in ipairs(proxy:GetDescendants()) do
            if part:IsA("BasePart") and part ~= proxyHRP then
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = proxyHRP
                weld.Part1 = part
                weld.Parent = proxyHRP
            end
        end
    end

    return proxy
end

local function destroyInvisProxy()
    if Ghost.RenderConn then
        pcall(function() Ghost.RenderConn:Disconnect() end)
        Ghost.RenderConn = nil
    end
    if Ghost.CharConn then
        pcall(function() Ghost.CharConn:Disconnect() end)
        Ghost.CharConn = nil
    end
    if Ghost.InputConn then
        pcall(function() Ghost.InputConn:Disconnect() end)
        Ghost.InputConn = nil
    end
    if Ghost.Proxy and Ghost.Proxy.Parent then
        pcall(function() Ghost.Proxy:Destroy() end)
    end
    Ghost.Proxy = nil
    Ghost.ProxyHRP = nil
    Ghost.ProxyAnimator = nil
end

local function getDescendantByPath(root, path)
    local current = root
    for part in string.gmatch(path, "[^%.]+") do
        current = current and current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

local function getRelativePath(root, object)
    local parts = {}
    local current = object
    while current and current ~= root do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    if current ~= root then return nil end
    return table.concat(parts, ".")
end

local function syncProxyPose(character, proxy)
    if not character or not proxy or not proxy.Parent then return end

    local realHRP = character:FindFirstChild("HumanoidRootPart")
    local proxyHRP = Ghost.ProxyHRP
    if not realHRP or not proxyHRP then return end

    for _, realPart in ipairs(character:GetDescendants()) do
        if realPart:IsA("BasePart") and realPart.Name ~= "HumanoidRootPart" then
            local path = getRelativePath(character, realPart)
            local proxyPart = path and getDescendantByPath(proxy, path)
            if proxyPart and proxyPart:IsA("BasePart") then
                local relative = realHRP.CFrame:ToObjectSpace(realPart.CFrame)
                pcall(function()
                    proxyPart.CFrame = proxyHRP.CFrame * relative
                    proxyPart.LocalTransparencyModifier = INVIS_CFG.ProxyAlpha
                end)
            end
        end
    end
end

local function attachInvisCamera()
    local proxy = Ghost.Proxy
    local camera = workspace.CurrentCamera
    local proxyHum = proxy and proxy:FindFirstChildOfClass("Humanoid")
    if camera and proxyHum then
        Ghost.camera = camera
        pcall(function()
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = proxyHum
        end)
    end
end

local function restoreInvisCamera()
    local camera = workspace.CurrentCamera or Ghost.camera
    local hum = getHum()
    if camera and hum then
        pcall(function()
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = hum
        end)
    end
    Ghost.camera = nil
end

local function stopInvisibility()
    if not Ghost.active then return end

    setInvisibilityState(false)

    if Ghost.RenderConn then
        pcall(function() Ghost.RenderConn:Disconnect() end)
        Ghost.RenderConn = nil
    end
    if Ghost.CharConn then
        pcall(function() Ghost.CharConn:Disconnect() end)
        Ghost.CharConn = nil
    end
    if Ghost.InputConn then
        pcall(function() Ghost.InputConn:Disconnect() end)
        Ghost.InputConn = nil
    end

    restoreInvisCamera()

    local char = LP.Character
    if char then
        restoreLocalCharacter(char)
    end

    local root = getRoot()
    if root and Ghost.OriginalCF then
        pcall(function()
            root.CFrame = Ghost.OriginalCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    destroyInvisProxy()
    removeInvisPlatform()

    Ghost.OriginalCF = nil
    Ghost.LastPos = nil
    Ghost.TargetPos = nil
    Ghost.LastLook = nil
    Ghost.JumpVel = 0
    Ghost.JumpOff = 0
    Ghost.Grounded = true
    Ghost.WasJumping = false
    Ghost.mapCFrame = nil
    Ghost.safeCFrame = nil
end

local toggleInvisibility

local function startInvisibility()
    if Ghost.active then return true end

    local char = LP.Character
    local root = getRoot()
    local hum = getHum()
    if not char or not root or not hum or hum.Health <= 0 then
        return false
    end

    destroyInvisProxy()
    removeInvisPlatform()
    table.clear(Ghost.LocalTransCache)

    Ghost.OriginalCF = root.CFrame
    Ghost.mapCFrame = Ghost.OriginalCF
    Ghost.LastPos = root.Position
    Ghost.TargetPos = root.Position
    Ghost.LastLook = root.CFrame.LookVector
    Ghost.JumpVel = 0
    Ghost.JumpOff = 0
    Ghost.Grounded = true
    Ghost.WasJumping = false

    local proxy = buildInvisProxy(char, root.CFrame)
    if not proxy then
        Ghost.OriginalCF = nil
        return false
    end

    Ghost.Proxy = proxy
    Ghost.ProxyHRP = proxy:FindFirstChild("HumanoidRootPart")
    if not Ghost.ProxyHRP then
        destroyInvisProxy()
        Ghost.OriginalCF = nil
        return false
    end

    local platform = ensureInvisPlatform()
    local safeCF = CFrame.new(
        platform.Position + Vector3.new(0, INVIS_CFG.PlatformSize.Y / 2 + 3.1, 0),
        platform.Position + Vector3.new(0, INVIS_CFG.PlatformSize.Y / 2 + 3.1, 0) + root.CFrame.LookVector
    )
    Ghost.safeCFrame = safeCF

    pcall(function()
        root.CFrame = safeCF
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    hideLocalCharacter(char)
    setInvisibilityState(true)
    attachInvisCamera()

    Ghost.RenderConn = RunService.RenderStepped:Connect(function(dt)
        if not Ghost.active then return end

        local currentChar = LP.Character
        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        local proxy = Ghost.Proxy
        local proxyHRP = Ghost.ProxyHRP
        if not currentHum or not proxy or not proxy.Parent or not proxyHRP or not proxyHRP.Parent then
            return
        end

        local move = currentHum.MoveDirection
        local speed = math.max(currentHum.WalkSpeed, 0)
        local horizontal = Vector3.new(move.X, 0, move.Z)

        if horizontal.Magnitude > 0.01 then
            horizontal = horizontal.Unit
            Ghost.LastPos = Ghost.LastPos + horizontal * speed * dt
            Ghost.LastLook = horizontal
        end

        local state = currentHum:GetState()
        local jumping = state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall

        if jumping and Ghost.Grounded and not Ghost.WasJumping then
            Ghost.Grounded = false
            Ghost.JumpVel = math.max(currentHum.JumpPower, 0) * 0.92
        end
        Ghost.WasJumping = jumping

        if not Ghost.Grounded then
            Ghost.JumpVel = Ghost.JumpVel - workspace.Gravity * dt
            Ghost.JumpOff = Ghost.JumpOff + Ghost.JumpVel * dt
            if Ghost.JumpOff <= 0 then
                Ghost.JumpOff = 0
                Ghost.JumpVel = 0
                Ghost.Grounded = true
            end
        end

        local finalPos = Ghost.LastPos + Vector3.new(0, Ghost.JumpOff, 0)
        local lookDir = Ghost.LastLook
        local targetCF
        if lookDir and lookDir.Magnitude > 0.01 then
            targetCF = CFrame.lookAt(finalPos, finalPos + lookDir)
        else
            targetCF = CFrame.new(finalPos)
        end

        pcall(function()
            proxyHRP.CFrame = targetCF
            proxyHRP.AssemblyLinearVelocity = Vector3.zero
            proxyHRP.AssemblyAngularVelocity = Vector3.zero
        end)

        pcall(function()
            syncProxyPose(currentChar, proxy)
        end)

        local realRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        local livePlatform = Ghost.Platform
        if realRoot and livePlatform and livePlatform.Parent and Ghost.safeCFrame then
            local dist = (realRoot.Position - Ghost.safeCFrame.Position).Magnitude
            if dist > 3 then
                pcall(function()
                    realRoot.CFrame = Ghost.safeCFrame
                    realRoot.AssemblyLinearVelocity = Vector3.zero
                    realRoot.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end)

    Ghost.CharConn = LP.CharacterRemoving:Connect(function()
        if Ghost.active then
            task.defer(function()
                pcall(stopInvisibility)
            end)
        end
    end)

    Ghost.InputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == INVIS_CFG.ToggleKey then
            toggleInvisibility()
        end
    end)

    return true
end

toggleInvisibility = function()
    if Ghost.active then
        stopInvisibility()
    else
        startInvisibility()
    end
end

local function toggleSafe()
    if Ghost.active then
        stopInvisibility()
        return
    end
    if SafeZone.active then
        tpToMap()
    else
        tpToSafe()
    end
end
local Grab = {
    Busy = false,
    Current = nil,
    LastGrab = 0,
    Cooldown = 0.10,
}
local grabConnections = {}
local grabLoopId = 0
local gunDrop = nil

local function isExactGunDrop(object)
    return object ~= nil and object.Name == "GunDrop" and object:IsDescendantOf(workspace)
end

local function playerAlreadyHasGun()
    local char = LP.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and tostring(obj.Name):lower() == "gun" then
                return true
            end
        end
    end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") and tostring(obj.Name):lower() == "gun" then
                return true
            end
        end
    end
    return false
end

local function getGunPart(object)
    if not object then return nil end
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") then
        local handle = object:FindFirstChild("Handle", true)
        if handle and handle:IsA("BasePart") then return handle end
        if object.PrimaryPart then return object.PrimaryPart end
        return object:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function getGunPrompt(object)
    return object and object:FindFirstChildWhichIsA("ProximityPrompt", true) or nil
end

local function getGunClickDetector(object)
    return object and object:FindFirstChildWhichIsA("ClickDetector", true) or nil
end

local function tryPromptPickup(container)
    local prompt = getGunPrompt(container)
    if not prompt then return false end
    local fp = getFPrompt()
    if fp then
        pcall(fp, prompt)
        if playerAlreadyHasGun() then return true end
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
    return playerAlreadyHasGun()
end

local function tryClickPickup(container)
    local click = getGunClickDetector(container)
    if not click then return false end
    local fc = getFClick()
    if not fc then return false end
    pcall(fc, click)
    return playerAlreadyHasGun()
end

local function tryTouchPickup(part)
    local fti = getFTI()
    local char = LP.Character
    if not fti or not part or not char then return false end

    local touchParts = {
        char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("LeftFoot"),
        char:FindFirstChild("RightFoot"),
        char:FindFirstChild("Left Leg"),
        char:FindFirstChild("Right Leg"),
    }

    if State.Invisibility then
        local root = getRoot()
        local saved = root and root.CFrame
        if root and saved then
            pcall(function()
                root.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            for _, bodyPart in ipairs(touchParts) do
                if bodyPart and bodyPart:IsA("BasePart") then
                    pcall(function()
                        fti(bodyPart, part, 0)
                        task.wait(0.01)
                        fti(bodyPart, part, 1)
                    end)
                    if playerAlreadyHasGun() then break end
                end
            end
            pcall(function()
                root.CFrame = saved
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            return playerAlreadyHasGun()
        end
    end

    for _, bodyPart in ipairs(touchParts) do
        if bodyPart and bodyPart:IsA("BasePart") then
            pcall(function()
                fti(bodyPart, part, 0)
                task.wait(0.015)
                fti(bodyPart, part, 1)
            end)
            if playerAlreadyHasGun() then return true end
        end
    end
    return playerAlreadyHasGun()
end

local function remoteGrabGun(drop)
    if not isExactGunDrop(drop) or playerAlreadyHasGun() then return false end
    local part = getGunPart(drop)
    if not part then return false end

    if tryPromptPickup(drop) then return true end
    if tryClickPickup(drop) then return true end

    return tryTouchPickup(part)
end

local function setAutoGrab(enabled)
    State.AutoGun = enabled
    for _, c in ipairs(grabConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(grabConnections)
    Grab.Busy = false
    Grab.Current = nil
    grabLoopId += 1
    local myLoop = grabLoopId

    if not enabled then
        gunDrop = nil
        return
    end

    local function onGunDrop(drop)
        if not State.AutoGun or not isExactGunDrop(drop) then return end
        gunDrop = drop
        if Grab.Busy or playerAlreadyHasGun() then return end

        Grab.Busy = true
        Grab.Current = drop
        task.spawn(function()
            local started = tick()
            local timeout = 1.0
            while State.AutoGun and isExactGunDrop(drop) and tick() - started < timeout do
                if playerAlreadyHasGun() then break end
                remoteGrabGun(drop)
                if playerAlreadyHasGun() then break end
                task.wait(0.08)
            end
            Grab.Busy = false
            Grab.Current = nil
            if not playerAlreadyHasGun() and gunDrop == drop then
                gunDrop = drop
            end
        end)
    end

    local existing = workspace:FindFirstChild("GunDrop", true)
    if existing then
        onGunDrop(existing)
    end

    table.insert(grabConnections, workspace.DescendantAdded:Connect(function(object)
        if object.Name == "GunDrop" then
            task.defer(onGunDrop, object)
        end
    end))

    table.insert(grabConnections, workspace.DescendantRemoving:Connect(function(object)
        if object == gunDrop then
            gunDrop = nil
        end
    end))

    task.spawn(function()
        while State.AutoGun and myLoop == grabLoopId do
            if not playerAlreadyHasGun() and not Grab.Busy then
                local drop = gunDrop or workspace:FindFirstChild("GunDrop", true)
                if drop and isExactGunDrop(drop) then
                    onGunDrop(drop)
                end
            end
            task.wait(0.35)
        end
    end)
end
local playerESPObjects = {}

local function removePlayerESP(plr)
    local hl = playerESPObjects[plr]
    if hl then pcall(function() hl:Destroy() end) end
    playerESPObjects[plr] = nil
end

local function clearPlayerESP()
    for plr in pairs(playerESPObjects) do removePlayerESP(plr) end
    table.clear(playerESPObjects)
end

local function applyPlayerESPFor(plr)
    if not State.PlayerESP or plr == LP then return end
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then removePlayerESP(plr); return end

    local role = getRole(plr)
    local color = roleColor(role) or roleColor("Innocent")

    local old = playerESPObjects[plr]
    if old and old.Parent == char then
        old.FillTransparency = 1
        old.OutlineTransparency = 0
        old.OutlineColor = color
        return
    end
    removePlayerESP(plr)

    local highlight = Instance.new("Highlight")
    highlight.Name = "Netspend_PlayerESP"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    playerESPObjects[plr] = highlight

    if hum then
        hum.Died:Connect(function() removePlayerESP(plr) end)
    end
end

local function applyPlayerESP()
    clearPlayerESP()
    if not State.PlayerESP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then applyPlayerESPFor(plr) end
    end
end

local function hookPlayerESPPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.1)
        if State.PlayerESP then applyPlayerESPFor(plr) end
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LP then hookPlayerESPPlayer(plr) end
end
Players.PlayerAdded:Connect(function(plr) hookPlayerESPPlayer(plr) end)
Players.PlayerRemoving:Connect(function(plr) removePlayerESP(plr) end)

LP.CharacterAdded:Connect(function(character)
    local hum = character:WaitForChild("Humanoid", 5)
    if hum then hum.Died:Connect(function() clearPlayerESP() end) end
end)

local SA = {
    targetPlayer = nil,
    targetPart = nil,
    predictedPoint = nil,
    lastTargetTime = 0,
    maxDistance = 5000,
    positionHistory = {},
    projectileSpeed = 320,
    lastPing = 0.05,
    lastPingSample = 0,
    lastVelocity = {},
    lastAcceleration = {},
}


local gameplayForRoles = nil
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    gameplayForRoles = remotes and remotes:FindFirstChild("Gameplay")
end)

if gameplayForRoles then
    local roleSelect = gameplayForRoles:FindFirstChild("RoleSelect")
    if roleSelect and roleSelect:IsA("RemoteEvent") then
        roleSelect.OnClientEvent:Connect(function(roleValue, extra)
            SA.targetPlayer = nil
            SA.targetPart = nil
            SA.predictedPoint = nil

            local function parseRolePayload(value, depth)
                if depth > 4 or value == nil then return end
                if type(value) == "string" then
                    local r = normalizeRoleString(value)
                    if r then setRole(LP, r, "RoleSelect") end
                    return
                end
                if type(value) ~= "table" then return end
                for k, v in pairs(value) do
                    local target = nil
                    if typeof(k) == "Instance" and k:IsA("Player") then target = k
                    elseif type(k) == "number" then target = Players:GetPlayerByUserId(k)
                    elseif type(k) == "string" then target = Players:FindFirstChild(k) end
                    local r = normalizeRoleString(v)
                    if target and r then
                        setRole(target, r, "RoleSelect")
                    else
                        parseRolePayload(v, depth + 1)
                    end
                end
            end

            parseRolePayload(roleValue, 0)
            parseRolePayload(extra, 0)

            if State.PlayerESP then applyPlayerESP() end
        end)
    end
    local coinsStarted = gameplayForRoles:FindFirstChild("CoinsStarted")
    if coinsStarted and coinsStarted:IsA("RemoteEvent") then
        coinsStarted.OnClientEvent:Connect(function()
            clearAllRoles()
            clearPlayerESP()
            SA.targetPlayer = nil
            SA.targetPart = nil
            SA.predictedPoint = nil
            if State.PlayerESP then task.defer(applyPlayerESP) end
        end)
    end

    local function hookRoundEvent(obj)
        if not obj or not obj:IsA("RemoteEvent") then return end
        local n = obj.Name:lower()
        if not (n:find("round",1,true) or n:find("intermission",1,true) or n:find("gameend",1,true) or n:find("roundend",1,true)) then return end
        if not (n:find("end",1,true) or n:find("intermission",1,true)) then return end
        obj.OnClientEvent:Connect(function()
            clearAllRoles()
            clearPlayerESP()
            SA.targetPlayer = nil
            SA.targetPart = nil
            SA.predictedPoint = nil
        end)
    end

    for _, obj in ipairs(gameplayForRoles:GetDescendants()) do hookRoundEvent(obj) end
    gameplayForRoles.DescendantAdded:Connect(hookRoundEvent)
end

local function roleFromObject(obj)
    if not obj then return nil end
    if obj:IsA("StringValue") then
        local n = obj.Name:lower()
        if n == "role" or n == "rolename" or n == "teamrole" or n:find("role",1,true) then
            return normalizeRoleString(obj.Value)
        end
    elseif obj:IsA("BoolValue") and obj.Value then
        local n = obj.Name:lower()
        if n:find("murder",1,true) then return "Murderer" end
        if n:find("sheriff",1,true) or n:find("hero",1,true) then return "Sheriff" end
    end
    return nil
end

local function refreshPlayerESPOnly(plr)
    if State.PlayerESP then
        task.defer(applyPlayerESPFor, plr)
    end
end

local function watchRoleSources(plr)
    if not plr or plr == LP then return end

    plr.AttributeChanged:Connect(function(attrName)
        local n = tostring(attrName):lower()
        if n == "role" or n == "rolename" or n == "teamrole" or n:find("murder",1,true) or n:find("sheriff",1,true) then
            local role = scanAttributes(plr)
            if role then
                setRole(plr, role, "attribute")
                refreshPlayerESPOnly(plr)
            end
        end
    end)

    local function hookContainer(container)
        if not container then return end
        container.DescendantAdded:Connect(function(obj)
            local role = roleFromObject(obj)
            if role then
                setRole(plr, role, "replicated")
                refreshPlayerESPOnly(plr)
            elseif obj:IsA("Tool") then
                local weaponRole = scanInventory(plr)
                if weaponRole then
                    setRole(plr, weaponRole, "weapon")
                    refreshPlayerESPOnly(plr)
                end
            end
        end)
    end

    hookContainer(plr)
    hookContainer(plr.Character)
    hookContainer(plr:FindFirstChildOfClass("Backpack"))

    plr.CharacterAdded:Connect(function(character)
        clearRole(plr)
        hookContainer(character)
        task.defer(function()
            local role = scanAttributes(plr) or scanCharacterRoleValues(plr) or scanTeam(plr)
            if role then
                setRole(plr, role, "character")
            end
            refreshPlayerESPOnly(plr)
        end)
    end)

    task.defer(function()
        local role = scanReplicatedRoleMarkers(plr) or scanAttributes(plr) or scanTeam(plr)
        if role then
            setRole(plr, role, "initial")
        end
        refreshPlayerESPOnly(plr)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LP then watchRoleSources(plr) end
end
Players.PlayerAdded:Connect(function(plr) watchRoleSources(plr) end)



local function getAimPart(plr)
    local char = plr and plr.Character
    if not char then return nil end

    for _, name in ipairs({"Head", "UpperTorso", "Torso", "HumanoidRootPart"}) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function samplePing()
    local now = os.clock()
    if now - SA.lastPingSample < 0.20 then
        return SA.lastPing
    end
    SA.lastPingSample = now

    local ping = SA.lastPing
    pcall(function()
        local stat = Stats.Network.ServerStatsItem["Data Ping"]
        if stat then
            local ok, value = pcall(function() return stat:GetValue() end)
            if ok and type(value) == "number" then
                ping = value / 1000
            end
        end
    end)

    if ping ~= ping then ping = 0.05 end
    SA.lastPing = math.clamp(ping, 0.01, 0.35)
    return SA.lastPing
end

local function getTargetMotion(plr)
    local char = plr and plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return Vector3.zero, Vector3.zero
    end

    local now = os.clock()
    local position = root.Position
    local rawVelocity = root.AssemblyLinearVelocity
    local previous = SA.positionHistory[plr]
    local velocity = rawVelocity
    local acceleration = Vector3.zero

    if previous then
        local dt = now - previous.time
        if dt > 0.005 and dt < 0.20 then
            local measured = (position - previous.position) / dt
            if measured.Magnitude < 500 then
                velocity = measured:Lerp(rawVelocity, 0.22)
            end

            local previousVelocity = SA.lastVelocity[plr]
            if previousVelocity then
                local measuredAcceleration = (velocity - previousVelocity) / dt
                if measuredAcceleration.Magnitude < 2500 then
                    acceleration = measuredAcceleration
                end
            end
        end
    end

    local previousAcceleration = SA.lastAcceleration[plr]
    if previousAcceleration then
        acceleration = previousAcceleration:Lerp(acceleration, 0.45)
    end

    SA.positionHistory[plr] = {
        position = position,
        time = now,
    }
    SA.lastVelocity[plr] = velocity
    SA.lastAcceleration[plr] = acceleration

    return velocity, acceleration
end

local function solveInterceptTime(relativePosition, targetVelocity, projectileSpeed)
    local speed = math.max(projectileSpeed or 0, 1)
    local a = targetVelocity:Dot(targetVelocity) - speed * speed
    local b = 2 * relativePosition:Dot(targetVelocity)
    local c = relativePosition:Dot(relativePosition)

    if math.abs(a) < 1e-5 then
        if math.abs(b) < 1e-5 then return 0 end
        local t = -c / b
        return t > 0 and t or 0
    end

    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return 0
    end

    local root = math.sqrt(discriminant)
    local t1 = (-b - root) / (2 * a)
    local t2 = (-b + root) / (2 * a)
    local t = math.huge

    if t1 > 0 then t = t1 end
    if t2 > 0 and t2 < t then t = t2 end
    if t == math.huge then return 0 end

    return math.clamp(t, 0, 1.25)
end

local function findMurdererTarget()
    local bestPlayer, bestPart = nil, nil
    local bestDistance = math.huge
    local myRoot = getRoot()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and getRole(plr) == "Murderer" then
            local part = getAimPart(plr)
            if part then
                local distance = myRoot and (part.Position - myRoot.Position).Magnitude or 0
                if distance < SA.maxDistance and distance < bestDistance then
                    bestDistance = distance
                    bestPlayer = plr
                    bestPart = part
                end
            end
        end
    end

    return bestPlayer, bestPart
end

local function currentTargetValid()
    local player = SA.targetPlayer
    local part = SA.targetPart

    if not player or not part then return false end
    if not alive(player) then return false end
    if getRole(player) ~= "Murderer" then return false end
    if player.Character ~= part.Parent then return false end

    local myRoot = getRoot()
    if not myRoot then return false end

    return (part.Position - myRoot.Position).Magnitude <= SA.maxDistance
end

local function getPredictedPointFromOrigin(origin)
    if not State.SilentAim or not SA.targetPlayer or not SA.targetPart then
        return nil
    end
    if not currentTargetValid() then
        return nil
    end

    local target = SA.targetPart
    local velocity, acceleration = getTargetMotion(SA.targetPlayer)
    local current = target.Position
    local relative = current - origin
    local distance = relative.Magnitude
    local ping = samplePing()

    local flightTime = solveInterceptTime(relative, velocity, SA.projectileSpeed)
    local networkDelay = math.clamp(ping * 0.62, 0.012, 0.20)
    local leadTime = math.clamp(flightTime + networkDelay, 0, 1.05)

    local predicted = current
        + velocity * leadTime
        + acceleration * (0.5 * leadTime * leadTime)

    local displacement = predicted - current
    local maxLead = math.clamp(distance * 0.28 + 10, 10, 48)
    if displacement.Magnitude > maxLead then
        predicted = current + displacement.Unit * maxLead
    end

    if velocity.Magnitude < 1.0 and acceleration.Magnitude < 6 then
        predicted = current
    end

    SA.predictedPoint = predicted
    return predicted
end

local function updateSilentTarget()
    if not State.SilentAim then
        SA.targetPlayer = nil
        SA.targetPart = nil
        SA.predictedPoint = nil
        return
    end

    local now = os.clock()

    if currentTargetValid() and now - SA.lastTargetTime < 0.16 then
        return
    end

    local newPlayer, newPart = findMurdererTarget()
    if newPlayer then
        if SA.targetPlayer ~= newPlayer then
            SA.positionHistory[newPlayer] = nil
            SA.lastVelocity[newPlayer] = nil
            SA.lastAcceleration[newPlayer] = nil
        end

        SA.targetPlayer = newPlayer
        SA.targetPart = newPart
        SA.predictedPoint = nil
        SA.lastTargetTime = now
    else
        SA.targetPlayer = nil
        SA.targetPart = nil
        SA.predictedPoint = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not State.SilentAim then return end

    pcall(updateSilentTarget)

    if SA.targetPlayer and SA.targetPart and currentTargetValid() then
        pcall(function()
            getTargetMotion(SA.targetPlayer)
        end)
    end
end)

local AIMBOT_MAX_DISTANCE = 2500
local AIMBOT_MAX_ANGLE = 82
local AIMBOT_SWITCH_MARGIN = 0.82
local AIMBOT_MIN_RESPONSE = 24
local AIMBOT_MAX_RESPONSE = 58
local AIMBOT_SCAN_INTERVAL = 0.10
local AIMBOT_PREDICT_INTERVAL = 0.045

local aimbotLastTarget = nil
local aimbotLastPart = nil
local aimbotCachedCandidate = nil
local aimbotCachedPoint = nil
local aimbotNextScan = 0
local aimbotNextPrediction = 0
local aimbotNextRoleCheck = 0
local aimbotIsSheriff = false
local aimbotLastSteerTime = os.clock()
local aimbotConnection = nil

local aimbotRayParams = RaycastParams.new()
aimbotRayParams.FilterType = Enum.RaycastFilterType.Exclude
aimbotRayParams.IgnoreWater = true

local function getAimbotPart(plr)
    local char = plr and plr.Character
    if not char then return nil end

    if State.AimbotPart == "Head" then
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            return head
        end
    end

    for _, name in ipairs({"UpperTorso", "Torso", "HumanoidRootPart", "Head"}) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function getAimbotAngle(camera, position)
    local offset = position - camera.CFrame.Position
    local magnitude = offset.Magnitude
    if magnitude <= 0.001 then return 0 end

    local direction = offset / magnitude
    local dot = math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)
    return math.deg(math.acos(dot))
end

local function isAimbotVisible(camera, plr, part)
    local character = plr and plr.Character
    if not character or not part then return false end

    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    if direction.Magnitude <= 0.01 then return true end

    aimbotRayParams.FilterDescendantsInstances = { LP.Character }
    local result = workspace:Raycast(origin, direction, aimbotRayParams)

    if not result then
        return true
    end

    return result.Instance and result.Instance:IsDescendantOf(character)
end

local function getAimbotCandidate(plr, camera)
    if plr == LP or not alive(plr) or getRole(plr) ~= "Murderer" then
        return nil, math.huge
    end

    local part = getAimbotPart(plr)
    if not part then
        return nil, math.huge
    end

    local distance = (part.Position - camera.CFrame.Position).Magnitude
    if distance > AIMBOT_MAX_DISTANCE then
        return nil, math.huge
    end

    local angle = getAimbotAngle(camera, part.Position)
    if angle > AIMBOT_MAX_ANGLE then
        return nil, math.huge
    end

    local screen, onScreen = camera:WorldToViewportPoint(part.Position)
    local viewport = camera.ViewportSize
    local center = viewport * 0.5
    local screenDistance = math.huge

    if onScreen and screen.Z > 0 then
        screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
    end

    local score = angle * 9.0
    score += distance * 0.0018

    if screenDistance < math.huge then
        score += screenDistance * 0.016
    end

    return {
        player = plr,
        part = part,
        score = score,
        angle = angle,
        visible = false,
    }, score
end

local function findAimbotTarget(camera)
    local best = nil
    local bestScore = math.huge

    if aimbotLastTarget then
        local current = getAimbotCandidate(aimbotLastTarget, camera)
        if current then
            current.score *= AIMBOT_SWITCH_MARGIN
            best = current
            bestScore = current.score
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local candidate, score = getAimbotCandidate(plr, camera)
        if candidate and score < bestScore then
            best = candidate
            bestScore = score
        end
    end

    if best and best.player and best.part then
        best.visible = isAimbotVisible(camera, best.player, best.part)
        if not best.visible then
            return nil
        end
    end

    return best
end

local function getAimbotPoint(plr, part)
    if not plr or not part then return nil end

    local point = part.Position

    pcall(function()
        local velocity = getTargetMotion(plr)
        local ping = samplePing()

        if typeof(velocity) == "Vector3" then
            local lead = math.clamp(ping * 0.58 + 0.025, 0.025, 0.12)
            point += velocity * lead
        elseif type(velocity) == "table" then
            local v = velocity[1]
            if typeof(v) == "Vector3" then
                local lead = math.clamp(ping * 0.58 + 0.025, 0.025, 0.12)
                point += v * lead
            end
        end
    end)

    return point
end

local function updateAimbot(now)
    if not State.Aimbot then
        aimbotLastTarget = nil
        aimbotLastPart = nil
        aimbotCachedCandidate = nil
        aimbotCachedPoint = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    if now >= aimbotNextRoleCheck then
        aimbotNextRoleCheck = now + 0.25
        aimbotIsSheriff = (getRole(LP) == "Sheriff")
    end

    if not aimbotIsSheriff then
        aimbotLastTarget = nil
        aimbotLastPart = nil
        aimbotCachedCandidate = nil
        aimbotCachedPoint = nil
        return
    end

    if now >= aimbotNextScan then
        aimbotNextScan = now + AIMBOT_SCAN_INTERVAL

        local candidate = findAimbotTarget(camera)
        aimbotCachedCandidate = candidate

        if candidate and candidate.player and candidate.part then
            aimbotLastTarget = candidate.player
            aimbotLastPart = candidate.part
            aimbotCachedPoint = getAimbotPoint(candidate.player, candidate.part)
            aimbotNextPrediction = now + AIMBOT_PREDICT_INTERVAL
        else
            aimbotLastTarget = nil
            aimbotLastPart = nil
            aimbotCachedPoint = nil
        end
    elseif aimbotCachedCandidate and aimbotCachedCandidate.player and aimbotCachedCandidate.part then
        if now >= aimbotNextPrediction then
            aimbotNextPrediction = now + AIMBOT_PREDICT_INTERVAL
            aimbotCachedPoint = getAimbotPoint(
                aimbotCachedCandidate.player,
                aimbotCachedCandidate.part
            )
        end
    end

    local candidate = aimbotCachedCandidate
    if not candidate or not candidate.player or not candidate.part then
        return
    end

    local player = candidate.player
    local part = candidate.part

    if not alive(player) or not part.Parent then
        aimbotCachedCandidate = nil
        aimbotCachedPoint = nil
        aimbotLastTarget = nil
        aimbotLastPart = nil
        return
    end

    local point = aimbotCachedPoint or part.Position
    if typeof(point) ~= "Vector3" then
        point = part.Position
    end

    local cameraPosition = camera.CFrame.Position
    local offset = point - cameraPosition
    local distance = offset.Magnitude
    if distance <= 0.001 then return end

    local goal = CFrame.new(cameraPosition, point)
    local angle = getAimbotAngle(camera, point)

    local angleAlpha = math.clamp(angle / 55, 0, 1)
    local response = AIMBOT_MIN_RESPONSE
        + (AIMBOT_MAX_RESPONSE - AIMBOT_MIN_RESPONSE) * angleAlpha

    if player == aimbotLastTarget then
        response += 5
    end

    local dt = math.clamp(now - aimbotLastSteerTime, 0.005, 0.05)
    aimbotLastSteerTime = now

    local alpha = 1 - math.exp(-response * dt)

    if angle > 42 then
        alpha = math.max(alpha, 0.58)
    elseif angle > 24 then
        alpha = math.max(alpha, 0.46)
    end

    camera.CFrame = camera.CFrame:Lerp(goal, math.clamp(alpha, 0, 0.88))
end

aimbotConnection = RunService.RenderStepped:Connect(function()
    if not State.Aimbot then return end
    if UserInputService and UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then
        return
    end
    updateAimbot(os.clock())
end)

local saNamecallHooked = false
local saHooksInstalledOnce = false
local saOriginalGetMouseTargetCFrame = nil

local function getSilentShotOrigin()
    local root = getRoot()
    if not root then return nil end
    local attachment = root:FindFirstChild("GunRaycastAttachment")
    if attachment and attachment:IsA("Attachment") then
        return attachment.WorldPosition
    end
    return root.Position
end

local function buildSilentMouseTargetCFrame(point)
    if typeof(point) ~= "Vector3" then return nil end

    local origin = getSilentShotOrigin()
    if not origin then
        return CFrame.new(point)
    end

    local direction = point - origin
    if direction.Magnitude <= 0.001 then
        return CFrame.new(point)
    end

    return CFrame.lookAt(point, point + direction.Unit)
end

local function installSilentAimHooks()
    if saHooksInstalledOnce then
        return saNamecallHooked
    end

    saHooksInstalledOnce = true

    if type(hookfunction) ~= "function" then
        return false
    end
    if type(newcclosure) ~= "function" then
        return false
    end
    if type(WeaponService) ~= "table" then
        return false
    end
    if type(WeaponService.GetMouseTargetCFrame) ~= "function" then
        return false
    end

    local targetFunction = WeaponService.GetMouseTargetCFrame
    local oldFunction

    local ok, result = pcall(function()
        oldFunction = hookfunction(targetFunction, newcclosure(function(self, ...)
            if not State.SilentAim then
                return oldFunction(self, ...)
            end

            pcall(updateSilentTarget)

            local origin = getSilentShotOrigin()
            local shotPoint = origin and getPredictedPointFromOrigin(origin) or nil

            if not shotPoint and SA.targetPart and currentTargetValid() then
                shotPoint = SA.targetPart.Position
            end

            if shotPoint then
                local targetCFrame = buildSilentMouseTargetCFrame(shotPoint)
                if targetCFrame then
                    return targetCFrame
                end
            end

            return oldFunction(self, ...)
        end))
        return oldFunction ~= nil
    end)

    if ok and result and oldFunction then
        saOriginalGetMouseTargetCFrame = oldFunction
        saNamecallHooked = true
    end

    return saNamecallHooked
end

local silentFireBusy = false

local function findMyGun()
    local char = LP.Character
    if not char then return nil end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and hasGunWord(obj.Name) then return obj end
    end
    return nil
end

local function silentFire()
    if silentFireBusy then return false end
    if not installSilentAimHooks() then return false end
    local gun = findMyGun()
    if not gun then return false end
    if not SA.targetPart or not SA.predictedPoint then updateSilentTarget() end
    if not SA.targetPart or not SA.predictedPoint then return false end
    silentFireBusy = true
    task.spawn(function()
        pcall(function() gun:Activate() end)
        task.wait(0.06)
        silentFireBusy = false
    end)
    return true
end

-- ============================================================
--  FORCE SHOOT (v2) — Remote Hook, no teleport
--  Перехватывает FireServer выстрела и подменяет позицию цели,
--  пока silent aim идёт через уже установленный хук.
-- ============================================================
local ForceShoot = {
    Busy = false,
    LastShot = 0,
    Cooldown = 0.30,
    OriginalNamecall = nil,
    HookInstalled = false,
    SilentRestore = nil,
    TargetPoint = nil,
}

local function installForceShootHook()
    if ForceShoot.HookInstalled then return true end
    if type(hookmetamethod) ~= "function" then return false end
    if type(getnamecallmethod) ~= "function" then return false end

    local ok, result = pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return nil end

        local original
        original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller()
                and (method == "FireServer" or method == "InvokeServer")
                and ForceShoot.Busy
                and ForceShoot.TargetPoint
            then
                local args = {...}
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = ForceShoot.TargetPoint
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame.lookAt(ForceShoot.TargetPoint, ForceShoot.TargetPoint + Vector3.new(0, 0, -1))
                    end
                end
                if table.unpack then
                    return original(self, table.unpack(args))
                end
                return original(self, unpack(args))
            end
            return original(self, ...)
        end))
        return original
    end)

    if ok and result then
        ForceShoot.OriginalNamecall = result
        ForceShoot.HookInstalled = true
        return true
    end
    return false
end

local function forceShoot()
    if ForceShoot.Busy then return false end
    if tick() - ForceShoot.LastShot < ForceShoot.Cooldown then return false end

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return false end

    local gun = findMyGun()
    if not gun then
        Window:Notify({ Title = T("forceShoot"), Content = T("forceShootNoGun"), Duration = 2 })
        return false
    end

    if not installForceShootHook() then
        Window:Notify({ Title = T("forceShoot"), Content = T("forceShootNoHook"), Duration = 2 })
        return false
    end

    -- refresh target
    if not currentTargetValid() then
        updateSilentTarget()
    end
    local target = SA.targetPlayer
    local targetPart = SA.targetPart
    if not target or not targetPart then
        target, targetPart = findMurdererTarget()
    end
    if not target or not targetPart then
        Window:Notify({ Title = T("forceShoot"), Content = T("forceShootNoTarget"), Duration = 2 })
        return false
    end

    -- turn silent aim on for the shot
    ForceShoot.SilentRestore = State.SilentAim
    State.SilentAim = true
    SA.targetPlayer = target
    SA.targetPart = targetPart
    SA.predictedPoint = nil

    ForceShoot.TargetPoint = targetPart.Position
    ForceShoot.Busy = true
    ForceShoot.LastShot = tick()

    task.spawn(function()
        task.wait(0.02)
        pcall(function() gun:Activate() end)
        task.wait(0.10)

        ForceShoot.Busy = false
        ForceShoot.TargetPoint = nil

        if ForceShoot.SilentRestore ~= nil then
            State.SilentAim = ForceShoot.SilentRestore
            ForceShoot.SilentRestore = nil
        end
        if not State.SilentAim then
            SA.targetPlayer = nil
            SA.targetPart = nil
            SA.predictedPoint = nil
        end
    end)

    return true
end

local behindBusy = false

local function nearestByRole(role)
    local root = getRoot()
    if not root then return nil end
    local best, bestDistance = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and getRole(plr) == role then
            local head = plr.Character and plr.Character:FindFirstChild("Head")
            if head then
                local distance = (head.Position - root.Position).Magnitude
                if distance < bestDistance then bestDistance = distance; best = plr end
            end
        end
    end
    return best
end

local function behind()
    if behindBusy then return end
    local target = nearestByRole("Murderer")
    if not target then return end
    local char = target.Character
    local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    local hum = getHum()
    if not char or not targetRoot or not root or not hum or hum.Health <= 0 then return end
    behindBusy = true
    task.spawn(function()
        local oldAutoRotate = hum.AutoRotate
        hum.AutoRotate = false
        for _ = 1, 4 do
            if not alive(target) or not targetRoot.Parent then break end
            local destination = targetRoot.Position - targetRoot.CFrame.LookVector * 3.25
            local cf = CFrame.new(destination, targetRoot.Position)
            pcall(function()
                root.CFrame = cf
                LP.Character:PivotTo(cf)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            RunService.Heartbeat:Wait()
            task.wait(0.05)
        end
        hum.AutoRotate = oldAutoRotate
        behindBusy = false
    end)
end

local FlingActive = false
local FlingOldPos = nil
local FlingFPDH = workspace.FallenPartsDestroyHeight

local function SkidFling(TargetPlayer)
    local Character = LP.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid, TRootPart, THead, Accessory, Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then THumanoid = TCharacter:FindFirstChildOfClass("Humanoid") end
    if THumanoid and THumanoid.RootPart then TRootPart = THumanoid.RootPart end
    if TCharacter:FindFirstChild("Head") then THead = TCharacter.Head end
    if TCharacter:FindFirstChildOfClass("Accessory") then Accessory = TCharacter:FindFirstChildOfClass("Accessory") end
    if Accessory and Accessory:FindFirstChild("Handle") then Handle = Accessory.Handle end
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then FlingOldPos = RootPart.CFrame end
        if THumanoid and THumanoid.Sit then return end
        if THead then workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then workspace.CurrentCamera.CameraSubject = THumanoid end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not FlingActive
        end
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if TRootPart then SFBasePart(TRootPart)
        elseif THead then SFBasePart(THead)
        elseif Handle then SFBasePart(Handle)
        else
            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.FallenPartsDestroyHeight = FlingFPDH
            return
        end
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        if FlingOldPos then
            repeat
                RootPart.CFrame = FlingOldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(FlingOldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
                end
                task.wait()
            until (RootPart.Position - FlingOldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = FlingFPDH
        end
    end
end

local function flingPlayer(target)
    if FlingActive then return end
    FlingActive = true
    task.spawn(function()
        pcall(function() SkidFling(target) end)
        FlingActive = false
    end)
end

local function flingAll(role)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and getRole(plr) == role then
            flingPlayer(plr)
            task.wait(1.8)
        end
    end
end
local KillAllBusy = false

local function getKnife()
    local char = LP.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and tostring(obj.Name):lower():find("knife", 1, true) then return obj end
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, obj in ipairs(bp:GetChildren()) do
            if obj:IsA("Tool") and tostring(obj.Name):lower():find("knife", 1, true) then return obj end
        end
    end
    return nil
end

local function equipKnife(knife)
    if not knife or not knife.Parent then return false end
    local hum = getHum()
    if not hum then return false end
    if knife.Parent ~= LP.Character then
        pcall(function() hum:EquipTool(knife) end)
        task.wait(0.15)
    end
    return knife.Parent == LP.Character
end

local function killAllInstant()
    if KillAllBusy then return end
    if getRole(LP) ~= "Murderer" then showMessage(T("killAllTitle"), T("notMurderer"), 2); return end
    local knife = getKnife()
    if not knife then showMessage(T("killAllTitle"), T("knifeNotFound"), 2); return end
    if not equipKnife(knife) then showMessage(T("killAllTitle"), T("knifeEquipFailed"), 2); return end
    KillAllBusy = true
    task.spawn(function()
        local fti = getFTI()
        local handle = knife:FindFirstChild("Handle")
        if not fti or not handle then KillAllBusy = false; return end
        local targets = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and alive(plr) then
                local tRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then table.insert(targets, tRoot) end
            end
        end
        for _, tRoot in ipairs(targets) do
            pcall(function()
                knife:Activate()
                fti(tRoot, handle, 0)
                task.wait(0.01)
                fti(tRoot, handle, 1)
            end)
            task.wait(0.03)
        end
        KillAllBusy = false
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        if State.KillAll and getRole(LP) == "Murderer" and not KillAllBusy then
            local hasTargets = false
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and alive(plr) then hasTargets = true; break end
            end
            if hasTargets then pcall(killAllInstant) end
        end
    end
end)
local lastWalkSpeed = -1
local lastJumpPower = -1
local lastFlingM = 0
local lastFlingS = 0

RunService.Heartbeat:Connect(function(dt)
    local hum = getHum()
    local root = getRoot()
    if hum then
        hum.AutoRotate = not State.Spin
        if lastWalkSpeed ~= State.WalkSpeed then
            pcall(function() hum.WalkSpeed = State.WalkSpeed end)
            lastWalkSpeed = State.WalkSpeed
        end
        if lastJumpPower ~= State.JumpPower then
            pcall(function()
                hum.JumpPower = State.JumpPower
                hum.UseJumpPower = true
            end)
            lastJumpPower = State.JumpPower
        end
    end
    if State.Spin and root and hum then
        local angle = math.rad((State.SpinSpeed or 500) * dt)
        pcall(function() root.CFrame = root.CFrame * CFrame.Angles(0, angle, 0) end)
    end
    if State.FlingM and tick() - lastFlingM > 2.5 then
        lastFlingM = tick()
        local target = nearestByRole("Murderer")
        if target then flingPlayer(target) end
    end
    if State.FlingS and tick() - lastFlingS > 2.5 then
        lastFlingS = tick()
        local target = nearestByRole("Sheriff")
        if target then flingPlayer(target) end
    end
end)
local Window = UI:CreateWindow({
    Title = "Netspend",
    Accent = Color3.fromRGB(0, 122, 255),
    Size = UDim2.fromOffset(640, 470),
    StartHidden = true,
})

local DeathLightning = {}
do
    local TweenService = game:GetService("TweenService")
    local ContentProvider = game:GetService("ContentProvider")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer

    DeathLightning.Enabled = false

    local CFG = {
        Image = "rbxassetid://101300628534522",

        -- The image stays still for this long after death.
        HoldTime = 4.0,

        -- Growth + fade duration after the hold.
        FadeTime = 1.6,

        -- Billboard size in screen pixels.
        StartSize = 170,
        EndSize = 285,

        -- Height above the death position.
        Height = 1.8,

        -- Keep it visible through geometry.
        AlwaysOnTop = true,
    }

    local state = {
        active = {},
        preloadStarted = false,
    }

    local function removeFromActive(gui)
        for i = #state.active, 1, -1 do
            if state.active[i] == gui then
                table.remove(state.active, i)
                return
            end
        end
    end

    local function getDeathPosition(character)
        if not character then
            return nil
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            return root.Position
        end

        local primary = character.PrimaryPart
        if primary and primary:IsA("BasePart") then
            return primary.Position
        end

        local ok, pivot = pcall(function()
            return character:GetPivot()
        end)

        if ok and typeof(pivot) == "CFrame" then
            return pivot.Position
        end

        return nil
    end

    local function startPreload()
        if state.preloadStarted then
            return
        end

        state.preloadStarted = true

        -- This runs only when the toggle is enabled, never inside Humanoid.Died.
        task.spawn(function()
            local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if not playerGui then
                return
            end

            local warmup = Instance.new("ImageLabel")
            warmup.Name = "DL_ImageWarmup"
            warmup.BackgroundTransparency = 1
            warmup.BorderSizePixel = 0
            warmup.Size = UDim2.fromOffset(1, 1)
            warmup.Position = UDim2.fromOffset(-10, -10)
            warmup.Visible = false
            warmup.Image = CFG.Image
            warmup.Parent = playerGui

            pcall(function()
                ContentProvider:PreloadAsync({warmup})
            end)

            if warmup.Parent then
                warmup:Destroy()
            end
        end)
    end

    local function createEffect(position)
        if not position or not DeathLightning.Enabled then
            return
        end

        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then
            return
        end

        ----------------------------------------------------------------
        -- Invisible world anchor. The BillboardGui is attached to it.
        ----------------------------------------------------------------
        local anchor = Instance.new("Part")
        anchor.Name = "DL_ImageAnchor"
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.CFrame = CFrame.new(position + Vector3.new(0, CFG.Height, 0))
        anchor.Parent = Workspace

        ----------------------------------------------------------------
        -- BillboardGui automatically faces the local camera.
        ----------------------------------------------------------------
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DL_ImageBillboard"
        billboard.Adornee = anchor
        billboard.AlwaysOnTop = CFG.AlwaysOnTop
        billboard.LightInfluence = 0
        billboard.Size = UDim2.fromOffset(CFG.StartSize, CFG.StartSize)
        billboard.StudsOffset = Vector3.zero
        billboard.MaxDistance = 10000
        billboard.ResetOnSpawn = false
        billboard.Parent = playerGui

        ----------------------------------------------------------------
        -- Actual image.
        ----------------------------------------------------------------
        local image = Instance.new("ImageLabel")
        image.Name = "DeathImage"
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.Size = UDim2.fromScale(1, 1)
        image.Position = UDim2.fromScale(0, 0)
        image.AnchorPoint = Vector2.new(0, 0)
        image.Image = CFG.Image
        image.ImageTransparency = 0
        image.ScaleType = Enum.ScaleType.Fit
        image.ResampleMode = Enum.ResamplerMode.Default
        image.ZIndex = 100
        image.Parent = billboard

        state.active[#state.active + 1] = billboard

        ----------------------------------------------------------------
        -- Stay still for 4 seconds.
        ----------------------------------------------------------------
        task.delay(CFG.HoldTime, function()
            if not billboard.Parent or not anchor.Parent then
                removeFromActive(billboard)
                if anchor.Parent then
                    anchor:Destroy()
                end
                return
            end

            if not DeathLightning.Enabled then
                removeFromActive(billboard)
                billboard:Destroy()
                if anchor.Parent then
                    anchor:Destroy()
                end
                return
            end

            local tweenInfo = TweenInfo.new(
                CFG.FadeTime,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.Out
            )

            local sizeTween = TweenService:Create(
                billboard,
                tweenInfo,
                {
                    Size = UDim2.fromOffset(CFG.EndSize, CFG.EndSize),
                }
            )

            local fadeTween = TweenService:Create(
                image,
                tweenInfo,
                {
                    ImageTransparency = 1,
                }
            )

            sizeTween:Play()
            fadeTween:Play()

            fadeTween.Completed:Once(function()
                removeFromActive(billboard)

                if billboard.Parent then
                    billboard:Destroy()
                end

                if anchor.Parent then
                    anchor:Destroy()
                end
            end)
        end)
    end

    function DeathLightning.Trigger(player, character)
        if not DeathLightning.Enabled then
            return
        end

        -- Do not exclude LocalPlayer.
        if not player then
            return
        end

        if not character or not character.Parent then
            return
        end

        local position = getDeathPosition(character)
        if not position then
            return
        end

        -- Keep the death callback itself extremely light.
        task.spawn(function()
            local ok, err = pcall(function()
                createEffect(position)
            end)

            if not ok then
                warn("[DeathLightning] createEffect failed:", err)
            end
        end)
    end

    function DeathLightning.Cleanup()
        for i = #state.active, 1, -1 do
            local billboard = state.active[i]
            state.active[i] = nil

            if billboard and billboard.Parent then
                local anchor = billboard.Adornee
                billboard:Destroy()

                if anchor and anchor.Parent then
                    anchor:Destroy()
                end
            end
        end

        -- Clean any leftovers from previous effect instances.
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name == "DL_ImageAnchor" then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end

        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, obj in ipairs(playerGui:GetChildren()) do
                if obj.Name == "DL_ImageBillboard" or obj.Name == "DL_ImageWarmup" then
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            end
        end
    end

    function DeathLightning.SetEnabled(value)
        DeathLightning.Enabled = value == true

        if DeathLightning.Enabled then
            startPreload()
        else
            DeathLightning.Cleanup()
        end
    end

    -- Kept for compatibility with the rest of the script.
    function DeathLightning.SetStormDarkness(_value)
    end
end

local DeathConnections = {}

local function getDeathPosition(character)
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    local primary = character.PrimaryPart
    return primary and primary.Position or nil
end

local function unbindDeathWatcher(plr)
    local conns = DeathConnections[plr]
    if conns then
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end
    DeathConnections[plr] = nil
end

local function bindDeathWatcher(plr)
    if not plr or DeathConnections[plr] then return end
    DeathConnections[plr] = {}

    local function bindCharacter(character)
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = character and character:WaitForChild("Humanoid", 6)
        end
        if not hum then return end

        local conn
        conn = hum.Died:Connect(function()
            local position = getDeathPosition(character)
            local role = getRole(plr)

            if State.NotifySheriffDeath and role == "Sheriff" then
                Window:Notify({
                    Title = T("sheriffDownTitle"),
                    Content = tostring(plr.DisplayName or plr.Name) .. " - " .. T("sheriffDownContent"),
                    Duration = 3.2,
                    SoundPitch = 1.08,
                })
            end

            DeathLightning.Trigger(plr, character)
        end)

        table.insert(DeathConnections[plr], conn)
    end

    if plr.Character then
        task.spawn(bindCharacter, plr.Character)
    end

    table.insert(DeathConnections[plr], plr.CharacterAdded:Connect(bindCharacter))
end

for _, plr in ipairs(Players:GetPlayers()) do
    bindDeathWatcher(plr)
end
Players.PlayerAdded:Connect(bindDeathWatcher)
Players.PlayerRemoving:Connect(function(plr)
    unbindDeathWatcher(plr)
end)

local StormGunSeen = setmetatable({}, {__mode = "k"})

local function notifyGunDrop(drop)
    if not State.NotifyGunDrop or not isExactGunDrop(drop) then return end
    if StormGunSeen[drop] then return end
    StormGunSeen[drop] = true

    Window:Notify({
        Title = T("gunDroppedTitle"),
        Content = T("gunDroppedContent"),
        Duration = 2.8,
        SoundPitch = 1.14,
    })

    task.delay(2, function()
        StormGunSeen[drop] = nil
    end)
end

local GunConnection = workspace.DescendantAdded:Connect(function(object)
    if object and object.Name == "GunDrop" and isExactGunDrop(object) then
        task.defer(notifyGunDrop, object)
    end
end)

DeathLightning.Cleanup()

Window:SetUISounds(true)

local Tabs = {
    Main   = Window:AddTab({ Title = T("tabMain"),   Icon = "main"     }),
    Combat = Window:AddTab({ Title = T("tabCombat"), Icon = "combat"   }),
    Misc   = Window:AddTab({ Title = T("tabMisc"),   Icon = "misc" }),
}
Tabs.Main:AddSection(T("sectionESP"))

Tabs.Main:AddToggle("PlayerESP", {
    Title = T("playerESP"), Default = false,
    Callback = function(value)
        State.PlayerESP = value
        if value then applyPlayerESP() else clearPlayerESP() end
    end,
})


Tabs.Main:AddSection(T("sectionGuns"))

Tabs.Main:AddToggle("AutoGrab", {
    Title = T("autoGrabGun"), Default = false,
    Callback = function(value) setAutoGrab(value) end,
})

Tabs.Main:AddSection(T("sectionNotifications"))

Tabs.Main:AddToggle("NotifyGunDrop", {
    Title = T("notifyGunDrop"), Default = false,
    Callback = function(value)
        State.NotifyGunDrop = value
    end,
})

Tabs.Main:AddToggle("NotifySheriffDeath", {
    Title = T("notifySheriffDeath"), Default = false,
    Callback = function(value)
        State.NotifySheriffDeath = value
    end,
})

Tabs.Main:AddSection(T("sectionVisuals"))

Tabs.Main:AddToggle("LightningVisuals", {
    Title = T("lightningVisuals"), Default = false,
    Callback = function(value)
        State.LightningVisuals = value == true
        DeathLightning.SetEnabled(value)
    end,
})


Tabs.Main:AddSection(T("sectionCustomization"))

Tabs.Main:AddColorpicker("AccentColor", {
    Title = T("accentColor"),
    Default = Color3.fromRGB(0, 122, 255),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Tabs.Main:AddSection(T("sectionSafePlatform"))

Tabs.Main:AddButton({ Title = T("tpSafe"), Callback = function() tpToSafe() end })
Tabs.Main:AddButton({ Title = T("tpMap"),  Callback = function() tpToMap()  end })

Tabs.Main:AddKeybind("KB_TPSafe", {
    Title = T("tpSafeMap"),
    Default = Enum.KeyCode.Y,
    Mode = "Press",
    Callback = function() toggleSafe() end,
})
Tabs.Combat:AddSection(T("sectionSilentAim"))

Tabs.Combat:AddToggle("SilentAim", {
    Title = T("silentAim"), Default = false,
    Callback = function(value)
        State.SilentAim = value
        if value then
            installSilentAimHooks()
        else
            SA.targetPlayer = nil
            SA.targetPart = nil
            SA.predictedPoint = nil
        end
    end,
})

Tabs.Combat:AddButton({
    Title = T("forceShoot"),
    Variant = "danger",
    Callback = function() forceShoot() end,
})

Tabs.Combat:AddKeybind("KB_ForceShoot", {
    Title = T("forceShoot"),
    Default = Enum.KeyCode.V,
    Mode = "Press",
    IgnoreGameProcessed = true,
    Callback = function() forceShoot() end,
})

Tabs.Combat:AddSection(T("sectionAimbot"))

Tabs.Combat:AddToggle("Aimbot", {
    Title = T("aimbot"), Default = false,
    Callback = function(value)
        State.Aimbot = value
    end,
})

Tabs.Combat:AddDropdown("AimbotPart", {
    Title = T("aimbotPart"),
    Values = {T("aimbotHead"), T("aimbotTorso")},
    Default = T("aimbotHead"),
    Callback = function(value)
        if tostring(value) == T("aimbotTorso") then
            State.AimbotPart = "Torso"
        else
            State.AimbotPart = "Head"
        end
    end,
})

Tabs.Combat:AddSection(T("sectionKillAll"))

Tabs.Combat:AddButton({
    Title = T("killAll"), Variant = "danger",
    Callback = function() killAllInstant() end,
})

Tabs.Combat:AddKeybind("KB_KillAll", {
    Title = T("killAll"),
    Default = Enum.KeyCode.K,
    Mode = "Press",
    Callback = function() killAllInstant() end,
})

Tabs.Combat:AddToggle("KillAllAuto", {
    Title = T("autoKillAll"), Default = false,
    Callback = function(value) State.KillAll = value end,
})

Tabs.Combat:AddSection(T("sectionRush"))

Tabs.Combat:AddButton({
    Title = T("behindMurderer"),
    Callback = function() behind() end,
})

Tabs.Combat:AddKeybind("KB_Behind", {
    Title = T("behindMurderer"),
    Default = Enum.KeyCode.H,
    Mode = "Press",
    Callback = function() behind() end,
})

Tabs.Combat:AddSection(T("sectionDefense"))

Tabs.Combat:AddToggle("AntiFling", {
    Title = T("antiFling"), Default = false,
    Callback = function(value)
        State.AntiFling = value
        if value then startAntiFling() else stopAntiFling() end
    end,
})

Tabs.Combat:AddSection(T("sectionFling"))

Tabs.Combat:AddToggle("FlingM", {
    Title = T("autoFlingMurderer"), Default = false,
    Callback = function(value) State.FlingM = value end,
})

Tabs.Combat:AddToggle("FlingS", {
    Title = T("autoFlingSheriff"), Default = false,
    Callback = function(value) State.FlingS = value end,
})

Tabs.Combat:AddButton({
    Title = T("flingMurderer"),
    Callback = function() task.spawn(function() flingAll("Murderer") end) end,
})

Tabs.Combat:AddKeybind("KB_FlingM", {
    Title = T("flingMurderer"),
    Default = Enum.KeyCode.F,
    Mode = "Press",
    IgnoreGameProcessed = true,
    Callback = function()
        task.spawn(function()
            flingAll("Murderer")
        end)
    end,
})

Tabs.Combat:AddButton({
    Title = T("flingSheriff"),
    Callback = function() task.spawn(function() flingAll("Sheriff") end) end,
})

Tabs.Combat:AddKeybind("KB_FlingS", {
    Title = T("flingSheriff"),
    Default = Enum.KeyCode.G,
    Mode = "Press",
    IgnoreGameProcessed = true,
    Callback = function()
        task.spawn(function()
            flingAll("Sheriff")
        end)
    end,
})
Tabs.Misc:AddSection(T("sectionMovement"))

Tabs.Misc:AddSlider("WalkSpeed", {
    Title = T("walkSpeed"), Default = 16, Min = 16, Max = 200, Rounding = 0,
    Callback = function(value) State.WalkSpeed = value end,
})

Tabs.Misc:AddSlider("JumpPower", {
    Title = T("jumpPower"), Default = 50, Min = 50, Max = 300, Rounding = 0,
    Callback = function(value) State.JumpPower = value end,
})

Tabs.Misc:AddToggle("Noclip", {
    Title = T("noclip"), Default = false,
    Callback = function(value)
        State.Noclip = value
        setNoclip(value)
    end,
})

Tabs.Misc:AddSection(T("sectionSpin"))

Tabs.Misc:AddToggle("Spin", {
    Title = T("spin"), Default = false,
    Callback = function(value) State.Spin = value end,
})

Tabs.Misc:AddSlider("SpinSpeed", {
    Title = T("spinSpeed"), Default = 500, Min = 50, Max = 3000, Rounding = 0,
    Callback = function(value) State.SpinSpeed = value end,
})

task.defer(function() pcall(installSilentAimHooks) end)
task.defer(function() pcall(installForceShootHook) end)

LP.CharacterRemoving:Connect(function()
    if Ghost.active then
        pcall(stopInvisibility)
    end
end)

Window:SelectTab(1)

local CharacterAnimationPacksController = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    local CharacterAnimationPacks = {}

    local function ids(run, walk, jump, idle1, idle2, fall, swim, swimIdle, climb, meta)
        return {
            Run = tonumber(run),
            Walk = tonumber(walk),
            Jump = tonumber(jump),
            Idle1 = tonumber(idle1),
            Idle2 = tonumber(idle2 or idle1),
            Fall = tonumber(fall),
            Swim = tonumber(swim),
            SwimIdle = tonumber(swimIdle),
            Climb = tonumber(climb),
            Rig = meta and meta.Rig or "Any",
        }
    end

    CharacterAnimationPacks = {
        ["Original"] = {
            Restore = true,
            Rig = "Any",
        },

        ["Astronaut"] = ids(
            891636393, 891636393, 891627522,
            891621366, 891633237,
            891617961, 891639666, 891663592, 891609353
        ),

        ["Bubbly"] = ids(
            910025107, 910034870, 910016857,
            910004836, 910009958,
            910001910, 910028158, 910030921, 909997997
        ),

        ["Cartoony"] = ids(
            742638842, 742640026, 742637942,
            742637544, 742638445,
            742637151, 742639220, 742639812, 742636889
        ),

        ["Elder"] = ids(
            845386501, 845403856, 845398858,
            845397899, 845400520,
            845396048, 845401742, 845403127, 845392038
        ),

        ["Knight"] = ids(
            657564596, 657552124, 658409194,
            657595757, 657568135,
            657600338, 657560551, 657557095, 658360781
        ),

        ["Levitation"] = ids(
            616010382, 616013216, 616008936,
            616006778, 616008087,
            886862142, 616005863, 616011509, 616012453
        ),

        ["Mage"] = ids(
            707861613, 707897309, 707853694,
            707742142, 707855907,
            885508740, 707829716, 707876443, 707894699
        ),

        ["Ninja"] = ids(
            656118852, 656121766, 656117878,
            656117400, 656118341,
            886742569, 656115606, 656119721, 656121397
        ),

        ["Pirate"] = ids(
            750783738, 750785693, 750782230,
            750781874, 750782770,
            885515365, 750780242, 750784579, 750785176
        ),

        ["Robot"] = ids(
            616091570, 616095330, 616090535,
            616088211, 616089559,
            885531463, 616087089, 616092998, 616094091
        ),

        ["Rthro"] = ids(
            2510198475, 2510202577, 2510197830,
            2510197257, 2510196951,
            3711062489, 2510195892, 2510199791, 2510201162
        ),

        ["Stylish"] = ids(
            616140816, 616146177, 616139451,
            616136790, 616138447,
            886888594, 616134815, 616143378, 616144772
        ),

        ["Superhero"] = ids(
            616117076, 616122287, 616115533,
            616111295, 616113536,
            885535855, 616108001, 616119360, 616120861
        ),

        ["Toy"] = ids(
            782842708, 782843345, 782847020,
            782841498, 782845736,
            980952228, 782846423, 782844582, 782845186
        ),

        ["Vampire"] = ids(
            1083462077, 1083473930, 1083455352,
            1083445855, 1083450166,
            1088037547, 1083443587, 1083464683, 1083467779
        ),

        ["Werewolf"] = ids(
            1083216690, 1083178339, 1083218792,
            1083195517, 1083214717,
            1099492820, 1083189019, 1083222527, 1083225406
        ),

        ["Zombie"] = ids(
            616163682, 616168032, 616161997,
            616158929, 616160636,
            885545458, 616157476, 616165109, 616166655
        ),
    }

    local AnimState = {
        Selected = "Original",
        Character = nil,
        Original = nil,
        Connections = {},
        Applying = false,
        ApplyToken = 0,
    }

    local AnimationPacks = {}
    for name, pack in pairs(CharacterAnimationPacks) do
        AnimationPacks[name] = pack
    end

    local AnimationPackController = {}
    AnimationPackController.__index = AnimationPackController

    local PATHS = {
        Run = { "run.RunAnim" },
        Walk = { "walk.WalkAnim" },
        Jump = { "jump.JumpAnim" },
        Idle1 = { "idle.Animation1" },
        Idle2 = { "idle.Animation2" },
        Fall = { "fall.FallAnim" },
        Swim = { "swim.Swim", "swimidle.Swim" },
        SwimIdle = { "swimidle.SwimIdle", "swimidle.SwimIdle1" },
        Climb = { "climb.ClimbAnim" },
    }

    local function disconnectAll()
        for _, connection in ipairs(AnimState.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(AnimState.Connections)
    end

    local function getCharacter(timeout)
        local deadline = os.clock() + (tonumber(timeout) or 0)
        repeat
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local animate = character:FindFirstChild("Animate")
                if humanoid and animate then
                    return character, humanoid, animate
                end
            end
            if deadline <= os.clock() then
                break
            end
            task.wait(0.05)
        until false
        return nil
    end

    local function getAnimationObject(animate, path)
        local current = animate
        for part in string.gmatch(path, "[^%.]+") do
            current = current and current:FindFirstChild(part)
        end
        if current and current:IsA("Animation") then
            return current
        end

        local wanted = path:match("[^%.]+$")
        if wanted then
            for _, descendant in ipairs(animate:GetDescendants()) do
                if descendant:IsA("Animation") and descendant.Name == wanted then
                    return descendant
                end
            end
        end
        return nil
    end

    local function captureOriginal(character)
        local animate = character and character:FindFirstChild("Animate")
        if not animate then
            return false
        end

        local original = {}
        for key, paths in pairs(PATHS) do
            local animation
            for _, path in ipairs(paths) do
                animation = getAnimationObject(animate, path)
                if animation then break end
            end
            if animation then
                original[key] = animation.AnimationId
            end
        end

        if next(original) == nil then
            return false
        end

        AnimState.Original = original
        AnimState.Character = character
        return true
    end

    local function stopCurrentTracks(humanoid)
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            return
        end

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function()
                track:Stop(0)
            end)
        end
    end

    local function setAnimateDisabled(animate, disabled)
        if animate:IsA("LocalScript") or animate:IsA("Script") then
            pcall(function()
                animate.Disabled = disabled
            end)
        end
    end

    local function restartAnimate(humanoid, animate)
        stopCurrentTracks(humanoid)
        setAnimateDisabled(animate, true)
        task.wait()
        if animate.Parent then
            setAnimateDisabled(animate, false)
        end
        task.wait()
        pcall(function()
            humanoid:ChangeState(humanoid:GetState())
        end)
    end

    local function writeIds(animate, pack)
        local changed = 0
        local expected = {}

        for key, paths in pairs(PATHS) do
            local value = tonumber(pack[key])
            if value then
                local animation
                for _, path in ipairs(paths) do
                    animation = getAnimationObject(animate, path)
                    if animation then break end
                end
                if animation then
                    local id = "rbxassetid://" .. tostring(value)
                    pcall(function() animation.AnimationId = id end)
                    expected[animation] = id
                    changed += 1
                end
            end
        end

        return changed, expected
    end

    local function verifyIds(expected)
        local count = 0
        for animation, expectedId in pairs(expected) do
            if animation and animation.Parent and animation.AnimationId == expectedId then
                count += 1
            end
        end
        return count
    end

    local function applyIds(pack, token)
        local character, humanoid, animate = getCharacter(4)
        if not character then
            return false, "Character/Animate is not ready"
        end

        if AnimState.Character ~= character or not AnimState.Original then
            if not captureOriginal(character) then
                return false, "Could not capture original animations"
            end
        end

        if token and token ~= AnimState.ApplyToken then
            return false, "Superseded"
        end

        local disabled = false
        if animate:IsA("LocalScript") or animate:IsA("Script") then
            pcall(function() animate.Disabled = true; disabled = true end)
        end

        local changed, expected = writeIds(animate, pack)
        if changed == 0 then
            if disabled and animate.Parent then pcall(function() animate.Disabled = false end) end
            return false, "No compatible animation slots found"
        end

        if disabled and animate.Parent then
            pcall(function() animate.Disabled = false end)
        end

        task.wait(0.08)
        if token and token ~= AnimState.ApplyToken then
            return false, "Superseded"
        end

        if animate.Parent then
            pcall(function() animate.Disabled = true end)
            writeIds(animate, pack)
            pcall(function() animate.Disabled = false end)
        end

        task.wait(0.08)
        if animate.Parent then
            writeIds(animate, pack)
        end

        stopCurrentTracks(humanoid)
        pcall(function() humanoid:ChangeState(humanoid:GetState()) end)

        local verified = verifyIds(expected)
        if verified < math.max(1, math.floor(changed * 0.5)) and animate.Parent then
            pcall(function() animate.Disabled = true end)
            writeIds(animate, pack)
            pcall(function() animate.Disabled = false end)
            task.wait(0.05)
            stopCurrentTracks(humanoid)
            pcall(function() humanoid:ChangeState(humanoid:GetState()) end)
            verified = verifyIds(expected)
        end

        if verified == 0 then
            return false, "Animation IDs were overwritten"
        end

        task.defer(function()
            if player.Character == character and AnimState.Selected ~= "Original" then
                pcall(function()
                    restartAnimate(humanoid, animate)
                end)
            end
        end)

        return true
    end

    local function restoreOriginal()
        local character, humanoid, animate = getCharacter(4)
        if not character then
            return false, "Character/Animate is not ready"
        end

        if AnimState.Character ~= character or not AnimState.Original then
            if not captureOriginal(character) then
                return false, "Original animation set was not captured"
            end
        end

        if not AnimState.Original then
            return false, "Original animation set was not captured"
        end

        pcall(function() animate.Disabled = true end)

        local restored = 0
        for key, paths in pairs(PATHS) do
            local originalId = AnimState.Original[key]
            if originalId then
                local animation
                for _, path in ipairs(paths) do
                    animation = getAnimationObject(animate, path)
                    if animation then break end
                end
                if animation then
                    pcall(function() animation.AnimationId = originalId end)
                    restored += 1
                end
            end
        end

        pcall(function() animate.Disabled = false end)
        task.wait(0.08)
        stopCurrentTracks(humanoid)
        pcall(function() humanoid:ChangeState(humanoid:GetState()) end)

        if restored == 0 then
            return false, "No original animation slots found"
        end

        return true
    end

    function AnimationPackController:RegisterPack(name, pack)
        assert(type(name) == "string" and name ~= "", "Animation pack name must be a string")
        assert(type(pack) == "table", "Animation pack must be a table")

        AnimationPacks[name] = {
            Run = tonumber(pack.Run),
            Walk = tonumber(pack.Walk),
            Jump = tonumber(pack.Jump),
            Idle1 = tonumber(pack.Idle1 or pack.Idle),
            Idle2 = tonumber(pack.Idle2 or pack.Idle1 or pack.Idle),
            Fall = tonumber(pack.Fall),
            Swim = tonumber(pack.Swim),
            SwimIdle = tonumber(pack.SwimIdle),
            Climb = tonumber(pack.Climb),
            Rig = pack.Rig or "Any",
        }

        return true
    end

    function AnimationPackController:GetPacks()
        local names = {}
        for name in pairs(AnimationPacks) do
            table.insert(names, name)
        end

        table.sort(names, function(a, b)
            if a == "Original" then
                return true
            end
            if b == "Original" then
                return false
            end
            return a:lower() < b:lower()
        end)

        return names
    end

    function AnimationPackController:Apply(name)
        name = tostring(name or "Original")
        local pack = AnimationPacks[name]
        if not pack then
            return false, "Unknown animation pack: " .. name
        end

        AnimState.ApplyToken += 1
        local token = AnimState.ApplyToken
        local previous = AnimState.Selected

        if pack.Restore then
            local ok, err = restoreOriginal()
            if ok then
                AnimState.Selected = "Original"
            else
                AnimState.Selected = previous
            end
            return ok, err
        end

        local ok, err = applyIds(pack, token)
        if ok then
            AnimState.Selected = name
            task.spawn(function()
                for _ = 1, 8 do
                    task.wait(0.45)
                    if AnimState.Selected ~= name or AnimState.ApplyToken ~= token or not player.Character then
                        break
                    end
                    local retryOk = false
                    pcall(function()
                        retryOk = applyIds(pack, token)
                    end)
                    if retryOk then
                        break
                    end
                end
            end)
        end

        return ok, err
    end

    function AnimationPackController:Reset()
        AnimState.ApplyToken += 1
        local ok, err = restoreOriginal()
        if ok then
            AnimState.Selected = "Original"
        end
        return ok, err
    end

    function AnimationPackController:GetSelected()
        return AnimState.Selected
    end

    function AnimationPackController:AttachCharacterLifecycle()
        disconnectAll()

        local function setup(character)
            AnimState.ApplyToken += 1
            AnimState.Character = character
            AnimState.Original = nil

            local animate = character:WaitForChild("Animate", 10)
            if not animate then
                return
            end

            task.wait(0.15)
            captureOriginal(character)

            local selected = AnimState.Selected
            if selected ~= "Original" and AnimationPacks[selected] then
                task.spawn(function()
                    task.wait(0.15)
                    if character.Parent and AnimState.Selected == selected then
                        self:Apply(selected)
                    end
                end)
            end
        end

        if player.Character then
            task.spawn(setup, player.Character)
        end

        table.insert(AnimState.Connections, player.CharacterAdded:Connect(setup))
    end

    function AnimationPackController:Build(tab)
        assert(tab and tab.AddDropdown and tab.AddButton, "A compatible Tab object is required")

        tab:AddSection(T("sectionAnimations"))

        tab:AddDropdown("CharacterAnimationPack", {
            Title = T("animationPack"),
            Values = self:GetPacks(),
            Default = self:GetSelected(),
            Callback = function(value)
                local name = tostring(value or "Original")
                local ok, err = self:Apply(name)
                if not ok and err ~= "Superseded" then
                    task.defer(function()
                        local retryOk, retryErr = self:Apply(name)
                        if not retryOk and retryErr ~= "Superseded" then
                        end
                    end)
                end
            end,
        })

        tab:AddButton({
            Title = T("resetOriginal"),
            Callback = function()
                self:Reset()
            end,
        })
    end

    return AnimationPackController
end)()

CharacterAnimationPacksController:AttachCharacterLifecycle()
CharacterAnimationPacksController:Build(Tabs.Misc)

-- ============================================================
--  CONFIG SYSTEM
-- ============================================================
local HttpService = game:GetService("HttpService")

local ConfigSystem = {
    Folder = "Netspend_Configs",
    Ext    = ".json",
    Available = false,
    Entries = {},
    Current = nil,
}

do
    local ok = pcall(function()
        if not isfolder(ConfigSystem.Folder) then
            makefolder(ConfigSystem.Folder)
        end
    end)
    ConfigSystem.Available = ok
end

local function sanitizeName(name)
    name = tostring(name or "")
    name = name:gsub("[^%w_%-%s]", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

function ConfigSystem:Register(id, kind)
    table.insert(self.Entries, { id = id, kind = kind })
end

function ConfigSystem:Save(name)
    if not self.Available then return false, "no_access" end
    name = sanitizeName(name)
    if name == "" then return false, "invalid_name" end

    local payload = { __meta = { v = 1, t = os.time(), n = name } }

    for _, entry in ipairs(self.Entries) do
        local el = Window:GetElement(entry.id)
        if el and el.GetValue then
            local ok, val = pcall(function() return el:GetValue() end)
            if ok then
                if entry.kind == "colorpicker" and typeof(val) == "Color3" then
                    payload[entry.id] = { __t = "c3", r = val.R, g = val.G, b = val.B }
                elseif entry.kind == "keybind" then
                    if typeof(val) == "EnumItem" then
                        payload[entry.id] = { __t = "k", n = val.Name }
                    else
                        payload[entry.id] = { __t = "k", n = false }
                    end
                elseif entry.kind == "dropdown" and el.GetIndex then
                    local ok2, idx = pcall(function() return el:GetIndex() end)
                    payload[entry.id] = { __t = "i", v = ok2 and idx or nil }
                else
                    payload[entry.id] = val
                end
            end
        end
    end

    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return false, "encode_failed" end

    local wok = pcall(function()
        writefile(self.Folder .. "/" .. name .. self.Ext, encoded)
    end)
    if not wok then return false, "write_failed" end

    self.Current = name
    return true
end

function ConfigSystem:Load(name)
    if not self.Available then return false, "no_access" end
    name = sanitizeName(name)
    if name == "" then return false, "invalid_name" end

    local path = self.Folder .. "/" .. name .. self.Ext
    if not isfile(path) then return false, "not_found" end

    local ok, content = pcall(function() return readfile(path) end)
    if not ok or not content then return false, "read_failed" end

    local dok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not dok or type(data) ~= "table" then return false, "decode_failed" end

    for _, entry in ipairs(self.Entries) do
        local raw = data[entry.id]
        if raw ~= nil then
            local el = Window:GetElement(entry.id)
            if el and el.SetValue then
                if type(raw) == "table" and raw.__t == "c3" then
                    pcall(function() el:SetValue(Color3.new(raw.r, raw.g, raw.b)) end)
                elseif type(raw) == "table" and raw.__t == "k" then
                    if raw.n then
                        local kok, key = pcall(function() return Enum.KeyCode[raw.n] end)
                        if kok and key then
                            pcall(function() el:SetValue(key) end)
                        end
                    else
                        pcall(function() el:SetValue(nil) end)
                    end
                elseif type(raw) == "table" and raw.__t == "i" then
                    if el.SetIndex and raw.v then
                        pcall(function() el:SetIndex(raw.v) end)
                    end
                else
                    pcall(function() el:SetValue(raw) end)
                end
            end
        end
    end

    self.Current = name
    return true
end

function ConfigSystem:Delete(name)
    if not self.Available then return false end
    name = sanitizeName(name)
    if name == "" then return false end
    local path = self.Folder .. "/" .. name .. self.Ext
    if not isfile(path) then return false end
    local ok = pcall(function() delfile(path) end)
    if ok and self.Current == name then self.Current = nil end
    return ok
end

function ConfigSystem:List()
    if not self.Available then return {} end
    local ok, files = pcall(function() return listfiles(self.Folder) end)
    if not ok or type(files) ~= "table" then return {} end
    local names = {}
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)" .. self.Ext .. "$")
        if n then table.insert(names, n) end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local ConfigTab = Window:AddTab({ Title = T("tabConfigs"), Icon = "misc" })

ConfigTab:AddSection(T("sectionConfigs"))

local configNameInput = ConfigTab:AddTextBox("ConfigNameInput", {
    Title = T("configName"),
    Placeholder = T("configNamePlaceholder"),
    Height = 34,
    Default = "",
})

ConfigTab:AddButton({
    Title = T("saveConfig"),
    Variant = "accent",
    Callback = function()
        local name = configNameInput:GetValue()
        local ok, err = ConfigSystem:Save(name)
        if ok then
            Window:Notify({
                Title = "Netspend • Config",
                Content = T("configSaved") .. ": " .. name,
                Duration = 2.5,
            })
            ConfigSystem._dropdown:SetValues(ConfigSystem:List())
            ConfigSystem._dropdown:SetValue(name)
        else
            local msg = err == "no_access" and T("configNoAccess")
                or err == "invalid_name" and T("configInvalidName")
                or tostring(err or "error")
            Window:Notify({
                Title = "Netspend • Config",
                Content = msg,
                Duration = 2.5,
                SoundPitch = 0.95,
            })
        end
    end,
})

ConfigTab:AddSection(T("sectionSaved"))

local configDropdown = ConfigTab:AddDropdown("ConfigDropdown", {
    Title = T("selectConfig"),
    Values = ConfigSystem:List(),
    Default = nil,
})
ConfigSystem._dropdown = configDropdown

ConfigTab:AddButton({
    Title = T("loadConfig"),
    Callback = function()
        local name = configDropdown:GetValue()
        if not name then
            Window:Notify({ Title = "Netspend • Config", Content = T("configSelectFirst"), Duration = 2.5 })
            return
        end
        local ok, err = ConfigSystem:Load(name)
        if ok then
            configNameInput:SetValue(name)
            Window:Notify({
                Title = "Netspend • Config",
                Content = T("configLoaded") .. ": " .. name,
                Duration = 2.5,
                SoundPitch = 1.05,
            })
        else
            Window:Notify({
                Title = "Netspend • Config",
                Content = tostring(err or "error"),
                Duration = 2.5,
                SoundPitch = 0.95,
            })
        end
    end,
})

ConfigTab:AddButton({
    Title = T("deleteConfig"),
    Variant = "danger",
    Callback = function()
        local name = configDropdown:GetValue()
        if not name then
            Window:Notify({ Title = "Netspend • Config", Content = T("configSelectFirst"), Duration = 2.5 })
            return
        end
        if ConfigSystem:Delete(name) then
            Window:Notify({
                Title = "Netspend • Config",
                Content = T("configDeleted") .. ": " .. name,
                Duration = 2.5,
                SoundPitch = 0.98,
            })
            configDropdown:SetValues(ConfigSystem:List())
            configNameInput:SetValue("")
        end
    end,
})

ConfigTab:AddButton({
    Title = T("refreshConfigs"),
    Callback = function()
        configDropdown:SetValues(ConfigSystem:List())
        Window:Notify({
            Title = "Netspend • Config",
            Content = T("configRefreshed"),
            Duration = 1.8,
        })
    end,
})

for _, entry in ipairs({
    {"PlayerESP","toggle"}, {"AutoGrab","toggle"},
    {"NotifyGunDrop","toggle"}, {"NotifySheriffDeath","toggle"},
    {"LightningVisuals","toggle"},
    {"AccentColor","colorpicker"},
    {"KB_TPSafe","keybind"},
    {"SilentAim","toggle"},
    {"KB_ForceShoot","keybind"},
    {"Aimbot","toggle"}, {"AimbotPart","dropdown"},
    {"KB_KillAll","keybind"}, {"KillAllAuto","toggle"}, {"KB_Behind","keybind"},
    {"AntiFling","toggle"}, {"FlingM","toggle"}, {"FlingS","toggle"},
    {"KB_FlingM","keybind"}, {"KB_FlingS","keybind"},
    {"WalkSpeed","slider"}, {"JumpPower","slider"}, {"Noclip","toggle"},
    {"Spin","toggle"}, {"SpinSpeed","slider"},
    {"CharacterAnimationPack","dropdown"},
}) do
    ConfigSystem:Register(entry[1], entry[2])
end

Loader:Finish(function()
    Window:SetVisible(true)
    Window:Notify({
        Title = "Netspend",
        Content = T("ready"),
        Duration = 3,
    })
end)
