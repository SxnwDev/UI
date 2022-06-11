-- game variables
local player = game:GetService('Players').LocalPlayer
local mouse = player:GetMouse()
-- Library variables
local library = {
	Name = 'Lite',
	Version = 'v. 1.0.0',
	Icon = 'rbxassetid://6023426988',
	Parent = game.CoreGui or player.PlayerGui or player:WaitForChild("PlayerGui", 5),
	IsMobile = not game:GetService("UserInputService").KeyboardEnabled or false,
	IsFileSystem = writefile and readfile and makefolder and true or false,
	Settings = {
		NewUser = true,
		AntiAFK = true,
		prefix = Enum.KeyCode.LeftAlt,
		Elements_Size = 0,
		Elements_TextSize = 0,
		Elements_Font = Enum.Font.SourceSans,
		LeftBar_MinSize = 25,
		Max_Notifications = 3,
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
	},
	CheckBox_groups = {},
	connections = {},
	end_funcs = {},
	binds = {},
	Functions = {},
	objects = {},
    page = {},
    section = {},
	notifications = {}
}
local original_library_settings = library

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
			-- if not isfile(library.Name .. ' UI/Settings.lua') then
			-- 	writefile(library.Name .. ' UI/Settings.lua', library.encode({}))
			-- end

			-- local savesettings = library.decode(readfile(library.Name .. ' UI/Settings.lua'))
			-- for i, v in pairs(library.Settings) do
			-- 	savesettings[i] = v
			-- end

			local settings = {
				Name = library.Name,
				Version = library.Version,
				Icon = library.Icon,
				Parent = library.Parent,
				IsMobile = library.IsMobile,
				IsFileSystem = library.IsFileSystem,
				Settings = library.Settings,
			}

			writefile(library.Name .. ' UI/Settings.lua', library.encode(settings))
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

			local success, message = pcall(function()
				local function loadSettings(tbl, loadIn)
					for i, v in pairs(tbl) do
						if typeof(v) ~= "table" then
							loadIn[i] = v
						else
							loadSettings(v, loadIn[i])
						end
					end
				end
				loadSettings(library.decode(readfile(library.Name .. ' UI/Settings.lua')), library)
			end)
			if success then
				return library.Settings
			else
				library.Name = original_library_settings.Name
				library.Version = original_library_settings.Version
				library.Icon = original_library_settings.Icon
				library.Parent = original_library_settings.Parent
				library.IsMobile = original_library_settings.IsMobile
				library.IsFileSystem = original_library_settings.IsFileSystem
				library.Settings = original_library_settings.Settings

				local settings = {
					Name = library.Name,
					Version = library.Version,
					Icon = library.Icon,
					Parent = library.Parent,
					IsMobile = library.IsMobile,
					IsFileSystem = library.IsFileSystem,
					Settings = library.Settings,
				}

				writefile(library.Name .. ' UI/Settings.lua', library.encode(settings))
			end
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
	local MaxNofications = 0
    function library:new(config) : table
		config = config or {}
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

		task.spawn(function()
			while library.Enabled and task.wait(5) do
				if not library.Enabled then return end
				library.Save()
			end
		end)

		library.Load()
		if library.Functions.BetterFindIndex(config, "Title") then
			library.Name = library.Functions.BetterFindIndex(config, "Title")
		end
		if library.Functions.BetterFindIndex(config, "Version") then
			library.Version = library.Functions.BetterFindIndex(config, "Version")
		end
		if library.Functions.BetterFindIndex(config, "Icon") then
			library.Icon = library.Functions.BetterFindIndex(config, "Icon")
		end
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
			Image = library.Icon,
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
                            Size = UDim2.new(0, 0, 0.8, 0),
                            BackgroundTransparency = 1,
                            LayoutOrder = 0,
                            ZIndex = 2
                        }, {
                            Create('ImageButton', {
                                Size = UDim2.new(1, 0, 1, 0),
                                AutoButtonColor = false,
                                BackgroundTransparency = 1,
                                Image = library.Icon,
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
                Size = UDim2.new(0, math.max(UISize.X.Offset * 0.07, library.Settings.LeftBar_MinSize), 1, 0),
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
                Size = UDim2.new(1, -math.max(UISize.X.Offset * 0.07, library.Settings.LeftBar_MinSize), 0.9, 0),
                Position = UDim2.new(0, math.max(UISize.X.Offset * 0.07, library.Settings.LeftBar_MinSize), 0.1, 0),
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
		local Notifications_Container = Create('Frame', {
			Parent = ScreenGui,
			Name = 'Notifications_Container',
			ClipsDescendants = true,
			Size = UDim2.new(0, UISize.X.Offset / 1.5, 1, -library.Settings.Elements_TextSize * 2),
			Position = UDim2.new(1, -library.Settings.Elements_TextSize, 1, -library.Settings.Elements_TextSize),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
		})
        Frame.Section_Container.Home_Container.Size = UDim2.new(1, 0, 0, Frame.Section_Container.AbsoluteSize.Y)
        Frame.Top_Frame.Container.Left.Logo.Size = UDim2.new(0, Frame.Top_Frame.Container.Left.Logo.AbsoluteSize.Y, 0, Frame.Top_Frame.Container.Left.Logo.AbsoluteSize.Y)
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
			notificationsContainer = Notifications_Container,
            pages = {},
        }, library)

		task.spawn(function()
			while library.Enabled and task.wait() do
				local temp_number = 0
				for i, v in pairs(library.notifications) do
					temp_number += v.AbsoluteSize.Y
					temp_number += (i - 1) * 10
					if temp_number < lib.notificationsContainer.AbsoluteSize.Y then
						MaxNofications += 1
					end
				end
				MaxNofications = math.min(MaxNofications, library.Settings.Max_Notifications)
			end
		end)
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
            lib.Functions.Tween(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Frame, { BackgroundColor3 = lib.Settings.theme.Accent }, 0.2)
			if lib.focusedPage then
				for i, v in pairs(lib.focusedPage.container:GetDescendants()) do
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
					lib.focusedPage:Resize()
				end)
			end
        end)
        Frame.Top_Frame.Container.Left.Search_Frame.TextBox.FocusLost:Connect(function()
			if lib.toggling then
				return
			end
            lib.Functions.Tween(Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Frame, { BackgroundColor3 = lib.Settings.theme.LightContrast }, 0.2)
			if lib.focusedPage then
				for i, v in pairs(lib.focusedPage.container:GetDescendants()) do
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
					lib.focusedPage:Resize()
				end)
			end
        end)
		Frame.Top_Frame.Container.Left.Search_Frame.TextBox:GetPropertyChangedSignal('Text'):Connect(function()
			if lib.toggling then
				return
			end
			if not lib.focusedPage then
				Frame.Top_Frame.Container.Left.Search_Frame.TextBox.Text = ''
			end
		end)
        lib.Functions.TextEffect(Frame.Top_Frame.Container.Left.UI_Version, 0.15)
        Frame.Top_Frame.Container.Left.Search_Button.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
            lib.Functions.Ripple(Frame.Top_Frame.Container.Left.Search_Button, 0.6)
			if lib.focusedPage then
				for i, v in pairs(lib.focusedPage.container:GetDescendants()) do
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
					lib.focusedPage:Resize()
				end)
			end
        end)
        Frame.Top_Frame.Container.Right.Hide_Button.MouseButton1Click:Connect(function()
			if lib.toggling then
				return
			end
            lib.Functions.Ripple(Frame.Top_Frame.Container.Right.Hide_Button, 0.6)
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
            lib.Functions.Tween(lib.sectionContainer, { CanvasPosition = Vector2.new(0, 0) }, 0.2)
			if #lib.pages > 0 and lib.focusedPage then
				lib:SelectPage(lib.focusedPage, false)
				lib.focusedPage = nil
			end
        end)

		table.insert(lib.connections, game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
			if lib.toggling or not lib.Enabled or not lib.Settings.prefix or typeof(lib.Settings.prefix) ~= "EnumItem" then
				return
			end
			if not processed and input.KeyCode == lib.Settings.prefix then
				lib:toggle()
			end
		end))

        return lib
    end
	function library:Close()
		self.Enabled = false
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
			if self.focusedPage ~= page then
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
		if toggle and self.focusedPage == page then
			return
		end

		if not page and #self.pages > 0 then
			page = self.pages[1]
			library.Functions.Tween(page.button, { ImageColor3 = library.Settings.theme.Accent }, 0.2)

			local focusedPage = self.focusedPage
			self.focusedPage = page

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

			local focusedPage = self.focusedPage
			self.focusedPage = page

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
			if page == self.focusedPage then
				self.focusedPage = nil
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
		if self.Visible == nil then
			self.Visible = true
		end

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
		task.wait(0.8)

		self.toggling = false
	end
	function library:setTheme(theme, color3)
		repeat task.wait()
			library.Settings.theme[theme] = color3
		until library.Settings.theme[theme] == color3
		for property, objects in pairs(library.objects[theme] or {}) do
			for i, object in pairs(objects) do
				if not object.Parent then
					objects[i] = nil
				else
					library.Functions.Tween(object, { [property] = color3 }, 0.1)
					-- object[property] = color3
				end
			end
		end
	end
	function library:Notification(config: table): table
		config = config or {}
		local frame = Create('Frame', {
			Name = 'Notification#'..#library.notifications,
			Parent = self.notificationsContainer,
			Visible = false,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size * 1.3),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = library.Settings.theme.Background,
			BackgroundTransparency = 1
		}, {
			Create('Frame', {
				Name = 'Content_NoBackground',
				Size = UDim2.new(1, 0, 1, -4),
				BackgroundTransparency = 1
			}, {
				Create('UIPadding', {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),
                Create('UIListLayout', {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
				Create('TextLabel', {
					Name = 'Title_NoBackground',
					Size = UDim2.new(1, 0, 0, library.Settings.Elements_TextSize + 1),
					BackgroundTransparency = 1,
					Text = '<b>' .. (library.Functions.BetterFindIndex(config, 'Title') and library.Functions.BetterFindIndex(config, 'Title') ~= "" and library.Functions.BetterFindIndex(config, 'Title') or library.Name) .. '</b>',
					Font = Enum.Font.SciFi,
					RichText = true,
					TextSize = library.Settings.Elements_TextSize + 1,
					TextColor3 = library.Settings.theme.TextColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 0
				}),
				Create('TextLabel', {
					Name = 'Description_NoBackground',
					Size = UDim2.new(1, 0, 0, library.Settings.Elements_TextSize),
					BackgroundTransparency = 1,
					Font = library.Settings.Elements_Font,
					LineHeight = 0.8,
					RichText = true,
					TextWrapped = true,
					TextSize = library.Settings.Elements_TextSize,
					TextColor3 = library.Settings.theme.TextColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					LayoutOrder = 1
				}),
			}),
			Create('Frame', {
				Name = 'Bar',
				Size = UDim2.new(1, 0, 0, 4),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = library.Settings.theme.Accent,
				BorderSizePixel = 0
			}, {
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5))
		}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5))

		table.insert(library.notifications, frame)

		local text = (library.Functions.BetterFindIndex(config, "Description") and library.Functions.BetterFindIndex(config, "Description") ~= "" and library.Functions.BetterFindIndex(config, "Description")) or "Description"
		for i = 1, text:len() do
			frame.Content_NoBackground.Description_NoBackground.Text = text:sub(1, i)
			frame.Content_NoBackground.Description_NoBackground.Size = UDim2.new(1, 0, 0, frame.Content_NoBackground.Description_NoBackground.TextBounds.Y)
		end
		frame.Size = UDim2.new(1, 0, 0, (library.Settings.Elements_Size * 1.3) + frame.Content_NoBackground.Description_NoBackground.AbsoluteSize.Y)

		table.insert(library.connections, frame.Destroying:connect(function()
			for i, v in pairs(library.notifications) do
				pcall(function()
					if i == 1 or i % 4 == 0 then
						v.Position = UDim2.new(0, 0, 1, 0)
					else
						v.Position = library.notifications[i - 1].Position - UDim2.new(0, 0, 0, library.notifications[i - 1].AbsoluteSize.Y + 10)
					end
				end)
			end
		end))

		local function show(time)
			task.spawn(function()
				for i, v in pairs(self.notificationsContainer:GetDescendants()) do
					pcall(function()
						if not string.find(v.Name, '_NoBackground') then
							library.Functions.Tween(v, { BackgroundTransparency = 0 }, time)
						end
					end)
					pcall(function()
						library.Functions.Tween(v, { ImageTransparency = 0 }, time)
					end)
					pcall(function()
						library.Functions.Tween(v, { TextTransparency  = 0 }, time)
					end)
				end
			end)
		end
		local function hide(time)
			task.spawn(function()
				for i, v in pairs(self.notificationsContainer:GetDescendants()) do
					pcall(function()
						library.Functions.Tween(v, { BackgroundTransparency = 1 }, time)
					end)
					pcall(function()
						library.Functions.Tween(v, { ImageTransparency = 1 }, time)
					end)
					pcall(function()
						library.Functions.Tween(v, { TextTransparency  = 1 }, time)
					end)
				end
			end)
		end
		hide(0)
		task.spawn(function()
			pcall(function()
				if #library.notifications == 1 then
					frame.Visible = true
					show(0.2); task.wait(0.2)
					library.Functions.Tween(frame.Bar, { Size = UDim2.new(0, 0, 0, 4) }, library.Functions.BetterFindIndex(config, 'Time') or 5).Completed:Wait()
					hide(0.2)
					library.Functions.Tween(frame, { Position = frame.Position + UDim2.new(0, 0, 0, frame.AbsoluteSize.Y) }, 0.2).Completed:Wait()
					table.remove(library.notifications, table.find(library.notifications, frame))
					frame:Destroy()
				else
					if table.find(library.notifications, frame) > MaxNofications then
						repeat
							task.wait()
						until table.find(library.notifications, frame) <= MaxNofications
					end
					local notification_pos = table.find(library.notifications, frame)

					-- task.spawn(function()
					-- 	for i, v in pairs(library.notifications) do
					-- 		pcall(function()
					-- 			if i == 1 then
					-- 				library.Functions.Tween(v, { Position = UDim2.new(0, 0, 1, 0) }, 0.1).Completed:Wait()
					-- 			else
					-- 				if i % 4 == 0 then
					-- 					library.Functions.Tween(v, { Position = UDim2.new(0, 0, 1, 0) }, 0.1).Completed:Wait()
					-- 				else
					-- 					library.Functions.Tween(v, { Position = library.notifications[i - 1].Position - UDim2.new(0, 0, 0, library.notifications[i - 1].AbsoluteSize.Y + 10) }, 0.1).Completed:Wait()
					-- 				end
					-- 			end
					-- 		end)
					-- 	end
					-- end)

					if notification_pos == 1 or notification_pos % 4 == 0 then
						frame.Position = UDim2.new(0, 0, 1, 0)
					else
						frame.Position = library.notifications[notification_pos - 1].Position - UDim2.new(0, 0, 0, library.notifications[notification_pos - 1].AbsoluteSize.Y + 10)
					end

					frame.Visible = true
					show(0.2); task.wait(0.2)
					library.Functions.Tween(frame.Bar, { Size = UDim2.new(0, 0, 0, 4) }, library.Functions.BetterFindIndex(config, 'Time') or 5).Completed:Wait()
					hide(0.2)
					library.Functions.Tween(frame, { Position = frame.Position + UDim2.new(0, 0, 0, frame.AbsoluteSize.Y) }, 0.2).Completed:Wait()
					table.remove(library.notifications, table.find(library.notifications, frame))
					frame:Destroy()
				end
			end)
		end)
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
			}, UDim.new(0, 8))
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
		self.page:Resize()

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
	function library.section:addClipboardLabel(config: table): table
		config = config or {}

		local ClipboardLabel = Create('Frame', {
			Name = 'ClipboardLabel_Element',
			Parent = (library.Functions.BetterFindIndex(config, 'section') or 1) > #self.container
					and self.container[#self.container]
				or self.container[library.Functions.BetterFindIndex(config, 'section') or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			Size = UDim2.new(1, 0, 0, library.Settings.Elements_Size),
		}, {
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
				Create('ImageLabel', {
					Image = 'rbxassetid://7072707790',
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.55, 0, 0.55, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5)),
			Create('StringValue', {
				Name = 'SearchValue',
				Value = ((library.Functions.BetterFindIndex(config, 'Text') and library.Functions.BetterFindIndex(config,'Text') ~= '' and library.Functions.BetterFindIndex(config, 'Text')) or 'Clipboard Label'):gsub('<[^<>]->', ''),
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, 'Corner') or 5))
		table.insert(self.modules, ClipboardLabel)
		self.page:Resize()

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
	function library.section:addDualLabel(config: table): table
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
		self.page:Resize()

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
	function library.section:addLabel(config: table): table
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
			self.page:Resize()
		end)

		table.insert(self.modules, label)
		self.page:Resize()

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
					return tonumber((value:gsub('%D+', '')))
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
		self.page:Resize()


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
	function library.section:addToggle(config: table): table
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
				Size = UDim2.new(1, 20, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
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
		self.page:Resize()

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
				if library.Functions.BetterFindIndex(config, "CallBack") then
					library.Functions.BetterFindIndex(config, "CallBack")(true)
				end
			else
				library.Functions.Tween(toggle.Frame.Button, { BackgroundColor3 = library.Settings.theme.LightContrast }, 0.3)
				library.Functions.Tween(toggle.Frame.Button, { Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5) }, 0.3)
				if library.Functions.BetterFindIndex(config, "CallBack") then
					library.Functions.BetterFindIndex(config, "CallBack")(false)
				end
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
		end)

		return { Instance = toggle, Update = update, KeyBind = { Instance = toggle.KeyBind, Update = update_KeyBind } }
	end
	function library.section:addKeybind(config: table): table
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
				Size = UDim2.new(1, 20, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
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
		self.page:Resize()

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
	function library.section:addDropdown(config: table): table
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
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
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
					Size = UDim2.new(0, 0, 0.8, 0)
				}, {
					Create("ImageButton", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Image = "rbxassetid://2777862738",
						ImageColor3 = library.Settings.theme.TextColor,
					}),
				}),
				Create("ImageButton", {
					LayoutOrder = 3,
					Name = "KeyBind",
					AutoButtonColor = false,
					BackgroundColor3 = library.Settings.theme.Contrast,
					Visible = library.Functions.BetterFindIndex(config, 'KeyBind') or false,
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
		dropdown.Frame.KeyBind.Size = UDim2.new(0, dropdown.Frame.KeyBind.AbsoluteSize.Y * 5, 0.55, 0)
		dropdown.Frame.Frame.Size = UDim2.new(0, dropdown.Frame.Frame.AbsoluteSize.Y, 0, dropdown.Frame.Frame.AbsoluteSize.Y)
		dropdown.Frame.TextBox.Size = UDim2.new(1, - dropdown.Frame.Frame.AbsoluteSize.X, 1, 0)
-- FIX CALLBACK
		table.insert(self.modules, dropdown)
		self.page:Resize()

		local list = library.Functions.BetterFindIndex(config, "List") or {}
		local toggling_table = {}
		local multiList = {}
		local multiListGroup = {}
		local savedValues = {}
		local _value

		local function update(update_config)
			update_config = update_config or {}

			if library.Functions.BetterFindIndex(update_config, "Title") and library.Functions.BetterFindIndex(update_config, "Title") ~= "" then
				dropdown.Frame.TextBox.PlaceholderText = library.Functions.BetterFindIndex(update_config, "Title")
				dropdown.SearchValue.Value = library.Functions.BetterFindIndex(update_config, "Title")
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
			local function check_value(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					return library.Functions.BetterFindIndex(update_config, var)
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					return library.Functions.BetterFindIndex(config, var)
				end
			end

			dropdown.Frame.KeyBind.Visible = check_boolean("KeyBind")
			if check_boolean("KeyBind") then
				dropdown.Frame.TextBox.Size = UDim2.new(1, - dropdown.Frame.Frame.AbsoluteSize.X - dropdown.Frame.KeyBind.AbsoluteSize.X, 1, 0)
			else
				dropdown.Frame.TextBox.Size = UDim2.new(1, - dropdown.Frame.Frame.AbsoluteSize.X, 1, 0)
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
						local original_value = value
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
							}, UDim.new(0, check_value("Corner") or 5)),
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
							check_value("Multi")
						)

						table.insert(multiListGroup, Dropdown_Item)

						Dropdown_Item.MouseButton1Click:Connect(function()
							Dropdown_Item.IsEnabled.Value = not Dropdown_Item.IsEnabled.Value
							savedValues[value] = Dropdown_Item.IsEnabled.Value

							if check_value("Multi") then
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
								check_value("Multi")
							)

							if check_value("CallBack") then
								if check_boolean("KeyBind") then
									if check_value("Multi") then
										_value = multiList
									else
										if Dropdown_Item.IsEnabled.Value then
											_value = original_value
										else
											_value = nil
										end
									end
								else
									if check_value("Multi") then
										check_value("CallBack")(multiList)
									else
										if Dropdown_Item.IsEnabled.Value then
											check_value("CallBack")(original_value)
										else
											check_value("CallBack")(nil)
										end
									end
								end
							end
						end)
						Dropdown_Item.ImageButton.MouseButton1Click:Connect(function()
							Dropdown_Item.IsEnabled.Value = not Dropdown_Item.IsEnabled.Value
							savedValues[value] = Dropdown_Item.IsEnabled.Value

							if check_value("Multi") then
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
								check_value("Multi")
							)

							if check_value("CallBack") then
								if check_boolean("KeyBind") then
									if check_value("Multi") then
										_value = multiList
									else
										if Dropdown_Item.IsEnabled.Value then
											_value = original_value
										else
											_value = nil
										end
									end
								else
									if check_value("Multi") then
										check_value("CallBack")(multiList)
									else
										if Dropdown_Item.IsEnabled.Value then
											check_value("CallBack")(original_value)
										else
											check_value("CallBack")(nil)
										end
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

		local function update_KeyBind(update_config)
			update_config = update_config or {}

			if self.binds[dropdown].connection then
				self.binds[dropdown].connection = self.binds[dropdown].connection:UnBind()
				if table.find(library.binds, self.binds[dropdown].connection) then
					table.remove(library.binds, table.find(library.binds, self.binds[dropdown].connection))
				end
			end

			if library.Functions.BetterFindIndex(update_config, "value") then
				self.binds[dropdown].connection = library.Functions.BindToKey(library.Functions.BetterFindIndex(update_config, "value"), self.binds[dropdown].callback)
				table.insert(library.binds, self.binds[dropdown].connection)
				dropdown.Frame.KeyBind.Text.Text = library.Functions.BetterFindIndex(update_config, "value").Name
			else
				dropdown.Frame.KeyBind.Text.Text = "None"
			end
		end

		self.binds[dropdown] = {
			callback = function()
				task.spawn(function()
					library.Functions.Tween(dropdown.Frame.KeyBind.Text, { TextColor3 = library.Settings.theme.TextColor }, 0.4).Completed:Wait()
					library.Functions.Tween(dropdown.Frame.KeyBind.Text, { TextColor3 = library.Settings.theme.LightContrast }, 0.2)
				end)

				if library.Functions.BetterFindIndex(config, "CallBack") then
					if dropdown.Frame.KeyBind.Visible then
						library.Functions.BetterFindIndex(config, "CallBack")(_value)
					end
				end
			end,
		}
		dropdown.Frame.KeyBind.MouseButton1Click:Connect(function()
			library.Functions.Ripple(dropdown.Frame.KeyBind, 0.5)

			if self.binds[dropdown].connection then
				return update_KeyBind()
			end

			if dropdown.Frame.KeyBind.Text.Text == "None" then
				dropdown.Frame.KeyBind.Text.Text = "..."

				local key = library.Functions.KeyPressed()

				update_KeyBind({ Value = key.KeyCode })
			end
		end)
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
	function library.section:addCheckbox(config: table): table
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
		self.page:Resize()

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
	function library.section:add3DPlayer(config: table): table
		config = config or {}
		local ViewPlayer = Create("ViewportFrame", {
			Name = "ViewPlayer_Element",
			Parent = (library.Functions.BetterFindIndex(config, "section") or 1) > #self.container and self.container[#self.container] or self.container[library.Functions.BetterFindIndex(config, "section") or 1],
			BackgroundColor3 = library.Settings.theme.Background,
			Size = library.Functions.BetterFindIndex(config, "Size") or UDim2.new(1, 0, 0, library.Settings.Elements_Size * 8),
		}, {
			Create("ImageButton", {
				BackgroundColor3 = library.Settings.theme.Contrast,
				AutoButtonColor = false,
				Size = UDim2.new(0, library.Settings.Elements_Size, 0, library.Settings.Elements_Size),
				Position = UDim2.new(1, -5, 0, 5),
				AnchorPoint = Vector2.new(1, 0),
			}, {
				Create("ImageLabel", {
					Image = "rbxassetid://7734051052",
					ImageColor3 = library.Settings.theme.TextColor,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.7, 0, 0.7, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
				}),
			}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5)),
			Create("WorldModel"),
			Create("StringValue", {
				Name = "SearchValue",
				Value = library.Functions.BetterFindIndex(config, "Player") and typeof(library.Functions.BetterFindIndex(config, "Player")) == "Instance" and library.Functions.BetterFindIndex(config, "Player").Name or "ViewPlayer",
			}),
		}, UDim.new(0, library.Functions.BetterFindIndex(config, "Corner") or 5))

		table.insert(self.modules, ViewPlayer)
		self.page:Resize()

		local PV_connections = {}

		local function Update(update_config: table)
			update_config = update_config or {}
			for i, v in pairs(PV_connections) do
				pcall(function()
					v:Disconnect()
				end)
			end
			table.clear(PV_connections)

			local function check(var)
				if library.Functions.BetterFindIndex(update_config, var) ~= nil then
					return library.Functions.BetterFindIndex(update_config, var)
				elseif library.Functions.BetterFindIndex(config, var) ~= nil then
					return library.Functions.BetterFindIndex(config, var)
				end
			end

			local PLAYER = check("Player")
			if not PLAYER or typeof(PLAYER) ~= "Instance" or PLAYER.Parent.Name ~= "Players" then
				return
			end
			ViewPlayer.SearchValue.Value = PLAYER.Name

			local CHARACTER = PLAYER.Character or PLAYER:waitForChild("Character", 5)
			if not CHARACTER then
				return
			end

			ViewPlayer.WorldModel:ClearAllChildren()

			CHARACTER.Archivable = true

			local model = CHARACTER:Clone()
			model.Name = "Model"
			model.Parent = ViewPlayer.WorldModel
			model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			model:SetPrimaryPartCFrame((check("Position") or CFrame.new(Vector3.new(0, 0, -5), Vector3.new(0, 0, 0))) * CFrame.Angles(0, 0, 0))

			local function UpdateAnim(Char, CloneChar)
				if #CloneChar.Humanoid:GetPlayingAnimationTracks() > #Char.Humanoid:GetPlayingAnimationTracks() then
					for i = #CloneChar.Humanoid:GetPlayingAnimationTracks(), #Char.Humanoid:GetPlayingAnimationTracks(), -1 do
						pcall(function()
							CloneChar.Humanoid:GetPlayingAnimationTracks()[i]:Stop(0.1)
						end)
					end
				end
				for i, v in pairs(Char.Humanoid:GetPlayingAnimationTracks()) do
					if not CloneChar.Humanoid:GetPlayingAnimationTracks()[i] then
						CloneChar.Humanoid.Animator:LoadAnimation(v.Animation):Play(0.2)
					else
						if
							CloneChar.Humanoid:GetPlayingAnimationTracks()[i].Animation.AnimationId
							~= v.Animation.AnimationId
						then
							for k = #CloneChar.Humanoid:GetPlayingAnimationTracks(), i, -1 do
								pcall(function()
									CloneChar.Humanoid:GetPlayingAnimationTracks()[i]:Stop(0.1)
								end)
							end
							CloneChar.Humanoid.Animator:LoadAnimation(v.Animation):Play(0.2)
						end
					end
				end
			end

			table.insert(PV_connections, game:GetService("RunService").Stepped:Connect(function()
				if check("UpdateAnim") and check("UpdateAnim") == true then
					pcall(function()
						UpdateAnim(CHARACTER, model)
					end)
				end
			end))

			local currentX
			local MouseButton1Down = false
			table.insert(PV_connections, ViewPlayer.InputBegan:Connect(function(input, processed)
				if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 or library.IsMobile and Enum.UserInputType.Touch then
					MouseButton1Down = true
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							MouseButton1Down = false
							currentX = nil
						end
					end)
				end
			end))
			table.insert(PV_connections, ViewPlayer.MouseMoved:Connect(function(X, Y)
				if not MouseButton1Down then
					return
				end
				if currentX then
					model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame * CFrame.fromEulerAnglesXYZ(0, ((X - currentX) * 0.025), 0))
				end
				currentX = X
			end))
		end

		if library.Functions.BetterFindIndex(config, "player") and typeof(library.Functions.BetterFindIndex(config, "Player")) == "Instance" and library.Functions.BetterFindIndex(config, "Player").Parent.Name == "Players" then
			Update()
		end
		ViewPlayer.ImageButton.MouseButton1Click:Connect(function()
			library.Functions.Ripple(ViewPlayer.ImageButton, 0.5)
			Update()
		end)
		local function getModel()
			return ViewPlayer.WorldModel:FindFirstChild("Model") or nil
		end

		return { Instance = ViewPlayer, Update = Update, getModel = getModel }
	end
	--#region TextBox's

	--#endregion
	--#region ColorPicker

	--#endregion
end

library.Icons = {
	["activity"] = "rbxassetid://7733655755",
	["add"] = "rbxassetid://3944675151",
	["add-circle"] = "rbxassetid://3605017115",
	["AED"] = "rbxassetid://4370336019",
	["airplane"] = "rbxassetid://4483363527",
	["airplay"] = "rbxassetid://7733655834",
	["alarm-check"] = "rbxassetid://7733655912",
	["alarm-clock"] = "rbxassetid://7733656100",
	["alarm-clock-off"] = "rbxassetid://7733656003",
	["alarm-minus"] = "rbxassetid://7733656164",
	["alarm-plus"] = "rbxassetid://7733658066",
	["album"] = "rbxassetid://7733658133",
	["album-2"] = "rbxassetid://4400695581",
	["alert"] = "rbxassetid://4370336704",
	["alert-circle"] = "rbxassetid://7733658271",
	["alert-octagon"] = "rbxassetid://7733658335",
	["alert-triangle"] = "rbxassetid://7733658504",
	["align-center"] = "rbxassetid://7733909776",
	["align-justify"] = "rbxassetid://7733661326",
	["align-left"] = "rbxassetid://7733911357",
	["align-right"] = "rbxassetid://7733663582",
	["anchor"] = "rbxassetid://7733911490",
	["android"] = "rbxassetid://3944664684",
	["android-head"] = "rbxassetid://4450736564",
	["aperture"] = "rbxassetid://7733666258",
	["apps"] = "rbxassetid://4483364237",
	["archive"] = "rbxassetid://7733911621",
	["arrow-big-down"] = "rbxassetid://7733668653",
	["arrow-big-left"] = "rbxassetid://7733911731",
	["arrow-big-right"] = "rbxassetid://7733671493",
	["arrow-big-up"] = "rbxassetid://7733671663",
	["arrow-down"] = "rbxassetid://7733672933",
	["arrow-down-circle"] = "rbxassetid://7733671763",
	["arrow-down-left"] = "rbxassetid://7733672282",
	["arrow-down-right"] = "rbxassetid://7733672831",
	["arrow-left"] = "rbxassetid://7733673136",
	["arrow-left-circle"] = "rbxassetid://7733673056",
	["arrow-right"] = "rbxassetid://7733673345",
	["arrow-right-circle"] = "rbxassetid://7733673229",
	["arrow-up"] = "rbxassetid://7733673717",
	["arrow-up-circle"] = "rbxassetid://7733673466",
	["arrow-up-left"] = "rbxassetid://7733673539",
	["arrow-up-right"] = "rbxassetid://7733673646",
	["asterisk"] = "rbxassetid://7733673800",
	["at-sign"] = "rbxassetid://7733673907",
	["attachment"] = "rbxassetid://4483345278",
	["award"] = "rbxassetid://7733673987",
	["axe"] = "rbxassetid://7733674079",
	["back"] = "rbxassetid://4370337241",
	["backspace"] = "rbxassetid://4483345463",
	["backup"] = "rbxassetid://4335477481",
	["backup-restore"] = "rbxassetid://4400696294",
	["banknote"] = "rbxassetid://7733674153",
	["bar-chart"] = "rbxassetid://7733674319",
	["bar-chart-2"] = "rbxassetid://7733674239",
	["barcode"] = "rbxassetid://4384394779",
	["battery"] = "rbxassetid://7733674820",
	["battery-charging"] = "rbxassetid://7733674402",
	["battery-full"] = "rbxassetid://7733674503",
	["battery-low"] = "rbxassetid://7733674589",
	["battery-medium"] = "rbxassetid://7733674731",
	["beaker"] = "rbxassetid://7733674922",
	["bell"] = "rbxassetid://7733911828",
	["bell-minus"] = "rbxassetid://7733675028",
	["bell-off"] = "rbxassetid://7733675107",
	["bell-plus"] = "rbxassetid://7733675181",
	["bell-ring"] = "rbxassetid://7733675275",
	["bike"] = "rbxassetid://7733678330",
	["binary"] = "rbxassetid://7733678388",
	["block"] = "rbxassetid://3944675664",
	["bluetooth"] = "rbxassetid://7733687147",
	["bluetooth-connected"] = "rbxassetid://7734110952",
	["bluetooth-off"] = "rbxassetid://7733914252",
	["bluetooth-searching"] = "rbxassetid://7733914320",
	["blur"] = "rbxassetid://4400696929",
	["blur-linear"] = "rbxassetid://4400698359",
	["blur-off"] = "rbxassetid://4400697855",
	["blur-radial"] = "rbxassetid://4400698963",
	["book"] = "rbxassetid://7733914390",
	["book-2"] = "rbxassetid://4330060040",
	["book-open"] = "rbxassetid://7733687281",
	["bookmark"] = "rbxassetid://7733692043",
	["bookmark-2"] = "rbxassetid://3605522284",
	["bookmark-minus"] = "rbxassetid://7733689754",
	["bookmark-plus"] = "rbxassetid://7734111084",
	["border-all"] = "rbxassetid://4483364408",
	["bot"] = "rbxassetid://7733916988",
	["box"] = "rbxassetid://7733917120",
	["box-select"] = "rbxassetid://7733696665",
	["briefcase"] = "rbxassetid://7733919017",
	["brush"] = "rbxassetid://7733701455",
	["bug"] = "rbxassetid://7733701545",
	["building"] = "rbxassetid://7733701625",
	["bus"] = "rbxassetid://7733701715",
	["calculator"] = "rbxassetid://7733919105",
	["calendar"] = "rbxassetid://7733919198",
	["camera"] = "rbxassetid://7733708692",
	["camera-off"] = "rbxassetid://7733919260",
	["cancel"] = "rbxassetid://4400699701",
	["candle"] = "rbxassetid://4483345607",
	["car"] = "rbxassetid://7733708835",
	["cast"] = "rbxassetid://7733919326",
	["CD"] = "rbxassetid://7734110220",
	["cellphone"] = "rbxassetid://4384403999",
	["charging"] = "rbxassetid://4370338095",
	["check"] = "rbxassetid://7733715400",
	["check-circle"] = "rbxassetid://7733919427",
	["check-circle-2"] = "rbxassetid://7733710700",
	["check-square"] = "rbxassetid://7733919526",
	["chevron-down"] = "rbxassetid://7733717447",
	["chevron-left"] = "rbxassetid://7733717651",
	["chevron-right"] = "rbxassetid://7733717755",
	["chevron-up"] = "rbxassetid://7733919605",
	["chevrons-down"] = "rbxassetid://7733720604",
	["chevrons-down-up"] = "rbxassetid://7733720483",
	["chevrons-left"] = "rbxassetid://7733720701",
	["chevrons-right"] = "rbxassetid://7733919682",
	["chevrons-up"] = "rbxassetid://7733723433",
	["chevrons-up-down"] = "rbxassetid://7733723321",
	["chrome"] = "rbxassetid://7733919783",
	["circle"] = "rbxassetid://7733919881",
	["clear"] = "rbxassetid://3944676352",
	["clipboard"] = "rbxassetid://7733734762",
	["clipboard-check"] = "rbxassetid://7733919947",
	["clipboard-list"] = "rbxassetid://7733920117",
	["clipboard-x"] = "rbxassetid://7733734668",
	["clock"] = "rbxassetid://7733734848",
	["cloud"] = "rbxassetid://7733746980",
	["cloud-2"] = "rbxassetid://4384402413",
	["cloud-alert"] = "rbxassetid://4384402990",
	["cloud-check"] = "rbxassetid://4384403532",
	["cloud-drizzle"] = "rbxassetid://7733920226",
	["cloud-fog"] = "rbxassetid://7733920317",
	["cloud-hail"] = "rbxassetid://7733920444",
	["cloud-lightning"] = "rbxassetid://7733741741",
	["cloud-moon"] = "rbxassetid://7733920519",
	["cloud-off"] = "rbxassetid://7733745572",
	["cloud-rain"] = "rbxassetid://7733746651",
	["cloud-rain-wind"] = "rbxassetid://7733746456",
	["cloud-snow"] = "rbxassetid://7733746798",
	["cloud-sun"] = "rbxassetid://7733746880",
	["clover"] = "rbxassetid://7733747233",
	["code"] = "rbxassetid://7733749837",
	["code-2"] = "rbxassetid://7733920644",
	["codepen"] = "rbxassetid://7733920768",
	["codesandbox"] = "rbxassetid://7733752575",
	["coffee"] = "rbxassetid://7733752630",
	["cogs"] = "rbxassetid://4483345737",
	["coins"] = "rbxassetid://7743866529",
	["coins-2"] = "rbxassetid://4483345875",
	["columns"] = "rbxassetid://7733757178",
	["command"] = "rbxassetid://7733924046",
	["commute"] = "rbxassetid://4335478275",
	["compare"] = "rbxassetid://4483363084",
	["compass"] = "rbxassetid://7733924216",
	["contact"] = "rbxassetid://7743866666",
	["contacts"] = "rbxassetid://4384401919",
	["contrast"] = "rbxassetid://7733764005",
	["copy"] = "rbxassetid://7733764083",
	["copyleft"] = "rbxassetid://7733764196",
	["copyright"] = "rbxassetid://7733764275",
	["copyright-2"] = "rbxassetid://3944676934",
	["corner-down-left"] = "rbxassetid://7733764327",
	["corner-down-right"] = "rbxassetid://7733764385",
	["corner-left-down"] = "rbxassetid://7733764448",
	["corner-left-up"] = "rbxassetid://7733764536",
	["corner-right-down"] = "rbxassetid://7733764605",
	["corner-right-up"] = "rbxassetid://7733764680",
	["corner-up-left"] = "rbxassetid://7733764800",
	["corner-up-right"] = "rbxassetid://7733764915",
	["cpu"] = "rbxassetid://7733765045",
	["create"] = "rbxassetid://3944677737",
	["creation"] = "rbxassetid://4483362748",
	["crop"] = "rbxassetid://7733765140",
	["cross"] = "rbxassetid://7733765224",
	["crosshair"] = "rbxassetid://7733765307",
	["crosshairs"] = "rbxassetid://4483345998",
	["crown"] = "rbxassetid://7733765398",
	["cube-scan"] = "rbxassetid://4483362458",
	["currency"] = "rbxassetid://7733765592",
	["database"] = "rbxassetid://7743866778",
	["delete"] = "rbxassetid://7733768142",
	["delete-2"] = "rbxassetid://4483361337",
	["delete-outline"] = "rbxassetid://4483362299",
	["delta"] = "rbxassetid://4400700924",
	["diamond"] = "rbxassetid://7723881066",
	["diskette"] = "rbxassetid://7072729672",
	["divide"] = "rbxassetid://7733769365",
	["divide-circle"] = "rbxassetid://7733769152",
	["divide-square"] = "rbxassetid://7733769261",
	["dollar-sign"] = "rbxassetid://7733770599",
	["dollar-sign-2"] = "rbxassetid://4400700509",
	["done"] = "rbxassetid://3944680095",
	["dots-horizontal"] = "rbxassetid://4384401360",
	["download"] = "rbxassetid://7733770755",
	["download-cloud"] = "rbxassetid://7733770689",
	["dribbble"] = "rbxassetid://7733770843",
	["droplet"] = "rbxassetid://7733770982",
	["droplets"] = "rbxassetid://7733771078",
	["edit"] = "rbxassetid://7733771472",
	["edit-2"] = "rbxassetid://7733771217",
	["edit-3"] = "rbxassetid://7733771361",
	["edit-4"] = "rbxassetid://4370186570",
	["electricity"] = "rbxassetid://7733771628",
	["electricity-off"] = "rbxassetid://7733771563",
	["equal"] = "rbxassetid://7733771811",
	["equal-not"] = "rbxassetid://7733771726",
	["equalizer"] = "rbxassetid://4384400812",
	["error"] = "rbxassetid://3944669799",
	["euro"] = "rbxassetid://7733771891",
	["expand"] = "rbxassetid://7733771982",
	["explore"] = "rbxassetid://4335479121",
	["explore-off"] = "rbxassetid://4335479658",
	["export"] = "rbxassetid://4400701343",
	["extension"] = "rbxassetid://4335480353",
	["external-link"] = "rbxassetid://7743866903",
	["eye"] = "rbxassetid://7733774602",
	["eye-off"] = "rbxassetid://7733774495",
	["face"] = "rbxassetid://4335480896",
	["face-id"] = "rbxassetid://4370335364",
	["fast-forward"] = "rbxassetid://7743867090",
	["favorite"] = "rbxassetid://4370033185",
	["favorite-border"] = "rbxassetid://4335482118",
	["feather"] = "rbxassetid://7733777166",
	["figma"] = "rbxassetid://7743867310",
	["file"] = "rbxassetid://7733793319",
	["file-check"] = "rbxassetid://7733779668",
	["file-check-2"] = "rbxassetid://7733779610",
	["file-code"] = "rbxassetid://7733779730",
	["file-digit"] = "rbxassetid://7733935829",
	["file-input"] = "rbxassetid://7733935917",
	["file-minus"] = "rbxassetid://7733936115",
	["file-minus-2"] = "rbxassetid://7733936010",
	["file-output"] = "rbxassetid://7733788742",
	["file-plus"] = "rbxassetid://7733788885",
	["file-plus-2"] = "rbxassetid://7733788816",
	["file-search"] = "rbxassetid://7733788966",
	["file-text"] = "rbxassetid://7733789088",
	["file-x"] = "rbxassetid://7733938136",
	["file-x-2"] = "rbxassetid://7743867554",
	["files"] = "rbxassetid://7743867811",
	["film"] = "rbxassetid://7733942579",
	["filter"] = "rbxassetid://7733798407",
	["filter_sort"] = "rbxassetid://4370342507",
	["fingerprint"] = "rbxassetid://3944703587",
	["flag"] = "rbxassetid://7733798691",
	["flag-2"] = "rbxassetid://3944688398",
	["flag-triangle-left"] = "rbxassetid://7733798509",
	["flag-triangle-right"] = "rbxassetid://7733798634",
	["flame"] = "rbxassetid://7733798747",
	["flashlight"] = "rbxassetid://7733798851",
	["flashlight-off"] = "rbxassetid://7733798799",
	["flask-conical"] = "rbxassetid://7733798901",
	["flask-round"] = "rbxassetid://7733798957",
	["flower"] = "rbxassetid://4483346149",
	["folder"] = "rbxassetid://7733799185",
	["folder-minus"] = "rbxassetid://7733799022",
	["folder-plus"] = "rbxassetid://7733799092",
	["forest"] = "rbxassetid://4370343755",
	["form-input"] = "rbxassetid://7733799275",
	["forward"] = "rbxassetid://7733799371",
	["framer"] = "rbxassetid://7733799486",
	["frown"] = "rbxassetid://7733799591",
	["function-square"] = "rbxassetid://7733799682",
	["gamepad"] = "rbxassetid://7733799901",
	["gamepad-2"] = "rbxassetid://7733799795",
	["gamepad-3"] = "rbxassetid://4384396122",
	["gamepad-circle"] = "rbxassetid://4384396714",
	["gauge"] = "rbxassetid://7733799969",
	["gavel"] = "rbxassetid://7733800044",
	["gem"] = "rbxassetid://7733942651",
	["ghost"] = "rbxassetid://7743868000",
	["GIF"] = "rbxassetid://3610246221",
	["gift"] = "rbxassetid://7733946818",
	["gift-2"] = "rbxassetid://4370344279",
	["gift-card"] = "rbxassetid://7733945018",
	["git-branch"] = "rbxassetid://7733949149",
	["git-branch-plus"] = "rbxassetid://7743868200",
	["git-commit"] = "rbxassetid://7743868360",
	["git-merge"] = "rbxassetid://7733952195",
	["git-pull-request"] = "rbxassetid://7733952287",
	["github"] = "rbxassetid://7733954058",
	["gitlab"] = "rbxassetid://7733954246",
	["glasses"] = "rbxassetid://7733954403",
	["globe"] = "rbxassetid://7733954760",
	["globe-2"] = "rbxassetid://7733954611",
	["globe-3"] = "rbxassetid://4370344717",
	["grab"] = "rbxassetid://7733954884",
	["grade"] = "rbxassetid://4335482575",
	["graduation-cap"] = "rbxassetid://7733955058",
	["grid"] = "rbxassetid://7733955179",
	["grip-horizontal"] = "rbxassetid://7733955302",
	["grip-vertical"] = "rbxassetid://7733955410",
	["hammer"] = "rbxassetid://7733955511",
	["hand"] = "rbxassetid://7733955740",
	["hand-metal"] = "rbxassetid://7733955664",
	["hard-drive"] = "rbxassetid://7733955793",
	["hard-hat"] = "rbxassetid://7733955850",
	["hash"] = "rbxassetid://7733955906",
	["haze"] = "rbxassetid://7733955969",
	["headphones"] = "rbxassetid://7733956063",
	["heart"] = "rbxassetid://7733956134",
	["heart-pulse"] = "rbxassetid://4483346354",
	["help-circle"] = "rbxassetid://7733956210",
	["hexagon"] = "rbxassetid://7743868527",
	["hexagon-2"] = "rbxassetid://7618136617",
	["highlighter"] = "rbxassetid://7743868648",
	["history"] = "rbxassetid://7733960880",
	["home"] = "rbxassetid://7733960981",
	["home-2"] = "rbxassetid://4370345144",
	["http"] = "rbxassetid://3610248649",
	["image"] = "rbxassetid://7733964126",
	["image-minus"] = "rbxassetid://7733963797",
	["image-off"] = "rbxassetid://7733963907",
	["image-plus"] = "rbxassetid://7733964016",
	["import"] = "rbxassetid://7733964240",
	["inbox"] = "rbxassetid://7733964370",
	["indent"] = "rbxassetid://7733964452",
	["indian-rupee"] = "rbxassetid://7733964536",
	["infinity"] = "rbxassetid://7733964640",
	["infinity-2"] = "rbxassetid://4370345701",
	["info"] = "rbxassetid://7733964719",
	["inspect"] = "rbxassetid://7733964808",
	["italic"] = "rbxassetid://7733964917",
	["jersey-pound"] = "rbxassetid://7733965029",
	["key"] = "rbxassetid://7733965118",
	["king"] = "rbxassetid://4370316039",
	["knight"] = "rbxassetid://4370316596",
	["landmark"] = "rbxassetid://7733965184",
	["language"] = "rbxassetid://3610245066",
	["languages"] = "rbxassetid://7733965249",
	["laptop"] = "rbxassetid://7733965386",
	["laptop-2"] = "rbxassetid://7733965313",
	["lasso"] = "rbxassetid://7733967892",
	["lasso-select"] = "rbxassetid://7743868832",
	["layers"] = "rbxassetid://7743868936",
	["layers-2"] = "rbxassetid://4384400106",
	["layout"] = "rbxassetid://7733970543",
	["layout-dashboard"] = "rbxassetid://7733970318",
	["layout-grid"] = "rbxassetid://7733970390",
	["layout-list"] = "rbxassetid://7733970442",
	["layout-template"] = "rbxassetid://7733970494",
	["library"] = "rbxassetid://7743869054",
	["life-buoy"] = "rbxassetid://7733973479",
	["lightbulb"] = "rbxassetid://7733975185",
	["lightbulb-off"] = "rbxassetid://7733975123",
	["link"] = "rbxassetid://7733978098",
	["link-2"] = "rbxassetid://7743869163",
	["link-2-off"] = "rbxassetid://7733975283",
	["link-3"] = "rbxassetid://4503342956",
	["link-off"] = "rbxassetid://3944689656",
	["list"] = "rbxassetid://7743869612",
	["list-checks"] = "rbxassetid://7743869317",
	["list-minus"] = "rbxassetid://7733980795",
	["list-ordered"] = "rbxassetid://7743869411",
	["list-plus"] = "rbxassetid://7733984995",
	["list-x"] = "rbxassetid://7743869517",
	["loader"] = "rbxassetid://7733992358",
	["loader-2"] = "rbxassetid://7733989869",
	["locate"] = "rbxassetid://7733992469",
	["locate-fixed"] = "rbxassetid://7733992424",
	["lock"] = "rbxassetid://7733992528",
	["lock-2"] = "rbxassetid://3610239960",
	["lock-open"] = "rbxassetid://3610242099",
	["log-in"] = "rbxassetid://7733992604",
	["log-out"] = "rbxassetid://7733992677",
	["mail"] = "rbxassetid://7733992732",
	["map"] = "rbxassetid://7733992829",
	["map-pin"] = "rbxassetid://7733992789",
	["maximize"] = "rbxassetid://7733992982",
	["maximize-2"] = "rbxassetid://7733992901",
	["megaphone"] = "rbxassetid://7733993049",
	["meh"] = "rbxassetid://7733993147",
	["memory"] = "rbxassetid://4384394237",
	["menu"] = "rbxassetid://7733993211",
	["menu-2"] = "rbxassetid://4370318685",
	["menu-four"] = "rbxassetid://4370319235",
	["message-circle"] = "rbxassetid://7733993311",
	["message-square"] = "rbxassetid://7733993369",
	["mic"] = "rbxassetid://7743869805",
	["mic-off"] = "rbxassetid://7743869714",
	["minimize"] = "rbxassetid://7733997941",
	["minimize-2"] = "rbxassetid://7733997870",
	["minus"] = "rbxassetid://7734000129",
	["minus-circle"] = "rbxassetid://7733998053",
	["minus-square"] = "rbxassetid://7743869899",
	["monitor"] = "rbxassetid://7734002839",
	["monitor-off"] = "rbxassetid://7734000184",
	["monitor-speaker"] = "rbxassetid://7743869988",
	["moon"] = "rbxassetid://7743870134",
	["more-horizontal"] = "rbxassetid://7734006080",
	["more-vertical"] = "rbxassetid://7734006187",
	["mountain"] = "rbxassetid://7734008868",
	["mountain-snow"] = "rbxassetid://7743870286",
	["mouse-pointer"] = "rbxassetid://7743870392",
	["mouse-pointer-2"] = "rbxassetid://7734010405",
	["mouse-pointer-click"] = "rbxassetid://7734010488",
	["move"] = "rbxassetid://7743870731",
	["move-diagonal"] = "rbxassetid://7743870505",
	["move-diagonal-2"] = "rbxassetid://7734013178",
	["move-horizontal"] = "rbxassetid://7734016210",
	["move-vertical"] = "rbxassetid://7743870608",
	["music"] = "rbxassetid://7734020554",
	["navigation"] = "rbxassetid://7734020989",
	["navigation-2"] = "rbxassetid://7734020942",
	["network"] = "rbxassetid://7734021047",
	["notification"] = "rbxassetid://3944670656",
	["octagon"] = "rbxassetid://7734021165",
	["on-charge"] = "rbxassetid://7734021231",
	["online"] = "rbxassetid://4370317928",
	["opacity"] = "rbxassetid://4335483334",
	["option"] = "rbxassetid://7734021300",
	["outdent"] = "rbxassetid://7734021384",
	["package"] = "rbxassetid://7734021469",
	["paint"] = "rbxassetid://4384393547",
	["palette"] = "rbxassetid://7734021595",
	["palette-2"] = "rbxassetid://4335483762",
	["palette-swatch"] = "rbxassetid://4400704299",
	["palm-scan"] = "rbxassetid://4370334869",
	["paperclip"] = "rbxassetid://7734021680",
	["pause"] = "rbxassetid://7734021897",
	["pause-circle"] = "rbxassetid://7734021767",
	["pause-octagon"] = "rbxassetid://7734021827",
	["pen-tool"] = "rbxassetid://7734022041",
	["pencil"] = "rbxassetid://7734022107",
	["percent"] = "rbxassetid://7743870852",
	["person-standing"] = "rbxassetid://7743871002",
	["pets"] = "rbxassetid://3610237052",
	["phone"] = "rbxassetid://7734032056",
	["phone-2"] = "rbxassetid://4506892591",
	["phone-call"] = "rbxassetid://7734027264",
	["phone-forwarded"] = "rbxassetid://7734027345",
	["phone-incoming"] = "rbxassetid://7743871120",
	["phone-missed"] = "rbxassetid://7734029465",
	["phone-off"] = "rbxassetid://7734029534",
	["phone-outgoing"] = "rbxassetid://7743871253",
	["photo-camera"] = "rbxassetid://4335484343",
	["pie-chart"] = "rbxassetid://7734034378",
	["piggy-bank"] = "rbxassetid://7734034513",
	["pin"] = "rbxassetid://4384392959",
	["pipette"] = "rbxassetid://7743871384",
	["plane"] = "rbxassetid://7734037723",
	["play"] = "rbxassetid://7743871480",
	["play-circle"] = "rbxassetid://7734037784",
	["plus"] = "rbxassetid://7734042071",
	["plus-circle"] = "rbxassetid://7734040271",
	["plus-square"] = "rbxassetid://7734040369",
	["pocket"] = "rbxassetid://7734042139",
	["podcast"] = "rbxassetid://7734042234",
	["pointer"] = "rbxassetid://7734042307",
	["pound-sterling"] = "rbxassetid://7734042354",
	["power"] = "rbxassetid://7734042493",
	["power-off"] = "rbxassetid://7734042423",
	["print"] = "rbxassetid://4377193226",
	["printer"] = "rbxassetid://7734042580",
	["qr-code"] = "rbxassetid://7743871575",
	["QRcode-scan"] = "rbxassetid://4384395384",
	["quote"] = "rbxassetid://7734045100",
	["radar"] = "rbxassetid://4384392464",
	["radio"] = "rbxassetid://7743871662",
	["radio-2"] = "rbxassetid://4370305054",
	["radio-receiver"] = "rbxassetid://7734045155",
	["radio-tower"] = "rbxassetid://4370305588",
	["redo"] = "rbxassetid://7743871739",
	["redo-2"] = "rbxassetid://3944702361",
	["refresh"] = "rbxassetid://4335476290",
	["refresh-ccw"] = "rbxassetid://7734050715",
	["refresh-cw"] = "rbxassetid://7734051052",
	["regex"] = "rbxassetid://7734051188",
	["remove"] = "rbxassetid://4370317406",
	["repeat"] = "rbxassetid://7734051454",
	["repeat-1"] = "rbxassetid://7734051342",
	["reply"] = "rbxassetid://7734051594",
	["reply-2"] = "rbxassetid://3944691398",
	["reply-all"] = "rbxassetid://7734051524",
	["reply-all-2"] = "rbxassetid://3944691867",
	["restart"] = "rbxassetid://4370306254",
	["rewind"] = "rbxassetid://7734051670",
	["rhombus"] = "rbxassetid://4384405947",
	["rocking-chair"] = "rbxassetid://7734051769",
	["rotate-90"] = "rbxassetid://4384406773",
	["rotate-ccw"] = "rbxassetid://7734051861",
	["rotate-cw"] = "rbxassetid://7734051957",
	["rss"] = "rbxassetid://7734052075",
	["ruler"] = "rbxassetid://7734052157",
	["russian-ruble"] = "rbxassetid://7734052248",
	["save"] = "rbxassetid://7734052335",
	["scale"] = "rbxassetid://7734052454",
	["schedule"] = "rbxassetid://4335484884",
	["scissors"] = "rbxassetid://7734052570",
	["screen-share"] = "rbxassetid://7734052814",
	["screen-share-off"] = "rbxassetid://7734052653",
	["search"] = "rbxassetid://7734052925",
	["search-2"] = "rbxassetid://3605509925",
	["send"] = "rbxassetid://7734053039",
	["send-2"] = "rbxassetid://3944690667",
	["separator-horizontal"] = "rbxassetid://7734053146",
	["separator-vertical"] = "rbxassetid://7734053213",
	["server"] = "rbxassetid://7734053426",
	["server-crash"] = "rbxassetid://7734053281",
	["server-off"] = "rbxassetid://7734053361",
	["settings"] = "rbxassetid://7734053495",
	["settings-2"] = "rbxassetid://3605022185",
	["share"] = "rbxassetid://7734053697",
	["share-2"] = "rbxassetid://7734053595",
	["sheet"] = "rbxassetid://7743871876",
	["shield"] = "rbxassetid://7734056608",
	["shield-alert"] = "rbxassetid://7734056326",
	["shield-check"] = "rbxassetid://7734056411",
	["shield-close"] = "rbxassetid://7734056470",
	["shield-off"] = "rbxassetid://7734056540",
	["shirt"] = "rbxassetid://7734056672",
	["shopping-bag"] = "rbxassetid://7734056747",
	["shopping-cart"] = "rbxassetid://7734056813",
	["shovel"] = "rbxassetid://7734056878",
	["shrink"] = "rbxassetid://7734056971",
	["shuffle"] = "rbxassetid://7734057059",
	["sidebar"] = "rbxassetid://7734058260",
	["sidebar-close"] = "rbxassetid://7734058092",
	["sidebar-open"] = "rbxassetid://7734058165",
	["sigma"] = "rbxassetid://7734058345",
	["skip-back"] = "rbxassetid://7734058404",
	["skip-forward"] = "rbxassetid://7734058495",
	["skip-next"] = "rbxassetid://4384407160",
	["skip-previous"] = "rbxassetid://4384407582",
	["skull"] = "rbxassetid://7734058599",
	["slack"] = "rbxassetid://7072722471",
	["slash"] = "rbxassetid://7072722603",
	["sliders"] = "rbxassetid://7734058803",
	["smartphone"] = "rbxassetid://7734058979",
	["smartphone-charging"] = "rbxassetid://7734058894",
	["smile"] = "rbxassetid://7734059095",
	["snowflake"] = "rbxassetid://7734059180",
	["snowflake-2"] = "rbxassetid://4384392025",
	["sort"] = "rbxassetid://3944704135",
	["sort-asc"] = "rbxassetid://7734060715",
	["sort-desc"] = "rbxassetid://7743871973",
	["speaker"] = "rbxassetid://7734063416",
	["speech"] = "rbxassetid://4370313618",
	["sprout"] = "rbxassetid://7743872071",
	["square"] = "rbxassetid://7743872181",
	["stack"] = "rbxassetid://4370346095",
	["star"] = "rbxassetid://7734068321",
	["star-half"] = "rbxassetid://7734068258",
	["stop-circle"] = "rbxassetid://7734068379",
	["strikethrough"] = "rbxassetid://7734068425",
	["sun"] = "rbxassetid://7734068495",
	["sunrise"] = "rbxassetid://7743872365",
	["sunset"] = "rbxassetid://7734070982",
	["swiss-franc"] = "rbxassetid://7734071038",
	["switch"] = "rbxassetid://4400702457",
	["switch-camera"] = "rbxassetid://7743872492",
	["switch-off"] = "rbxassetid://4400702947",
	["synchronize"] = "rbxassetid://4370226511",
	["table"] = "rbxassetid://7734073253",
	["tablet"] = "rbxassetid://7743872620",
	["tag"] = "rbxassetid://7734075797",
	["target"] = "rbxassetid://7743872758",
	["taxi"] = "rbxassetid://4506892784",
	["tent"] = "rbxassetid://7734078943",
	["terminal"] = "rbxassetid://7743872929",
	["terminal-square"] = "rbxassetid://7734079055",
	["texture"] = "rbxassetid://4335485422",
	["thermometer"] = "rbxassetid://7734084149",
	["thermometer-snowflake"] = "rbxassetid://7743873074",
	["thermometer-sun"] = "rbxassetid://7734084018",
	["thumbs-down"] = "rbxassetid://7734084236",
	["thumbs-up"] = "rbxassetid://7743873212",
	["ticket"] = "rbxassetid://7734086558",
	["timer"] = "rbxassetid://7743873443",
	["timer-2"] = "rbxassetid://4335485957",
	["timer-off"] = "rbxassetid://4335486524",
	["timer-reset"] = "rbxassetid://7743873336",
	["toggle-left"] = "rbxassetid://7734091286",
	["toggle-right"] = "rbxassetid://7743873539",
	["tonality"] = "rbxassetid://4335487169",
	["tool"] = "rbxassetid://7072723685",
	["tornado"] = "rbxassetid://7743873633",
	["transform"] = "rbxassetid://4335487866",
	["translate"] = "rbxassetid://4335488543",
	["trash"] = "rbxassetid://7743873871",
	["trash-2"] = "rbxassetid://7743873772",
	["trello"] = "rbxassetid://7743873996",
	["trend-down"] = "rbxassetid://3944704985",
	["trend-flat"] = "rbxassetid://3944705374",
	["trend-up"] = "rbxassetid://3944705939",
	["trending-down"] = "rbxassetid://7743874143",
	["trending-up"] = "rbxassetid://7743874262",
	["triangle"] = "rbxassetid://7743874367",
	["truck"] = "rbxassetid://7743874482",
	["tune"] = "rbxassetid://4335489011",
	["tv"] = "rbxassetid://7743874674",
	["tv-2"] = "rbxassetid://7743874599",
	["type"] = "rbxassetid://7743874740",
	["typing"] = "rbxassetid://4370314188",
	["umbrella"] = "rbxassetid://7743874820",
	["underline"] = "rbxassetid://7743874904",
	["undo"] = "rbxassetid://7743874974",
	["undo-2"] = "rbxassetid://3944702835",
	["unfold-less"] = "rbxassetid://4400703447",
	["unfold-more"] = "rbxassetid://4400703888",
	["unlink"] = "rbxassetid://7743875149",
	["unlink-2"] = "rbxassetid://7743875069",
	["unlock"] = "rbxassetid://7743875263",
	["upgrade"] = "rbxassetid://4370346582",
	["upload"] = "rbxassetid://7743875428",
	["upload-cloud"] = "rbxassetid://7743875358",
	["user"] = "rbxassetid://7743875962",
	["user-check"] = "rbxassetid://7743875503",
	["user-minus"] = "rbxassetid://7743875629",
	["user-plus"] = "rbxassetid://7743875759",
	["user-x"] = "rbxassetid://7743875879",
	["users"] = "rbxassetid://7743876054",
	["verified"] = "rbxassetid://7743876142",
	["verified-user"] = "rbxassetid://4335489513",
	["vibrate"] = "rbxassetid://7743876302",
	["video"] = "rbxassetid://7743876610",
	["video-off"] = "rbxassetid://7743876466",
	["view"] = "rbxassetid://7743876754",
	["visibility"] = "rbxassetid://3610254229",
	["visibility-off"] = "rbxassetid://3610254425",
	["voicemail"] = "rbxassetid://7743876916",
	["volume"] = "rbxassetid://7743877487",
	["volume-1"] = "rbxassetid://7743877081",
	["volume-2"] = "rbxassetid://7743877250",
	["volume-x"] = "rbxassetid://7743877381",
	["vote"] = "rbxassetid://4400704837",
	["wallet"] = "rbxassetid://7743877573",
	["warning"] = "rbxassetid://3944668821",
	["watch"] = "rbxassetid://7743877668",
	["watch-2"] = "rbxassetid://4384391488",
	["webcam"] = "rbxassetid://7743877896",
	["wet"] = "rbxassetid://4370347078",
	["wifi"] = "rbxassetid://7743878148",
	["wifi-off"] = "rbxassetid://7743878056",
	["wind"] = "rbxassetid://7743878264",
	["wrench"] = "rbxassetid://7743878358",
	["x"] = "rbxassetid://7743878857",
	["x-circle"] = "rbxassetid://7743878496",
	["x-octagon"] = "rbxassetid://7743878618",
	["x-square"] = "rbxassetid://7743878737",
	["zoom-in"] = "rbxassetid://7743878977",
	["zoom-in-2"] = "rbxassetid://3610253578",
	["zoom-out"] = "rbxassetid://7743879082",
	["zoom-out-2"] = "rbxassetid://3610253853",
}

return library
