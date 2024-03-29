-------------------------------------------------------------------------------
-- ElvUI Titles Datatext By Crackpotx
-------------------------------------------------------------------------------
local E, _, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local L = E.Libs.ACL:GetLocale("ElvUI_TitlesDatatext", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local unpack = _G["unpack"]
local CreateFrame = _G["CreateFrame"]
local GetTitleName = _G["GetTitleName"]
local UnitClass = _G["UnitClass"]
local UnitName = _G["UnitName"]
local GetNumTitles = _G["GetNumTitles"]
local IsTitleKnown = _G["IsTitleKnown"]
local GetCurrentTitle = _G["GetCurrentTitle"]
local SetCurrentTitle = _G["SetCurrentTitle"]
local UIDropDownMenu_AddButton = _G["UIDropDownMenu_AddButton"]
local ToggleDropDownMenu = _G["ToggleDropDownMenu"]
local StaticPopup_Show = _G["StaticPopup_Show"]

local format = string.format
local sub = string.sub
local len = string.len
local find = string.find
local join = string.join
local sort = table.sort
local wipe = table.wipe
local tinsert = table.insert
local random = math.random

local displayString = ""
local noTitles = ""
local titles = {}

local Frame = CreateFrame("Frame")
local menu = {}
local startChar = {
	[L["AI"]] = {},
	[L["JR"]] = {},
	[L["SZ"]] = {},
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

local function OnEvent(self, event, ...)
	UpdateTitles()

	if #titles == 0 then
		self.text:SetFormattedText(noTitles, L["No Titles"])
	else
		self.text:SetFormattedText(displayString, L["Titles"], #titles)
	end

	CreateMenu()
end

local interval = 15
local function OnUpdate(self, elapsed)
	if not self.lastUpdate then self.lastUpdate = 0 end
	self.lastUpdate = self.lastUpdate + elapsed
	if self.lastUpdate > interval then
		OnEvent(self)
		self.lastUpdate = 0
	end
	if #titles == 0 then
		self.text:SetFormattedText(noTitles, L["No Titles"])
	else
		self.text:SetFormattedText(displayString, L["Titles"], #titles)
	end	
end

local function OnClick(self, button)
	DT.tooltip:Hide()
	ToggleDropDownMenu(1, nil, Frame, self, 0, 0)
end

local function ValueColorUpdate(self, hex, r, g, b)
	displayString = join("", "|cffffffff%s:|r", " ", hex, "%d|r")
	noTitles = join("", hex, "%s|r")
	OnEvent(self)
end

P["titlesdt"] = {
	["useName"] = true,
	["addRandom"] = true,
	["addNone"] = true,
}

Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:SetScript("OnEvent", function(self, event, ...)
	self.initialize = CreateMenu
	self.displayMode = "MENU"
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

local function InjectOptions()
	if not E.Options.args.Crackpotx then
		E.Options.args.Crackpotx = ACH:Group(L["Plugins by |cff0070deCrackpotx|r"])
	end
	if not E.Options.args.Crackpotx.args.thanks then
		E.Options.args.Crackpotx.args.thanks = ACH:Description(L["Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."], 1)
	end

	E.Options.args.Crackpotx.args.titlesdt = ACH:Group(L["Titles Datatext"], nil, nil, nil, function(info) return E.db.titlesdt[info[#info]] end, function(info, value) E.db.titlesdt[info[#info]] = value; DT:ForceUpdate_DataText("Titles") end)
	E.Options.args.Crackpotx.args.titlesdt.args.useName = ACH:Toggle(L["Use Character Name"], L["Use your character's class color and name in the tooltip."], 1)
	E.Options.args.Crackpotx.args.titlesdt.args.addRandom = ACH:Toggle(L["Random Option"], L["Add random option to the datatext menu.\n\n|cffff0000Changing this setting requires reloading your UI.|r"], 2, nil, nil, nil, function(info) return E.db.titlesdt.addRandom end, function(info, value) E.db.titlesdt.addRandom = value; E:StaticPopup_Show("TITLESDT_RL") end)
	E.Options.args.Crackpotx.args.titlesdt.args.addNone = ACH:Toggle(L["None Option"], L["Add none option to the datatext menu. This will set your title to none.\n\n|cffff0000Changing this setting requires reloading your UI.|r"], 3, nil, nil, nil, function(info) return E.db.titlesdt.addNone end, function(info, value) E.db.titlesdt.addNone = value; E:StaticPopup_Show("TITLESDT_RL") end)
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("Titles", nil, {"PLAYER_ENTERING_WORLD", "KNOWN_TITLES_UPDATE"}, OnEvent, OnUpdate, OnClick, OnEnter, nil, L["Titles"], nil, ValueColorUpdate)