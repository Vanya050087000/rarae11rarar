
-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Mouse = LocalPlayer:GetMouse()

-- Global State
local Fatality = {
    Font = Enum.Font.RobotoMono,
    Accent = Color3.fromRGB(180, 0, 255),
    Secondary = Color3.fromRGB(255, 0, 150),
    Options = {},
    ConfigFolder = "FatalityConfigs",
    Gradients = {},
    AccentObjects = {},
    Registry = {},
    Flags = {},
    IsSearching = false,
    RainbowEnabled = true,
    RainbowSpeed = 1.5
}

-- Theme Palette
local Theme = {
    Main = Color3.fromRGB(15, 15, 22),
    Sidebar = Color3.fromRGB(12, 12, 18),
    Outline = Color3.fromRGB(35, 35, 45),
    Section = Color3.fromRGB(20, 20, 28),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(160, 160, 170),
    Input = Color3.fromRGB(25, 25, 35),
    AccentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 150))
    })
}

-- Helper Functions
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function Ripple(button)
    task.spawn(function()
        local ripple = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0),
            Parent = button,
            ZIndex = button.ZIndex + 1
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ripple})
        
        local tween = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, button.AbsoluteSize.X * 1.5, 0, button.AbsoluteSize.X * 1.5),
            Position = UDim2.new(0.5, -(button.AbsoluteSize.X * 0.75), 0.5, -(button.AbsoluteSize.X * 0.75)),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        ripple:Destroy()
    end)
end

-- Initialization
if makefolder then
    pcall(makefolder, Fatality.ConfigFolder)
end

-- Theme Management
function Fatality:SetTheme(accent, secondary)
    self.Accent = accent or self.Accent
    self.Secondary = secondary or self.Secondary

    local newGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, self.Accent),
        ColorSequenceKeypoint.new(1, self.Secondary)
    })

    for _, grad in pairs(self.Gradients) do
        if grad and grad.Parent then
            grad.Color = newGradient
        end
    end

    for _, obj in pairs(self.AccentObjects) do
        if obj and obj.Parent then
            if obj:IsA("Frame") or obj:IsA("TextButton") then
                obj.BackgroundColor3 = self.Accent
            elseif obj:IsA("ScrollingFrame") then
                obj.ScrollBarImageColor3 = self.Accent
            end
        end
    end

    -- Если радуга выключена, применяем текущую тему к обводке меню
    if not self.RainbowEnabled and self.MainStroke then
        local grad = self.MainStroke:FindFirstChildOfClass("UIGradient")
        if grad then
            grad.Color = newGradient
        end
    end
end

-- Config System
function Fatality:SaveConfig(name)
    local data = {}
    for flag, option in pairs(self.Options) do
        if option.Type == "ColorPicker" then
            data[flag] = {r = option.Value.R, g = option.Value.G, b = option.Value.B}
        else
            data[flag] = option.Value
        end
    end
    
    if writefile then
        local path = self.ConfigFolder .. "/" .. name .. ".json"
        writefile(path, HttpService:JSONEncode(data))
    end
end

function Fatality:LoadConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not success then return end
        
        for flag, value in pairs(data) do
            if self.Options[flag] then
                if self.Options[flag].Type == "ColorPicker" and typeof(value) == "table" then
                    self.Options[flag]:Set(Color3.new(value.r, value.g, value.b))
                else
                    self.Options[flag]:Set(value)
                end
            end
        end
    end
end

-- Watermark System
function Fatality:AddWatermark()
    local WatermarkGui = Create("ScreenGui", {
        Name = "FatalityWatermark",
        Parent = CoreGui,
        DisplayOrder = 9999
    })

    local Frame = Create("Frame", {
        Size = UDim2.new(0, 280, 0, 24),
        Position = UDim2.new(1, -290, 0, 10),
        BackgroundColor3 = Theme.Main,
        BorderSizePixel = 0,
        Parent = WatermarkGui
    })
    Create("UIStroke", {Color = Theme.Outline, Parent = Frame})
    
    local TopBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        Parent = Frame
    })
    local Grad = Create("UIGradient", {Color = Theme.AccentGradient, Parent = TopBar})
    table.insert(self.Gradients, Grad)

    local Label = Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = "FATALITY.WIN | user: " .. LocalPlayer.Name .. " | fps: 0 | ping: 0ms",
        TextColor3 = Color3.new(1, 1, 1),
        Font = self.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame
    })

    RunService.RenderStepped:Connect(function()
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        Label.Text = string.format("FATALITY.WIN | user: %s | fps: %d | ping: %dms", LocalPlayer.Name, fps, ping)
        Frame.Size = UDim2.new(0, Label.TextBounds.X + 20, 0, 24)
        Frame.Position = UDim2.new(1, -Frame.Size.X.Offset - 10, 0, 10)
    end)
end

-- The Main Window Class
function Fatality:CreateWindow(titleText)
    local Window = {
        Tabs = {},
        Visible = true,
        CurrentTab = nil
    }

    local ScreenGui = Create("ScreenGui", {
        Name = "FatalityWin_" .. titleText,
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })

    -- Custom Mouse
    local Cursor = Create("Frame", {
        Size = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 10000,
        Parent = ScreenGui,
        Visible = false
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Cursor})

    -- Loading Screen Animation
    local Loading = Create("Frame",{
        Size = UDim2.new(0, 320, 0, 120),
        Position = UDim2.new(0.5, -160, 0.5, -60),
        BackgroundColor3 = Theme.Main,
        Parent = ScreenGui,
        ZIndex = 100
    })
    Create("UIStroke", {Color = Theme.Outline, Parent = Loading})

    local LoadingText = Create("TextLabel",{
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "FATALITY.WIN",
        Font = self.Font,
        TextSize = 24,
        TextColor3 = Color3.new(1, 1, 1),
        Parent = Loading,
        ZIndex = 101
    })

    local BarBg = Create("Frame",{
        Size = UDim2.new(0.8, 0, 0, 4),
        Position = UDim2.new(0.1, 0, 0.75, 0),
        BackgroundColor3 = Theme.Outline,
        Parent = Loading,
        ZIndex = 101
    })

    local Fill = Create("Frame",{
        Size = UDim2.new(0, 0, 1, 0),
        Parent = BarBg,
        ZIndex = 102
    })
    local FillGrad = Create("UIGradient",{Color = Theme.AccentGradient, Parent = Fill})
    table.insert(self.Gradients, FillGrad)

    -- Main Menu Frame
    local Main = Create("Frame", {
        Size = UDim2.new(0, 600, 0, 460),
        Position = UDim2.new(0.5, -300, 0.5, -230),
        BackgroundColor3 = Theme.Main,
        BorderSizePixel = 0,
        Parent = ScreenGui,
        Visible = false,
        ClipsDescendants = false
    })
    
    -- Rainbow Border Logic
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Main
    Stroke.Thickness = 3
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local StrokeGradient = Instance.new("UIGradient")
    StrokeGradient.Parent = Stroke
    StrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    })
    Fatality.MainStroke = Stroke
    Fatality.MainStrokeGradient = StrokeGradient

    task.spawn(function()
        while Main.Parent do
            if Fatality.RainbowEnabled then
                StrokeGradient.Rotation += Fatality.RainbowSpeed
            end
            task.wait(0.01)
        end
    end)

    local Sidebar = Create("Frame", {
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Main
    })

    local Logo = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "FATALITY",
        TextColor3 = Color3.new(1, 1, 1),
        Font = self.Font,
        TextSize = 20,
        Parent = Sidebar
    })
    local LogoGrad = Create("UIGradient", {Color = Theme.AccentGradient, Parent = Logo})
    table.insert(self.Gradients, LogoGrad)

    -- Search Bar Implementation
    local SearchContainer = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 55),
        BackgroundColor3 = Theme.Input,
        Parent = Sidebar
    })
    Create("UIStroke", {Color = Theme.Outline, Parent = SearchContainer})

    local SearchInput = Create("TextBox", {
        Size = UDim2.new(1, -5, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Theme.TextDark,
        Font = self.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SearchContainer
    })

    local TabContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 1, -100),
        Position = UDim2.new(0, 0, 0, 90),
        BackgroundTransparency = 1,
        Parent = Sidebar
    })
    local TabList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabContainer})

    local PageContainer = Create("Frame", {
        Size = UDim2.new(1, -150, 1, -20),
        Position = UDim2.new(0, 145, 0, 10),
        BackgroundTransparency = 1,
        Parent = Main
    })

    -- Dragging Logic
    local dragging, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Main.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    -- Finish Loading
    task.spawn(function()
        TweenService:Create(Fill, TweenInfo.new(1.8), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        task.wait(1.8)
        Loading:Destroy()
        Main.Visible = true
    end)

    -- Search Logic
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        Fatality.IsSearching = query ~= ""
        
        for _, tab in pairs(Window.Tabs) do
            for _, section in pairs(tab.Sections) do
                local sectionMatch = section.Name:lower():find(query)
                local anyElementMatch = false
                
                for _, element in pairs(section.Elements) do
                    local match = element.Name:lower():find(query) or sectionMatch
                    element.Frame.Visible = match
                    if match then anyElementMatch = true end
                end
                
                section.Frame.Visible = anyElementMatch
            end
        end
    end)

    -- Add Tab Function
    function Window:AddTab(name)
        local Tab = {Name = name, Sections = {}, Visible = false}
        
        local TabBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = name:upper(),
            TextColor3 = Theme.TextDark,
            Font = Fatality.Font,
            TextSize = 13,
            Parent = TabContainer
        })

        local Page = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 2,
            BorderSizePixel = 0,
            Parent = PageContainer
        })
        Create("UIListLayout", {Padding = UDim.new(0, 15), Parent = Page})
        Create("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), Parent = Page})
        table.insert(Fatality.AccentObjects, Page)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.TextColor3 = Theme.TextDark
            end
            Page.Visible = true
            TabBtn.TextColor3 = Theme.Text
            Window.CurrentTab = Tab
        end)

        if #TabContainer:GetChildren() <= 2 then
            Page.Visible = true
            TabBtn.TextColor3 = Theme.Text
            Window.CurrentTab = Tab
        end

        Tab.Button = TabBtn
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)

        -- Add Section Function
        function Tab:AddSection(sName)
            local Section = {Name = sName, Elements = {}}
            
            local SectionFrame = Create("Frame", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Theme.Section,
                BorderSizePixel = 0,
                Parent = Page
            })
            Create("UIStroke", {Color = Theme.Outline, Parent = SectionFrame})

            local Title = Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 16),
                Position = UDim2.new(0, 10, 0, -8),
                BackgroundColor3 = Theme.Main,
                Text = " " .. sName .. " ",
                TextColor3 = Theme.Text,
                Font = Fatality.Font,
                TextSize = 12,
                Parent = SectionFrame
            })
            Title.Size = UDim2.new(0, Title.TextBounds.X + 4, 0, 16)

            local Container = Create("Frame", {
                Size = UDim2.new(1, -20, 1, -20),
                Position = UDim2.new(0, 10, 0, 12),
                BackgroundTransparency = 1,
                Parent = SectionFrame
            })
            local Layout = Create("UIListLayout", {Padding = UDim.new(0, 8), Parent = Container})

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, -10, 0, Layout.AbsoluteContentSize.Y + 25)
                Page.CanvasSize = UDim2.new(0, 0, 0, Page.UIListLayout.AbsoluteContentSize.Y + 20)
            end)

            Section.Frame = SectionFrame
            table.insert(Tab.Sections, Section)

            -- UI Elements Generation
            local Elements = {}

            -- Toggle
            function Elements:AddToggle(text, default, flag, callback)
                local Tgl = {Value = default, Type = "Toggle", Name = text}
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Container})
                
                local Box = Create("TextButton", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = Tgl.Value and Fatality.Accent or Theme.Outline,
                    Text = "",
                    BorderSizePixel = 0,
                    Parent = Frame
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = Box})

                local Label = Create("TextLabel", {
                    Size = UDim2.new(1, -25, 1, 0),
                    Position = UDim2.new(0, 25, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame
                })

                function Tgl:Set(val)
                    Tgl.Value = val
                    Box.BackgroundColor3 = val and Fatality.Accent or Theme.Outline
                    callback(val)
                end

                Box.MouseButton1Click:Connect(function()
                    Ripple(Box)
                    Tgl:Set(not Tgl.Value)
                end)

                if flag then Fatality.Options[flag] = Tgl end
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return Tgl
            end

            -- Slider
            function Elements:AddSlider(text, min, max, default, flag, callback)
                local Sld = {Value = default, Type = "Slider", Name = text}
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Parent = Container})
                
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame
                })

                local ValText = Create("TextLabel", {
                    Size = UDim2.new(0, 40, 0, 15),
                    Position = UDim2.new(1, -40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default),
                    TextColor3 = Theme.TextDark,
                    Font = Fatality.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Frame
                })

                local Bar = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 1, -8),
                    BackgroundColor3 = Theme.Outline,
                    BorderSizePixel = 0,
                    Parent = Frame
                })

                local Fill = Create("Frame", {
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Fatality.Accent,
                    BorderSizePixel = 0,
                    Parent = Bar
                })
                table.insert(Fatality.AccentObjects, Fill)

                function Sld:Set(v)
                    v = math.clamp(v, min, max)
                    local percent = (v - min) / (max - min)
                    Sld.Value = v
                    Fill.Size = UDim2.new(percent, 0, 1, 0)
                    ValText.Text = tostring(v)
                    callback(v)
                end

                local dragging = false
                local function update()
                    local p = math.clamp((Mouse.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local v = math.floor(min + (max - min) * p)
                    Sld:Set(v)
                end

                Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update() end end)
                UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

                if flag then Fatality.Options[flag] = Sld end
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return Sld
            end

            -- Advanced Color Picker
            function Elements:AddColorPicker(text, default, flag, callback)
                local CP = {Value = default, Type = "ColorPicker", Name = text}
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Container})
                
                Create("TextLabel", {
                    Size = UDim2.new(1, -35, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame
                })

                local Preview = Create("TextButton", {
                    Size = UDim2.new(0, 24, 0, 12),
                    Position = UDim2.new(1, -28, 0.5, -6),
                    BackgroundColor3 = default,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = Frame
                })
                Create("UIStroke", {Color = Theme.Outline, Parent = Preview})

                -- Picker UI
                local PickerFrame = Create("Frame", {
                    Size = UDim2.new(0, 150, 0, 170),
                    Position = UDim2.new(1, 10, 0, 0),
                    BackgroundColor3 = Theme.Main,
                    Visible = false,
                    ZIndex = 50,
                    Parent = Preview
                })
                Create("UIStroke", {Color = Theme.Outline, Parent = PickerFrame})

                local SatFrame = Create("ImageLabel", {
                    Size = UDim2.new(0, 130, 0, 130),
                    Position = UDim2.new(0, 10, 0, 10),
                    Image = "rbxassetid://4155801252",
                    Parent = PickerFrame,
                    ZIndex = 51
                })
                
                local SatCursor = Create("Frame", {
                    Size = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 52,
                    Parent = SatFrame
                })
                Create("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Parent = SatCursor})
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SatCursor})

                local HueFrame = Create("ImageLabel", {
                    Size = UDim2.new(0, 130, 0, 10),
                    Position = UDim2.new(0, 10, 0, 150),
                    Image = "rbxassetid://3641079629",
                    Parent = PickerFrame,
                    ZIndex = 51
                })
                
                local HueCursor = Create("Frame", {
                    Size = UDim2.new(0, 2, 1, 4),
                    Position = UDim2.new(0, 0, 0, -2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 52,
                    Parent = HueFrame
                })
                Create("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Parent = HueCursor})

                local h, s, v = default:ToHSV()
                
                function CP:Set(color)
                    local nh, ns, nv = color:ToHSV()
                    h, s, v = nh, ns, nv
                    CP.Value = color
                    Preview.BackgroundColor3 = color
                    SatCursor.Position = UDim2.new(s, -2, 1 - v, -2)
                    HueCursor.Position = UDim2.new(1 - h, -1, 0, -2)
                    callback(color)
                end
                CP:Set(default)

                local draggingHue, draggingSat = false, false
                
                HueFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end end)
                SatFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSat = true end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false; draggingSat = false end end)
                
                RunService.RenderStepped:Connect(function()
                    if draggingHue then
                        h = 1 - math.clamp((Mouse.X - HueFrame.AbsolutePosition.X) / HueFrame.AbsoluteSize.X, 0, 1)
                        CP.Value = Color3.fromHSV(h, s, v)
                        Preview.BackgroundColor3 = CP.Value
                        HueCursor.Position = UDim2.new(1 - h, -1, 0, -2)
                        callback(CP.Value)
                    end
                    if draggingSat then
                        s = math.clamp((Mouse.X - SatFrame.AbsolutePosition.X) / SatFrame.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((Mouse.Y - SatFrame.AbsolutePosition.Y) / SatFrame.AbsoluteSize.Y, 0, 1)
                        CP.Value = Color3.fromHSV(h, s, v)
                        Preview.BackgroundColor3 = CP.Value
                        SatCursor.Position = UDim2.new(s, -2, 1 - v, -2)
                        callback(CP.Value)
                    end
                end)

                Preview.MouseButton1Click:Connect(function() PickerFrame.Visible = not PickerFrame.Visible end)

                if flag then Fatality.Options[flag] = CP end
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return CP
            end

            -- Keybind
            function Elements:AddKeybind(text, default, flag, callback)
                local Bind = {Value = default.Name, Type = "Keybind", Name = text}
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Container})
                
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame
                })

                local Btn = Create("TextButton", {
                    Size = UDim2.new(0, 60, 0, 16),
                    Position = UDim2.new(1, -60, 0.5, -8),
                    BackgroundColor3 = Theme.Outline,
                    Text = default.Name,
                    TextColor3 = Theme.TextDark,
                    Font = Fatality.Font,
                    TextSize = 11,
                    BorderSizePixel = 0,
                    Parent = Frame
                })

                function Bind:Set(val)
                    Bind.Value = val
                    Btn.Text = val
                    callback(Enum.KeyCode[val] or val)
                end

                local picking = false
                Btn.MouseButton1Click:Connect(function() 
                    picking = true
                    Btn.Text = "..." 
                end)

                UserInputService.InputBegan:Connect(function(i)
                    if picking and i.UserInputType == Enum.UserInputType.Keyboard then
                        picking = false
                        Bind:Set(i.KeyCode.Name)
                    end
                end)

                if flag then Fatality.Options[flag] = Bind end
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return Bind
            end

            -- Button
            function Elements:AddButton(text, callback)
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = Container})
                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Theme.Outline,
                    Text = text:upper(),
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 12,
                    BorderSizePixel = 0,
                    Parent = Frame
                })
                Create("UIStroke", {Color = Theme.Outline, Parent = Btn})

                Btn.MouseButton1Click:Connect(function()
                    Ripple(Btn)
                    callback()
                end)
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return Btn
            end
            
            -- Dropdown
            function Elements:AddDropdown(text, list, default, flag, callback)
                local Dd = {Value = default, Type = "Dropdown", Name = text}
                local Frame = Create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = Container})
                
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = Fatality.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Frame
                })

                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 1, -20),
                    BackgroundColor3 = Theme.Input,
                    Text = default,
                    TextColor3 = Theme.TextDark,
                    Font = Fatality.Font,
                    TextSize = 12,
                    BorderSizePixel = 0,
                    Parent = Frame
                })
                Create("UIStroke", {Color = Theme.Outline, Parent = Btn})

                local DropFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3 = Theme.Main,
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 100,
                    Parent = Btn
                })
                Create("UIStroke", {Color = Theme.Outline, Parent = DropFrame})
                local DropLayout = Create("UIListLayout", {Parent = DropFrame})

                local function toggle(state)
                    DropFrame.Visible = state
                    DropFrame.Size = state and UDim2.new(1, 0, 0, #list * 20) or UDim2.new(1, 0, 0, 0)
                end

                for _, val in pairs(list) do
                    local Item = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = Theme.Main,
                        Text = val,
                        TextColor3 = Theme.TextDark,
                        Font = Fatality.Font,
                        TextSize = 11,
                        BorderSizePixel = 0,
                        Parent = DropFrame,
                        ZIndex = 101
                    })
                    Item.MouseButton1Click:Connect(function()
                        Btn.Text = val
                        Dd.Value = val
                        toggle(false)
                        callback(val)
                    end)
                end

                Btn.MouseButton1Click:Connect(function() toggle(not DropFrame.Visible) end)

                function Dd:Set(val)
                    Btn.Text = val
                    Dd.Value = val
                    callback(val)
                end

                if flag then Fatality.Options[flag] = Dd end
                table.insert(Section.Elements, {Name = text, Frame = Frame})
                return Dd
            end

            return Elements
        end
        return Tab
    end

    -- Window Logic
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
            Window.Visible = not Window.Visible
            Main.Visible = Window.Visible
            Cursor.Visible = Window.Visible
        end
    end)

    RunService.RenderStepped:Connect(function()
        if Window.Visible then
            Cursor.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
        end
    end)

    return Window
end

-- Global Notifications
function Fatality:Notify(title, text, duration)
    local duration = duration or 5
    local NotifyGui = CoreGui:FindFirstChild("FatalityNotifications")
    if not NotifyGui then
        NotifyGui = Create("ScreenGui", {Name = "FatalityNotifications", Parent = CoreGui})
    end

    local Frame = Create("Frame", {
        Size = UDim2.new(0, 250, 0, 60),
        Position = UDim2.new(1, 10, 1, -70),
        BackgroundColor3 = Theme.Main,
        Parent = NotifyGui
    })
    Create("UIStroke", {Color = Theme.Outline, Parent = Frame})
    
    local Line = Create("Frame", {Size = UDim2.new(1, 0, 0, 2), Parent = Frame})
    local Grad = Create("UIGradient", {Color = Theme.AccentGradient, Parent = Line})
    table.insert(self.Gradients, Grad)

    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = title:upper(),
        TextColor3 = self.Accent,
        Font = self.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = self.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame
    })

    Frame:TweenPosition(UDim2.new(1, -260, 1, -70), "Out", "Quart", 0.5)
    task.delay(duration, function()
        Frame:TweenPosition(UDim2.new(1, 10, 1, -70), "In", "Quart", 0.5)
        task.wait(0.5); Frame:Destroy()
    end)
end

return Fatality
