-- [[ Anti-AFK Script with Modern GUI ]] --
-- [[ Created for CalCor 🍒 ]] --

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- Создание UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiAFK_CalCor"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -75, 0.5, -50)
MainFrame.Size = UDim2.new(0, 150, 0, 100)
MainFrame.Active = true
MainFrame.Draggable = true -- Позволяет двигать GUI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

-- Заголовок/Кнопка
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.BackgroundTransparency = 0.3
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

-- Подпись
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

-- Логика Anti-AFK
local antiAfkEnabled = false
local connection

local function toggleAntiAfk()
    antiAfkEnabled = not antiAfkEnabled
    
    if antiAfkEnabled then
        ToggleButton.Text = "Anti-AFK: ON"
        ToggleButton.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Подключаем событие
        connection = player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        ToggleButton.Text = "Anti-AFK: OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

ToggleButton.MouseButton1Click:Connect(toggleAntiAfk)

-- Уведомление в консоль (опционально)
print("Anti-AFK Loaded. Created for CalCor 🍒")
