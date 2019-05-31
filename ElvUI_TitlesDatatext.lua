-------------------------------------------------------------------------------
-- ElvUI Titles Datatext By Lockslap
-------------------------------------------------------------------------------
local E, _, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local L = LibStub("AceLocale-3.0"):GetLocale("ElvUI_TitlesDatatext", false)
local EP = LibStub("LibElvUIPlugin-1.0")

local format	= string.format
local sub		= string.sub
local len		= string.len
local find		= string.find
local join		= string.join
local sort		= table.sort
local wipe		= table.wipe
local tinsert	= table.insert
local random	= math.random

local displayString = ""
local noTitles		= ""
local titles		= {}
local lastPanel

local Frame		= CreateFrame("Frame")
local menu 		= {}
local startChar	= {
	[L["AI"]]	= {},
	[L["JR"]]	= {},
	[L["SZ"]]	= {},
}

E.PopupDialogs.TITLESDT_RL = {
	text = L["In order for this change to take effect you must reload your UI."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	whileDead = 1,
	hideOnEscape = false,
}

local function pairsByKeys(startChar, f)
	local a = {}
	for n in pairs(startChar) do tinsert(a, n) end
	sort(a, f)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], startChar[a[i]]
		end
	end
	return iter
end

local function GetTitleFormat(data)
	if data == -1 then return ("|cffffffff%s|r"):format(L["None"]) end
	local title, formatTitle, replace, name = GetTitleName(data), "", "", ""

	-- determine the title formatting for display
	if title:sub(-1) ~= " " then
		if title:find(L["Jenkins"]) == nil and title:find(L["Ironbane"]) == nil and title:sub(1, 2) ~= L["of"] and title:sub(1, 3) ~= L["the"] then
			replace = "%s, "
		else
			replace = "%s "
		end
		formatTitle = replace .. ("|cffffffff%s|r"):format(title)
	else
		formatTitle = ("|cffffffff%s|r"):format(title) .. "%s"
	end
	
	if not E.db.titlesdt.useName then
		name = ("|cffa6c939<%s>|r"):format(L["name"])
	else
		local _, classFile = UnitClass("player")
		local player, nameRGB = UnitName("player"), RAID_CLASS_COLORS[classFile]
		local nameHex = ("%02x%02x%02x"):format(nameRGB.r * 255, nameRGB.g * 255, nameRGB.b * 255)
		name = ("|cff%s%s|r"):format(nameHex, player)
	end
	
	return formatTitle:format(name)
end

local function UpdateTitles()
	titles = {}
	for i = 1, GetNumTitles() do
		if IsTitleKnown(i) == true then
			local title = GetTitleName(i)
			local current = GetCurrentTitle() == i and true or false
			titles[#titles + 1] = {
				id			= i,
				name		= title:sub(1, 1) == " " and title:sub(2) or title:sub(1, title:len() - 1),
				formatName	= GetTitleFormat(i),
				current		= current,
			}
		end
	end
	sort(titles, function(a, b) return a["name"] < b["name"] end)
end

local function TitleClick(button, info)
	SetCurrentTitle(info)
	DEFAULT_CHAT_FRAME:AddMessage(info ~= -1 and (L["Title changed to \"%s\"."]):format(GetTitleFormat(info)) or L["You have elected not to use a title."], 1.0, 1.0, 0)
end

local function RandomClick(button, info)
	UpdateTitles()
	if #titles == 0 then return end
	local rand = random(1, #titles)
	SetCurrentTitle(titles[rand].id)
	DEFAULT_CHAT_FRAME:AddMessage((L["Title changed to \"%s\"."]):format(GetTitleFormat(titles[rand].id)), 1.0, 1.0, 0)
end

local function CreateMenu(self, level)
	UpdateTitles()
	menu = wipe(menu)
	
	if #titles == 0 then return end
	if #titles <= 10 then
		-- add "none" option
		if E.db.titlesdt.addNone then			
			menu.hasArrow = false
			menu.notCheckable = true
			menu.text = L["None"]
			menu.colorCode = "|cffff0000"
			menu.func = TitleClick
			menu.arg1 = -1
			UIDropDownMenu_AddButton(menu)
		end

		-- add "random" option
		if E.db.titlesdt.addRandom then		
			menu.hasArrow = false
			menu.notCheckable = true
			menu.text = L["Random"]
			menu.colorCode = "|cff00ff00"
			menu.func = RandomClick
			UIDropDownMenu_AddButton(menu)
		end
		
		for _, title in pairs(titles) do
			menu.hasArrow = false
			menu.notCheckable = true
			menu.text = title.formatName
			menu.colorCode = title.current == true and "|cff00ff00" or "|cffffffff"
			menu.func = TitleClick
			menu.arg1 = title.id
			UIDropDownMenu_AddButton(menu)
		end
	else
		level = level or 1
		
		if level == 1 then
			for key, value in pairsByKeys(startChar) do
				menu.text = key
				menu.notCheckable = true
				menu.hasArrow = true
				menu.value = {
					["Level1_Key"] = key
				}
				UIDropDownMenu_AddButton(menu, level)
			end
			
			-- add "none" option
			if E.db.titlesdt.addNone then			
				menu.hasArrow = false
				menu.notCheckable = true
				menu.text = L["None"]
				menu.colorCode = "|cffff0000"
				menu.func = TitleClick
				menu.arg1 = -1
				UIDropDownMenu_AddButton(menu, level)
			end

			-- add "random" option
			if E.db.titlesdt.addRandom then		
				menu.hasArrow = false
				menu.notCheckable = true
				menu.text = L["Random"]
				menu.colorCode = "|cff00ff00"
				menu.func = RandomClick
				UIDropDownMenu_AddButton(menu, level)
			end
		elseif level == 2 then
			-- add the sorted titles
			local Level1_Key = UIDROPDOWNMENU_MENU_VALUE["Level1_Key"]
			
			for _, title in pairs(titles) do
				local firstChar = title.name:sub(1, 1):upper()
				menu = wipe(menu)
				menu.hasArrow = false
				menu.notCheckable = true
				menu.text = title.formatName
				menu.colorCode = title.current == true and "|cff00ff00" or "|cffffffff"
				menu.func = TitleClick
				menu.arg1 = title.id
				
				if firstChar >= L["A"] and firstChar <= L["I"] and Level1_Key == L["AI"] then
					UIDropDownMenu_AddButton(menu, level)
				end
				
				if firstChar >= L["J"] and firstChar <= L["R"] and Level1_Key == L["JR"] then
					UIDropDownMenu_AddButton(menu, level)
				end
				
				if firstChar >= L["S"] and firstChar <= L["Z"] and Level1_Key == L["SZ"] then
					UIDropDownMenu_AddButton(menu, level)
				end
			end
			
		end
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)
	DT.tooltip:AddLine(GetTitleFormat(GetCurrentTitle()))
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddLine(("|cff00ff00You have|r |cff00ff96%d|r |cff00ff00titles.|r"):format(#titles))
	DT.tooltip:AddLine(L["<Click> to select a title."])
	DT.tooltip:Show()
end

function Frame:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("KNOWN_TITLES_UPDATE")
	self.KNOWN_TITLES_UPDATE = UpdateTitles
	
	self.initialize = CreateMenu
	self.displayMode = "MENU"
	
	UpdateTitles()
end
Frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local interval = 15
local function Update(self, elapsed)
	if not self.lastUpdate then self.lastUpdate = 0 end
	self.lastUpdate = self.lastUpdate + elapsed
	if self.lastUpdate > interval then
		UpdateTitles()
		self.lastUpdate = 0
	end
	if #titles == 0 then
		self.text:SetFormattedText(noTitles, L["No Titles"])
	else
		self.text:SetFormattedText(displayString, L["Titles"], #titles)
	end	
end

local function Click(self, button)
	DT.tooltip:Hide()
	ToggleDropDownMenu(1, nil, Frame, self, 0, 0)
end

local function ValueColorUpdate(hex, r, g, b)
	displayString = join("", "|cffffffff%s:|r", " ", hex, "%d|r")
	noTitles = join("", hex, "%s|r")
	if lastPanel ~= nil then OnEvent(lastPanel) end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true

P["titlesdt"] = {
	["useName"] = true,
	["addRandom"] = true,
	["addNone"] = true,
}

local function InjectOptions()
	if not E.Options.args.lockslap then
		E.Options.args.lockslap = {
			type = "group",
			order = -2,
			name = L["Plugins by |cff9382c9Lockslap|r"],
			args = {
				thanks = {
					type = "description",
					order = 1,
					name = L["Thanks for using and supporting my work!  -- |cff9382c9Lockslap|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."],
				},
			},
		}
	elseif not E.Options.args.lockslap.args.thanks then
		E.Options.args.lockslap.args.thanks = {
			type = "description",
			order = 1,
			name = L["Thanks for using and supporting my work!  -- |cff9382c9Lockslap|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."],
		}
	end
	
	E.Options.args.lockslap.args.titlesdt = {
		type = "group",
		name = L["Titles Datatext"],
		get = function(info) return E.db.titlesdt[info[#info]] end,
		set = function(info, value) E.db.titlesdt[info[#info]] = value; DT:LoadDataTexts() end,
		args = {
			useName = {
				type = "toggle",
				order = 4,
				name = L["Use Character Name"],
				desc = L["Use your character's class color and name in the tooltip."],
			},
			addRandom = {
				type = "toggle",
				order = 5,
				name = L["Random Option"],
				desc = L["Add random option to the datatext menu.\n\n|cffff0000Changing this setting requires reloading your UI.|r"],
				get = function(info) return E.db.titlesdt.addRandom end,
				set = function(info, value) E.db.titlesdt.addRandom = value; E:StaticPopup_Show("TITLESDT_RL") end,
			},
			addNone = {
				type = "toggle",
				order = 6,
				name = L["None Option"],
				desc = L["Add none option to the datatext menu. This will set your title to none.\n\n|cffff0000Changing this setting requires reloading your UI.|r"],
				get = function(info) return E.db.titlesdt.addNone end,
				set = function(info, value) E.db.titlesdt.addNone = value; E:StaticPopup_Show("TITLESDT_RL") end,
			},
		},
	}
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("Titles", nil, nil, Update, Click, OnEnter)