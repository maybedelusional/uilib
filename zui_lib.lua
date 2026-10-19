local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lib = {
Flags = {},
KeyFlags = {},
Binds = {},
Conns = {},
Themed = {},
Redraw = {},
MenuKey = Enum.KeyCode.RightShift,
Dead = false,
Restoring = false,
SetFlags = {MenuBind = function() end},
Images = {},
Folders = {},
}
local Theme = {
Background = Color3.fromRGB(12, 13, 17),
Panel = Color3.fromRGB(18, 19, 25),
Card = Color3.fromRGB(24, 26, 33),
Element = Color3.fromRGB(33, 35, 45),
Outline = Color3.fromRGB(43, 46, 58),
Text = Color3.fromRGB(232, 234, 240),
SubText = Color3.fromRGB(139, 145, 160),
Accent = Color3.fromRGB(92, 160, 255),
Danger = Color3.fromRGB(240, 85, 85),
}
Lib.Theme = Theme
local AccentPresets = {
{"Blue", Color3.fromRGB(92, 160, 255)},
{"Cyan", Color3.fromRGB(70, 205, 220)},
{"Purple", Color3.fromRGB(150, 110, 255)},
{"Pink", Color3.fromRGB(240, 110, 190)},
{"Green", Color3.fromRGB(85, 210, 130)},
{"Orange", Color3.fromRGB(245, 160, 70)},
{"Red", Color3.fromRGB(240, 90, 90)},
}
local function Connect(Signal, Fn)
local Connection = Signal:Connect(Fn)
table.insert(Lib.Conns, Connection)
return Connection
end
local function Call(Fn, ...)
if not Fn then return end
local Ok, Err = pcall(Fn, ...)
if not Ok then warn("[ZAF UI] " .. tostring(Err)) end
end
local function New(Class, Props, Parent)
local Obj = Instance.new(Class)
for Key, Value in pairs(Props or {}) do Obj[Key] = Value end
if Parent then Obj.Parent = Parent end
return Obj
end
local function Bind(Obj, Prop, Key)
table.insert(Lib.Themed, {Obj, Prop, Key})
Obj[Prop] = Theme[Key]
end
local function Round(Obj, Radius)
return New("UICorner", {CornerRadius = UDim.new(0, Radius)}, Obj)
end
local function Outline(Obj, Key)
local Stroke = New("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, Obj)
Bind(Stroke, "Color", Key or "Outline")
return Stroke
end
local function Pad(Obj, Left, Top, Right, Bottom)
return New("UIPadding", {
PaddingLeft = UDim.new(0, Left),
PaddingTop = UDim.new(0, Top),
PaddingRight = UDim.new(0, Right),
PaddingBottom = UDim.new(0, Bottom),
}, Obj)
end
local function Stack(Obj, Gap)
return New("UIListLayout", {Padding = UDim.new(0, Gap), SortOrder = Enum.SortOrder.LayoutOrder}, Obj)
end
local function Tween(Obj, Time, Props)
TweenService:Create(Obj, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props):Play()
end
local function Text(Parent, Props)
local Label = New("TextLabel", {
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Center,
TextTruncate = Enum.TextTruncate.AtEnd,
Text = "",
}, nil)
for Key, Value in pairs(Props or {}) do
if Key ~= "SubText" then Label[Key] = Value end
end
Bind(Label, "TextColor3", Props and Props.SubText and "SubText" or "Text")
Label.Parent = Parent
return Label
end
local function Over(Obj, Point)
local Pos, Size = Obj.AbsolutePosition, Obj.AbsoluteSize
return Point.X >= Pos.X and Point.X <= Pos.X + Size.X and Point.Y >= Pos.Y and Point.Y <= Pos.Y + Size.Y
end
local function IsClick(Input)
return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end
local function Decimals(Step)
local Part = tostring(Step):match("%.(%d+)")
return Part and #Part or 0
end
local function MakeFolder(Path)
local Built = ""
for Part in tostring(Path):gmatch("[^/]+") do
if Built == "" then Built = Part else Built = Built .. "/" .. Part end
pcall(function() if isfolder and makefolder and not isfolder(Built) then makefolder(Built) end end)
end
end
function Lib:SetAccent(Color)
Theme.Accent = Color
for _, Item in ipairs(Lib.Themed) do
if Item[3] == "Accent" then pcall(function() Item[1][Item[2]] = Color end) end
end
for _, Fn in ipairs(Lib.Redraw) do pcall(Fn) end
end
local SaveTask
local function Save()
if Lib.Restoring or Lib.Dead or not Lib.ConfigPath then return end
if SaveTask then task.cancel(SaveTask) end
SaveTask = task.delay(0.4, function()
SaveTask = nil
local Data = {}
for Flag, Item in pairs(Lib.Flags) do
local Ok, Value = pcall(Item.Get)
if Ok and Value ~= nil then Data[Flag] = Value end
end
for Flag, Item in pairs(Lib.KeyFlags) do
local Ok, Value = pcall(Item.Get)
if Ok then Data[Flag .. "__key"] = Value or "" end
end
pcall(function() writefile(Lib.ConfigPath, HttpService:JSONEncode(Data)) end)
end)
end
function Lib:LoadConfig()
if not (Lib.ConfigPath and isfile and readfile and isfile(Lib.ConfigPath)) then return end
local Ok, Data = pcall(function() return HttpService:JSONDecode(readfile(Lib.ConfigPath)) end)
if not Ok or type(Data) ~= "table" then return end
Lib.Restoring = true
for Flag, Item in pairs(Lib.Flags) do
if Data[Flag] ~= nil then pcall(Item.Set, Data[Flag]) end
end
for Flag, Item in pairs(Lib.KeyFlags) do
local Saved = Data[Flag .. "__key"]
if Saved ~= nil then pcall(Item.Set, Saved) end
end
Lib.Restoring = false
end
Connect(UserInputService.InputBegan, function(Input)
if Lib.Dead then return end
if Lib.Capture then
if Input.UserInputType == Enum.UserInputType.Keyboard then
local Fn = Lib.Capture
Lib.Capture = nil
Fn(Input.KeyCode)
end
return
end
if UserInputService:GetFocusedTextBox() then return end
if Input.UserInputType == Enum.UserInputType.Keyboard then
if Input.KeyCode == Lib.MenuKey and Lib.WindowObj then
Lib.WindowObj:SetOpen(not Lib.WindowObj.IsOpen)
return
end
for _, Bind in pairs(Lib.Binds) do
if Bind.Key and Bind.Key == Input.KeyCode then Call(Bind.Fire) end
end
end
if Lib.OpenDropdown and IsClick(Input) then
local Point = UserInputService:GetMouseLocation()
local Drop = Lib.OpenDropdown
if not Over(Drop.List, Point) and not Over(Drop.Header, Point) then Drop:Close() end
end
end)
function Lib:CloseDropdown()
if Lib.OpenDropdown then Lib.OpenDropdown:Close() end
end
local Section = {}
Section.__index = Section
function Section:Next()
self.Order = self.Order + 1
return self.Order
end
local function KeyChip(Parent, Order, Get, SetKey)
local Chip = New("TextButton", {
AutoButtonColor = false,
Font = Enum.Font.GothamMedium,
TextSize = 11,
Text = "None",
AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, 18),
LayoutOrder = Order or 0,
ZIndex = 3,
}, Parent)
Bind(Chip, "BackgroundColor3", "Element")
Bind(Chip, "TextColor3", "SubText")
Round(Chip, 4)
Outline(Chip)
Pad(Chip, 6, 0, 6, 0)
local function Show()
local Key = Get()
Chip.Text = Key and Key.Name or "None"
end
Show()
Chip.MouseButton1Click:Connect(function()
Chip.Text = "..."
Lib.Capture = function(Key)
if Key == Enum.KeyCode.Escape or Key == Enum.KeyCode.Backspace then SetKey(nil) else SetKey(Key) end
Show()
Save()
end
end)
return Chip, Show
end
function Section:Toggle(Opts)
local Handle = {}
local State = Opts.Default == true
local Key = Opts.Key
local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = self:Next()}, self.Card)
Text(Row, {Text = Opts.Name or "Toggle", Size = UDim2.new(1, -96, 1, 0)})
local Switch = New("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18)}, Row)
Bind(Switch, "BackgroundColor3", "Element")
Round(Switch, 9)
Outline(Switch)
local Knob = New("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(14, 14)}, Switch)
Bind(Knob, "BackgroundColor3", "SubText")
Round(Knob, 7)
local function Render(Animate)
local Time = Animate and 0.15 or 0
Tween(Switch, Time, {BackgroundColor3 = State and Theme.Accent or Theme.Element})
Tween(Knob, Time, {
Position = State and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
BackgroundColor3 = State and Color3.fromRGB(255, 255, 255) or Theme.SubText,
})
end
table.insert(Lib.Redraw, function() Render(false) end)
Render(false)
local function Set(Value, Silent)
Value = Value == true
if Value == State and not Silent then return end
State = Value
Render(true)
if not Silent then
Call(Opts.Callback, State)
Save()
end
end
local Click = New("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), ZIndex = 2}, Row)
Click.MouseButton1Click:Connect(function() Set(not State) end)
local Bind_ = {Key = Key, Fire = function() Set(not State) end}
table.insert(Lib.Binds, Bind_)
if Key ~= nil or Opts.Config == true then
local Holder = New("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -42, 0.5, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3}, Row)
local _, Show = KeyChip(Holder, 0, function() return Bind_.Key end, function(NewKey) Bind_.Key = NewKey end)
if Opts.Flag then
Lib.KeyFlags[Opts.Flag] = {
Get = function() return Bind_.Key and Bind_.Key.Name or "" end,
Set = function(Name)
Bind_.Key = Name ~= "" and Enum.KeyCode[Name] or nil
Show()
end,
}
end
end
if Opts.Flag then
Lib.Flags[Opts.Flag] = {Get = function() return State end, Set = function(Value) Set(Value) end}
end
function Handle:Set(Value) Set(Value) end
function Handle:Get() return State end
function Handle:Keybind() return Handle end
return Handle
end
function Section:Slider(Opts)
local Handle = {}
local Min, Max = tonumber(Opts.Min) or 0, tonumber(Opts.Max) or 100
local Step = tonumber(Opts.Decimals) or 1
local Places = Decimals(Step)
local Suffix = Opts.Suffix and tostring(Opts.Suffix) or ""
local Value = math.clamp(tonumber(Opts.Default) or Min, Min, Max)
local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = self:Next()}, self.Card)
Text(Row, {Text = Opts.Name or "Slider", Size = UDim2.new(1, -70, 0, 18)})
local Box = New("TextBox", {
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Right,
ClearTextOnFocus = true,
AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, 0, 0, 0),
Size = UDim2.fromOffset(70, 18),
Text = "",
}, Row)
Bind(Box, "TextColor3", "SubText")
local Bar = New("Frame", {Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 6)}, Row)
Bind(Bar, "BackgroundColor3", "Element")
Round(Bar, 3)
local Fill = New("Frame", {Size = UDim2.new(0, 0, 1, 0)}, Bar)
Bind(Fill, "BackgroundColor3", "Accent")
Round(Fill, 3)
local Grab = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, Fill)
Round(Grab, 6)
local function Format(Number)
return string.format("%." .. Places .. "f", Number) .. Suffix
end
local function Snap(Number)
Number = Min + math.floor((Number - Min) / Step + 0.5) * Step
Number = tonumber(string.format("%." .. Places .. "f", Number)) or Number
return math.clamp(Number, Min, Max)
end
local function Render()
local Ratio = Max > Min and (Value - Min) / (Max - Min) or 0
Fill.Size = UDim2.new(Ratio, 0, 1, 0)
Box.Text = Format(Value)
end
local function Set(Number, Silent)
Number = Snap(tonumber(Number) or Value)
if Number == Value and not Silent then return end
Value = Number
Render()
if not Silent then
Call(Opts.Callback, Value)
Save()
end
end
Render()
Box.FocusLost:Connect(function()
local Typed = tonumber((Box.Text:gsub("[^%d%.%-]", "")))
if Typed then Set(Typed) else Render() end
end)
local Dragging = false
local Hit = New("TextButton", {BackgroundTransparency = 1, Text = "", Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 18), ZIndex = 2}, Row)
local function FromX(X)
local Width = math.max(Bar.AbsoluteSize.X, 1)
Set(Min + math.clamp((X - Bar.AbsolutePosition.X) / Width, 0, 1) * (Max - Min))
end
Hit.InputBegan:Connect(function(Input)
if IsClick(Input) then
Dragging = true
FromX(Input.Position.X)
end
end)
Connect(UserInputService.InputChanged, function(Input)
if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
FromX(Input.Position.X)
end
end)
Connect(UserInputService.InputEnded, function(Input)
if IsClick(Input) then Dragging = false end
end)
if Opts.Flag then
Lib.Flags[Opts.Flag] = {Get = function() return Value end, Set = function(Number) Set(Number) end}
end
function Handle:Set(Number) Set(Number) end
function Handle:Get() return Value end
return Handle
end
function Section:Dropdown(Opts)
local Handle = {}
local Multi = Opts.Multi == true
local Items = {}
local Single = nil
local Chosen = {}
local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = self:Next()}, self.Card)
Text(Row, {Text = Opts.Name or "Dropdown", Size = UDim2.new(1, 0, 0, 18)})
local Header = New("TextButton", {AutoButtonColor = false, Text = "", Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 26)}, Row)
Bind(Header, "BackgroundColor3", "Element")
Round(Header, 5)
Outline(Header)
local Shown = Text(Header, {Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -28, 1, 0)})
local Arrow = Text(Header, {Text = "v", SubText = true, Font = Enum.Font.GothamBold, TextSize = 11, Position = UDim2.new(1, -20, 0, 0), Size = UDim2.fromOffset(14, 26), TextXAlignment = Enum.TextXAlignment.Center})
local List = New("Frame", {Visible = false, ZIndex = 100, Size = UDim2.fromOffset(100, 100)}, Lib.Gui)
Bind(List, "BackgroundColor3", "Card")
Round(List, 5)
Outline(List)
local Scroll = New("ScrollingFrame", {
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollingDirection = Enum.ScrollingDirection.Y,
AutomaticCanvasSize = Enum.AutomaticSize.Y,
CanvasSize = UDim2.new(),
Size = UDim2.new(1, 0, 1, 0),
ZIndex = 101,
}, List)
Pad(Scroll, 4, 4, 4, 4)
Stack(Scroll, 2)
local Drop = {List = List, Header = Header}
local function Summary()
if Multi then
local Names = {}
for _, Item in ipairs(Items) do
if Chosen[Item] then table.insert(Names, Item) end
end
return #Names > 0 and table.concat(Names, ", ") or "None"
end
return Single or "Select..."
end
local Buttons = {}
local function Paint()
Shown.Text = Summary()
for _, Entry in ipairs(Buttons) do
local On = Multi and Chosen[Entry.Name] or (not Multi and Single == Entry.Name)
Entry.Button.TextColor3 = On and Theme.Accent or Theme.Text
Entry.Button.BackgroundTransparency = On and 0.85 or 1
end
end
table.insert(Lib.Redraw, Paint)
local function Pick(Name, Silent)
if Multi then
Chosen[Name] = not Chosen[Name] or nil
else
Single = Name
end
Paint()
if not Silent then
if Multi then
local Out = {}
for _, Item in ipairs(Items) do
if Chosen[Item] then table.insert(Out, Item) end
end
Call(Opts.Callback, Out)
else
Call(Opts.Callback, Single)
end
Save()
end
end
local function Build()
for _, Entry in ipairs(Buttons) do Entry.Button:Destroy() end
Buttons = {}
for Index, Name in ipairs(Items) do
local Button = New("TextButton", {
AutoButtonColor = false,
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
Text = Name,
Size = UDim2.new(1, 0, 0, 24),
LayoutOrder = Index,
ZIndex = 102,
}, Scroll)
Bind(Button, "BackgroundColor3", "Accent")
Round(Button, 4)
Pad(Button, 8, 0, 6, 0)
Button.MouseButton1Click:Connect(function()
Pick(Name)
if not Multi then Drop:Close() end
end)
table.insert(Buttons, {Name = Name, Button = Button})
end
Paint()
end
function Drop:Close()
List.Visible = false
Arrow.Text = "v"
if Lib.OpenDropdown == Drop then Lib.OpenDropdown = nil end
end
function Drop:Open()
Lib:CloseDropdown()
local Pos, Size = Header.AbsolutePosition, Header.AbsoluteSize
List.Position = UDim2.fromOffset(Pos.X, Pos.Y + Size.Y + 3)
List.Size = UDim2.fromOffset(Size.X, math.min(#Items * 26 + 8, 176))
List.Visible = true
Arrow.Text = "^"
Lib.OpenDropdown = Drop
end
Header.MouseButton1Click:Connect(function()
if Lib.OpenDropdown == Drop then Drop:Close() else Drop:Open() end
end)
local function SetItems(NewItems)
Items = {}
for _, Value in ipairs(NewItems or {}) do table.insert(Items, tostring(Value)) end
Build()
end
SetItems(Opts.Items)
if not Multi and Opts.Default ~= nil and table.find(Items, tostring(Opts.Default)) then Single = tostring(Opts.Default) end
if Multi and type(Opts.Default) == "table" then
for _, Name in ipairs(Opts.Default) do Chosen[tostring(Name)] = true end
end
Paint()
local function Set(Value, Silent)
if Multi then
if type(Value) ~= "table" then return false end
Chosen = {}
for _, Name in ipairs(Value) do Chosen[tostring(Name)] = true end
Paint()
if not Silent then Pick(nil, false) end
return true
end
Value = tostring(Value)
if not table.find(Items, Value) then return false end
Pick(Value, Silent)
return true
end
local RawPick = Pick
Pick = function(Name, Silent)
if Multi and Name == nil then
local Out = {}
for _, Item in ipairs(Items) do
if Chosen[Item] then table.insert(Out, Item) end
end
Call(Opts.Callback, Out)
Save()
return
end
RawPick(Name, Silent)
end
if Opts.Flag then
Lib.Flags[Opts.Flag] = {
Get = function()
if Multi then
local Out = {}
for _, Item in ipairs(Items) do
if Chosen[Item] then table.insert(Out, Item) end
end
return Out
end
return Single
end,
Set = function(Value) Set(Value) end,
}
end
function Handle:Refresh(NewItems, Default)
Drop:Close()
Single, Chosen = nil, {}
SetItems(NewItems)
if not Multi and Default ~= nil and table.find(Items, tostring(Default)) then Single = tostring(Default) end
Paint()
end
function Handle:Set(Value) Set(Value, true) end
function Handle:Get()
if not Multi then return Single end
local Out = {}
for _, Item in ipairs(Items) do
if Chosen[Item] then table.insert(Out, Item) end
end
return Out
end
return Handle
end
function Section:Textbox(Opts)
local Handle = {}
local HasName = Opts.Name ~= nil and Opts.Name ~= ""
local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HasName and 48 or 26), LayoutOrder = self:Next()}, self.Card)
if HasName then Text(Row, {Text = Opts.Name, Size = UDim2.new(1, 0, 0, 18)}) end
local Holder = New("Frame", {Position = UDim2.new(0, 0, 0, HasName and 22 or 0), Size = UDim2.new(1, 0, 0, 26)}, Row)
Bind(Holder, "BackgroundColor3", "Element")
Round(Holder, 5)
Outline(Holder)
local Box = New("TextBox", {
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
ClearTextOnFocus = false,
PlaceholderText = Opts.Placeholder or "",
Text = Opts.Default ~= nil and tostring(Opts.Default) or "",
Position = UDim2.new(0, 8, 0, 0),
Size = UDim2.new(1, -16, 1, 0),
}, Holder)
Bind(Box, "TextColor3", "Text")
Bind(Box, "PlaceholderColor3", "SubText")
Box.FocusLost:Connect(function()
Call(Opts.Callback, Box.Text)
Save()
end)
if Opts.Flag then
Lib.Flags[Opts.Flag] = {
Get = function() return Box.Text end,
Set = function(Value)
Box.Text = tostring(Value)
Call(Opts.Callback, Box.Text)
end,
}
end
function Handle:Set(Value) Box.Text = tostring(Value) end
function Handle:Get() return Box.Text end
return Handle
end
function Section:Button(Opts)
local Button = New("TextButton", {
AutoButtonColor = false,
Font = Enum.Font.GothamMedium,
TextSize = 13,
Text = Opts.Name or "Button",
Size = UDim2.new(1, 0, 0, 28),
LayoutOrder = self:Next(),
}, self.Card)
Bind(Button, "BackgroundColor3", "Element")
Bind(Button, "TextColor3", "Text")
Round(Button, 5)
Outline(Button)
Button.MouseEnter:Connect(function() Tween(Button, 0.12, {BackgroundColor3 = Theme.Outline}) end)
Button.MouseLeave:Connect(function() Tween(Button, 0.12, {BackgroundColor3 = Theme.Element}) end)
Button.MouseButton1Click:Connect(function()
Button.BackgroundColor3 = Theme.Accent
Tween(Button, 0.25, {BackgroundColor3 = Theme.Element})
Call(Opts.Callback)
end)
local Handle = {}
function Handle:SetText(Value) Button.Text = tostring(Value) end
return Handle
end
function Section:Label(Value)
local Label = New("TextLabel", {
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Top,
TextWrapped = true,
AutomaticSize = Enum.AutomaticSize.Y,
Size = UDim2.new(1, 0, 0, 0),
Text = tostring(Value),
LayoutOrder = self:Next(),
}, self.Card)
Bind(Label, "TextColor3", "SubText")
local Handle = {}
function Handle:SetText(New_) Label.Text = tostring(New_) end
Handle.Set = Handle.SetText
return Handle
end
function Section:Keybind(Opts)
local Key = Opts.Default
local Row = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = self:Next()}, self.Card)
Text(Row, {Text = Opts.Name or "Keybind", Size = UDim2.new(1, -90, 1, 0)})
local Holder = New("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X}, Row)
local _, Show = KeyChip(Holder, 0, function() return Key end, function(NewKey)
Key = NewKey
Call(Opts.Callback, NewKey)
end)
if Opts.Flag then
Lib.KeyFlags[Opts.Flag] = {
Get = function() return Key and Key.Name or "" end,
Set = function(Name)
Key = Name ~= "" and Enum.KeyCode[Name] or nil
Show()
Call(Opts.Callback, Key)
end,
}
end
return {}
end
local Page = {}
Page.__index = Page
function Page:Section(Opts)
Opts = Opts or {}
local Column = Opts.Side == 2 and self.Right or self.Left
local Card = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #Column:GetChildren()}, Column)
Bind(Card, "BackgroundColor3", "Card")
Round(Card, 7)
Outline(Card)
Pad(Card, 10, 9, 10, 10)
Stack(Card, 8)
local Title = Text(Card, {Text = string.upper(tostring(Opts.Name or "")), Font = Enum.Font.GothamBold, TextSize = 11, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0})
Bind(Title, "TextColor3", "Accent")
return setmetatable({Card = Card, Order = 0}, Section)
end
function Lib:Notification(Info)
if Lib.Dead or not Lib.Notes then return end
Info = Info or {}
local Duration = tonumber(Info.Duration) or 3
local Note = New("CanvasGroup", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, GroupTransparency = 1}, Lib.Notes)
Bind(Note, "BackgroundColor3", "Card")
Round(Note, 6)
Outline(Note)
local Bar = New("Frame", {Size = UDim2.new(0, 3, 1, 0)}, Note)
Bind(Bar, "BackgroundColor3", "Accent")
local Body = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, Note)
Pad(Body, 14, 8, 10, 9)
Stack(Body, 2)
Text(Body, {Text = tostring(Info.Title or "ZAF Hub"), Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1})
local Desc = New("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Text = tostring(Info.Description or Info.Content or ""), LayoutOrder = 2}, Body)
Bind(Desc, "TextColor3", "SubText")
Tween(Note, 0.2, {GroupTransparency = 0})
task.delay(Duration, function()
if Note.Parent then
Tween(Note, 0.3, {GroupTransparency = 1})
task.wait(0.35)
Note:Destroy()
end
end)
end
local Window = {}
Window.__index = Window
function Window:Category() end
function Window:SetOpen(State)
self.IsOpen = State == true
Lib:CloseDropdown()
if self.IsOpen then
self.Main.Visible = true
self.Scale.Scale = 0.94
Tween(self.Scale, 0.18, {Scale = 1})
else
Tween(self.Scale, 0.14, {Scale = 0.94})
task.delay(0.15, function()
if not self.IsOpen and self.Main.Parent then self.Main.Visible = false end
end)
end
end
function Window:Select(Target)
Lib:CloseDropdown()
for _, Item in ipairs(self.Pages) do
local On = Item == Target
Item.Scroll.Visible = On
Tween(Item.Tab, 0.12, {BackgroundTransparency = On and 0 or 1})
Item.TabLabel.TextColor3 = On and Theme.Text or Theme.SubText
Item.Mark.Visible = On
end
self.Current = Target
self.Heading.Text = Target.Name
end
function Window:Page(Opts)
Opts = Opts or {}
local Item = setmetatable({Name = tostring(Opts.Name or "Page")}, Page)
local Tab = New("TextButton", {AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = #self.Pages + 1}, self.TabList)
Bind(Tab, "BackgroundColor3", "Element")
Round(Tab, 6)
Item.Mark = New("Frame", {Visible = false, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 16)}, Tab)
Bind(Item.Mark, "BackgroundColor3", "Accent")
Round(Item.Mark, 2)
Item.TabLabel = Text(Tab, {Text = Item.Name, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -20, 1, 0), Font = Enum.Font.GothamMedium})
Item.TabLabel.TextColor3 = Theme.SubText
Item.Tab = Tab
Item.Scroll = New("ScrollingFrame", {
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollingDirection = Enum.ScrollingDirection.Y,
AutomaticCanvasSize = Enum.AutomaticSize.Y,
CanvasSize = UDim2.new(),
Size = UDim2.new(1, 0, 1, 0),
Visible = false,
}, self.Pages_)
Pad(Item.Scroll, 0, 0, 6, 8)
Item.Left = New("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, Item.Scroll)
Stack(Item.Left, 8)
Item.Right = New("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0.5, 4, 0, 0), Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, Item.Scroll)
Stack(Item.Right, 8)
local Owner = self
Tab.MouseButton1Click:Connect(function() Owner:Select(Item) end)
Tab.MouseEnter:Connect(function() if Owner.Current ~= Item then Tween(Tab, 0.12, {BackgroundTransparency = 0.6}) end end)
Tab.MouseLeave:Connect(function() if Owner.Current ~= Item then Tween(Tab, 0.12, {BackgroundTransparency = 1}) end end)
table.insert(self.Pages, Item)
if not self.Current then self:Select(Item) end
return Item
end
local function MakeDraggable(Handle, Target)
local Dragging, StartPos, StartInput = false, nil, nil
Handle.InputBegan:Connect(function(Input)
if IsClick(Input) then
Dragging = true
StartPos = Target.Position
StartInput = Input.Position
end
end)
Connect(UserInputService.InputChanged, function(Input)
if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
local Delta = Input.Position - StartInput
Target.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
Lib:CloseDropdown()
end
end)
Connect(UserInputService.InputEnded, function(Input)
if IsClick(Input) then Dragging = false end
end)
end
function Window:BuildSettings()
local Settings = self:Page({Name = "Settings"})
local Menu = Settings:Section({Name = "Menu", Side = 1})
Menu:Keybind({
Name = "Menu key",
Default = Lib.MenuKey,
Flag = "__MenuKey",
Callback = function(Key)
if Key then Lib.MenuKey = Key end
self.Footer.Text = "Menu key: " .. Lib.MenuKey.Name
end,
})
local Names = {}
for _, Preset in ipairs(AccentPresets) do table.insert(Names, Preset[1]) end
Menu:Dropdown({
Name = "Accent color",
Items = Names,
Default = "Blue",
Flag = "__Accent",
Callback = function(Name)
for _, Preset in ipairs(AccentPresets) do
if Preset[1] == Name then Lib:SetAccent(Preset[2]) end
end
end,
})
Menu:Toggle({
Name = "Watermark",
Default = true,
Flag = "__Watermark",
Callback = function(Value) self.Watermark.Visible = Value end,
})
local Danger = Settings:Section({Name = "Hub", Side = 2})
local Armed = false
local Handle
Handle = Danger:Button({
Name = "Unload hub",
Callback = function()
if not Armed then
Armed = true
Handle:SetText("Click again to unload")
task.delay(3, function()
Armed = false
pcall(function() Handle:SetText("Unload hub") end)
end)
return
end
if Lib.Unload then Lib.Unload(Lib) end
end,
})
Danger:Label("Settings are saved automatically and")
Danger:Label("restored the next time the hub runs.")
end
function Window:Init()
self:BuildSettings()
Lib:LoadConfig()
self.Footer.Text = "Menu key: " .. Lib.MenuKey.Name
if not self.Current and self.Pages[1] then self:Select(self.Pages[1]) end
self:SetOpen(true)
end
function Lib:Window(Opts)
Opts = Opts or {}
local Self = setmetatable({Pages = {}, IsOpen = false}, Window)
local Folder = Opts.Folder or "ZafHub"
MakeFolder(Folder .. "/Config")
Lib.ConfigPath = Folder .. "/Config/zui.json"
local Gui = New("ScreenGui", {Name = "ZafUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)
pcall(function() if protectgui then protectgui(Gui) end end)
local Parented = pcall(function() Gui.Parent = (gethui and gethui()) or CoreGui end)
if not Parented or not Gui.Parent then Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
Lib.Gui = Gui
Lib.WindowObj = Self
Lib.Notes = New("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 280, 1, -28), ZIndex = 200}, Gui)
New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right}, Lib.Notes)
local Main = New("Frame", {Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(680, 440)}, Gui)
Bind(Main, "BackgroundColor3", "Background")
Round(Main, 10)
Outline(Main)
Self.Main = Main
Self.Scale = New("UIScale", {Scale = 1}, Main)
local Side = New("Frame", {Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 164, 1, -16)}, Main)
Bind(Side, "BackgroundColor3", "Panel")
Round(Side, 8)
Outline(Side)
local Logo = Text(Side, {Text = string.upper(tostring(Opts.Name or "ZAF Hub")), Font = Enum.Font.GothamBold, TextSize = 17, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -20, 0, 22)})
Bind(Logo, "TextColor3", "Accent")
Text(Side, {Text = tostring(Opts.SubName or ""), SubText = true, TextSize = 12, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -20, 0, 16)})
local Rule = New("Frame", {Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 0, 1)}, Side)
Bind(Rule, "BackgroundColor3", "Outline")
Self.TabList = New("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Position = UDim2.fromOffset(8, 68), Size = UDim2.new(1, -16, 1, -104)}, Side)
Stack(Self.TabList, 4)
Self.Footer = Text(Side, {Text = "Menu key: " .. Lib.MenuKey.Name, SubText = true, TextSize = 11, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.new(1, -20, 0, 16)})
local Content = New("Frame", {Position = UDim2.fromOffset(180, 8), Size = UDim2.new(1, -188, 1, -16), BackgroundTransparency = 1}, Main)
local Header = New("Frame", {Size = UDim2.new(1, 0, 0, 36)}, Content)
Bind(Header, "BackgroundColor3", "Panel")
Round(Header, 8)
Outline(Header)
Self.Heading = Text(Header, {Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -60, 1, 0)})
local Close = New("TextButton", {AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 14, Text = "X", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(26, 26)}, Header)
Bind(Close, "TextColor3", "SubText")
Close.MouseEnter:Connect(function() Close.TextColor3 = Theme.Danger end)
Close.MouseLeave:Connect(function() Close.TextColor3 = Theme.SubText end)
Close.MouseButton1Click:Connect(function() Self:SetOpen(false) end)
Self.Pages_ = New("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44)}, Content)
MakeDraggable(Header, Main)
MakeDraggable(Logo, Main)
local Mark = New("Frame", {AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(0, 24)}, Gui)
Bind(Mark, "BackgroundColor3", "Panel")
Round(Mark, 6)
Outline(Mark)
Pad(Mark, 10, 0, 10, 0)
local MarkText = New("TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamMedium, TextSize = 12, Size = UDim2.fromOffset(0, 24), Text = ""}, Mark)
Bind(MarkText, "TextColor3", "Text")
Self.Watermark = Mark
MarkText.Text = tostring(Opts.Name or "ZAF Hub") .. "  |  " .. tostring(Opts.SubName or "")
local Frames, Last = 0, os.clock()
Connect(RunService.RenderStepped, function()
Frames = Frames + 1
if os.clock() - Last >= 1 then
MarkText.Text = tostring(Opts.Name or "ZAF Hub") .. "  |  " .. tostring(Opts.SubName or "") .. "  |  " .. tostring(Frames) .. " fps"
Frames, Last = 0, os.clock()
end
end)
return Self
end
local function Dummy()
return setmetatable({}, {__index = function() return function() end end})
end
function Lib:KeybindList() return Dummy() end
function Lib:CreateSettingsPage() end
function Lib:Watermark() return Dummy() end
function Lib:Unload()
if Lib.Dead then return end
Lib.Dead = true
for _, Connection in ipairs(Lib.Conns) do pcall(function() Connection:Disconnect() end) end
Lib.Binds = {}
Lib.Capture = nil
pcall(function() if Lib.Gui then Lib.Gui:Destroy() end end)
end
return Lib