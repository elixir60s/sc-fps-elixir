if getgenv().Library then
    getgenv().Library:Unload()
end

local Library do 
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local Vector2New = Vector2.new

    local MathClamp = math.clamp
    local MathFloor = math.floor

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub

    local InstanceNew = Instance.new

    Library = {
        Theme =  { },
        MenuKeybind = tostring(Enum.KeyCode.Z),
        Flags = { },
        Tween = {
            Time = 0.25,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out
        },
        FadeSpeed = 0.2,
        Folders = {
            Directory = "MULTIFARM",
            Configs = "MULTIFARM/Configs",
            Assets = "MULTIFARM/Assets",
        },
        Pages = { },
        Sections = { },
        Connections = { },
        Threads = { },
        ThemeMap = { },
        ThemeItems = { },
        OpenFrames = { },
        SetFlags = { },
        UnnamedConnections = 0,
        UnnamedFlags = 0,
        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,
        Font = nil
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Themes = {
        ["Preset"] = {
            ["Background"] = FromRGB(13, 15, 18),
            ["Inline"] = FromRGB(22, 25, 30),
            ["Outline"] = FromRGB(26, 30, 36),
            ["Text"] = FromRGB(200, 200, 200),
            ["Dark Text"] = FromRGB(100, 100, 100),
            ["Element"] = FromRGB(28, 32, 38),
            ["Accent"] = FromRGB(184, 212, 255)
        }
    }

    Library.Theme = TableClone(Themes["Preset"])

    -- Folders
    for Index, Value in Library.Folders do 
        if not isfolder(Value) then
            makefolder(Value)
        end
    end

    -- Tweening
    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()
            setmetatable(NewTween, Tween)
            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item 
            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item 
            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then 
                    task.wait()
                    Item[Property] = OldTransparency
                end
            end)
            return NewTween
        end

        Tween.Pause = function(self)
            if not self.Tween then return end
            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then return end
            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then return end
            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }
            setmetatable(NewItem, Instances)
            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end
            return NewItem
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then return end
            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then return end
            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then return end
            if not self.Instance[Event] then return end
            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then return end
            return Tween:Create(self, Info, Goal)
        end

        Instances.Clean = function(self)
            if not self.Instance then return end
            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then return end
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 

            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y
                local ScreenSize = Gui.Parent.AbsoluteSize
                local GuiSize = Gui.AbsoluteSize
                NewX = MathClamp(NewX, 0, ScreenSize.X - GuiSize.X)
                NewY = MathClamp(NewY, 0, ScreenSize.Y - GuiSize.Y)
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, NewX, 0, NewY)})
            end

            local InputChanged
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
                    if InputChanged then return end
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then Set(Input) end
                end
            end)
            return Dragging
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then return end
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then return end
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then 
                writefile(Data.Id, game:HttpGet(Data.Url))
            end
            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }
            writefile(`{Library.Folders.Assets}/{Name}.font`, HttpService:JSONEncode(Data))
            return Font.new(getcustomasset(`{Library.Folders.Assets}/{Name}.font`))
        end

        Library.Font = CustomFont:New("InterSemiBold", 400, "Regular", {
            Id = "InterSemiBold",
            Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/InterSemibold.ttf"
        })
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = UDim2New(0, 0, 1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })

    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            Value.Connection:Disconnect()
        end
        for Index, Value in self.Threads do 
            coroutine.close(Value)
        end
        if self.Holder then 
            self.Holder:Clean()
        end
        Library = nil 
        getgenv().Library = nil
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()
        TableInsert(self.Threads, NewThread)
        return NewThread
    end

    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))
        if not Success then
            warn(Result)
            return false
        end
        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))
        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }
        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)
        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s_%s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item 
        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }
        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end
        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    Library.ToRich = function(self, Text, Color)
        return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
    end

    Library.GetConfig = function(self)
        local Config = { } 
        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)
        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)
        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do 
                local SetFunction = Library.SetFlags[Index]
                if not SetFunction then continue end
                if type(Value) == "table" and Value.Key then 
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)
        return Success, Result
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then 
            delfile(Library.Folders.Configs .. "/" .. Config)
        end
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item
        if not self.ThemeMap[Item] then return end
        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color
        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    Library.IsMouseOverFrame = function(self, Frame)
        Frame = Frame.Instance
        local MousePosition = Vector2New(Mouse.X, Mouse.Y)
        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.Lerp = function(self, Start, Finish, Time)
        return Start + (Finish - Start) * Time
    end

    Library.CompareVectors = function(self, PointA, PointB)
        return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
    end

    Library.IsClipped = function(self, Object, Column)
        local Parent = Column
        local BoundryTop = Parent.AbsolutePosition
        local BoundryBottom = BoundryTop + Parent.AbsoluteSize
        local Top = Object.AbsolutePosition
        local Bottom = Top + Object.AbsoluteSize 
        return Library:CompareVectors(Top, BoundryTop) or Library:CompareVectors(BoundryBottom, Bottom)
    end

    -- ============================================
    -- WINDOW
    -- ============================================

    Library.Window = function(self, Data)
        Data = Data or { }

        local Window = {
            Name = Data.Name or "ELIXIRPROJECTION",
            SubName = Data.SubName or "MULTIFARM",
            Logo = Data.Logo or "",
            Pages = { },
            Items = { },
            IsOpen = false
        }

        local Items = { } do
            Items["MainFrame"] = Instances:Create("Frame", {
                Parent = Library.Holder.Instance,
                Name = "\0",
                AnchorPoint = Vector2New(0.5, 0.5),
                Position = UDim2New(0.5, 0, 0.5, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 500, 0, 400),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(13, 15, 18)
            })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})

            Items["MainFrame"]:MakeDraggable()

            Instances:Create("UICorner", {
                Parent = Items["MainFrame"].Instance,
                Name = "\0",
                CornerRadius = UDimNew(0, 6)
            })
            
            Items["Top"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 45),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(22, 25, 30)
            })  Items["Top"]:AddToTheme({BackgroundColor3 = "Inline"})
            
            Instances:Create("UICorner", {
                Parent = Items["Top"].Instance,
                Name = "\0",
                CornerRadius = UDimNew(0, 6)
            })

            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["Top"].Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(200, 200, 200),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Window.Name,
                Size = UDim2New(1, -100, 0, 20),
                Position = UDim2New(0, 12, 0, 4),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

            Items["SubTitle"] = Instances:Create("TextLabel", {
                Parent = Items["Top"].Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(100, 100, 100),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Window.SubName,
                Size = UDim2New(1, -100, 0, 16),
                Position = UDim2New(0, 12, 0, 25),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["SubTitle"]:AddToTheme({TextColor3 = "Dark Text"})

            Items["CloseBtn"] = Instances:Create("TextButton", {
                Parent = Items["Top"].Instance,
                Name = "\0",
                Size = UDim2New(0, 30, 0, 30),
                Position = UDim2New(1, -38, 0.5, -15),
                BackgroundTransparency = 1,
                Text = "✕",
                TextColor3 = FromRGB(100, 100, 100),
                TextSize = 16,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
            })  Items["CloseBtn"]:AddToTheme({TextColor3 = "Dark Text"})

            Items["CloseBtn"]:Connect("MouseButton1Click", function()
                Items["MainFrame"].Instance.Visible = not Items["MainFrame"].Instance.Visible
                Window.IsOpen = Items["MainFrame"].Instance.Visible
            end)

            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                Name = "\0",
                ClipsDescendants = true,
                BorderColor3 = FromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 45),
                Size = UDim2New(1, 0, 1, -45),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })

            Items["Page"] = Instances:Create("Frame", {
                Parent = Items["Content"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["Page"].Instance,
                Name = "\0",
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Padding = UDimNew(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill
            })

            Items["LeftColumn"] = Instances:Create("ScrollingFrame", {
                Parent = Items["Page"].Instance,
                Name = "\0",
                ScrollBarImageColor3 = FromRGB(0, 0, 0),
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0,
                BackgroundTransparency = 1,
                Size = UDim2New(0.5, -6, 1, 0),
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0,
                CanvasSize = UDim2New(0, 0, 0, 0)
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["LeftColumn"].Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, 8),
                PaddingBottom = UDimNew(0, 8),
                PaddingRight = UDimNew(0, 1),
                PaddingLeft = UDimNew(0, 8)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["LeftColumn"].Instance,
                Name = "\0",
                Padding = UDimNew(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })        
            
            Items["RightColumn"] = Instances:Create("ScrollingFrame", {
                Parent = Items["Page"].Instance,
                Name = "\0",
                ScrollBarImageColor3 = FromRGB(0, 0, 0),
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0,
                BackgroundTransparency = 1,
                Size = UDim2New(0.5, -6, 1, 0),
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0,
                CanvasSize = UDim2New(0, 0, 0, 0)
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["RightColumn"].Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, 8),
                PaddingBottom = UDimNew(0, 1),
                PaddingRight = UDimNew(0, 8),
                PaddingLeft = UDimNew(0, 8)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["RightColumn"].Instance,
                Name = "\0",
                Padding = UDimNew(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Window.Items = Items
        end

        function Window:SetOpen(Bool)
            Window.IsOpen = Bool
            Items["MainFrame"].Instance.Visible = Bool
        end

        Window:SetOpen(true)
        return setmetatable(Window, Library)
    end

    -- ============================================
    -- PAGE
    -- ============================================

    Library.Page = function(self, Data)
        Data = Data or { }

        local Page = {
            Window = self,
            Name = Data.Name or "Page",
            Icon = Data.Icon or "",
            Items = { },
            Active = false
        }

        local Items = { } do
            Items["Page"] = Instances:Create("Frame", {
                Parent = Page.Window.Items["Content"].Instance,
                Name = "\0",
                Visible = true,
                BackgroundTransparency = 1,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })

            Page.Items = Items
        end

        function Page:Section(Data)
            Data = Data or { }

            local Section = {
                Name = Data.Name or "Section",
                Icon = Data.Icon or "",
                Side = Data.Side or 1,
                Items = { },
                Page = Page,
            }

            local Column = Section.Side == 1 and Page.Window.Items["LeftColumn"] or Page.Window.Items["RightColumn"]

            local SectionFrame = Instances:Create("Frame", {
                Parent = Column.Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 0),
                BackgroundColor3 = FromRGB(22, 25, 30),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
            })  SectionFrame:AddToTheme({BackgroundColor3 = "Inline"})

            Instances:Create("UICorner", {
                Parent = SectionFrame.Instance,
                Name = "\0",
                CornerRadius = UDimNew(0, 6)
            })

            Instances:Create("UIStroke", {
                Parent = SectionFrame.Instance,
                Name = "\0",
                Color = FromRGB(26, 30, 36),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"})

            local SectionTitle = Instances:Create("TextLabel", {
                Parent = SectionFrame.Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(200, 200, 200),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Section.Name,
                Size = UDim2New(1, -20, 0, 25),
                Position = UDim2New(0, 10, 0, 6),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  SectionTitle:AddToTheme({TextColor3 = "Text"})

            local SectionContent = Instances:Create("Frame", {
                Parent = SectionFrame.Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 0),
                Position = UDim2New(0, 0, 0, 35),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            })

            Instances:Create("UIListLayout", {
                Parent = SectionContent.Instance,
                Name = "\0",
                Padding = UDimNew(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Instances:Create("UIPadding", {
                Parent = SectionContent.Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, 4),
                PaddingBottom = UDimNew(0, 8),
                PaddingRight = UDimNew(0, 6),
                PaddingLeft = UDimNew(0, 6)
            })

            Section.Items = SectionContent

            -- ============================================
            -- TOGGLE
            -- ============================================
            function Section:Toggle(Data)
                local Toggle = {
                    Name = Data.Name or "Toggle",
                    Flag = Data.Flag or Library:NextFlag(),
                    Default = Data.Default or false,
                    Value = Data.Default or false,
                    Callback = Data.Callback or function() end,
                    Instance = nil,
                    Section = Section,
                }

                local ToggleFrame = Instances:Create("Frame", {
                    Parent = SectionContent.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                })

                local ToggleLabel = Instances:Create("TextLabel", {
                    Parent = ToggleFrame.Instance,
                    Name = "\0",
                    Size = UDim2New(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Toggle.Name,
                    TextColor3 = FromRGB(200, 200, 200),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })  ToggleLabel:AddToTheme({TextColor3 = "Text"})

                local ToggleBtn = Instances:Create("TextButton", {
                    Parent = ToggleFrame.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 45, 0, 22),
                    Position = UDim2New(1, -50, 0.5, -11),
                    BackgroundColor3 = Toggle.Default and FromRGB(100, 200, 100) or FromRGB(60, 60, 70),
                    Text = Toggle.Default and "ON" or "OFF",
                    TextColor3 = FromRGB(255, 255, 255),
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                })

                Instances:Create("UICorner", {
                    Parent = ToggleBtn.Instance,
                    Name = "\0",
                    CornerRadius = UDim.new(1, 0)
                })

                Toggle.Instance = ToggleBtn

                ToggleBtn:Connect("MouseButton1Click", function()
                    Toggle.Value = not Toggle.Value
                    ToggleBtn.Instance.BackgroundColor3 = Toggle.Value and FromRGB(100, 200, 100) or FromRGB(60, 60, 70)
                    ToggleBtn.Instance.Text = Toggle.Value and "ON" or "OFF"
                    Library.Flags[Toggle.Flag] = Toggle.Value
                    Toggle.Callback(Toggle.Value)
                end)

                Library.Flags[Toggle.Flag] = Toggle.Default
                Library.SetFlags[Toggle.Flag] = function(Value)
                    Toggle.Value = Value
                    ToggleBtn.Instance.BackgroundColor3 = Value and FromRGB(100, 200, 100) or FromRGB(60, 60, 70)
                    ToggleBtn.Instance.Text = Value and "ON" or "OFF"
                    Toggle.Callback(Value)
                end

                TableInsert(Section.Items, Toggle)
                return Toggle
            end

            -- ============================================
            -- BUTTON
            -- ============================================
            function Section:Button(Data)
                local Button = {
                    Name = Data.Name or "Button",
                    Callback = Data.Callback or function() end,
                    Instance = nil,
                    Section = Section,
                }

                local Btn = Instances:Create("TextButton", {
                    Parent = SectionContent.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 28),
                    BackgroundColor3 = FromRGB(28, 32, 38),
                    Text = Button.Name,
                    TextColor3 = FromRGB(200, 200, 200),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                })  Btn:AddToTheme({BackgroundColor3 = "Element", TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Btn.Instance,
                    Name = "\0",
                    CornerRadius = UDim.new(0, 4)
                })

                Button.Instance = Btn

                Btn:Connect("MouseButton1Click", function()
                    Button.Callback()
                end)

                Btn:Connect("MouseEnter", function()
                    Btn.Instance.BackgroundColor3 = FromRGB(35, 40, 48)
                end)

                Btn:Connect("MouseLeave", function()
                    Btn.Instance.BackgroundColor3 = FromRGB(28, 32, 38)
                end)

                TableInsert(Section.Items, Button)
                return Button
            end

            -- ============================================
            -- SLIDER
            -- ============================================
            function Section:Slider(Data)
                local Slider = {
                    Name = Data.Name or "Slider",
                    Flag = Data.Flag or Library:NextFlag(),
                    Min = Data.Min or 0,
                    Max = Data.Max or 100,
                    Default = Data.Default or 50,
                    Suffix = Data.Suffix or "",
                    Value = Data.Default or 50,
                    Callback = Data.Callback or function() end,
                    Instance = nil,
                    Section = Section,
                }

                local SliderFrame = Instances:Create("Frame", {
                    Parent = SectionContent.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 45),
                    BackgroundTransparency = 1,
                })

                local SliderLabel = Instances:Create("TextLabel", {
                    Parent = SliderFrame.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = Slider.Name .. ": " .. tostring(Slider.Value) .. Slider.Suffix,
                    TextColor3 = FromRGB(200, 200, 200),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })  SliderLabel:AddToTheme({TextColor3 = "Text"})

                local SliderBar = Instances:Create("Frame", {
                    Parent = SliderFrame.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 5),
                    Position = UDim2New(0, 0, 0, 22),
                    BackgroundColor3 = FromRGB(40, 40, 50),
                    BorderSizePixel = 0,
                })

                Instances:Create("UICorner", {
                    Parent = SliderBar.Instance,
                    Name = "\0",
                    CornerRadius = UDim.new(1, 0)
                })

                local SliderFill = Instances:Create("Frame", {
                    Parent = SliderBar.Instance,
                    Name = "\0",
                    Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
                    BackgroundColor3 = FromRGB(100, 180, 255),
                    BorderSizePixel = 0,
                })

                Instances:Create("UICorner", {
                    Parent = SliderFill.Instance,
                    Name = "\0",
                    CornerRadius = UDim.new(1, 0)
                })

                local SliderValue = Slider.Value
                local Dragging = false

                local function UpdateSlider(input)
                    local pos = MathClamp((input.Position.X - SliderBar.Instance.AbsolutePosition.X) / SliderBar.Instance.AbsoluteSize.X, 0, 1)
                    SliderValue = Slider.Min + (Slider.Max - Slider.Min) * pos
                    SliderValue = MathFloor(SliderValue)
                    SliderFill.Instance.Size = UDim2.new(pos, 0, 1, 0)
                    SliderLabel.Instance.Text = Slider.Name .. ": " .. tostring(SliderValue) .. Slider.Suffix
                    Slider.Value = SliderValue
                    Library.Flags[Slider.Flag] = SliderValue
                    Slider.Callback(SliderValue)
                end

                SliderBar:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true
                        UpdateSlider(Input)
                    end
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(Input)
                    end
                end)

                Library:Connect(UserInputService.InputEnded, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                Slider.Instance = SliderFrame
                Library.Flags[Slider.Flag] = Slider.Default
                Library.SetFlags[Slider.Flag] = function(Value)
                    SliderValue = Value
                    SliderFill.Instance.Size = UDim2.new((Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)
                    SliderLabel.Instance.Text = Slider.Name .. ": " .. tostring(Value) .. Slider.Suffix
                    Slider.Value = Value
                    Slider.Callback(Value)
                end

                TableInsert(Section.Items, Slider)
                return Slider
            end

            -- ============================================
            -- TEXTBOX
            -- ============================================
            function Section:Textbox(Data)
                local Textbox = {
                    Name = Data.Name or "Textbox",
                    Flag = Data.Flag or Library:NextFlag(),
                    Default = Data.Default or "",
                    Placeholder = Data.Placeholder or "Type here...",
                    Callback = Data.Callback or function() end,
                    Value = "",
                    Section = Section,
                }

                local Box = Instances:Create("TextBox", {
                    Parent = SectionContent.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 28),
                    BackgroundColor3 = FromRGB(28, 32, 38),
                    Text = Textbox.Default,
                    PlaceholderText = Textbox.Placeholder,
                    TextColor3 = FromRGB(200, 200, 200),
                    PlaceholderColor3 = FromRGB(100, 100, 100),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                })  Box:AddToTheme({BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "Dark Text"})

                Instances:Create("UICorner", {
                    Parent = Box.Instance,
                    Name = "\0",
                    CornerRadius = UDim.new(0, 4)
                })

                Textbox.Instance = Box

                Box:Connect("FocusLost", function()
                    Textbox.Value = Box.Instance.Text
                    Library.Flags[Textbox.Flag] = Box.Instance.Text
                    Textbox.Callback(Box.Instance.Text)
                end)

                Library.Flags[Textbox.Flag] = Textbox.Default
                Library.SetFlags[Textbox.Flag] = function(Value)
                    Box.Instance.Text = Value
                    Textbox.Value = Value
                    Textbox.Callback(Value)
                end

                TableInsert(Section.Items, Textbox)
                return Textbox
            end

            -- ============================================
            -- LABEL
            -- ============================================
            function Section:Label(Text)
                local Label = {
                    Name = Text or "Label",
                    Text = Text or "Label",
                    Section = Section,
                }

                local Lbl = Instances:Create("TextLabel", {
                    Parent = SectionContent.Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = Label.Text,
                    TextColor3 = FromRGB(200, 200, 200),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })  Lbl:AddToTheme({TextColor3 = "Text"})

                Label.Instance = Lbl

                function Label:SetText(NewText)
                    Lbl.Instance.Text = NewText
                end

                TableInsert(Section.Items, Label)
                return Label
            end

            return Section
        end

        return Page
    end

    -- ============================================
    -- NOTIFICATION
    -- ============================================
    Library.Notification = function(self, Data)
        Data = Data or { }
        local Title = Data.Title or Data.title or "Notification"
        local Description = Data.Description or Data.description or ""
        local Duration = Data.Duration or Data.duration or 5
        local Icon = Data.Icon or Data.icon or ""

        local Items = { } do
            Items["Notification"] = Instances:Create("Frame", {
                Parent = Library.NotifHolder.Instance,
                Name = "\0",
                Size = UDim2New(0, 0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = FromRGB(13, 15, 18)
            })  Items["Notification"]:AddToTheme({BackgroundColor3 = "Background"})
            
            Instances:Create("UICorner", {
                Parent = Items["Notification"].Instance,
                Name = "\0",
                CornerRadius = UDimNew(0, 6)
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["Notification"].Instance,
                Name = "\0",
                Color = FromRGB(26, 30, 36),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"})

            local Content = Instances:Create("Frame", {
                Parent = Items["Notification"].Instance,
                Name = "\0",
                Size = UDim2New(0, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.XY,
            })

            Instances:Create("UIPadding", {
                Parent = Content.Instance,
                Name = "\0",
                PaddingTop = UDimNew(0, 8),
                PaddingBottom = UDimNew(0, 8),
                PaddingRight = UDimNew(0, 12),
                PaddingLeft = UDimNew(0, 12)
            })

            Instances:Create("UIListLayout", {
                Parent = Content.Instance,
                Name = "\0",
                Padding = UDimNew(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            if Icon and Icon ~= "" then
                local IconImg = Instances:Create("ImageLabel", {
                    Parent = Content.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 20, 0, 20),
                    Image = "rbxassetid://" .. Icon,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })  IconImg:AddToTheme({ImageColor3 = "Text"})
            end

            local TitleLbl = Instances:Create("TextLabel", {
                Parent = Content.Instance,
                Name = "\0",
                Size = UDim2New(0, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = Title,
                TextColor3 = FromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Left,
            })  TitleLbl:AddToTheme({TextColor3 = "Text"})

            if Description and Description ~= "" then
                local DescLbl = Instances:Create("TextLabel", {
                    Parent = Content.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = FromRGB(150, 150, 170),
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })  DescLbl:AddToTheme({TextColor3 = "Dark Text"})
            end

            local Size = Content.Instance.AbsoluteSize
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)
            Content.Instance.Size = UDim2New(0, Size.X, 0, Size.Y)
            
            for _, obj in pairs(Items["Notification"].Instance:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    obj.TextTransparency = 1
                elseif obj:IsA("ImageLabel") then
                    obj.ImageTransparency = 1
                elseif obj:IsA("UIStroke") then
                    obj.Transparency = 1
                end
            end

            Items["Notification"]:Tween(nil, {Size = UDim2New(0, Size.X + 24, 0, Size.Y + 16)})
            
            task.wait(0.1)
            for _, obj in pairs(Items["Notification"].Instance:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0})
                elseif obj:IsA("ImageLabel") then
                    Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0})
                elseif obj:IsA("UIStroke") then
                    Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Transparency = 0})
                end
            end

            task.delay(Duration, function()
                for _, obj in pairs(Items["Notification"].Instance:GetDescendants()) do
                    if obj:IsA("TextLabel") then
                        Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1})
                    elseif obj:IsA("ImageLabel") then
                        Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 1})
                    elseif obj:IsA("UIStroke") then
                        Tween:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Transparency = 1})
                    end
                end
                task.wait(0.4)
                Items["Notification"]:Clean()
            end)
        end
    end
end

getgenv().Library = Library
return Library
