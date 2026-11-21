local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local startedAt = os.clock()

pcall(function()
    local old = CoreGui:FindFirstChild("AntiAFK_Fluent")
    if old then old:Destroy() end
end)

local C = {
    bg = Color3.fromRGB(32, 32, 32),
    card = Color3.fromRGB(43, 43, 43),
    island = Color3.fromRGB(0, 0, 0),
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),
    text = Color3.fromRGB(255, 255, 255),
    muted = Color3.fromRGB(172, 172, 172),
    faint = Color3.fromRGB(128, 128, 128),
    outline = Color3.fromRGB(165, 165, 165),
    knob = Color3.fromRGB(205, 205, 205),
    knobOn = Color3.fromRGB(20, 20, 20),
    accent = Color3.fromRGB(96, 205, 255),
    green = Color3.fromRGB(108, 203, 95),
    red = Color3.fromRGB(255, 153, 164),
    violet = Color3.fromRGB(177, 140, 255),
    amber = Color3.fromRGB(255, 185, 0),
    closeRed = Color3.fromRGB(196, 43, 28),
}

local F = {
    regular = Enum.Font.BuilderSans,
    medium = Enum.Font.BuilderSansMedium,
    bold = Enum.Font.BuilderSansBold,
}

local QUAD, QUINT, BACK = Enum.EasingStyle.Quad, Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local IN, OUT = Enum.EasingDirection.In, Enum.EasingDirection.Out
local ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right

local PANEL_W, PANEL_H = 320, 284
local PANEL_SIZE = UDim2.fromOffset(PANEL_W, PANEL_H)
local PANEL_T = 0.04
local WINDOW_STROKE_T = 0.86
local CARD_STROKE_T = 0.92
local BAR_COUNT = 18
local COMPACT = UDim2.fromOffset(176, 34)
local EXPANDED = UDim2.fromOffset(304, 88)
local ISLAND_POS = UDim2.new(0.5, 0, 0, 10)

local alive = true
local state = "busy"
local antiAfkEnabled = false
local hovering = false
local expanded = false
local idleConnection, heartbeat, dragConnection
local savedPos, savedSize = Vector2.zero, Vector2.zero
local frames = 0

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, transparency)
    return make("UIStroke", {
        Color = color,
        Transparency = transparency,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function label(parent, props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or F.regular
    props.TextColor3 = props.TextColor3 or C.text
    props.TextSize = props.TextSize or 12
    props.TextXAlignment = props.TextXAlignment or ALIGN_LEFT
    return make("TextLabel", props, parent)
end

local function tween(object, duration, props, style, direction, delay)
    local animation = TweenService:Create(object, TweenInfo.new(duration, style or QUINT, direction or OUT, 0, false, delay or 0), props)
    animation:Play()
    return animation
end

local gui = make("ScreenGui", {
    Name = "AntiAFK_Fluent",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, CoreGui)

local toastStack = make("Frame", {
    Name = "Toasts",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.fromOffset(280, 196),
    BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, toastStack)

local toasts, toastOrder = {}, 0

local function dismiss(entry)
    if entry.gone then return end
    entry.gone = true
    tween(entry.card, 0.22, { Position = UDim2.fromOffset(28, 0), BackgroundTransparency = 1 }, QUAD, IN)
    tween(entry.edge, 0.22, { Transparency = 1 }, QUAD, IN)
    tween(entry.content, 0.18, { GroupTransparency = 1 }, QUAD, IN)
    task.delay(0.26, entry.holder.Destroy, entry.holder)
end

local function notify(title, message, tint)
    if not alive then return end
    toastOrder += 1
    local holder = make("Frame", {
        LayoutOrder = toastOrder,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
    }, toastStack)
    local card = make("Frame", {
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, holder)
    corner(card, 8)
    local edge = stroke(card, C.white, 1)
    local content = make("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
    }, card)
    corner(make("Frame", {
        Position = UDim2.fromOffset(10, 14),
        Size = UDim2.fromOffset(3, 32),
        BackgroundColor3 = tint or C.accent,
        BorderSizePixel = 0,
    }, content), 2)
    label(content, { Position = UDim2.fromOffset(24, 10), Size = UDim2.new(1, -36, 0, 18), Text = title, Font = F.medium, TextSize = 13 })
    label(content, { Position = UDim2.fromOffset(24, 30), Size = UDim2.new(1, -36, 0, 18), Text = message, TextColor3 = C.muted })
    local entry = { holder = holder, card = card, edge = edge, content = content }
    toasts[#toasts + 1] = entry
    while #toasts > 3 do dismiss(table.remove(toasts, 1)) end
    tween(card, 0.4, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 })
    tween(edge, 0.4, { Transparency = CARD_STROKE_T })
    tween(content, 0.3, { GroupTransparency = 0 }, QUAD, OUT, 0.05)
    task.delay(3.6, dismiss, entry)
end

local panel = make("Frame", {
    Name = "Dashboard",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = PANEL_SIZE,
    BackgroundColor3 = C.bg,
    BackgroundTransparency = PANEL_T,
    BorderSizePixel = 0,
    Active = true,
}, gui)
corner(panel, 8)
local panelStroke = stroke(panel, C.white, WINDOW_STROKE_T)
local body = make("CanvasGroup", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, panel)

local titleBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
}, body)
local appIcon = make("Frame", {
    Position = UDim2.fromOffset(14, 10),
    Size = UDim2.fromOffset(20, 20),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, titleBar)
corner(appIcon, 6)
label(appIcon, {
    Size = UDim2.fromScale(1, 1), Text = "A", Font = F.bold, TextSize = 13,
    TextColor3 = C.black, TextXAlignment = ALIGN_CENTER,
})
label(titleBar, {
    Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -130, 1, 0),
    Text = "Anti-AFK", Font = F.medium, TextSize = 13,
})

local function captionButton(offsetX, hoverColor, hoverTransparency)
    local button = make("TextButton", {
        Position = UDim2.new(1, offsetX, 0, 6),
        Size = UDim2.fromOffset(32, 28),
        BackgroundColor3 = hoverColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, body)
    corner(button, 5)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, { BackgroundTransparency = hoverTransparency }, QUAD)
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, { BackgroundTransparency = 1 }, QUAD)
    end)
    return button
end

local function glyph(parent, width, rotation)
    return make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, 1),
        BackgroundColor3 = C.text,
        BorderSizePixel = 0,
        Rotation = rotation,
    }, parent)
end

local minimizeButton = captionButton(-74, C.white, 0.9)
glyph(minimizeButton, 10, 0)
local closeButton = captionButton(-38, C.closeRed, 0)
glyph(closeButton, 14, 45)
glyph(closeButton, 14, -45)

local grid = make("Frame", {
    Position = UDim2.fromOffset(12, 44),
    Size = UDim2.new(1, -24, 0, 144),
    BackgroundTransparency = 1,
}, body)
make("UIGridLayout", {
    CellSize = UDim2.new(0.5, -4, 0, 68),
    CellPadding = UDim2.fromOffset(8, 8),
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)

local function metricCard(order, name, tint, initial)
    local card = make("Frame", {
        LayoutOrder = order,
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
    }, grid)
    corner(card, 8)
    stroke(card, C.white, CARD_STROKE_T)
    label(card, {
        Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 0, 14),
        Text = name, TextColor3 = C.muted, TextSize = 11, Font = F.medium,
    })
    local value = label(card, {
        Position = UDim2.fromOffset(12, 22), Size = UDim2.new(1, -24, 0, 24),
        Text = initial, TextSize = 19, Font = F.bold,
    })
    local graph = make("Frame", {
        Position = UDim2.new(0, 12, 1, -18),
        Size = UDim2.new(1, -24, 0, 10),
        BackgroundTransparency = 1,
    }, card)
    local bars = table.create(BAR_COUNT)
    for i = 1, BAR_COUNT do
        local bar = make("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new((i - 1) / BAR_COUNT, 0, 1, 0),
            Size = UDim2.new(1 / BAR_COUNT, -2, 0, 2),
            BackgroundColor3 = tint,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
        }, graph)
        corner(bar, 1)
        bars[i] = bar
    end
    return { value = value, bars = bars, history = {} }
end

local metrics = {
    fps = metricCard(1, "FPS", C.accent, "--"),
    ping = metricCard(2, "PING", C.violet, "-- ms"),
    players = metricCard(3, "PLAYERS", C.green, "-- / --"),
    time = metricCard(4, "SESSION", C.amber, "00:00"),
}
local metricList = { metrics.fps, metrics.ping, metrics.players, metrics.time }

local control = make("Frame", {
    Position = UDim2.fromOffset(12, 196),
    Size = UDim2.new(1, -24, 0, 56),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
}, body)
corner(control, 8)
stroke(control, C.white, CARD_STROKE_T)
label(control, {
    Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -80, 0, 18),
    Text = "Anti-AFK protection", Font = F.medium, TextSize = 13,
})
local statusText = label(control, {
    Position = UDim2.fromOffset(14, 29), Size = UDim2.new(1, -80, 0, 16),
    Text = "Idle kick protection is off", TextColor3 = C.muted, TextSize = 11,
})
local toggle = make("TextButton", {
    Name = "ToggleButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(40, 20),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
}, control)
corner(toggle, 10)
local toggleStroke = stroke(toggle, C.outline, 0)
local knob = make("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 4, 0.5, 0),
    Size = UDim2.fromOffset(12, 12),
    BackgroundColor3 = C.knob,
    BorderSizePixel = 0,
}, toggle)
corner(knob, 8)
toggle.MouseEnter:Connect(function()
    tween(knob, 0.12, { Size = UDim2.fromOffset(14, 14) }, QUAD)
end)
toggle.MouseLeave:Connect(function()
    tween(knob, 0.12, { Size = UDim2.fromOffset(12, 12) }, QUAD)
end)

label(body, {
    Position = UDim2.fromOffset(16, 262), Size = UDim2.new(1, -32, 0, 14),
    Text = "By RavenScall Project", TextColor3 = C.faint, TextSize = 11,
})

local island = make("TextButton", {
    Name = "DynamicIsland",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = ISLAND_POS,
    Size = COMPACT,
    BackgroundColor3 = C.island,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    Visible = false,
    ClipsDescendants = true,
}, gui)
local islandCorner = corner(island, 17)
stroke(island, C.white, 0.9)
local islandContent = make("CanvasGroup", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    GroupTransparency = 1,
}, island)
local islandDot = make("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0, 17),
    Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = C.faint,
    BorderSizePixel = 0,
}, islandContent)
corner(islandDot, 4)
label(islandContent, {
    Position = UDim2.fromOffset(30, 0), Size = UDim2.new(0.5, 0, 0, 34),
    Text = "Anti-AFK", Font = F.medium, TextSize = 13,
})
local islandState = label(islandContent, {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0.4, 0, 0, 34),
    Text = "Paused", TextColor3 = C.muted, TextSize = 12, Font = F.medium, TextXAlignment = ALIGN_RIGHT,
})
local islandStats = make("CanvasGroup", {
    Position = UDim2.fromOffset(14, 40),
    Size = UDim2.new(1, -28, 0, 36),
    BackgroundTransparency = 1,
    GroupTransparency = 1,
}, islandContent)

local function islandStat(index, name)
    local cell = make("Frame", {
        Position = UDim2.fromScale((index - 1) / 4, 0),
        Size = UDim2.fromScale(0.25, 1),
        BackgroundTransparency = 1,
    }, islandStats)
    label(cell, {
        Size = UDim2.new(1, 0, 0, 12), Text = name, TextColor3 = C.faint, TextSize = 10, Font = F.medium,
    })
    return label(cell, {
        Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 20),
        Text = "--", TextSize = 14, Font = F.bold,
    })
end

local islandValues = {
    fps = islandStat(1, "FPS"),
    ping = islandStat(2, "PING"),
    players = islandStat(3, "PLAYERS"),
    time = islandStat(4, "SESSION"),
}

local pulse = TweenService:Create(
    islandDot,
    TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { BackgroundTransparency = 0.6 }
)

local function shutdown()
    if not alive then return end
    alive = false
    antiAfkEnabled = false
    if idleConnection then idleConnection:Disconnect(); idleConnection = nil end
    if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
    if dragConnection then dragConnection:Disconnect(); dragConnection = nil end
    pulse:Cancel()
end

gui.Destroying:Connect(shutdown)

local function setAntiAfk(enabled)
    if not alive or antiAfkEnabled == enabled then return end
    antiAfkEnabled = enabled
    if enabled then
        idleConnection = player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
        pulse:Play()
    else
        if idleConnection then idleConnection:Disconnect(); idleConnection = nil end
        pulse:Cancel()
        islandDot.BackgroundTransparency = 0
    end
    statusText.Text = enabled and "Idle kick protection is on" or "Idle kick protection is off"
    islandState.Text = enabled and "Active" or "Paused"
    islandState.TextColor3 = enabled and C.green or C.muted
    tween(toggle, 0.2, { BackgroundTransparency = enabled and 0 or 1 }, QUAD)
    tween(toggleStroke, 0.2, { Transparency = enabled and 1 or 0 }, QUAD)
    tween(knob, 0.26, {
        AnchorPoint = Vector2.new(enabled and 1 or 0, 0.5),
        Position = UDim2.new(enabled and 1 or 0, enabled and -4 or 4, 0.5, 0),
        BackgroundColor3 = enabled and C.knobOn or C.knob,
    })
    tween(islandDot, 0.2, { BackgroundColor3 = enabled and C.green or C.faint }, QUAD)
    notify(enabled and "Anti-AFK enabled" or "Anti-AFK paused", enabled and "Idle protection is active." or "Idle protection is off.", enabled and C.green or C.red)
end

toggle.Activated:Connect(function() setAntiAfk(not antiAfkEnabled) end)

local function pushSample(metric, value, scale)
    local history = metric.history
    history[#history + 1] = math.clamp(value / math.max(scale, 1), 0.15, 1)
    if #history > BAR_COUNT then table.remove(history, 1) end
end

local function renderGraph(metric)
    local history, bars = metric.history, metric.bars
    local shift = BAR_COUNT - #history
    for i = shift + 1, BAR_COUNT do
        local sample = history[i - shift]
        local bar = bars[i]
        bar.Size = UDim2.new(1 / BAR_COUNT, -2, 0, math.max(2, math.floor(sample * 10 + 0.5)))
        bar.BackgroundTransparency = 0.1 + (1 - sample) * 0.5
    end
end

local function setExpanded(value)
    if state ~= "island" or expanded == value then return end
    expanded = value
    local style = value and BACK or QUINT
    tween(island, value and 0.42 or 0.3, { Size = value and EXPANDED or COMPACT }, style)
    tween(islandCorner, 0.34, { CornerRadius = UDim.new(0, value and 24 or 17) }, style)
    tween(islandStats, value and 0.28 or 0.1, { GroupTransparency = value and 0 or 1 }, QUAD, OUT, value and 0.1 or 0)
end

local function minimizeDashboard()
    if state ~= "open" then return end
    state = "busy"
    savedPos, savedSize = panel.AbsolutePosition, panel.AbsoluteSize
    tween(body, 0.12, { GroupTransparency = 1 }, QUAD)
    task.delay(0.12, function()
        if not alive then return end
        panel.Visible = false
        islandStats.GroupTransparency = 1
        islandContent.GroupTransparency = 1
        island.Size = UDim2.fromOffset(savedSize.X, savedSize.Y)
        island.Position = UDim2.fromOffset(savedPos.X + savedSize.X / 2, savedPos.Y)
        island.BackgroundColor3 = C.bg
        island.BackgroundTransparency = PANEL_T
        islandCorner.CornerRadius = UDim.new(0, 8)
        island.Visible = true
        tween(island, 0.5, {
            Size = COMPACT,
            Position = ISLAND_POS,
            BackgroundColor3 = C.island,
            BackgroundTransparency = 0,
        })
        tween(islandCorner, 0.5, { CornerRadius = UDim.new(0, 17) })
        tween(islandContent, 0.25, { GroupTransparency = 0 }, QUAD, OUT, 0.2)
        task.delay(0.52, function()
            if not alive then return end
            state = "island"
            if hovering then setExpanded(true) end
        end)
    end)
end

local function restoreDashboard()
    if state ~= "island" then return end
    state = "busy"
    expanded = false
    hovering = false
    tween(islandStats, 0.1, { GroupTransparency = 1 }, QUAD)
    tween(islandContent, 0.16, { GroupTransparency = 1 }, QUAD)
    tween(island, 0.42, {
        Size = UDim2.fromOffset(savedSize.X, savedSize.Y),
        Position = UDim2.fromOffset(savedPos.X + savedSize.X / 2, savedPos.Y),
        BackgroundColor3 = C.bg,
        BackgroundTransparency = PANEL_T,
    })
    tween(islandCorner, 0.42, { CornerRadius = UDim.new(0, 8) })
    task.delay(0.36, function()
        if not alive then return end
        for i = 1, #metricList do renderGraph(metricList[i]) end
        body.GroupTransparency = 1
        panel.Visible = true
        island.Visible = false
        tween(body, 0.22, { GroupTransparency = 0 }, QUAD)
        state = "open"
    end)
end

local function closeDashboard()
    if state ~= "open" then return end
    state = "closing"
    shutdown()
    tween(body, 0.14, { GroupTransparency = 1 }, QUAD)
    tween(panel, 0.2, { Size = UDim2.fromOffset(PANEL_W - 16, PANEL_H - 16), BackgroundTransparency = 1 }, QUAD, IN)
    tween(panelStroke, 0.2, { Transparency = 1 }, QUAD)
    task.delay(0.24, gui.Destroy, gui)
end

minimizeButton.Activated:Connect(minimizeDashboard)
closeButton.Activated:Connect(closeDashboard)
island.Activated:Connect(restoreDashboard)

island.MouseEnter:Connect(function()
    hovering = true
    setExpanded(true)
end)
island.MouseLeave:Connect(function()
    hovering = false
    task.delay(0.08, function()
        if not hovering then setExpanded(false) end
    end)
end)

titleBar.InputBegan:Connect(function(input)
    local kind = input.UserInputType
    if state ~= "open" or (kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch) then return end
    local origin, base = input.Position, panel.Position
    if dragConnection then dragConnection:Disconnect() end
    dragConnection = UserInputService.InputChanged:Connect(function(change)
        local changeKind = change.UserInputType
        if changeKind ~= Enum.UserInputType.MouseMovement and changeKind ~= Enum.UserInputType.Touch then return end
        local view = gui.AbsoluteSize
        local limitX = math.max((view.X - PANEL_W) / 2, 0)
        local limitY = math.max((view.Y - PANEL_H) / 2, 0)
        local delta = change.Position - origin
        panel.Position = UDim2.new(
            0.5, math.clamp(base.X.Offset + delta.X, -limitX, limitX),
            0.5, math.clamp(base.Y.Offset + delta.Y, -limitY, limitY)
        )
    end)
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End and dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end)
end)

local pingItem
pcall(function()
    pingItem = Stats.Network.ServerStatsItem["Data Ping"]
end)

local function readPing()
    if not pingItem then return nil end
    local ok, result = pcall(pingItem.GetValue, pingItem)
    if ok and type(result) == "number" then return math.floor(result + 0.5) end
    return nil
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = seconds // 3600
    local minutes = seconds % 3600 // 60
    local secs = seconds % 60
    if hours > 0 then return string.format("%02d:%02d:%02d", hours, minutes, secs) end
    return string.format("%02d:%02d", minutes, secs)
end

heartbeat = RunService.Heartbeat:Connect(function()
    frames += 1
end)

task.spawn(function()
    local lastTick = os.clock()
    local interval = 0.3
    while alive do
        task.wait(interval)
        interval = 1
        if not alive then break end
        local now = os.clock()
        local fps = math.floor(frames / math.max(now - lastTick, 0.001) + 0.5)
        frames, lastTick = 0, now
        local ping = readPing()
        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local elapsed = now - startedAt
        local fpsText = tostring(fps)
        local pingText = ping and (ping .. " ms") or "N/A"
        local playersText = string.format("%d / %s", playerCount, maxPlayers > 0 and tostring(maxPlayers) or "?")
        local timeText = formatTime(elapsed)
        pushSample(metrics.fps, fps, 120)
        if ping then pushSample(metrics.ping, ping, 250) end
        pushSample(metrics.players, playerCount, math.max(maxPlayers, 20))
        pushSample(metrics.time, elapsed % 60, 60)
        if panel.Visible then
            metrics.fps.value.Text = fpsText
            metrics.ping.value.Text = pingText
            metrics.players.value.Text = playersText
            metrics.time.value.Text = timeText
            for i = 1, #metricList do renderGraph(metricList[i]) end
        end
        if island.Visible then
            islandValues.fps.Text = fpsText
            islandValues.ping.Text = pingText
            islandValues.players.Text = playersText
            islandValues.time.Text = timeText
        end
    end
end)

panel.Size = UDim2.fromOffset(PANEL_W - 24, PANEL_H - 24)
panel.BackgroundTransparency = 1
panelStroke.Transparency = 1
body.GroupTransparency = 1
tween(panel, 0.45, { Size = PANEL_SIZE, BackgroundTransparency = PANEL_T })
tween(panelStroke, 0.3, { Transparency = WINDOW_STROKE_T })
tween(body, 0.3, { GroupTransparency = 0 }, QUAD, OUT, 0.08)
task.delay(0.45, function()
    if state == "busy" then state = "open" end
end)

notify("Dashboard ready", "Live server metrics are running.", C.accent)
print("Anti-AFK Fluent dashboard loaded · RavenScall Project")
