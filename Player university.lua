local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

-- ลบ UI หน้าต่างเลือกเก่าทิ้งก่อน (ถ้ามี)
if playerGui:FindFirstChild("ScriptHubSelector") then
    playerGui.ScriptHubSelector:Destroy()
end

-- สร้าง ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptHubSelector"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- สร้างหน้าต่างหลัก (Window)
local window = Instance.new("Frame")
window.Size = UDim2.fromOffset(340, 310)
window.Position = UDim2.new(0.5, -170, 0.5, -155)
window.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
window.BorderSizePixel = 0
window.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = window

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(168, 85, 247)
stroke.Thickness = 1.5
stroke.Transparency = 0.2
stroke.Parent = window

-- หัวข้อหน้าต่าง
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "⚡ PLAYERHUB SELECTOR"
title.TextColor3 = Color3.fromRGB(240, 242, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = window

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, 0, 0, 20)
subTitle.Position = UDim2.fromOffset(0, 32)
subTitle.BackgroundTransparency = 1
subTitle.Text = "กรุณาเลือกสคริปต์ที่ต้องการใช้งาน"
subTitle.TextColor3 = Color3.fromRGB(135, 140, 175)
subTitle.Font = Enum.Font.Gotham
subTitle.TextSize = 11
subTitle.Parent = window

-- พื้นที่ใส่ปุ่มเลือกสคริปต์
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -30, 1, -75)
container.Position = UDim2.fromOffset(15, 65)
container.BackgroundTransparency = 1
container.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = container

-- ฟังก์ชันสร้างปุ่มกดเลือกสคริปต์
local function createScriptButton(name, desc, scriptUrl, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 56)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.LayoutOrder = order
    btn.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(56, 56, 84)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.4
    btnStroke.Parent = btn

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -20, 0, 20)
    nameLbl.Position = UDim2.fromOffset(12, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = btn

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -20, 0, 18)
    descLbl.Position = UDim2.fromOffset(12, 28)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc
    descLbl.TextColor3 = Color3.fromRGB(135, 140, 175)
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Parent = btn

    -- เอฟเฟกต์ตอนกดเลือก
    btn.MouseButton1Click:Connect(function()
        -- เล่นอนิเมชันปิดหน้าต่างแบบนุ่มนวล
        TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.2)
        screenGui:Destroy() -- ลบหน้าต่างเลือกทิ้ง

        -- โหลดสคริปต์ที่เลือกผ่าน loadstring
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptUrl))()
        end)
        
        if not success then
            warn("Failed to load script: " .. tostring(err))
        end
    end)
end

-- เพิ่มปุ่มสคริปต์ทั้ง 3 ตัวตามที่คุณต้องการ
createScriptButton("⚡ PlayerHUB Main", "เปิดใช้งานสคริปต์ศูนย์กลางหลัก", "https://raw.githubusercontent.com/Petch25-1/PlayerHUB/refs/heads/main/PlayerHUB.lua", 1)
createScriptButton("🔪 MM2 Edition (Final)", "เปิดใช้งานสคริปต์โปรไฟล์เกม MM2", "https://raw.githubusercontent.com/Petch25-1/PlayerHUB/refs/heads/main/MM2.lua", 2)
createScriptButton("🛠️ Dumper Utility", "เปิดใช้งานเครื่องมือเสริม Dumper", "https://raw.githubusercontent.com/Petch25-1/PlayerHUB/refs/heads/main/Dumper.lua", 3)
