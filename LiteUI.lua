-- game variables
local player = game:GetService('Players').LocalPlayer
local mouse = player:GetMouse()
-- Library variables
local library = {
	Name = 'Lite',
	Version = 'v. 1.0.0',
	Parent = game.CoreGui,
	IsMobile = not game:GetService("UserInputService").KeyboardEnabled or false,
	IsFileSystem = writefile and readfile and makefolder and true or false,
	Enabled = false,
	Visible = true,
	Settings = {
		NewUser = true,
		AntiAFK = true,
		prefix = Enum.KeyCode.LeftAlt,
		Elements_Size = 0,
		Elements_TextSize = 0,
		Elements_Font = Enum.Font.SourceSans,
		theme = {
			-- Background = Color3.fromRGB(17, 14, 24), -- Purple THEME
			-- Contrast = Color3.fromRGB(12, 2, 15), -- Purple THEME
			-- DarkContrast = Color3.fromRGB(8, 0, 12), -- Purple THEME
			-- Accent = Color3.fromRGB(55, 2, 105), -- Purple THEME
			Background = Color3.fromRGB(14, 17, 24), -- Blue THEME
			Contrast = Color3.fromRGB(2, 8, 15), -- Blue THEME
			DarkContrast = Color3.fromRGB(0, 3, 12), -- Blue 
			Accent = Color3.fromRGB(2, 86, 105), -- Blue THEME
			-- Background = Color3.fromRGB(17, 17, 17), -- Gray THEME
			-- Contrast = Color3.fromRGB(12, 12, 12), -- Gray THEME
			-- DarkContrast = Color3.fromRGB(8, 8, 8), -- Gray THEME
			LightContrast = Color3.fromRGB(160, 160, 160),
			TextColor = Color3.fromRGB(255, 255, 255),
		},
		Games = {},
	},
	CheckBox_groups = {},
	connections = {},
	end_funcs = {},
	binds = {},
	Functions = {},
	objects = {},

    page = {},
    section = {}
}

-- encode/decode function
do
	local types = {
		["nil"] = "0",
		["boolean"] = "1",
		["number"] = "2",
		["string"] = "3",
		["table"] = "4",

		["Vector3"] = "5",
		["CFrame"] = "6",
		["Instance"] = "7",
		["Color3"] = "8",

		["EnumItem"] = "9",

		-- ["function"] = "10",
	}
	local typeof = typeof or type
	function library.encode(data, p)
		if data == nil then
			return
		end
		local function hex_encode(IN: number, len: number): string
			local B, K, OUT, I, D = 16, "0123456789ABCDEF", "", 0, nil
			while IN > 0 do
				I = I + 1
				IN, D = math.floor(IN / B), IN % B + 1
				OUT = string.sub(K, D, D) .. OUT
			end
			if len then
				OUT = ("0"):rep(len - #OUT) .. OUT
			end
			return OUT
		end
		local function encode(t, ...)
			local type = typeof(t)
			local s = types[type]
			local c = ""
			if type == "nil" then
				c = types[type] .. "0"
			elseif type == "boolean" then
				local t = t == true and "1" or "0"
				c = s .. t
			elseif type == "number" then
				local new = tostring(t)
				local len = #new
				c = s .. len .. "." .. new
			elseif type == "string" then
				local new = t
				local len = #new
				c = s .. len .. "." .. new
			elseif type == "Vector3" then
				local x, y, z = tostring(t.X), tostring(t.Y), tostring(t.Z)
				local new = hex_encode(#x, 2) .. x .. hex_encode(#y, 2) .. y .. hex_encode(#z, 2) .. z
				c = s .. new
			elseif type == "CFrame" then
				local a = { t:GetComponents() }
				local new = ""
				for i, v in pairs(a) do
					local l = tostring(v)
					new = new .. hex_encode(#l, 2) .. l
				end
				c = s .. new
			elseif type == "Color3" then
				local a = { t.R, t.G, t.B }
				local new = ""
				for i, v in pairs(a) do
					local l = tostring(v)
					new = new .. hex_encode(#l, 2) .. l
				end
				c = s .. new
			elseif type == "table" then
				return library.encode(t, ...)
			elseif type == "EnumItem" then
				c = s .. tostring(t.EnumType) .. "" .. #t.Name .. "." .. t.Name
			end
			return c
		end
		local type = typeof(data)
		if type == "table" then
			local extra = {}
			local s = types[type]
			local new = ""
			local p = p or 0
			for i, v in pairs(data) do
				local i1, camera
				local t0, t1 = typeof(i), typeof(v)

				local a, b
				if t0 == "Instance" then
					p = p + 1
					extra[p] = i
					i1 = types[t0] .. hex_encode(p, 2)
				else
					i1, a = encode(i, p)
					if a then
						for i, v in pairs(a) do
							extra[i] = v
						end
					end
				end

				if t1 == "Instance" then
					p = p + 1
					extra[p] = v
					camera = types[t1] .. hex_encode(p, 2)
				else
					camera, b = encode(v, p)
					if b then
						for i, v in pairs(b) do
							extra[i] = v
						end
					end
				end
				new = new .. i1 .. camera
			end
			return s .. #new .. "." .. new, extra
		elseif type == "Instance" then
			return types[type] .. hex_encode(1, 2), { data }
		else
			return encode(data), {}
		end
	end
	function library.decode(data, extra)
		if data == nil then
			return
		end
		local function hex_decode(IN: string): number
			return tonumber(IN, 16)
		end
		local rtypes = (function(): table
			local a = {}
			for i, v in pairs(types) do
				a[v] = i
			end
			return a
		end)()
		local function decode(t, extra)
			local p = 0
			local function read(l)
				l = l or 1
				p = p + l
				return t:sub(p - l + 1, p)
			end
			local function get(a)
				local k = ""
				while p < #t do
					if t:sub(p + 1, p + 1) == a then
						break
					else
						k = k .. read()
					end
				end
				return k
			end
			local type = rtypes[read()]
			local c

			if type == "nil" then
				read()
			elseif type == "boolean" then
				local d = read()
				c = d == "1" and true or false
			elseif type == "number" then
				local length = tonumber(get("."))
				local d = read(length + 1):sub(2, -1)
				c = tonumber(d)
			elseif type == "string" then
				local length = tonumber(get(".")) --read()
				local d = read(length + 1):sub(2, -1)
				c = d
			elseif type == "Vector3" then
				local function getnext()
					local length = hex_decode(read(2))
					local a = read(tonumber(length))
					return tonumber(a)
				end
				local x, y, z = getnext(), getnext(), getnext()
				c = Vector3.new(x, y, z)
			elseif type == "CFrame" then
				local a = {}
				for i = 1, 12 do
					local l = hex_decode(read(2))
					local b = read(tonumber(l))
					a[i] = tonumber(b)
				end
				c = CFrame.new(unpack(a))
			elseif type == "Instance" then
				local pos = hex_decode(read(2))
				c = extra[tonumber(pos)]
			elseif type == "Color3" then
				local a = {}
				for i = 1, 3 do
					local l = hex_decode(read(2))
					local b = read(tonumber(l))
					a[i] = tonumber(b)
				end
				c = Color3.new(unpack(a))
			elseif type == "EnumItem" then
				local l = get(".")

				local leng = l:gsub('%D+', '')
				local enumType = l:gsub('%d+', '')
				local a = read(tonumber(leng) + 1):sub(2)

				c = Enum[enumType][a]
			end
			return c
		end
		extra = extra or {}

		local type = rtypes[data:sub(1, 1)]
		if type == "table" then
			local p = 0
			local function read(l)
				l = l or 1
				p = p + l
				return data:sub(p - l + 1, p)
			end
			local function get(a)
				local k = ""
				while p < #data do
					if data:sub(p + 1, p + 1) == a then
						break
					else
						k = k .. read()
					end
				end
				return k
			end

			local length = tonumber(get("."):sub(2, -1))
			read()

			local new = {}

			local l = 0
			while p <= length do
				l = l + 1

				local function getnext()
					local i
					local t = read()
					local type = rtypes[t]

					if type == "nil" then
						i = decode(t .. read())
					elseif type == "boolean" then
						i = decode(t .. read())
					elseif type == "number" then
						local l = get(".")

						local dc = t .. l .. read()
						local a = read(tonumber(l))
						dc = dc .. a

						i = decode(dc)
					elseif type == "string" then
						local l = get(".")
						local dc = t .. l .. read()
						local a = read(tonumber(l))
						dc = dc .. a

						i = decode(dc)
					elseif type == "Vector3" then
						local function getnext()
							local length = hex_decode(read(2))
							local a = read(tonumber(length))
							return tonumber(a)
						end
						local x, y, z = getnext(), getnext(), getnext()
						i = Vector3.new(x, y, z)
					elseif type == "CFrame" then
						local a = {}
						for i = 1, 12 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l)) -- why did I decide to do this
							a[i] = tonumber(b)
						end
						i = CFrame.new(unpack(a))
					elseif type == "Instance" then
						local pos = hex_decode(read(2))
						i = extra[tonumber(pos)]
					elseif type == "Color3" then
						local a = {}
						for i = 1, 3 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l))
							a[i] = tonumber(b)
						end
						i = Color3.new(unpack(a))
					elseif type == "table" then
						local l = get(".")
						local dc = t .. l .. read() .. read(tonumber(l))
						i = library.decode(dc, extra)
					elseif type == "EnumItem" then
						local l = get(".")

						local leng = l:gsub('%D+', '')
						local enumType = l:gsub('%d+', '')
						local a = read(tonumber(leng) + 1):sub(2)

						i = Enum[enumType][a]
					end
					return i
				end
				local i = getnext()
				local v = getnext()

				new[(typeof(i) ~= "nil" and i or l)] = v
			end

			return new
		elseif type == "Instance" then
			local pos = tonumber(hex_decode(data:sub(2, 3)))
			return extra[pos]
		else
			return decode(data, extra)
		end
	end
end

do
    function library.Functions.Vector2ToUDim2(value: Vector2)
        return UDim2.fromOffset(value.X, value.Y)
    end
    function library.Functions.BetterFind(t: table, value)
        for i, v in pairs(t) do
            if v == value then
                return i
            end
        end
    end
	function library.Functions.BetterFindIndex(t: table, value)
		for i, v in pairs(t) do
			if tostring(i):lower() == value:lower() then
				return v
			end
		end
	end
	function library.Functions.mergeTable(t1: table, t2: table): table
		for i, v in pairs(t2) do
			t1[i] = v
		end
		return t1
	end
    function library.Functions.GetTextSize(Text: string, TextSize: number, Font: EnumItem): Vector2
        return game:GetService('TextService'):GetTextSize(Text:gsub('<[^<>]->', ''), TextSize, Font, Vector2.new(math.huge, TextSize))
    end
    function library.Functions.Instance(className: string, properties: table, children: table, radius: UDim): Instance
        local object = Instance.new(className)
        for i, v in pairs(properties or {}) do
            object[i] = v
            if typeof(v) == 'Color3' then
                local theme = library.Functions:BetterFind(library.Settings.theme, v)
                if theme then
                    library.objects[theme] = library.objects[theme] or {}
                    library.objects[theme][i] = library.objects[theme][i] or setmetatable({}, { _mode = 'k' })
                    table.insert(library.objects[theme][i], object)
					local lastTheme = library.objects[theme][i]
					object:GetPropertyChangedSignal(i):Connect(function()
						if lastTheme then
							if table.find(lastTheme, object) then
								table.remove(lastTheme, table.find(lastTheme, object))
								lastTheme = nil
							end
						end
						local newTheme = library.Functions:BetterFind(library.Settings.theme, object[i])
						if newTheme then
							library.objects[newTheme] = library.objects[newTheme] or {}
							library.objects[newTheme][i] = library.objects[newTheme][i] or setmetatable({}, { _mode = 'k' })
							table.insert(library.objects[newTheme][i], object)
							lastTheme = library.objects[newTheme][i]
						end
					end)
                end
            end
        end
        for i, module in pairs(children or {}) do
            module.Parent = object
        end
        if radius then
            local uicorner = Instance.new('UICorner', object)
            uicorner.CornerRadius = radius
        end
        return object
    end
    function library.Functions.addColors(c1: Color3, c2: Color3): Color3
        return Color3.new(c1.R + c2.R, c1.G + c2.G, c1.B + c2.B)
    end
    function library.Functions.Tween(instance: Instance, properties, duration: number, ...): Tween
        local Tween = game:GetService('TweenService'):Create(instance, TweenInfo.new(duration, ...), properties)
        Tween:Play()
        return Tween
    end
    function library.Functions.Ripple(instance: Instance, duration: number)
        local Ripple = library.Functions.Instance('Frame', {
            Parent = instance,
            BackgroundColor3 = library.Settings.theme.TextColor,
            BackgroundTransparency = 0.6,
            ZIndex = 10,
        }, {}, UDim.new(1, 0))
        Ripple.Position = UDim2.new(0, mouse.X - Ripple.AbsolutePosition.X, 0, mouse.Y - Ripple.AbsolutePosition.Y)
        local Size = instance.AbsoluteSize.X
        instance.ClipsDescendants = true
        local Tween = library.Functions.Tween(Ripple, {
            Position = UDim2.fromScale(math.clamp(mouse.X - instance.AbsolutePosition.X, 0, instance.AbsoluteSize.X) / instance.AbsoluteSize.X, instance, math.clamp(mouse.Y - instance.AbsolutePosition.Y, 0, instance.AbsoluteSize.Y) / instance.AbsoluteSize.Y) - UDim2.fromOffset(Size / 2, Size / 2),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Size, Size),
        }, duration or 0)
        Tween.Completed:connect(function()
            Ripple:Destroy()
        end)
        return Tween
    end
    function library.Functions.TextEffect(TextLabel: Instance, delay: number, await: boolean)
        TextLabel.Visible = true
        local displayText = TextLabel.Text
        displayText = displayText:gsub('<br%s*/>', '\n')
        displayText:gsub('<[^<>]->', '')
        local index = 0
        if await then
            for i, v in utf8.graphemes(displayText) do
                index = index + 1
                TextLabel.MaxVisibleGraphemes = index
                task.wait(delay)
            end
            TextLabel.MaxVisibleGraphemes = -1
        else
            task.spawn(function()
                for i, v in utf8.graphemes(displayText) do
                    index = index + 1
                    TextLabel.MaxVisibleGraphemes = index
                    task.wait(delay)
                end
                TextLabel.MaxVisibleGraphemes = -1
            end)
        end
    end
	function library.Functions.DraggingEnabled(instance: Instance, parent: Instance)
		parent = parent or instance
		local Dragging = false
		instance.InputBegan:Connect(function(input, processed)
			if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 or library.IsMobile and Enum.UserInputType.Touch then
				local tweens = {}
				local mousePos, framePos = input.Position, parent.Position
				Dragging = true
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
				repeat
					task.wait()
					local delta = Vector2.new(mouse.X - mousePos.X, mouse.Y - mousePos.Y)
					spawn(function()
						local tween = library.Functions.Tween(parent, { Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y) }, 0.1)
						table.insert(tweens, tween)
					end)
				until not Dragging
				for i, v in ipairs(tweens) do
					if v then
						v:Cancel()
					end
				end
			end
		end)
	end
	function library.Functions.DraggingEnded(callback)
		table.insert(library.Functions.ended, callback)
	end
	function library.Functions.InitializeKeybind()
		library.Functions.keybinds = {}
		library.Functions.ended = {}
		game:GetService('UserInputService').InputBegan:Connect(function(key, proc)
			if library.Functions.keybinds[key.KeyCode] and not proc then
				for i, bind in pairs(library.Functions.keybinds[key.KeyCode]) do
					bind()
				end
			end
		end)
		game:GetService('UserInputService').InputEnded:Connect(function(key)
			if key.UserInputType == Enum.UserInputType.MouseButton1 then
				for i, callback in pairs(library.Functions.ended) do
					callback()
				end
			end
		end)
	end
	function library.Functions.BindToKey(key, callback)
		library.Functions.keybinds[key] = library.Functions.keybinds[key] or {}
		table.insert(library.Functions.keybinds[key], callback)
		return {
			UnBind = function()
				for i, bind in pairs(library.Functions.keybinds[key]) do
					if bind == callback then
						table.remove(library.Functions.keybinds[key], i)
					end
				end
			end,
		}
	end
	function library.Functions.KeyPressed()
		local key = game:GetService('UserInputService').InputBegan:Wait()
		while key.UserInputType ~= Enum.UserInputType.Keyboard do
			key = game:GetService('UserInputService').InputBegan:Wait()
		end
		task.wait()
		return key
	end
	function library.Functions.SaveConfig_game(name_of_the_game: string, config: table)
		if library.IsFileSystem then
			if not isfolder(library.Name .. ' UI') then
				makefolder(library.Name .. ' UI')
			end
			if not isfolder(library.Name .. ' UI/Games') then
				makefolder(library.Name .. ' UI/Games')
			end
			if not isfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua') then
				writefile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua', library.encode(config))
			else
				local lastConfig = library.decode(readfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua'))
				config = library.Functions.mergeTable(lastConfig, config)
				writefile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua', library.encode(config))
			end
		end
	end
	function library.Functions.SaveConfig_game_noReplace(name_of_the_game: string, config: table)
		if library.IsFileSystem then
			if not isfolder(library.Name .. ' UI') then
				makefolder(library.Name .. ' UI')
			end
			if not isfolder(library.Name .. ' UI/Games') then
				makefolder(library.Name .. ' UI/Games')
			end
			if not isfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua') then
				writefile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua', library.encode(config))
			else
				local lastConfig = library.decode(readfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua'))
				local function check(t, saved)
					for i, v in pairs(t) do
						if not library.Functions.BetterFindIndex(saved, i) then
							saved[i] = v
						elseif typeof(v) == "table" then
							check(v, saved[i])
						end
					end
				end
				check(config, lastConfig)
				writefile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua', library.encode(lastConfig))
			end
		end
	end
	function library.Functions.LoadConfig_game(name_of_the_game: string)
		if library.IsFileSystem then
			if not isfolder(library.Name .. ' UI') then
				makefolder(library.Name .. ' UI')
			end
			if not isfolder(library.Name .. ' UI/Games') then
				makefolder(library.Name .. ' UI/Games')
			end
			if isfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua') then
				return library.decode(readfile(library.Name .. ' UI/Games/' .. name_of_the_game .. '.lua'))
			end
		end
	end
	function library.Save()
		if library.IsFileSystem then
			if not isfolder(library.Name .. ' UI') then
				makefolder(library.Name .. ' UI')
			end
			if not isfile(library.Name .. ' UI/Settings.lua') then
				writefile(library.Name .. ' UI/Settings.lua', library.encode({}))
			end

			local savesettings = library.decode(readfile(library.Name .. ' UI/Settings.lua'))
			for i, v in pairs(library.Settings) do
				savesettings[i] = v
			end

			writefile(library.Name .. ' UI/Settings.lua', library.encode(savesettings))
		end
	end
	function library.Load()
		if library.IsFileSystem then
			if not isfolder(library.Name .. ' UI') then
				makefolder(library.Name .. ' UI')
			end
			if not isfile(library.Name .. ' UI/Settings.lua') then
				return
			end

			for i, v in pairs(library.decode(readfile(library.Name .. ' UI/Settings.lua'))) do
				library.Settings[i] = v
			end
			return library.Settings
		end
	end
end

table.insert(library.end_funcs, function()
	for i, v in pairs(library.connections) do
		pcall(function()
			v:Disconnect()
		end)
		library.connections[i] = nil
	end
end)

do
	library.__index = library
	library.page.__index = library.page
	library.section.__index = library.section

    local Create = library.Functions.Instance
    function library:new() : table
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		repeat
			pcall(function()
				library.Parent:FindFirstChild(library.Name .. ' UI'):Destroy()
			end)
		until not library.Parent:FindFirstChild(library.Name .. ' UI')
		game:GetService("UserInputService").MouseIconEnabled = true
		library.Enabled = true

		library.Load()
		if library.Settings.AntiAFK then
			table.insert(library.connections, player.Idled:connect(function()
				pcall(function()
					game:service("VirtualUser"):ClickButton2(Vector2.new())
				end)
			end))
		end
        local ScreenGui = Create('ScreenGui', {
            Name = library.Name .. ' UI',
            Parent = library.Parent
        })
		table.insert(library.connections, ScreenGui.Destroying:connect(function()
			library:Close()
		end))
		table.insert(library.connections, game.Players.PlayerRemoving:Connect(function(plr)
			if plr == player then
				library:Close()
			end
		end))
		library.Settings.Elements_Size = math.max(ScreenGui.AbsoluteSize.Y * 0.025, 18)
		library.Settings.Elements_TextSize = math.max(ScreenGui.AbsoluteSize.Y * 0.018, 8)

        local MinSize = library.IsMobile and Vector2.new(220, 220) or Vector2.new(420, 220)
		local UISize = library.IsMobile and UDim2.new(0, math.max((ScreenGui.AbsoluteSize.X + 1) / 3.4, MinSize.X), 0, math.max(ScreenGui.AbsoluteSize.Y / 2.8, MinSize.Y)) or UDim2.new(0, math.max((ScreenGui.AbsoluteSize.X + 1) / 2.8, MinSize.X), 0, math.max(ScreenGui.AbsoluteSize.Y / 2.8, MinSize.Y))

		local show_icon = Create('ImageButton', {
			Name = 'show_icon',
			Parent = ScreenGui,
			Size = UDim2.new(0, math.max(ScreenGui.AbsoluteSize.Y * 0.04, 20), 0, math.max(ScreenGui.AbsoluteSize.Y * 0.04, 20)),
			Position = UDim2.new(0.5, 0, 0.05, 0),
			AnchorPoint = Vector2.new(0.5, 0.05),
			AutoButtonColor = false,
			ImageTransparency = 1,
			BackgroundTransparency = 1,
			Image = 'rbxassetid://6023426988',
			ImageColor3 = library.Settings.theme.Accent
		})
        local Frame = Create('Frame', {
            Parent = ScreenGui,
            Size = UISize,
            BackgroundColor3 = library.Settings.theme.Background,
            BackgroundTransparency = 0.3,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
        }, {
            Create('Frame', {
                Name = 'Top_Frame',
                Size = UDim2.new(1, 0, 0.1, 0),
                BackgroundColor3 = library.Settings.theme.Background
            }, {
                Create('Frame', {
                    Name = ' ',
                    Size = UDim2.new(1, 0.5, 0.5, 0),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundColor3 = library.Settings.theme.Background,
                    BorderSizePixel = 0
                }),
                Create('Frame', {
                    Name = 'Container',
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1
                }, {
                    Create('UIPadding', {
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10)
                    }),
                    Create('Frame', {
                        Name = 'Left',
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1
                    }, {
                        Create('UIListLayout', {
                            Padding = UDim.new(0, 15),
                            FillDirection = Enum.FillDirection.Horizontal,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        Create('Frame', {
                            Name = 'Logo',
                            Size = UDim2.new(0, 0, 0.9, 0),
                            BackgroundTransparency = 1,
                            LayoutOrder = 0,
                            ZIndex = 2
                        }, {
                            Create('ImageButton', {
                                Size = UDim2.new(1, 0, 1, 0),
                                AutoButtonColor = false,
                                BackgroundTransparency = 1,
                                Image = 'rbxassetid://6023426988',
                                ImageColor3 = library.Settings.theme.Accent,
                                ZIndex = 2
                            })
                        }),
                        Create('TextLabel', {
                            Name = 'UI_Name',
                            Size = UDim2.new(1, 0, 0.60, 0),
                            BackgroundTransparency = 1,
                            Text = '<b>' .. library.Name .. '</b>',
                            Font = Enum.Font.SciFi,
                            RichText = true,
                            TextScaled = true,
                            TextColor3 = library.Settings.theme.TextColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Bottom,
                            LayoutOrder = 1,
                            ZIndex = 2
                        }),
                        Create('Frame', {
                            Name = 'Separator',
                            Size = UDim2.new(0, 2, 0.65, 0),
                            LayoutOrder = 2,
                            ZIndex = 2
                        }, {
                            Create('UIGradient', {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, library.Settings.theme.Accent),
                                    ColorSequenceKeypoint.new(0.5, library.Functions.addColors(library.Settings.theme.Background, Color3.fromRGB(10, 10, 10))),
                                    ColorSequenceKeypoint.new(1, library.Settings.theme.Accent),
                                }),
                                Offset = Vector2.new(0, -1),
                                Rotation = 90
                            })
                        }, UDim.new(1, 0)),
                        Create('TextLabel', {
                            Name = 'UI_Version',
                            Size = UDim2.new(1, 0, 0.40, 0),
                            BackgroundTransparency = 1,
                            Text = library.Version,
                            Font = Enum.Font.SciFi,
                            TextScaled = true,
                            TextColor3 = library.Settings.theme.LightContrast,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Bottom,
                            LayoutOrder = 3,
                            ZIndex = 2
                        }),
                        Create('Frame', {
                            Name = 'Search_Frame',
                            Size = UDim2.new(0.4, 0, 0.45, 0),
                            BackgroundTransparency = 1,
							Visible = not library.IsMobile,
                            LayoutOrder = 4,
                            ZIndex = 2
                        }, {
                            Create('UIPadding', {
                                PaddingLeft = UDim.new(0, 15)
                            }),
                            Create('TextBox', {
                                BackgroundTransparency = 1,
                                ClearTextOnFocus = true,
                                Size = UDim2.new(1, 10, 0.9, 0),
                                Font = library.Settings.Elements_Font,
                                PlaceholderColor3 = library.Settings.theme.LightContrast,
                                PlaceholderText = 'Search...',
                                Text = '',
                                TextColor3 = library.Settings.theme.TextColor,
								TextSize = library.Settings.Elements_TextSize,
                                TextXAlignment = Enum.TextXAlignment.Left
                            }, {
                                Create('Frame', {
                                    Size = UDim2.new(1, 0, 0, 2),
                                    Position = UDim2.new(0, 0, 1.3, 0),
                                    AnchorPoint = Vector2.new(0, 1),
                                    BackgroundColor3 = library.Settings.theme.LightContrast,
                                    ZIndex = 2
                                }, {}, UDim.new(1, 0)),
                            }),
                        }),
                        Create('ImageButton', {
                            Name = 'Search_Button',
                            AutoButtonColor = false,
                            Size = UDim2.new(0, 0, 0.65, 0),
                            BackgroundColor3 = library.Settings.theme.DarkContrast,
							Visible = not library.IsMobile,
                            LayoutOrder = 5,
                            ZIndex = 2
                        }, {
                            Create('ImageLabel', {
                                Size = UDim2.new(0.75, 0, 0.75, 0),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Image = 'rbxassetid://7072721559',
                                ImageColor3 = library.Settings.theme.TextColor,
                                ZIndex = 2
                            })
                        }, UDim.new(0, 5)),
                    }),
                    Create('Frame', {
                        Name = 'Right',
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1
                    }, {
                        Create('UIListLayout', {
                            Padding = UDim.new(0, 15),
                            FillDirection = Enum.FillDirection.Horizontal,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            HorizontalAlignment = Enum.HorizontalAlignment.Right,
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        Create('ImageButton', {
                            Name = 'Hide_Button',
                            AutoButtonColor = false,
                            Size = UDim2.new(0, 0, 0.65, 0),
                            BackgroundColor3 = library.Settings.theme.DarkContrast,
                            ZIndex = 2
                        }, {
                            Create('ImageLabel', {
                                Size = UDim2.new(0.75, 0, 0.75, 0),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Image = 'rbxassetid://7733717447',
                                ImageColor3 = library.Settings.theme.TextColor,
                                ZIndex = 2
                            })
                        }, UDim.new(0, 5)),
                    })
                })
            }, UDim.new(0, 8)),
            Create('Frame', {
                Name = 'Left_Frame',
                Size = UDim2.new(0, math.max(UISize.X.Offset * 0.07, 25), 1, 0),
                BackgroundColor3 = library.Settings.theme.Background
            }, {
                Create('Frame', {
                    Name = ' ',
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundColor3 = library.Settings.theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, 0, 0, 0)
                }),
                Create('Frame', {
                    Name = 'Container',
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                }, {
                    Create('UIListLayout', {
                        Padding = UDim.new(0, 15),
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center
                    }),
                    Create('UIPadding', {
                        PaddingTop = UDim.new(0.1, 20)
                    }),
                }),
            }, UDim.new(0, 8)),
            Create('ScrollingFrame', {
                Name = 'Section_Container',
                ClipsDescendants = true,
                ScrollingEnabled = false,
                Size = UDim2.new(1, -math.max(UISize.X.Offset * 0.07, 25), 0.9, 0),
                Position = UDim2.new(0, math.max(UISize.X.Offset * 0.07, 25), 0.1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.X,
                CanvasSize = UDim2.new(0, 0, 0, 0),
            }, {
                Create('UIListLayout', {
                    Padding = UDim.new(0, 10),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                Create('ScrollingFrame', {
                    Name = 'Home_Container',
                    LayoutOrder = 0,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = library.Settings.theme.TextColor,
                }, {
                    Create('UIListLayout', {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 10),
                    }),
                    Create('UIPadding', {
                        PaddingRight = UDim.new(0, 15),
                    }),
                })
            }),
        }, UDim.new(0, 20))
        Frame.Section_Container.Home_Container.Size = UDim2.new(1, 0, 0, Frame.Section_Container.AbsoluteSize.Y)
        Frame.Top_Frame.Container.Left.Logo.Size = UDim2.new(0, Frame.Top_Frame.Container.Left.Logo.AbsoluteSize.Y, 0.9, 0)
        Frame.Top_Frame.Container.Left.UI_Name.Size = UDim2.new(0, library.Functions.GetTextSize(Frame.Top_Frame.Container.Left.UI_Name.Text, Frame.Top_Frame.Container.Left.UI_Name.TextBounds.Y, Frame.Top_Frame.Container.Left.UI_Name.Font).X, 0.6, 0)
        Frame.Top_Frame.Container.Left.UI_Version.Size = UDim2.new(0, library.Functions.GetTextSize(Frame.Top_Frame.Container.Left.UI_Version.Text, Frame.Top_Frame.Container.Left.UI_Version.TextBounds.Y, Frame.Top_Frame.Container.Left.UI_Version.Font).X, 0.4, 0)

        Frame.Top_Frame.Container.Left.Search_Button.Size = UDim2.new(0, Frame.Top_Frame.Container.Left.Search_Button.AbsoluteSize.Y, 0.65, 0)
        Frame.Top_Frame.Container.Right.Hide_Button.Size = UDim2.new(0, Frame.Top_Frame.Container.Right.Hide_Button.AbsoluteSize.Y, 0.65, 0)

		library.Functions.InitializeKeybind()
		library.Functions.DraggingEnabled(Frame.Left_Frame, Frame)
		library.Functions.DraggingEnabled(Frame.Top_Frame, Frame)

        game:GetService('TweenService'):Create(Frame.Top_Frame.Container.Left.Separator.UIGradient, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0), { Offset = Vector2.new(0, 1) }):Play()
        game:GetService('TweenService'):Create(Frame.Top_Frame.Container.Left.Logo.ImageButton, TweenInfo.new(5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, -1, true, 0), { Rotation = 360 }):Play()
        game:GetService('TweenService'):Create(show_icon, TweenInfo.new(5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, -1, true, 0), { Rotation = 360 }):Play()

		local lib = setmetatable({
            container = ScreenGui,
            pageContainer = Frame.Left_Frame.Container,
            sectionContainer = Frame.Section_Container,
            pages = {},
        }, library)

		task.spawn(function()
			local i = 0
			while true do task.wait()
				i += 1
				if i == 5 then
					break
				end
				if #lib.pages > 0 then
					pcall(function()
						lib:SelectPage()
					end)
					break
				end
			end
		end)

        Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Focused:connect(function()
			if lib.toggling then
				return
			end
            library.Functions.Tween(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Frame, { BackgroundColor3 = library.Settings.theme.Accent }, 0.2)
			if library.focusedPage then
				for i, v in pairs(library.focusedPage.container:GetDescendants()) do
					if v:FindFirstChild('Section') and v:FindFirstChild('Section').ClassName == 'NumberValue' then
						local Elements = 0
						for i, v in pairs(v:GetChildren()) do
							if v.Name:match('_Element') then
								Elements += 1
							end
						end
						v.Visible = true
					end
					if v.Name:match('_Element') then
						if v:FindFirstChild('SearchValue') then
							v.Visible = true
							v.Parent.Visible = true
						end
					end
				end
				task.spawn(function()
					library.focusedPage:Resize()
				end)
			end
        end)
        Frame.Top_Frame.Container.Left.Search_Frame.TextBox.FocusLost:Connect(function()
			if lib.toggling then
				return
			end
            library.Functions.Tween(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Frame, { BackgroundColor3 = library.Settings.theme.LightContrast }, 0.2)
			if library.focusedPage then
				for i, v in pairs(library.focusedPage.container:GetDescendants()) do
					if v:FindFirstChild('Section') and v:FindFirstChild('Section').ClassName == 'NumberValue' then
						local Elements = 0
						for i, v in pairs(v:GetChildren()) do
							if v.Name:match('_Element') then
								Elements += 1
							end
						end
						if Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text ~= '' then
							if Elements == 0 then
								v.Visible = false
							else
								v.Visible = true
							end
						else
							v.Visible = true
						end
					end
					if v.Name:match('_Element') then
						if v:FindFirstChild('SearchValue') then
							if v:FindFirstChild('SearchValue').Value:lower():find(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text:lower()) then
								v.Visible = true
							else
								v.Visible = false
							end
							local toggle = true
							for _, p in pairs(v.Parent:GetChildren()) do
								if p.Name:match('_Element') then
									if p.Visible then
										toggle = false
									end
								end
							end
							if toggle then
								v.Parent.Visible = false
							else
								v.Parent.Visible = true
							end
						end
					end
				end
				task.spawn(function()
					library.focusedPage:Resize()
				end)
			end
        end)
		Frame.Top_Frame.Container.Left.Search_Frame.TextBox:GetPropertyChangedSignal('Text'):Connect(function()
			if lib.toggling then
				return
			end
			if not library.focusedPage then
				Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text = ''
			end
		end)
        library.Functions.TextEffect(Frame.Top_Frame.Container.Left.UI_Version, 0.15)
        Frame.Top_Frame.Container.Left.Search_Button.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
            library.Functions.Ripple(Frame.Top_Frame.Container.Left.Search_Button, 0.6)
			if library.focusedPage then
				for i, v in pairs(library.focusedPage.container:GetDescendants()) do
					if v:FindFirstChild('Section') and v:FindFirstChild('Section').ClassName == 'NumberValue' then
						local Elements = 0
						for i, v in pairs(v:GetChildren()) do
							if v.Name:match('_Element') then
								Elements += 1
							end
						end
						if Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text ~= '' then
							if Elements == 0 then
								v.Visible = false
							else
								v.Visible = true
							end
						else
							v.Visible = true
						end
					end
					if v.Name:match('_Element') then
						if v:FindFirstChild('SearchValue') then
							if
								v
									:FindFirstChild('SearchValue').Value
									:lower()
									:find(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text:lower())
							then
								v.Visible = true
							else
								v.Visible = false
							end
							local toggle = true
							for _, p in pairs(v.Parent:GetChildren()) do
								if p.Name:match('_Element') then
									if p.Visible then
										toggle = false
									end
								end
							end
							if toggle then
								v.Parent.Visible = false
							else
								v.Parent.Visible = true
							end
						end
					end
				end
				task.spawn(function()
					library.focusedPage:Resize()
				end)
			end
        end)
        Frame.Top_Frame.Container.Right.Hide_Button.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
            library.Functions.Ripple(Frame.Top_Frame.Container.Right.Hide_Button, 0.6)
			lib:toggle()
        end)
		show_icon.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
			lib:toggle()
        end)
        Frame.Top_Frame.Container.Left.Logo.ImageButton.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
            library.Functions.Tween(lib.sectionContainer, { CanvasPosition = Vector2.new(0, 0) }, 0.2)
			if #lib.pages > 0 and library.focusedPage then
				lib:SelectPage(library.focusedPage, false)
				library.focusedPage = nil
			end
        end)

		table.insert(library.connections, game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
			if lib.toggling or not library.Enabled or not library.Settings.prefix or typeof(library.Settings.prefix) ~= "EnumItem" then
				return
			end
			if not processed and input.KeyCode == library.Settings.prefix then
				lib:toggle()
			end
		end))

        return lib
    end
	function library:Close()
		library.Enabled = false
		library.Save()
		task.spawn(function()
			for _, func in pairs(library.end_funcs) do
				func()
			end
			for i, key in pairs(library.binds) do
				pcall(function()
					key:UnBind()
				end)
				library.binds[i] = nil
			end
		end)
	end
	function library:addPage(config: table): table
		config = config or {}
		config.library = self
		local page = library.page.new(config)

		table.insert(self.pages, page)

        local OriginalSize = page.button.Size
		page.button.MouseEnter:Connect(function()
			if library.focusedPage ~= page then
                library.Functions.Tween(page.button, { Size = page.button.Size + UDim2.fromOffset(4, 4) }, 0.2).Completed:Wait()
			end
		end)
		page.button.MouseLeave:Connect(function()
			library.Functions.Tween(page.button, { Size = OriginalSize }, 0.2).Completed:Wait()
		end)
		page.button.MouseButton1Click:Connect(function()
			self:SelectPage(page, true)
			library.Functions.Tween(page.button, { Size = OriginalSize }, 0.2).Completed:Wait()
		end)
		return page
	end
	function library:SelectPage(page: table, toggle: boolean)
		if toggle and library.focusedPage == page then
			return
		end

		if not page and #self.pages > 0 then
			page = self.pages[1]
			library.Functions.Tween(page.button, { ImageColor3 = library.Settings.theme.Accent }, 0.2)

			local focusedPage = library.focusedPage
			library.focusedPage = page

			if focusedPage then
				self:SelectPage(focusedPage)
			end
			task.wait(0.1)

            local position = Vector2.new(0, page.container.AbsoluteSize.Y * page.container.LayoutOrder + (((page.container.Parent.AbsoluteSize.Y - page.container.AbsoluteSize.Y) + (page.container.Parent.UIListLayout.Padding.Offset / page.container.LayoutOrder)) * page.container.LayoutOrder))
            library.Functions.Tween(page.container.Parent, { CanvasPosition = position }, 0.2)

			task.spawn(function()
				page:Resize()
			end)
			return
		end

		if toggle then
			library.Functions.Tween(page.button, { ImageColor3 = library.Settings.theme.Accent }, 0.2)

			local focusedPage = library.focusedPage
			library.focusedPage = page

			if focusedPage then
				self:SelectPage(focusedPage)
			end
			task.wait(0.1)

            local position = Vector2.new(0, page.container.AbsoluteSize.Y * page.container.LayoutOrder + (((page.container.Parent.AbsoluteSize.Y - page.container.AbsoluteSize.Y) + (page.container.Parent.UIListLayout.Padding.Offset / page.container.LayoutOrder)) * page.container.LayoutOrder))
            library.Functions.Tween(page.container.Parent, { CanvasPosition = position }, 0.2)

			task.spawn(function()
				page:Resize()
			end)
		else
			library.Functions.Tween(page.button, { ImageColor3 = library.Settings.theme.LightContrast }, 0.2)
			if page == library.focusedPage then
				library.focusedPage = nil
			end
			task.spawn(function()
				for i, v in pairs(page.container:GetDescendants()) do
					if v:FindFirstChild('Section') and v:FindFirstChild('Section').ClassName == 'NumberValue' then
						v.Visible = true
					end
					if v.Name:match('_Element') then
						v.Visible = true
					end
				end
			end)
		end
	end
	function library:toggle()
		if self.toggling then
			return
		end

		local container = self.container:FindFirstChild("Frame")
		if not container then
			return
		end

		self.toggling = true

		if self.Visible then
			self.Visible = false
			self.container.show_icon.Visible = true
			library.Functions.Tween(self.container.show_icon, {ImageTransparency = 0}, 0.6)
			library.Functions.Tween(container, {Position = container.Position + UDim2.new(1, 0, 0, 0)}, 0.6)
		else
			self.Visible = true
			library.Functions.Tween(self.container.show_icon, {ImageTransparency = 1}, 0.4)
			library.Functions.Tween(container, {Position = container.Position - UDim2.new(1, 0, 0, 0)}, 0.4)
			task.spawn(function()
				task.wait(0.4)
				self.container.show_icon.Visible = false
			end)
		end
		wait(1)

		self.toggling = false
	end

	function library.page.new(config: table): table
		config = config or {}
        local button = Create('ImageButton', {
			Parent = library.Functions.BetterFindIndex(config, 'library').pageContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.4, 0, 0, 0),
            AutoButtonColor = false,
            Image = (library.Functions.BetterFindIndex(config, 'icon') and (library.Functions.BetterFindIndex(config, 'icon'):match('//') and library.Functions.BetterFindIndex(config, 'icon') or 'rbxassetid://' .. library.Functions.BetterFindIndex(config, 'icon'))) or 'rbxassetid://7072717639',
            ImageColor3 = library.Settings.theme.LightContrast,
            ZIndex = 2
        })
        button.Size = UDim2.new(0.4, 0, 0, button.AbsoluteSize.X)

		local container = Create('ScrollingFrame', {
			Name = library.Functions.BetterFindIndex(config, 'Title') or 'Container',
			Parent = library.Functions.BetterFindIndex(config, 'library').sectionContainer,
            LayoutOrder = #library.Functions.BetterFindIndex(config, 'library').sectionContainer:GetChildren() - 1,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, library.Functions.BetterFindIndex(config, 'library').sectionContainer.AbsoluteSize.Y - 10),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 0,
		}, {
			Create('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),
			Create('UIPadding', {
				PaddingTop = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
			})
		})
        library.Functions.BetterFindIndex(config, 'library').sectionContainer.CanvasSize = UDim2.new(0, 0, #library.Functions.BetterFindIndex(config, 'library').sectionContainer:GetChildren() - 1, 0)
		return setmetatable({
			library = library.Functions.BetterFindIndex(config, 'library'),
			button = button,
			container = container,
			sections = {},
		}, library.page)
	end
	function library.page:addSection(config: table): table
		config = config or {}
		config.page = self
		local section = library.section.new(config)

		table.insert(self.sections, section)

		return section
	end
	function library.page:Resize()
		local size = (#self.sections - 1) * 10 + self.container.Parent.UIListLayout.Padding.Offset

		for i, section in pairs(self.sections) do
			section:Resize()
			size += section.parent.UIListLayout.AbsoluteContentSize.Y
		end
		for i, section in pairs(self.sections) do
			section:Resize()
		end
		self.container.CanvasSize = UDim2.new(0, 0, 0, size)
	end

	function library.section.new(config: table): table
		config = config or {}

		local divisions = library.IsMobile and 1 or library.Functions.BetterFindIndex(config, 'Divisions') or 1

		local container = Create('Frame', {
			Parent = library.Functions.BetterFindIndex(config, 'page').container,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
		}, {
			Create('UIListLayout', {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
			}),
		})

		local sections = {}
		for i = 1, divisions do
			local section = Create('Frame', {
				Parent = container,
				BackgroundColor3 = library.Settings.theme.Contrast,
				Size = UDim2.new(1 / divisions, -(((5 * (divisions - 1)) / divisions) + 1), 0, 16),
			}, {
				Create('UICorner', {
					CornerRadius = UDim.new(0, 8),
				}),
				Create('UIPadding', {
					PaddingTop = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				}),
				Create('UIListLayout', {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				Create('NumberValue', {
					Name = 'Section',
					Value = divisions,
				}),
			})
			table.insert(sections, i, section)
		end

		return setmetatable({
			page = library.Functions.BetterFindIndex(config, 'page'),
			parent = container,
			container = sections,
			colorpickers = {},
			modules = {},
			binds = {},
			lists = {},
		}, library.section)
	end
	function library.section:Resize()
		local allSizes = {}

		local containerI = 0
		for i, v in pairs(self.container) do
			if v.ClassName == 'Frame' then
				if v.Visible then
					containerI += 1
				end
			end
		end
		for i, v in pairs(self.container) do
			if v.ClassName == 'Frame' then
				local a = 16
				for _, v in pairs(v:GetChildren()) do
					if v.Name:match('_Element') then
						if v.Visible then
							a += v.AbsoluteSize.Y + 4
						end
					end
				end
				v.Size = UDim2.new(1 / containerI, -(((5 * (containerI - 1)) / containerI) + 1), 0, a)
				table.insert(allSizes, i, a)
			end
		end
		if containerI == 0 then
			self.parent.Visible = false
			return
		else
			self.parent.Visible = true
		end

		local size = 0
		for i = 1, #allSizes do
			local a = allSizes[i]
			size = math.max(size, a)
		end

		library.Functions.Tween(self.parent, { Size = UDim2.new(1, 0, 0, size) }, 0)
	end
	function library.section:getModule(info): Instance
		if table.find(self.modules, info) or library.Functions.BetterFind(self.modules, info) then
			return info
		end

		for i, module in pairs(self.modules) do
			if (module:FindFirstChild("Title") or module:FindFirstChild("TextBox", true)) and (module:FindFirstChild("Title") or module:FindFirstChild("TextBox", true)).Text == info then
				return module
			end
		end

		error("No module found under " .. tostring(info))
	end

	function library.section:addButton(config: table): table
		config = config or {}
		local button = Create('ImageButton', {
			Name = 'Button_Element',
			Parent = (library.Functions.BetterFindIndex(config, 'section') or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, 'section') or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
            Create('TextLabel', {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = (library.Functions.BetterFindIndex(config, 'Title') and library.Functions.BetterFindIndex(config, 'Title') ~= '' and library.Functions.BetterFindIndex(config, 'Title')) or 'Button',
                Font = library.Settings.Elements_Font,
				TextSize = library.Settings.Elements_TextSize,
                RichText = true,
                TextColor3 = library.Settings.theme.TextColor,
            }),
			Create('Frame', {
				Name = 'Disabled_Frame',
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = library.Functions.BetterFindIndex(config, 'Disabled') or false,
				ZIndex = 2
			}, {
				Create('ImageLabel', {
					Image = 'rbxassetid://7072718362',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.55, 0),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5)),
			Create('BoolValue', {
				Name = 'Disabled',
				Value = library.Functions.BetterFindIndex(config, 'Disabled') or false,
			}),
			Create('StringValue', {
				Name = 'SearchValue',
				Value = ((library.Functions.BetterFindIndex(config, 'Title') and library.Functions.BetterFindIndex(config, 'Title') ~= '' and library.Functions.BetterFindIndex(config, 'Title')) or 'Button'):gsub('<[^<>]->', ''),
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5))

        button.Disabled_Frame.ImageLabel.Size = UDim2.new(0, button.Disabled_Frame.ImageLabel.AbsoluteSize.Y, 0.55, 0)
        button.Disabled_Frame.ImageLabel.Position = UDim2.new(1, -button.Disabled_Frame.ImageLabel.AbsoluteSize.Y, 0.5, 0)

		table.insert(self.modules, button)

		local debounce

		button.MouseButton1Click:Connect(function()
			if debounce then
				return
			end
			if button.Disabled.Value then
				return
			end

			library.Functions.Ripple(button, 0.5)

			debounce = true

			if library.Functions.BetterFindIndex(config, 'CallBack') then
				library.Functions.BetterFindIndex(config, 'CallBack')()
			end

			debounce = false
		end)

		local function update(update_config)
			update_config = update_config or {}
			if library.Functions.BetterFindIndex(update_config, 'Title') and library.Functions.BetterFindIndex(update_config, 'Title') ~= '' then
				button.Text = library.Functions.BetterFindIndex(update_config, "Title")
				button.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end
			local function check_boolean(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(update_config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(update_config, var)
					else
						return false
					end
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(config, var)
					else
						return false
					end
				else
					return false
				end
			end

			button.Disabled.Value = check_boolean("Disabled")
			button.Disabled_Frame.Visible = check_boolean("Disabled")
		end

		return { Instance = button, Update = update }
	end
	function library.section:addClipboardLabel(config: table): Instance
		config = config or {}

		local ClipboardLabel = Create('Frame', {
			Name = 'ClipboardLabel_Element',
			Parent = (library.Functions.BetterFindIndex(config, 'section') or 1) > #self.container
					and self.container[#self.container]
				or self.container[library.Functions.BetterFindIndex(config, 'section') or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create('UICorner', {
				CornerRadius = UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5),
			}),
			Create('UIPadding', {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
            Create('TextLabel', {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = (library.Functions.BetterFindIndex(config, 'Text') and library.Functions.BetterFindIndex(config, 'Text') ~= '' and library.Functions.BetterFindIndex(config, 'Text')) or 'Clipboard Label',
                Font = library.Settings.Elements_Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = library.Settings.Elements_TextSize,
				ClipsDescendants = true,
                RichText = true,
                TextColor3 = library.Settings.theme.LightContrast,
            }),
			Create('ImageButton', {
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				AutoButtonColor = false,
				Size = UDim2.new(0, 0, 0.85, 0),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}, {
				Create('UICorner', {
					CornerRadius = UDim.new(0, 5),
				}),
				Create('ImageLabel', {
					Image = 'rbxassetid://7072707790',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.55, 0, 0.55, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
				}),
			}),
			Create('StringValue', {
				Name = 'SearchValue',
				Value = ((library.Functions.BetterFindIndex(config, 'Text') and library.Functions.BetterFindIndex(config,'Text') ~= '' and library.Functions.BetterFindIndex(config, 'Text')) or 'Clipboard Label'):gsub('<[^<>]->', ''),
			}),
		})
		table.insert(self.modules, ClipboardLabel)
        ClipboardLabel.ImageButton.Size = UDim2.new(0, ClipboardLabel.ImageButton.AbsoluteSize.Y, 0.85, 0)

		ClipboardLabel.ImageButton.MouseButton1Click:connect(function()
			library.Functions.Ripple(ClipboardLabel.ImageButton, 0.5)
			if setclipboard then
				setclipboard(ClipboardLabel.TextLabel.Text:gsub('<[^<>]->', ''))
			end
		end)

		local function update(update_config)
			update_config = update_config or {}
			if library.Functions.BetterFindIndex(update_config, 'Text') and library.Functions.BetterFindIndex(update_config, 'Text') ~= '' then
				ClipboardLabel.TextLabel.Text = library.Functions.BetterFindIndex(update_config, "Text")
				ClipboardLabel.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Text")
			end
		end

		return { Instance = ClipboardLabel, Update = update }
	end
	function library.section:addDualLabel(config: table): Instance
		config = config or {}
		local titleText = ((library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title")) or "Title") .. ":"
		local descText = (library.Functions.BetterFindIndex(config, "Description") and library.Functions.BetterFindIndex(config, "Description") ~= "" and library.Functions.BetterFindIndex(config, "Description")) or "Description"

		local frame = Create("Frame", {
			Name = "DualLabel_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Text = titleText,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = library.Settings.Elements_Font,
				TextColor3 = library.Settings.theme.TextColor,
				ClipsDescendants = true,
				RichText = true,
			}),
			Create("TextLabel", {
				Name = "Description",
				BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Text = descText,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = library.Settings.Elements_Font,
				TextColor3 = library.Settings.theme.LightContrast,
				ClipsDescendants = true,
				RichText = true,
			}),
			Create("StringValue", {
				Name = "SearchValue",
				Value = titleText:gsub("<[^<>]->", ""),
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5))
		frame.Title.Size = UDim2.new(0, library.Functions.GetTextSize(titleText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X + 5, 1, 0)
		frame.Description.Size = UDim2.new(0, math.min(library.Functions.GetTextSize(descText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, frame.AbsoluteSize.X - library.Functions.GetTextSize(titleText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X), 1, 0)

		table.insert(self.modules, frame)

		local function update(update_config)
			update_config = update_config or {}
			if library.Functions.BetterFindIndex(update_config, 'Title') and library.Functions.BetterFindIndex(update_config, 'Title') ~= '' then
				frame.Title.Text = library.Functions.BetterFindIndex(update_config, "Title") .. ":"
			end
			if library.Functions.BetterFindIndex(update_config, 'Description') and library.Functions.BetterFindIndex(update_config, 'Description') ~= '' then
				frame.Description.Text = library.Functions.BetterFindIndex(update_config, "Description")
			end

			frame.Title.Size = UDim2.new(0, library.Functions.GetTextSize(titleText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X + 5, 1, 0)
			frame.Description.Size = UDim2.new(0, math.min(library.Functions.GetTextSize(descText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, frame.AbsoluteSize.X - library.Functions.GetTextSize(titleText, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X), 1, 0)
		end

		return { Instance = frame, Update = update }
	end
	function library.section:addLabel(config: table): Instance
		config = config or {}
		local label = Create("TextLabel", {
			Name = "Label_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			BackgroundTransparency = 1,
			TextSize = library.Functions.BetterFindIndex(config, "TextSize") or library.Settings.Elements_TextSize,
			TextXAlignment = library.Functions.BetterFindIndex(config, "TextXAlignment") or Enum.TextXAlignment.Left,
			TextYAlignment = library.Functions.BetterFindIndex(config, "TextYAlignment") or Enum.TextYAlignment.Center,
			Font = library.Functions.BetterFindIndex(config, "Font") or library.Settings.Elements_Font,
			TextColor3 = library.Settings.theme.TextColor,
			TextWrapped = true,
			RichText = true,
		}, {
			Create("StringValue", {
				Name = "SearchValue",
				Value = (library.Functions.BetterFindIndex(config, 'Text') and library.Functions.BetterFindIndex(config, 'Text') ~= '' and library.Functions.BetterFindIndex(config, "Text"):gsub('<[^<>]->', '')) or "Text Label",
			}),
		})

		local text = (library.Functions.BetterFindIndex(config, "Text") and library.Functions.BetterFindIndex(config, "Text") ~= "" and library.Functions.BetterFindIndex(config, "Text")) or "Text Label"
		for i = 1, text:len() do
			label.Text = text:sub(1, i)
			label.Size = UDim2.new(1, 0, 0, label.TextBounds.Y + ((library.Settings.Elements_Size) - label.TextBounds.Y))
		end

		label:GetPropertyChangedSignal("Size"):Connect(function()
			self:Resize()
		end)

		table.insert(self.modules, label)

		local function update(update_config)
			update_config = update_config or {}
			if library.Functions.BetterFindIndex(update_config, 'Text') and library.Functions.BetterFindIndex(update_config, 'Text') ~= '' then
				for i = 1, library.Functions.BetterFindIndex(update_config, "Text"):len() do
					label.Text = library.Functions.BetterFindIndex(update_config, "Text"):sub(1, i)
					label.Size = UDim2.new(1, 0, 0, label.TextBounds.Y)
				end
				label.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Text"):gsub('<[^<>]->', '')
			end
		end

		return { Instance = label, Update = update }
	end
	function library.section:addSlider(config: table): table
		config = config or {}
		local function checkValue(value)
			if value then
				if typeof(value) == "number" then
					return value
				else
					return tonumber(value:gsub('%D+', ''))
				end
			end
		end
		local min = math.clamp(checkValue(library.Functions.BetterFindIndex(config, "Min")) or 0, 0, math.huge)
		local max = math.clamp(checkValue(library.Functions.BetterFindIndex(config, "Max")) or 0, min, math.huge)
		local value = math.clamp(checkValue(library.Functions.BetterFindIndex(config, "Default")) or 0, min, max)

		local slider_text = (library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title")) or "Slider"
		local num_text = tostring(value)
		local slider = Create("Frame", {
			Name = "Slider_Element",
			BackgroundTransparency = 1,
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Size = UDim2.new(0, library.Functions.GetTextSize(slider_text, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 0, library.Settings.Elements_TextSize),
				Font = library.Settings.Elements_Font,
				RichText = true,
				Text = slider_text,
				TextColor3 = library.Settings.theme.TextColor,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Create("TextBox", {
				Name = "Count",
				BackgroundTransparency = 1,
				Size = UDim2.new(0, library.Functions.GetTextSize(num_text, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 0, library.Settings.Elements_TextSize),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Font = library.Settings.Elements_Font,
				Text = num_text,
				TextColor3 = library.Settings.theme.LightContrast,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			Create("ImageButton", {
				BackgroundTransparency = 1,
				Name = "Slider",
				Size = UDim2.new(1, 0, 0.35, 0),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
			}, {
				Create("UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Create("Frame", {
					Name = "Bar",
					Size = UDim2.new(1, 0, 0.4, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = library.Settings.theme.LightContrast,
				}, {
					Create("Frame", {
						Name = "Fill",
						Size = UDim2.new(0.8, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = library.Settings.theme.Accent,
					}, {
						Create("Frame", {
							Name = "Circle",
							Size = UDim2.new(0, 0, 2, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(1, -5, 0.5, 0),
							BackgroundColor3 = library.Settings.theme.Accent,
							BorderSizePixel = 0,
							BackgroundTransparency = 1,
						}, {}, UDim.new(1, 0)),
					}, UDim.new(1, 0)),
				}, UDim.new(1, 0)),
			}),
			Create("Frame", {
				Name = "Disabled_Frame",
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				BackgroundTransparency = 0.4,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = library.Functions.BetterFindIndex(config, "Disabled") or false,
				ZIndex = 2
			}, {
				Create('ImageLabel', {
					Image = 'rbxassetid://7072718362',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.55, 0),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create("BoolValue", {
				Name = "Disabled",
				Value = library.Functions.BetterFindIndex(config, "Disabled") or false,
			}),
			Create("StringValue", {
				Name = "SearchValue",
				Value = slider_text:gsub('<[^<>]->', ''),
			}),
		})
		slider.Slider.Bar.Fill.Circle.Size = UDim2.new(0, slider.Slider.Bar.Fill.Circle.AbsoluteSize.Y, 0, slider.Slider.Bar.Fill.Circle.AbsoluteSize.Y)
        slider.Disabled_Frame.ImageLabel.Size = UDim2.new(0, slider.Disabled_Frame.ImageLabel.AbsoluteSize.Y, 0.55, 0)
        slider.Disabled_Frame.ImageLabel.Position = UDim2.new(1, -slider.Disabled_Frame.ImageLabel.AbsoluteSize.Y, 0.5, 0)

		table.insert(self.modules, slider)


		local dragging, last

		local function update(update_config)
			update_config = update_config or {}

			if library.Functions.BetterFindIndex(update_config, "Title") and library.Functions.BetterFindIndex(update_config, "Title") ~= "" then
				slider.Title.Text = library.Functions.BetterFindIndex(update_config, "Title")
				slider.Title.Size = UDim2.new(0, library.Functions.GetTextSize(library.Functions.BetterFindIndex(update_config, "Title"), library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 0, library.Settings.Elements_TextSize)
				slider.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end

			local function check_boolean(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(update_config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(update_config, var)
					else
						return false
					end
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(config, var)
					else
						return false
					end
				else
					return false
				end
			end

			slider.Disabled.Value = check_boolean("Disabled")
			slider.Disabled_Frame.Visible = check_boolean("Disabled")

			local percent = (mouse.X - slider.Slider.Bar.AbsolutePosition.X) / slider.Slider.Bar.AbsoluteSize.X

			if library.Functions.BetterFindIndex(update_config, "Min") then
				min = math.clamp(checkValue(library.Functions.BetterFindIndex(update_config, "Min")) or 0, 0, math.huge)
			end
			if library.Functions.BetterFindIndex(update_config, "Max") then
				max = math.clamp(checkValue(library.Functions.BetterFindIndex(update_config, "Max")) or 0, min, math.huge)
			end

			if library.Functions.BetterFindIndex(update_config, "Value") then
				value = math.clamp(checkValue(library.Functions.BetterFindIndex(update_config, "Value")) or 0, min, max)
				percent = (library.Functions.BetterFindIndex(update_config, "Value") - min) / (max - min)
			end

			percent = math.clamp(percent, 0, 1)
			local Value = library.Functions.BetterFindIndex(update_config, "Value") and value or math.floor(min + (max - min) * percent)
			library.Functions.Tween(slider.Slider.Bar.Fill, { Size = UDim2.new(percent, 0, 1, 0) }, 0.1)
			slider.Count.Text = Value
			slider.Count.Size = UDim2.new(0, library.Functions.GetTextSize(tostring(Value), library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 0, library.Settings.Elements_TextSize)

			return Value
		end
		local function callback(v)
			if library.Functions.BetterFindIndex(config, "CallBack") then
				library.Functions.BetterFindIndex(config, "CallBack")(v)
			end
		end

		update({
			Value = value,
			Min = min,
			Max = max,
		})

		slider.Count:GetPropertyChangedSignal("Text"):Connect(function()
			slider.Count.Text = math.clamp(tonumber(slider.Count.Text:gsub('%D+', ''):len() > 0 and slider.Count.Text:gsub('%D+', '') or 0), min, max)
			if slider.Count.Text == "0" then
				slider.Count.CursorPosition = 2
			end

			update({
				Value = tonumber(slider.Count.Text),
				Min = min,
				Max = max
			})
			callback(value)
		end)
		slider.Slider.InputBegan:Connect(function(input)
			if slider.Disabled.Value then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or library.IsMobile and Enum.UserInputType.Touch then
				dragging = true

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)

				while dragging do
					task.wait()
					library.Functions.Tween(slider.Slider.Bar.Fill.Circle, { BackgroundTransparency = 0 }, 0.1)

					update({
						Min = min,
						Max = max
					})
					callback(value)

					game:GetService("RunService").RenderStepped:Wait()
				end

				task.wait(0.5)
				library.Functions.Tween(slider.Slider.Bar.Fill.Circle, { BackgroundTransparency = 1 }, 0.2)
			end
		end)

		return { Instance = slider, Update = update }
	end
	function library.section:addToggle(config: table): Instance
		config = config or {}
		local toggle = Create("ImageButton", {
			Name = "Toggle_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			AutoButtonColor = false,
			BackgroundColor3 = library.Settings.theme.Background,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create('UIPadding', {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Create("TextLabel", {
				Name = "Title",
				Size = UDim2.new(0, library.Functions.GetTextSize((library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title")) or "Toggle", library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 1, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Font = library.Settings.Elements_Font,
				RichText = true,
				ClipsDescendants = true,
				Text = (library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title")) or "Toggle",
				TextColor3 = library.Settings.theme.TextColor,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Create("Frame", {
				BackgroundColor3 = library.Settings.theme.Contrast,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 0.5, 0),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}, {
				Create("Frame", {
					Name = "Button",
					BackgroundColor3 = library.Settings.theme.LightContrast,
					Position = UDim2.new(0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.new(0, 0, 1.3, 0),
				}, {}, UDim.new(1, 0)),
			}, UDim.new(1, 0)),
			Create("ImageButton", {
				Name = "KeyBind",
				AutoButtonColor = false,
				BackgroundColor3 = library.Settings.theme.Contrast,
				Visible = library.Functions.BetterFindIndex(config, 'KeyBind') or false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 0, 0.55, 0),
			}, {
				Create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Size = UDim2.new(1, 0, 1, 0),
					Font = library.Settings.Elements_Font,
					Text = library.Functions.BetterFindIndex(config, "KeyBind_Default") and library.Functions.BetterFindIndex(config, "KeyBind_Default").Name or "None",
					TextColor3 = library.Settings.theme.LightContrast,
					TextSize = library.Settings.Elements_TextSize,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create('Frame', {
				Name = 'Disabled_Frame',
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = library.Functions.BetterFindIndex(config, 'Disabled') or false,
				ZIndex = 2
			}, {
				Create('ImageLabel', {
					Image = 'rbxassetid://7072718362',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.55, 0),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5)),
			Create("BoolValue", {
				Name = "Disabled",
				Value = library.Functions.BetterFindIndex(config, "Disabled") or false,
			}),
			Create("BoolValue", {
				Name = "ResetOnSpawn",
				Value = library.Functions.BetterFindIndex(config, "ResetOnSpawn") and true or false,
			}),
			Create("StringValue", {
				Name = "SearchValue",
				Value = library.Functions.BetterFindIndex(config, "Title") or "Toggle",
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5))

		toggle.KeyBind.Size = UDim2.new(0, toggle.KeyBind.AbsoluteSize.Y * 5, 0.55, 0)
		toggle.Frame.Size = UDim2.new(0, toggle.Frame.AbsoluteSize.Y * 2.6, 0.5, 0)
		toggle.Frame.Button.Size = UDim2.new(0, toggle.Frame.Button.AbsoluteSize.Y, 0, toggle.Frame.Button.AbsoluteSize.Y)
		table.insert(self.modules, toggle)

		local function update(update_config)
			update_config = update_config or {}

			if library.Functions.BetterFindIndex(update_config, "Title") and library.Functions.BetterFindIndex(update_config, "Title") ~= "" then
				toggle.Title.Text = library.Functions.BetterFindIndex(update_config, "Title")
				toggle.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end

			local function check_boolean(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(update_config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(update_config, var)
					else
						return false
					end
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(config, var)
					else
						return false
					end
				else
					return false
				end
			end

			toggle.Disabled.Value = check_boolean("Disabled")
			toggle.Disabled_Frame.Visible = check_boolean("Disabled")
			toggle.KeyBind.Visible = check_boolean("KeyBind")
			if check_boolean("KeyBind") then
				toggle.Frame.Position = UDim2.new(1, - (toggle.KeyBind.AbsoluteSize.Y * 5) - 5, 0.5, 0)
				toggle.Title.Size = UDim2.new(0, math.min(library.Functions.GetTextSize(toggle.Title.Text, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, toggle.AbsoluteSize.X - toggle.UIPadding.PaddingLeft.Offset - toggle.UIPadding.PaddingRight.Offset - toggle.Frame.AbsoluteSize.X - toggle.KeyBind.AbsoluteSize.X - 10), 1, 0)
			else
				toggle.Frame.Position = UDim2.new(1, 0, 0.5, 0)
				toggle.Title.Size = UDim2.new(0, math.min(library.Functions.GetTextSize(toggle.Title.Text, library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, toggle.AbsoluteSize.X - toggle.UIPadding.PaddingLeft.Offset - toggle.UIPadding.PaddingRight.Offset - toggle.Frame.AbsoluteSize.X), 1, 0)
			end

			if library.Functions.BetterFindIndex(update_config, "value") then
				library.Functions.Tween(toggle.Frame.Button, { BackgroundColor3 = library.Settings.theme.Accent }, 0.3)
				library.Functions.Tween(toggle.Frame.Button, { Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5) }, 0.3)
			else
				library.Functions.Tween(toggle.Frame.Button, { BackgroundColor3 = library.Settings.theme.LightContrast }, 0.3)
				library.Functions.Tween(toggle.Frame.Button, { Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5) }, 0.3)
			end
		end
		local active = library.Functions.BetterFindIndex(config, "Default") or false
		update({ Value = active })

		local over_KeyBind = false
		local function update_KeyBind(update_config)
			update_config = update_config or {}

			local bind = self.binds[toggle]

			if bind.connection then
				bind.connection = bind.connection:UnBind()
				if table.find(library.binds, bind.connection) then
					table.remove(library.binds, table.find(library.binds, bind.connection))
				end
			end

			if library.Functions.BetterFindIndex(update_config, "value") then
				self.binds[toggle].connection = library.Functions.BindToKey(library.Functions.BetterFindIndex(update_config, "value"), bind.callback)
				table.insert(library.binds, self.binds[toggle].connection)
				toggle.KeyBind.Text.Text = library.Functions.BetterFindIndex(update_config, "value").Name
			else
				toggle.KeyBind.Text.Text = "None"
			end
		end

		self.binds[toggle] = {
			callback = function()
				if toggle.Disabled.Value or not active then
					return
				end
				task.spawn(function()
					library.Functions.Tween(toggle.KeyBind.Text, { TextColor3 = library.Settings.theme.TextColor }, 0.4).Completed:Wait()
					library.Functions.Tween(toggle.KeyBind.Text, { TextColor3 = library.Settings.theme.LightContrast }, 0.2)
				end)

				if library.Functions.BetterFindIndex(config, "KeyBind_CallBack") then
					library.Functions.BetterFindIndex(config, "KeyBind_CallBack")()
				end
			end,
		}

		if library.Functions.BetterFindIndex(config, "KeyBind_Default") and library.Functions.BetterFindIndex(config, "KeyBind_CallBack") then
			update_KeyBind({ Value = library.Functions.BetterFindIndex(config, "KeyBind_Default") })
		end

		toggle.KeyBind.MouseEnter:Connect(function()
			over_KeyBind = true
		end)
		toggle.KeyBind.MouseLeave:Connect(function()
			over_KeyBind = false
		end)
		toggle.KeyBind.MouseButton1Click:Connect(function()
			if toggle.Disabled.Value or not active then
				return
			end
			library.Functions.Ripple(toggle.KeyBind, 0.5)

			if self.binds[toggle].connection then
				return update_KeyBind()
			end

			if toggle.KeyBind.Text.Text == "None" then
				toggle.KeyBind.Text.Text = "..."

				local key = library.Functions.KeyPressed()

				update_KeyBind({ Value = key.KeyCode })

				if library.Functions.BetterFindIndex(config, "KeyBind_changedCallback") then
					library.Functions.BetterFindIndex(config, "KeyBind_changedCallback")(key)
				end
			end
		end)
		toggle.MouseButton1Click:Connect(function()
			if toggle.Disabled.Value or over_KeyBind then
				return
			end

			if toggle.Frame.Button.Position == UDim2.new(1, 0, 0.5, 0) then
				active = false
			elseif toggle.Frame.Button.Position == UDim2.new(0, 0, 0.5, 0) then
				active = true
			else
				active = not active
			end
			update({ Value = active })

			if library.Functions.BetterFindIndex(config, "CallBack") then
				library.Functions.BetterFindIndex(config, "CallBack")(active)
			end
		end)

		return { Instance = toggle, Update = update, KeyBind = { Instance = toggle.KeyBind, Update = update_KeyBind } }
	end
	function library.section:addKeybind(config: table): Instance
		config = config or {}
		local keybind = Create("ImageButton", {
			Name = "Keybind_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = library.Settings.Elements_Font,
				RichText = true,
				ClipsDescendants = true,
				Text = library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "KeyBind",
				TextColor3 = library.Settings.theme.TextColor,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Create("ImageLabel", {
				Name = "Button",
				BackgroundColor3 = library.Settings.theme.Contrast,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 0, 0.55, 0),
			}, {
				Create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Size = UDim2.new(1, 0, 1, 0),
					Font = library.Settings.Elements_Font,
					Text = library.Functions.BetterFindIndex(config, "default") and library.Functions.BetterFindIndex(config, "default").Name or "None",
					TextColor3 = library.Settings.theme.LightContrast,
					TextSize = library.Settings.Elements_TextSize,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create('Frame', {
				Name = 'Disabled_Frame',
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = library.Functions.BetterFindIndex(config, 'Disabled') or false,
				ZIndex = 2
			}, {
				Create('ImageLabel', {
					Image = 'rbxassetid://7072718362',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.55, 0),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5)),
			Create("BoolValue", {
				Name = "Disabled",
				Value = library.Functions.BetterFindIndex(config, "Disabled") or false,
			}),
			Create("StringValue", {
				Name = "SearchValue",
				Value = library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "KeyBind"
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5))
		keybind.Button.Size = UDim2.new(0, keybind.Button.AbsoluteSize.Y * 5, 0.55, 0)

		local TitleSize = math.min(keybind.AbsoluteSize.X - keybind.Button.AbsoluteSize.X - 5, library.Functions.GetTextSize(library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "KeyBind", library.Settings.Elements_TextSize, library.Settings.Elements_Font).X)
		keybind.Title.Size = UDim2.new(0, TitleSize, 1, 0)

		table.insert(self.modules, keybind)

		local function update(update_config)
			update_config = update_config or {}

			local bind = self.binds[keybind]

			if library.Functions.BetterFindIndex(update_config, "title") and library.Functions.BetterFindIndex(update_config, "title") ~= "" then
				keybind.Title.Text = library.Functions.BetterFindIndex(update_config, "Title")
				local TitleSize = math.min(keybind.AbsoluteSize.X - keybind.Button.AbsoluteSize.X - 5, library.Functions.GetTextSize(library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "KeyBind", library.Settings.Elements_TextSize, library.Settings.Elements_Font).X)
				keybind.Title.Size = UDim2.new(0, TitleSize, 1, 0)
				keybind.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end

			local function check_boolean(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(update_config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(update_config, var)
					else
						return false
					end
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(config, var)
					else
						return false
					end
				else
					return false
				end
			end

			keybind.Disabled.Value = check_boolean("Disabled")
			keybind.Disabled_Frame.Visible = check_boolean("Disabled")

			if bind.connection then
				bind.connection = bind.connection:UnBind()
				if table.find(library.binds, bind.connection) then
					table.remove(library.binds, table.find(library.binds, bind.connection))
				end
			end

			if library.Functions.BetterFindIndex(update_config, "value") then
				self.binds[keybind].connection = library.Functions.BindToKey(library.Functions.BetterFindIndex(update_config, "value"), bind.callback)
				table.insert(library.binds, self.binds[keybind].connection)
				keybind.Button.Text.Text = library.Functions.BetterFindIndex(update_config, "value").Name
			else
				keybind.Button.Text.Text = "None"
			end
		end

		self.binds[keybind] = {
			callback = function()
				task.spawn(function()
					library.Functions.Tween(keybind.Button.Text, { TextColor3 = library.Settings.theme.TextColor }, 0.4).Completed:Wait()
					library.Functions.Tween(keybind.Button.Text, { TextColor3 = library.Settings.theme.LightContrast }, 0.2)
				end)

				if library.Functions.BetterFindIndex(config, "callback") then
					library.Functions.BetterFindIndex(config, "callback")()
				end
			end,
		}

		if library.Functions.BetterFindIndex(config, "default") and library.Functions.BetterFindIndex(config, "callback") then
			update({ Value = library.Functions.BetterFindIndex(config, "default") })
		end

		keybind.MouseButton1Click:Connect(function()
			if keybind.Disabled.Value then
				return
			end
			library.Functions.Ripple(keybind.Button, 0.5)

			if self.binds[keybind].connection then
				return update()
			end

			if keybind.Button.Text.Text == "None" then
				keybind.Button.Text.Text = "..."

				local key = library.Functions.KeyPressed()

				update({ Value = key.KeyCode })

				if library.Functions.BetterFindIndex(config, "changedCallback") then
					library.Functions.BetterFindIndex(config, "changedCallback")(key)
				end
			end
		end)

		return { Instance = keybind, Update = update }
	end
	function library.section:addDropdown(config: table): Instance
		config = config or {}
		local dropdown = Create("Frame", {
			Name = "Dropdown_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
			ClipsDescendants = true,
		}, {
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			}),
			Create("Frame", {
				BackgroundColor3 = library.Settings.theme.Background,
				Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
			}, {
				Create("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),
				Create("UIListLayout", {
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Create("TextBox", {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = library.Settings.Elements_Font,
					RichText = true,
					PlaceholderText = library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "DropDown",
					PlaceholderColor3 = library.Settings.theme.LightContrast,
					Text = "",
					TextColor3 = library.Settings.theme.TextColor,
					TextSize = library.Settings.Elements_TextSize,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				Create("Frame", {
					LayoutOrder = 2,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 0, 1.5, 0)
				}, {
					Create("ImageButton", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Image = "rbxassetid://2777862738",
						ImageColor3 = library.Settings.theme.TextColor,
					}),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create("Frame", {
				Name = "List",
				Size = UDim2.new(1, 0, 1, - library.Settings.Elements_Size - 5),
				BorderSizePixel = 0,
				BackgroundColor3 = library.Settings.theme.Background,
			}, {
				Create("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),
				Create("ScrollingFrame", {
					Active = true,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					CanvasSize = UDim2.new(0, 0, 0, 0),
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = library.Settings.theme.TextColor,
					ScrollBarImageTransparency = 1,
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5),
					}),
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
					}),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create("StringValue", {
				Name = "SearchValue",
				Value = library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "DropDown",
			}),
		})
		dropdown.Frame.Frame.Size = UDim2.new(0, dropdown.Frame.Frame.AbsoluteSize.Y, 0, dropdown.Frame.Frame.AbsoluteSize.Y)
		dropdown.Frame.TextBox.Size = UDim2.new(1, - dropdown.Frame.Frame.AbsoluteSize.Y, 1, 0)

		table.insert(self.modules, dropdown)

		local list = library.Functions.BetterFindIndex(config, "List") or {}
		local toggling_table = {}
		local multiList = {}
		local multiListGroup = {}
		local savedValues = {}

		local function update(update_config)
			update_config = update_config or {}

			if library.Functions.BetterFindIndex(update_config, "Title") and library.Functions.BetterFindIndex(update_config, "Title") ~= "" then
				dropdown.Frame.TextBox.PlaceholderText = library.Functions.BetterFindIndex(update_config, "Title")
				dropdown.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end

			local function updateDropdown_Item(dropdown_Item: Instance, value: boolean, multi: boolean)
				if toggling_table[dropdown_Item] then
					return
				end

				toggling_table[dropdown_Item] = true

				if value then
					library.Functions.Tween(dropdown_Item.ImageButton, { BackgroundColor3 = library.Settings.theme.Accent }, 0.3)
					task.spawn(function()
						task.wait(0.15)
						pcall(function()
							library.Functions.Tween(dropdown_Item.ImageButton.ImageLabel, { ImageTransparency = 0 }, 0.2)
						end)
					end)
				else
					library.Functions.Tween(dropdown_Item.ImageButton, { BackgroundColor3 = library.Settings.theme.DarkContrast }, 0.3)
					library.Functions.Tween(dropdown_Item.ImageButton.ImageLabel, { ImageTransparency = 1 }, 0.3)
				end

				if multi then
					local temp_list =  {}
					for _, v in pairs(multiListGroup) do
						if v.IsEnabled.Value then
							table.insert(temp_list, v.ListName.Value)
						end
					end
					dropdown.Frame.TextBox.PlaceholderText = #temp_list > 0 and dropdown.SearchValue.Value .. ' - ' .. table.concat(temp_list, ', ') or dropdown.SearchValue.Value
				else
					dropdown.Frame.TextBox.PlaceholderText = value and dropdown.SearchValue.Value .. ' - ' .. dropdown_Item.ListName.Value  or dropdown.SearchValue.Value
					for _, v in pairs(multiListGroup) do
						if v ~= dropdown_Item then
							v.IsEnabled.Value = false
							library.Functions.Tween(v.ImageButton,{ BackgroundColor3 = library.Settings.theme.DarkContrast }, 0.3)
							library.Functions.Tween(v.ImageButton.ImageLabel, { ImageTransparency = 1 }, 0.3)
						end
					end
				end

				task.spawn(function()
					task.wait(0.3)
					toggling_table[dropdown_Item] = false
				end)
			end

			if library.Functions.BetterFindIndex(update_config, "List") then
				table.clear(multiListGroup)
				table.clear(toggling_table)
				task.spawn(function()
					for i, button in pairs(dropdown.List.ScrollingFrame:GetChildren()) do
						if button:IsA("ImageButton") then
							button:Destroy()
						end
					end
					for i, value in pairs(library.Functions.BetterFindIndex(update_config, "List") or {}) do
						value = tostring(value)
						local Dropdown_Item = Create("ImageButton", {
							BackgroundTransparency = 1,
							Parent = dropdown.List.ScrollingFrame,
							Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
							AutoButtonColor = false,
						}, {
							Create("BoolValue", {
								Name = "IsEnabled",
								Value = savedValues[value] or false,
							}),
							Create("StringValue", {
								Name = "ListName",
								Value = value,
							}),
							Create("UIListLayout", {
								Padding = UDim.new(0, 10),
								VerticalAlignment = Enum.VerticalAlignment.Center,
								FillDirection = Enum.FillDirection.Horizontal,
							}),
							Create("ImageButton", {
								BackgroundColor3 = library.Settings.theme.DarkContrast,
								Size = UDim2.new(0, 0, 0.75, 0),
								AutoButtonColor = false,
							}, {
								Create("ImageLabel", {
									BackgroundTransparency = 1,
									Size = UDim2.new(0.8, 0, 0.8, 0),
									Position = UDim2.new(0.5, 0, 0.5, 0),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Image = "rbxassetid://7072706620",
									ImageColor3 = library.Settings.theme.TextColor,
									ImageTransparency = 1,
								}),
							}, UDim.new(0, library.Functions.BetterFindIndex(update_config, "Corner") or 5)),
							Create("TextLabel", {
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, 0),
								Font = library.Settings.Elements_Font,
								RichText = true,
								Text = value,
								TextColor3 = library.Settings.theme.TextColor,
								TextSize = library.Settings.Elements_TextSize,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						})
						toggling_table[Dropdown_Item] = false
						Dropdown_Item.ImageButton.Size = UDim2.new(0, Dropdown_Item.ImageButton.AbsoluteSize.Y, 0, Dropdown_Item.ImageButton.AbsoluteSize.Y)
						Dropdown_Item.TextLabel.Size = UDim2.new(1, - Dropdown_Item.ImageButton.AbsoluteSize.Y - Dropdown_Item.UIListLayout.Padding.Offset, 1, 0)
						updateDropdown_Item(
							Dropdown_Item,
							Dropdown_Item.IsEnabled.Value,
							library.Functions.BetterFindIndex(update_config, "Multi")
						)

						table.insert(multiListGroup, Dropdown_Item)

						Dropdown_Item.MouseButton1Click:Connect(function()
							Dropdown_Item.IsEnabled.Value = not Dropdown_Item.IsEnabled.Value
							savedValues[value] = Dropdown_Item.IsEnabled.Value

							if library.Functions.BetterFindIndex(update_config, "Multi") then
								if Dropdown_Item.IsEnabled.Value then
									table.insert(multiList, value)
								else
									if table.find(multiList, value) then
										table.remove(
											multiList,
											table.find(multiList, value)
										)
									end
								end
							end

							updateDropdown_Item(
								Dropdown_Item,
								Dropdown_Item.IsEnabled.Value,
								library.Functions.BetterFindIndex(update_config, "Multi")
							)

							if library.Functions.BetterFindIndex(update_config, "CallBack") then
								if library.Functions.BetterFindIndex(update_config, "Multi") then
									library.Functions.BetterFindIndex(update_config, "CallBack")(multiList)
								else
									if Dropdown_Item.IsEnabled.Value then
										library.Functions.BetterFindIndex(update_config, "CallBack")(value)
									end
								end
							end
						end)
						Dropdown_Item.ImageButton.MouseButton1Click:Connect(function()
							Dropdown_Item.IsEnabled.Value = not Dropdown_Item.IsEnabled.Value
							savedValues[value] = Dropdown_Item.IsEnabled.Value

							if library.Functions.BetterFindIndex(update_config, "Multi") then
								if Dropdown_Item.IsEnabled.Value then
									table.insert(multiList, value)
								else
									if table.find(multiList, value) then
										table.remove(
											multiList,
											table.find(multiList, value)
										)
									end
								end
							end

							updateDropdown_Item(
								Dropdown_Item,
								Dropdown_Item.IsEnabled.Value,
								library.Functions.BetterFindIndex(update_config, "Multi")
							)

							if library.Functions.BetterFindIndex(update_config, "CallBack") then
								if library.Functions.BetterFindIndex(update_config, "Multi") then
									library.Functions.BetterFindIndex(update_config, "CallBack")(multiList)
								else
									if Dropdown_Item.IsEnabled.Value then
										library.Functions.BetterFindIndex(update_config, "CallBack")(value)
									end
								end
							end
						end)
					end
				end)
			end
		end

		update({
			Multi = library.Functions.BetterFindIndex(config, "Multi") or false,
			Default = library.Functions.BetterFindIndex(config, "Default"),
			List = list,
			CallBack = library.Functions.BetterFindIndex(config, "CallBack"),
		})

		local function toggle(value: boolean)
			library.Functions.Tween(dropdown.Frame.Frame.ImageButton, { Rotation = value and 180 or 0 }, 0.3)
			library.Functions.Tween(dropdown.Frame.Frame.ImageButton, {
				ImageColor3 = value and library.Settings.theme.TextColor or library.Settings.theme.LightContrast
			}, 0.3)

			if value then
				library.Functions.Tween(dropdown, {
					Size = UDim2.new(1, 0, 0, (#list == 0 and library.Settings.Elements_Size) or library.Settings.Elements_Size + dropdown.UIListLayout.Padding.Offset + (math.clamp(#list, 0, 3) * library.Settings.Elements_Size) + (math.clamp(#list, 0, 3) * dropdown.UIListLayout.Padding.Offset)),
				}, 0.3)
				if #list > 3 then
					dropdown.List.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (#list * library.Settings.Elements_Size) + ((#list - 1) * dropdown.List.ScrollingFrame.UIListLayout.Padding.Offset))
					dropdown.List.ScrollingFrame.ScrollBarImageTransparency = 0
				else
					dropdown.List.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
					dropdown.List.ScrollingFrame.ScrollBarImageTransparency = 1
				end
			else
				library.Functions.Tween(dropdown, { Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size) }, 0.3)
				dropdown.List.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				dropdown.List.ScrollingFrame.ScrollBarImageTransparency = 1
			end
		end

		dropdown.Frame.Frame.ImageButton.MouseButton1Click:Connect(function()
			if dropdown.Frame.Frame.ImageButton.Rotation == 0 then
				toggle(true)
			else
				toggle(false)
			end
		end)

		dropdown.Frame.TextBox.Focused:Connect(function()
			if dropdown.Frame.Frame.ImageButton.Rotation == 0 then
				toggle(true)
			end
		end)

		dropdown.Frame.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local entries = 0
			for i, v in pairs(dropdown.List.ScrollingFrame:GetChildren()) do
				if v:FindFirstChild("ListName") then
					if v:FindFirstChild("ListName").Value:lower():find(dropdown.Frame.TextBox.Text:lower()) then
						entries += 1
						v.Visible = true
					else
						v.Visible = false
					end
				end
			end
			library.Functions.Tween(dropdown, {
				Size = UDim2.new(1, 0, 0, (#list == 0 and library.Settings.Elements_Size) or library.Settings.Elements_Size + dropdown.UIListLayout.Padding.Offset + (math.clamp(entries, 0, 3) * library.Settings.Elements_Size) + (math.clamp(entries, 0, 3) * dropdown.UIListLayout.Padding.Offset)),
			}, 0.3)
			if entries > 3 then
				dropdown.List.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (entries * library.Settings.Elements_Size) + ((entries - 1) * dropdown.UIListLayout.Padding.Offset))
				dropdown.List.ScrollingFrame.ScrollBarImageTransparency = 0
			else
				dropdown.List.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				dropdown.List.ScrollingFrame.ScrollBarImageTransparency = 1
			end
		end)

		dropdown:GetPropertyChangedSignal("Size"):Connect(function()
			self.page:Resize()
		end)

		return { Instance = dropdown, Update = update}
	end
	function library.section:addCheckbox(config: table): Instance
		config = config or {}
		local checkbox = Create("ImageButton", {
			Name = "Checkbox_Element",
			BackgroundTransparency = 1,
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
			Create("BoolValue", {
				Name = "IsEnabled",
				Value = library.Functions.BetterFindIndex(config, "Default") or false,
			}),
			Create("ImageButton", {
				BackgroundColor3 = library.Settings.theme.Background,
				Size = UDim2.new(0, 0, 0.75, 0),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				AutoButtonColor = false,
			}, {
				Create("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.8, 0, 0.8, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = "rbxassetid://7072706620",
					ImageColor3 = library.Settings.theme.TextColor,
					ImageTransparency = 1,
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Size = UDim2.new(0, library.Functions.GetTextSize((library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title")) or "Checkbox", library.Settings.Elements_TextSize, library.Settings.Elements_Font).X, 1, 0),
				Text = library.Functions.BetterFindIndex(config, "Title") and library.Functions.BetterFindIndex(config, "Title") ~= "" and library.Functions.BetterFindIndex(config, "Title") or "Checkbox",
				Font = library.Settings.Elements_Font,
				TextColor3 = library.Settings.theme.TextColor,
				TextSize = library.Settings.Elements_TextSize,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Create('Frame', {
				Name = 'Disabled_Frame',
				BackgroundColor3 = library.Settings.theme.DarkContrast,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = library.Functions.BetterFindIndex(config, 'Disabled') or false,
				ZIndex = 2
			}, {
				Create('ImageLabel', {
					Image = 'rbxassetid://7072718362',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0.55, 0),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5)),
			Create("BoolValue", {
				Name = "Disabled",
				Value = library.Functions.BetterFindIndex(config, "Disabled") or false,
			}),
			Create("StringValue", {
				Name = "SearchValue",
				Value = library.Functions.BetterFindIndex(config, "Title") or "Checkbox",
			}),
		})
		checkbox.ImageButton.Size = UDim2.new(0, checkbox.ImageButton.AbsoluteSize.Y, 0, checkbox.ImageButton.AbsoluteSize.Y)
		checkbox.Title.Size = UDim2.new(1, - checkbox.ImageButton.AbsoluteSize.Y - 10, 1, 0)
		checkbox.Title.Position = UDim2.new(0, checkbox.ImageButton.AbsoluteSize.Y + 10, 0, 0)
		table.insert(self.modules, checkbox)

		local GroupName = library.Functions.BetterFindIndex(config, "Group")
		if GroupName then
			if not library.CheckBox_groups[GroupName] then
				library.CheckBox_groups[GroupName] = {}
			end
			table.insert(library.CheckBox_groups[GroupName], checkbox)
		end

		local toggling = false
		local function update(update_config)
			update_config = update_config or {}
			local function checkValue(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					return { true, library.Functions.BetterFindIndex(update_config, var) }
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					return { false, library.Functions.BetterFindIndex(config, var) }
				else
					return false
				end
			end

			toggling = true

			local temp_value = checkValue("Group")
			if temp_value then
				if temp_value[2] == "" then
					if GroupName then
						table.remove(library.CheckBox_groups[GroupName], table.find(library.CheckBox_groups[GroupName], checkbox))
					end
					GroupName = nil
				else
					if temp_value[1] then
						if GroupName then
							table.remove(library.CheckBox_groups[GroupName], table.find(library.CheckBox_groups[GroupName], checkbox))
						end
						GroupName = temp_value[2]
						if not library.CheckBox_groups[GroupName] then
							library.CheckBox_groups[GroupName] = {}
						end
						table.insert(library.CheckBox_groups[GroupName], checkbox)
					end
					for _, v in pairs(library.CheckBox_groups[temp_value[2]]) do
						if v ~= checkbox then
							v.IsEnabled.Value = false
							library.Functions.Tween(v.ImageButton,{ BackgroundColor3 = library.Settings.theme.Background }, 0.3)
							library.Functions.Tween(v.ImageButton.ImageLabel, { ImageTransparency = 1 }, 0.3)
						end
					end
				end
			end

			local function check_boolean(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(update_config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(update_config, var)
					else
						return false
					end
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					if typeof(library.Functions.BetterFindIndex(config, var)) == "boolean" then
						return library.Functions.BetterFindIndex(config, var)
					else
						return false
					end
				else
					return false
				end
			end

			if library.Functions.BetterFindIndex(update_config, "Title") and library.Functions.BetterFindIndex(update_config, "Title") ~= "" then
				checkbox.Title.Text = library.Functions.BetterFindIndex(update_config, "Title")
				checkbox.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
			end

			if check_boolean("Value") then
				library.Functions.Tween(checkbox.ImageButton, { BackgroundColor3 = library.Settings.theme.Accent }, 0.3)
				task.spawn(function()
					task.wait(0.15)
					pcall(function()
						library.Functions.Tween(checkbox.ImageButton.ImageLabel, { ImageTransparency = 0 }, 0.2)
					end)
				end)
			else
				library.Functions.Tween(checkbox.ImageButton, { BackgroundColor3 = library.Settings.theme.Background }, 0.3)
				library.Functions.Tween(checkbox.ImageButton.ImageLabel, { ImageTransparency = 1 }, 0.3)
			end

			task.spawn(function()
				task.wait(0.3)
				toggling = false
			end)
		end
		update({
			Value = checkbox.IsEnabled.Value
		})

		checkbox.MouseButton1Click:Connect(function()
			if checkbox.Disabled.Value or toggling then
				return
			end
			checkbox.IsEnabled.Value = not checkbox.IsEnabled.Value

			update({
				Value = checkbox.IsEnabled.Value
			})

			if library.Functions.BetterFindIndex(config, "CallBack") then
				library.Functions.BetterFindIndex(config, "CallBack")(checkbox.IsEnabled.Value)
			end
		end)
		checkbox.ImageButton.MouseButton1Click:Connect(function()
			if checkbox.Disabled.Value or toggling then
				return
			end
			checkbox.IsEnabled.Value = not checkbox.IsEnabled.Value

			update({
				Value = checkbox.IsEnabled.Value
			})

			if library.Functions.BetterFindIndex(config, "CallBack") then
				library.Functions.BetterFindIndex(config, "CallBack")(checkbox.IsEnabled.Value)
			end
		end)

		return { Instance = checkbox, Update = update}
	end
	--#region 3dPlayer

	--#endregion
	--#region TextBox's

	--#endregion
	--#region ColorPicker

	--#endregion
end

return library
