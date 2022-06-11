# How To Use
- ### Lite UI <sub>*It's still in development*</sub>
> #### Encode / Decode
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

local temp_table = {
    AutoFarm = true,
    Distance = 4,
    Settings = {
        Enemy_Color = Color3.new(1, 0, 0),
        Team_Color = Color3.new(0, 1, 0)
    }
}
local encode_table = library.encode(temp_table)
print(encode_table)

local decode_table = library.decode(encode_table)
print(decode_table)
```
***Only this type of data can be encoded*:**
1. boolean
2. number
3. string
4. table
5. Vector3
6. CFrame
7. Instance
8. Color3
9. EnumItem
> #### Save Config
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

local config = {}
library.Functions.SaveConfig_game("Some game", config) -- Save config
library.Functions.SaveConfig_game_noReplace("Some game", config) -- Save config without rewriting already saved data (can be used to update some script without users configuration being reset)
library.Functions.LoadConfig_game("Some game") -- Load config
```
> #### Library Config
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

-- It is not necessary to set these values as they will be placed automatically

library.Name = 'Lite'
library.Version = 'v. 1.0.0'
library.Icon = library.Icons['hexagon-2']
library.Parent = game.CoreGui

library.Settings.AntiAFK = true
library.Settings.prefix = Enum.KeyCode.LeftAlt
library.Settings.Elements_Font = Enum.Font.SourceSans

library:setTheme("Background", Color3.fromRGB(17, 14, 24)) -- Purple THEME
library:setTheme("Contrast", Color3.fromRGB(12, 2, 15)) -- Purple THEME
library:setTheme("DarkContrast", Color3.fromRGB(8, 0, 12)) -- Purple THEME
library:setTheme("Accent", Color3.fromRGB(55, 2, 105)) -- Purple THEME
```
> #### Notifications
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

local window = library:new()

window:Notification()
window:Notification({
	title = "Notification"
})
window:Notification({
	description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin arcu magna, facilisis eu scelerisque nec, condimentum sed nibh. Ut id."
})
```
> #### Add Modules
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

-- It is not necessary to place all the configurations of the modules, only the necessary ones

local window = library:new({
    title = 'Lite',
    version = 'v. 1.0.0',
    icon = library.Icons['hexagon-2']
})

local page = window:addPage({
    icon = library.Icons.hexagon, -- or roblox image id
    title = "page_name",
})
do
    local section = page:addSection({
        Divisions = 1,
    })
    section:addButton({
        Section = 1,
        title = "Button",
        disabled = false,
        corner = 5,
        callback = function() end,
    })
    section:addClipboardLabel({
        Section = 1,
        text = "Clipboad Label",
        corner = 5,
    })
    section:addDualLabel({
        Section = 1,
        title = "Title",
        description = "Description",
        corner = 5,
    })
    section:addLabel({
        Section = 1,
        text = '<font color="#' .. library.Settings.theme.Accent:ToHex() .. '"><b>Lite</b></font>, the best UI ^-^',
        textsize = nil, -- auto
        textxalignment = Enum.TextXAlignment.Left,
        textyalignment = Enum.TextYAlignment.Center,
    })
    section:addSlider({
        Section = 1,
        Max = 10,
        Min = 0,
        Default = 0,
        title = "Slider",
        disabled = false,
        corner = 5,
        callback = function() end,
    })
    section:addToggle({
        Section = 1,
        title = "Toggle",
        keybind = false,
        keybind_default = Enum.KeyCode.LeftAlt,
        keybind_callback = function() end,
        keybind_changedcallback = function() end,
        default = false,
        resetonspawn = false,
        corner = 5,
        disabled = false,
        callback = function() end,
    })
    section:addCheckbox({
        Section = 1,
        default = false,
        corner = 5,
        title = "CheckBox",
        disabled = false,
        Group = "group_name", -- nil == no group
        callback = function() end,
    })
    section:addKeybind({
        Section = 1,
        title = "KeyBind",
        default = Enum.KeyCode.LeftAlt,
        corner = 5,
        disabled = false,
        callback = function() end,
        changedcallback = function() end,
    })
    section:addDropdown({
        Section = 1,
        title = "Dropdown",
        corner = 5,
        List = { 1, 2, 3, 4, 5 },
	keybind = false,
        multi = false,
        callback = function() end
    })
	section:add3DPlayer({
		Player = game.Players.LocalPlayer,
		UpdateAnim = true
	})
end
```
> #### Update Modules
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()

-- It is not necessary to place all the configurations of the modules, only the necessary ones

local section = library:new():addPage():addSection()

local button = section:addButton()
local clipboard = section:addClipboardLabel()
local duallabel = section:addDualLabel()
local label = section:addLabel()
local slider = section:addSlider()
local toggle = section:addToggle()
local checkbox = section:addCheckbox()
local keybind = section:addKeybind()
local dropdown = section:addDropdown()
local 3dPlayer = section:add3DPlayer()

button.Update({
    title = "new title",
    disabled = false
})
clipboard.Update({
    text = "new text"
})
duallabel.Update({
    title = "new title",
    description = "new description"
})
label.Update({
    text = "new text"
})
slider.Update({
    title = "new title",
    disabled = false,
    min = 0,
    max = 10,
    value = 5
})
toggle.Update({
    title = "new title",
    disabled = false,
    keybind = false,
    value = false
})
checkbox.Update({
    title = "new title",
    group = "new group", -- "" == remove group
    value = false
})
keybind.Update({
    title = "new title",
    disabled = false,
    value = Enum.KeyCode.LeftAlt
})
dropdown.Update({
    title = "new title",
    multi = false,
    keybind = false,
    default = "3",
    list = { 1, 2, 3, 4 },
    callback = function() end,
})
3dPlayer.Update({
    Player = game.Players.LocalPlayer,
    UpdateAnim = false,
})
```
