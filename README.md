# How To Use
- ### Lite UI <sub>*It's still in development*</sub>
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxnwDev/UI/main/LiteUI.lua"))()
local window = library:new()

local page = window:addPage({
	icon = "page_icon",
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
		multi = false,
		callback = function() end
	})
end
```
> #### Update Modules
```lua

local button = section:addButton()
local clipboard = section:addClipboardLabel()
local duallabel = section:addDualLabel()
local label = section:addLabel()
local slider = section:addSlider()
local toggle = section:addToggle()
local checkbox = section:addCheckbox()
local keybind = section:addKeybind()
local dropdown = section:addDropdown()

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
	default = "3",
	list = { 1, 2, 3, 4 },
	callback = function() end,
})
```
