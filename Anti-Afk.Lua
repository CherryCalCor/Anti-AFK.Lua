-- [[ Anti-AFK Script with Modern GUI & Notifications ]] --
-- [[ Created for CalCor 🍒 ]] --

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Создание основного ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiAFK_CalCor_Pro"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- [[ ФУНКЦИЯ УВЕДОМЛЕНИЙ ]] --
local function sendNotification(message, color)
    local NotifFrame = Instance.new("Frame")
    local NotifCorner = Instance.new("UICorner")
    local NotifText = Instance.new("TextLabel")
    local NotifStroke = Instance.new("UIStroke")

    NotifFrame.Parent = ScreenGui
    NotifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    NotifFrame.BackgroundTransparency = 0.2
    NotifFrame.BorderSizePixel = 0
    -- Начальная позиция (за пределами экрана справа)
    NotifFrame.Position = UDim2.new(1, 10, 0.85, 0)
    NotifFrame.Size = UDim2.new(0, 200, 0, 50)

    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame

    NotifStroke.Thickness = 2
    NotifStroke.Color = color
    NotifStroke.Parent = NotifFrame

    NotifText.Parent = NotifFrame
    NotifText.BackgroundTransparency = 1
    NotifText.Size = UDim2.new(1, 0, 1, 0)
    NotifText.Font = Enum.Font.GothamBold
    NotifText.Text = message
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.TextSize = 14

    -- Анимация появления (выезд влево)
    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -210, 0.85, 0)
    }):Play()

    -- Исчезновение через 3 секунды
    task.delay(3, function()
        local tweenOut = TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 10, 0.85, 0),
            BackgroundTransparency = 1
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            NotifFrame:Destroy()
        end)
    end)
end

-- [[ ОСНОВНОЕ GUI ]] --
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Position = UDim2.new(0.5, -75, 0.5, -50)
MainFrame.Size = UDim2.new(0, 150, 0, 100)
MainFrame.Active = true
MainFrame.Draggable = true 

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ToggleButton.Position = UDim2.new(0.1, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0.8, 0, 0.4, 0)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "Anti-AFK: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 100, 100)
ToggleButton.TextSize = 14
ToggleButton.AutoButtonColor = true

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ToggleButton

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Name = "CreditLabel"
CreditLabel.Parent = MainFrame
CreditLabel.BackgroundTransparency = 1
CreditLabel.Position = UDim2.new(0, 0, 0.7, 0)
CreditLabel.Size = UDim2.new(1, 0, 0.25, 0)
CreditLabel.Font = Enum.Font.GothamMedium
CreditLabel.Text = "By CalCor 🍒"
CreditLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CreditLabel.TextSize = 12

-- [[ ЛОГИКА ]] --
local antiAfkEnabled = false
local connection

local function toggleAntiAfk()
    antiAfkEnabled = not antiAfkEnabled
    
    if antiAfkEnabled then
        ToggleButton.Text = "Anti-AFK: ON"
        ToggleButton.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Уведомление
        sendNotification("Anti-AFK Включен ✅", Color3.fromRGB(100, 255, 100))
        
        connection = player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        ToggleButton.Text = "Anti-AFK: OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Уведомление
        sendNotification("Anti-AFK Выключен ❌", Color3.fromRGB(255, 100, 100))
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

ToggleButton.MouseButton1Click:Connect(toggleAntiAfk)

print("Anti-AFK Loaded. Created for CalCor 🍒 (UTF-8 Ready)")
