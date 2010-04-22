



local VERSION = ("$Revision$"):match("%d+")


do
	local frame
	local sf

	local clientVersion, clientBuild = GetBuildInfo()

	local insetBackdrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 10, right = 10, top = 10, bottom = 10 }
			}


	local skillFrame

	local colorWhite = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 }
	local colorBlack = { ["r"] = 0.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 0.0 }
	local colorDark = { ["r"] = 1.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.0 }

	local highlightOff = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 }
	local highlightSelected = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 0.5 }
	local highlightSelectedMouseOver = { ["r"] = 1, ["g"] = 1, ["b"] = 0.5, ["a"] = 0.5 }


	local cbag = "|cffffff80"
	local cvendor = "|cff80ff80"
	local cbank =  "|cffffa050"
	local calt = "|cffff80ff"


	local selectedRows = {}

	local detailsOpen


	local textFilter


	local playerSelectMenu


	local itemQualityColor = {}

	for i=0,7 do
		local r,g,b = GetItemQualityColor(i)
		itemQualityColor[i] = { r=r, g=g, b=b }
--		itemQualityColor[i].r, itemQualityColor[i].g, itemQualityColor[i].b = GetItemQualityColor(i)
	end


	local tradeIDList = {
		2259,           -- alchemy
		2018,           -- blacksmithing
		7411,           -- enchanting
		4036,           -- engineering
		45357,			-- inscription
		25229,          -- jewelcrafting
		2108,           -- leatherworking
	--	2575,			-- mining (or smelting?)
		2656,           -- smelting (from mining)
		3908,           -- tailoring
		2550,           -- cooking
		3273,           -- first aid

		53428,			-- runeforging
	}




	local filterMenuFrame = CreateFrame("Frame", "GnomeWorksFilterMenuFrame", getglobal("UIParent"), "UIDropDownMenuTemplate")

	local filterParameters = {
		haveMaterials = {
			enabled = false,
			func = function(entry)
				if entry and entry.craftAlt and entry.craftAlt > 0 then
					return false
				else
					return true
				end
			end,
		},
	}

--	local selectedPlayers = {["STRANGERS"] = true, ["OFFLINE"] = true}

	local function filerSet(button, setting)
	print("filter set")
		filterParameters[setting].enabled = not filterParameters[setting].enabled
		sf:Refresh()
	end


	local craftFilterMenu = {
		{ text = "Have Materials", func = filterSet, arg1 = "haveMaterials", checked = function() return filterParameters.haveMaterials.enabled end},
--		{ text = "Show Offline", func = PlayerFilterSet, arg1 = "OFFLINE", checked = function() return selectedPlayers["OFFLINE"] end },
	}


	local columnHeaders = {
		{
			["name"] = "Level",
			["align"] = "CENTER",
			["width"] = 30,
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["font"] = "GameFontHighlightSmall",
			["draw"] =	function (rowFrame,cellFrame,entry)
							if entry.subGroup then
								cellFrame.text:SetText("")
								return
							end


							if not entry.itemColor then
								local itemLink = GetTradeSkillItemLink(entry.skillIndex)

								local _,itemRarity,reqLevel
								local itemColor

								if itemLink then
									_,_,itemRarity,_,reqLevel = GetItemInfo(itemLink)

									itemColor = itemQualityColor[itemRarity]
								else
									itemColor = itemQualityColor[0]
								end

								if reqLevel and reqLevel > 0 then
									entry.itemLevel = reqLevel
								end

								entry.itemColor = itemColor
							end

							local cr,cg,cb = 1,1,1

							if entry.subGroup then
								cr,cg,cb = 1,.82,0
							else
								if entry.itemColor then
									cr,cg,cb = entry.itemColor.r, entry.itemColor.g, entry.itemColor.b
								end
							end

							cellFrame.text:SetFormattedText("%s",entry.itemLevel or "")
							cellFrame.text:SetTextColor(cr,cg,cb)

--								local _,skillType,craftable = GetTradeSkillInfo(i)

						end,


--[[									if (rowData.value or 0 ) > 0 then
										cellFrame.text:SetFormattedText("%d",entry.value)

										local cr,cg,cb = 1,1,1

										if entry.subGroup then
											cr,cg,cb = 1,.82,0
										else
											if entry.color then
												cr,cg,cb = entry.color.r, entry.color.g, entry.color.b
											end
										end

										cellFrame.text:SetTextColor(cr,cg,cb)
									else
										cellFrame.text:SetText("");
									end
]]
		}, -- [1]
		{
			["font"] = "GameFontHighlight",
			["name"] = "Recipe",
			["width"] = 250,
			["bgcolor"] = colorDark,
			["tooltipText"] = "click to sort\rright-click to filter",
			["OnClick"] = function(cellFrame, button)
								if cellFrame:GetParent().rowIndex>0 then
									local entry = cellFrame.data

									if entry.subGroup then
										entry.subGroup.expanded = not entry.subGroup.expanded
										sf:Refresh()
									else
										GnomeWorks:SelectSkill(entry.skillIndex)
										sf:Draw()
									end
								end
							end,
			["draw"] =	function (rowFrame,cellFrame,entry)
							cellFrame.data = entry
--							local entry = data[realrow]
--							local colData = entry.cols[column]

							local texExpanded = "|TTexturePath:Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga:0|t"
							local texClosed = "|TTexturePath:Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga:0|t"


							cellFrame.text:SetPoint("LEFT", cellFrame, "LEFT", entry.depth*16+4, 0)
							cellFrame.text:SetPoint("RIGHT", cellFrame, "RIGHT", -4, 0)

							if entry.subGroup then
								local tex

								if entry.subGroup.expanded then
									tex = "+ " -- texExpanded
								else
									tex = "-  " -- texClosed
								end

								cellFrame.text:SetFormattedText("%s%s (%d)",tex,entry.name,#entry.subGroup.entries)

							else
								cellFrame.text:SetText(entry.name)
							end


							local cr,cg,cb = 1,0,0

							if entry.subGroup then
								cr,cg,cb = 1,.82,0
							else
								if not entry.skillColor then
									entry.skillColor = GnomeWorks:GetSkillColor(entry.skillIndex)
								end

								cr,cg,cb = entry.skillColor.r, entry.skillColor.g, entry.skillColor.b
							end

							cellFrame.text:SetTextColor(cr,cg,cb)
						end,
		}, -- [2]
		{
			["font"] = "GameFontHighlightSmall",
			["name"] = "Craftable",
			["width"] = 60,
			["align"] = "CENTER",
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["dataField"]= "craftBag",
			["OnClick"] = 	function(cellFrame, button)
								if button == "RightButton" then
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(craftFilterMenu, filterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end
							end,
			["draw"] =	function (rowFrame,cellFrame,entry)
							if entry.subGroup then
								cellFrame.text:SetText("")
								return
							end

							if GnomeWorks.data.recipeDB[entry.recipeID].unlimited then
								cellFrame.text:SetText("\226\136\158")
							else
								local bag,vendor,bank,alt = entry.craftBag or -1, entry.craftVendor or -1, entry.craftBank or -1 , entry.craftAlt or -1

								if alt > 0 then
									local display = ""

									if bag > 0 then
										display = string.format("%s%d|r",cbag,bag)
									elseif vendor > 0 then
										display = string.format("%s%d|r",cvendor,vendor)
									elseif bank > 0 then
										display = string.format("%s%d|r",cbank,bank)
									elseif alt > 0 then
										display = string.format("%s%d|r",calt,alt)
									end

									if alt > bank and bank > 0 then
										display = string.format("%s/%s%s", display, calt, alt)
									elseif bank > vendor and vendor > 0 then
										display = string.format("%s/%s%s", display, cbank, bank)
									elseif vendor > bag and bag > 0 then
										display = string.format("%s/%s%s", display, cvendor, vendor)
									end


									cellFrame.text:SetText(display)
								else
									cellFrame.text:SetText("")
								end

--								local _,skillType,craftable = GetTradeSkillInfo(i)
							end
						end,

			["OnEnter"] =	function (cellFrame)
								local entry = cellFrame:GetParent().data

								if entry and entry.craftAlt and entry.craftAlt > 0 then
									GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
									GameTooltip:ClearLines()
									GameTooltip:AddLine("Recipe Craftability",1,1,1,true)
									GameTooltip:AddLine(GnomeWorks.player.."'s inventory")

									if entry.craftBag then
										GameTooltip:AddDoubleLine("|cffffff80bags",entry.craftBag)
									end

									if entry.craftVendor then
										GameTooltip:AddDoubleLine("|cff80ff80vendor",entry.craftVendor)
									end

									if entry.craftBank then
										GameTooltip:AddDoubleLine("|cffffa050bank",entry.craftBank)
									end

									if entry.craftAlt then
										GameTooltip:AddDoubleLine("|cffff80ffalts",entry.craftAlt)
									end

									GameTooltip:Show()
								end
							end,
			["OnLeave"] = 	function()
								GameTooltip:Hide()
							end,
		}, -- [3]
	}

	local oldTable = {
		{
			["font"] = "GameFontHighlightSmall",
			["name"] = "Value",
			["width"] = 60,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 },
			["bgcolor"] = colorDark,
			["tooltipText"] = "click to sort\rright-click to filter",
			["dataField"]= "skillIndex",
--[[
			["onclick"] =	function(button, link)
								local tradeString = string.match(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

								if IsShiftKeyDown() then
									if (ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus ~= nil) then
										ChatEdit_InsertLink(link)
									else
										DEFAULT_CHAT_FRAME:AddMessage(link)
									end
								elseif IsControlKeyDown() then
									local tradeID, bitmap = string.match(tradeString, "trade:(%d+):%d+:%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)")

									tradeID = tonumber(tradeID)

									GYP.TradeLink:DumpSpells(Config.spellList[tradeID], bitmap)
								else
									getglobal("GYPFrame"):SetFrameStrata("LOW")

									OpenTradeLink(tradeString)
								end
							end,
			["rightclick"] = 	function()
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(tradeFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end
]]
		}, -- [4]
		{
			["font"] = "GameFontHighlightSmall",
			["name"] = "Cost",
			["width"] = 60,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 },
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["dataField"]= "skillIndex",
		}, -- [5]
	}





	local function ResizeMainWindow()
		if sf then
			if not GetTradeSkillSelectionIndex() then
				GnomeWorks.detailFrame:Hide()
				GnomeWorks.reagentFrame:Hide()
			end

			if GnomeWorks.detailFrame:IsShown() then
				skillFrame:SetPoint("BOTTOMLEFT",GnomeWorks.detailFrame,"TOPLEFT",0,20)
			else
				skillFrame:SetPoint("BOTTOMLEFT",20,35)
			end
		end
	end



	local function BuildScrollingTable()

		local function ResizeSkillFrame(scrollFrame,width,height)
			if scrollFrame then
				scrollFrame.columnWidth[2] = scrollFrame.columnWidth[2] + width - scrollFrame.headerWidth
				scrollFrame.headerWidth = width

				local x = 0

				for i=1,#scrollFrame.columnFrames do
					scrollFrame.columnFrames[i]:SetPoint("LEFT",scrollFrame, "LEFT", x,0)
					scrollFrame.columnFrames[i]:SetPoint("RIGHT",scrollFrame, "LEFT", x+scrollFrame.columnWidth[i],0)

					x = x + scrollFrame.columnWidth[i]
				end
			end
		end

		local ScrollPaneBackdrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 9.5, right = 9.5, top = 9.5, bottom = 11.5 }
			}

		skillFrame = CreateFrame("Frame",nil,frame)
		skillFrame:SetPoint("BOTTOMLEFT",20,20)
		skillFrame:SetPoint("TOP", frame, 0, -85)
		skillFrame:SetPoint("RIGHT", frame, -20,0)

		GnomeWorks.skillFrame = skillFrame

		sf = GnomeWorks:CreateScrollingTable(skillFrame, ScrollPaneBackdrop, columnHeaders, ResizeSkillFrame)

		sf.IsEntryFiltered = function(self, entry)
			for k,filter in pairs(filterParameters) do
				if filter.enabled then
					if filter.func(entry) then
						return true
					end
				end
			end

			if textFilter and textFilter ~= "" then
				for w in string.gmatch(textFilter, "%a+") do
					if string.match(string.lower(entry.name), w, 1, true)==nil then
						return true
					end
				end
			end

			return false
		end



		sf.UpdateRowData = function(scrollFrame,entry)
			if not entry.subGroup then
				local bag,vendor,bank,alts = GnomeWorks:InventoryRecipeIterations(entry.recipeID)

				entry.craftBag = bag
				entry.craftVendor = vendor
				entry.craftBank = bank
				entry.craftAlt = alts
			end
		end



--[[
				if currentTradeskill then
					if (row.cols[4].tradeID ~= currentTradeskill) then
						return false
					end
				else
					if selectedTradeskill and (row.cols[4].tradeID ~= selectedTradeskill) then
						return false
					end
				end


				if selectedAge and ((time() - row.cols[5].value)/(60*60*24) > selectedAge) then
					return false
				end

				if not selectedPlayers["OFFLINE"] then
					if not playerLocation[row.cols[1].value] or string.find(playerLocation[row.cols[1].value],OFFLINE) then
						return false
					end
				end

				if not selectedPlayers["STRANGERS"] then
					if not guildList[row.cols[1].value] and not friendList[row.cols[1].value] then
						return false
					end
				end
	--DEFAULT_CHAT_FRAME:AddMessage(type(selectedLevel).." "..tostring(selectedLevel))

				if selectedLevel and tonumber(row.cols[3].value) < selectedLevel then
					return false
				end

				return true
			end)
		end
]]

	end

--[[
	function ItemLevelFunction(data, cols, realrow, column, sttable)
		local itemLink = GetTradeSkillItemLink(realrow)

		if itemLink then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel = GetItemInfo(itemLink)

			return itemMinLevel or 1
		end

		return 1
	end


	function ItemColorFunction(data, cols, realrow, column, sttable)
		return colorWhite
	end


	function SkillNameFunction(data, cols, realrow, column, sttable)
		local skillName, skillType = GetTradeSkillInfo(realrow)

		return skillName or "unknown: "..realrow
	end
]]

	function GnomeWorks:TRADE_SKILL_SHOW(...)
		frame:Show()
		frame.title:Show()
		sf:Show()

		self:ScanTrade()


		local index = GetTradeSkillSelectionIndex()

		if index then
			self:ShowDetails(index)
			self:ShowReagents(index)

			self.selectedSkill = index
		end

		self:ShowQueueList()
	end


	function GnomeWorks:ShowSkillList()
		local player = self.currentPlayer
		local tradeID = self.currentTradeID

		if player and tradeID then
			local key = player..":"..tradeID

			local group = self:RecipeGroupFind(player, tradeID, "Blizzard", nil)

			GnomeWorksDB.text = group
			sf.data = group
			sf:Refresh()
			sf:Show()
		end
	end


	function GnomeWorks:ShowStatus()
		local rank, maxRank = self:GetTradeSkillRank()
		self.levelStatusBar:SetMinMaxValues(0,maxRank)
		self.levelStatusBar:SetValue(rank)
		self.levelStatusBar:Show()


		self.playerNameFrame:SetFormattedText("%s - %s", self.player, (GetSpellInfo(self.tradeID)))
	end


	function GnomeWorks:UpdateMainWindow()
		self:ShowSkillList()
		self:ShowStatus()
		self:UpdateTradeButtons(self.player,self.tradeID)
	end


	function GnomeWorks:TRADE_SKILL_UPDATE()
		if frame:IsVisible() then
			ResizeMainWindow()
		end
	end

	function GnomeWorks:TRADE_SKILL_CLOSE()
		frame.title:Hide()
		frame:Hide()
	end

	function GnomeWorks:SetFilterText(text)
		textFilter = string.lower(text)
		sf:Refresh()
	end



	local function SelectTradeLink(frame)

		local function SelectTradeSkill(menuFrame, player, tradeLink)
			ToggleDropDownMenu(1, nil, playerSelectMenu, menuFrame, menuFrame:GetWidth(), 0)
			local tradeString = string.match(tradeLink, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

			if (UnitName("player")) == player then
				local tradeName = GetSpellInfo(string.match(tradeString, "trade:(%d+)"))

				if ((GetTradeSkillLine() == "Mining" and "Smelting") or GetTradeSkillLine()) ~= tradeName or IsTradeSkillLinked() then
					CastSpellByName(tradeName)
				end
			else
				SetItemRef(tradeString,tradeLink,"LeftButton")
			end
		end


		local function InitMenu(menuFrame, level)
			if (level == 1) then  -- character names
				local title = {}
				local playerMenu = {}

				title.text = "Select Player and Tradeskill"
--				title.isTitle = true
--				title.notClickable = true
				title.fontObject = "GameFontNormal"


				UIDropDownMenu_AddButton(title)

				local index = 1

				for player,data in pairs(GnomeWorks.data.playerData) do
					if data.build == clientBuild then
						playerMenu.text = player
						playerMenu.hasArrow = true
						playerMenu.value = player
						playerMenu.disabled = false

						UIDropDownMenu_AddButton(playerMenu)
						index = index + 1
					end
				end
			end

			if (level == 2) then  -- skills per player
				local links = GnomeWorks:GetTradeLinkList(UIDROPDOWNMENU_MENU_VALUE)
				skillButton = {}

				for index, tradeID in ipairs(tradeIDList) do
					if links[tradeID] then
						local rank, maxRank = string.match(links[tradeID], "trade:%d+:(%d+):(%d+)")
						local spellName, spellLink, spellIcon = GetSpellInfo(tradeID)

						skillButton.text = string.format("%s |cff00ff00[%s/%s]|r", spellName, rank, maxRank)
						skillButton.value = tradeID

						skillButton.icon = spellIcon

						skillButton.arg1 = UIDROPDOWNMENU_MENU_VALUE
						skillButton.arg2 = links[tradeID]
						skillButton.func = SelectTradeSkill

						skillButton.checked = (tradeID == GnomeWorks.tradeID and UIDROPDOWNMENU_MENU_VALUE == GnomeWorks.player)


						UIDropDownMenu_AddButton(skillButton, level)
					end
				end
			end
		end

		if not playerSelectMenu then
			playerSelectMenu = CreateFrame("Frame", "GWPlayerSelectMenu", getglobal("UIParent"), "UIDropDownMenuTemplate")
		end

		UIDropDownMenu_Initialize(playerSelectMenu, InitMenu, "MENU")
		ToggleDropDownMenu(1, nil, playerSelectMenu, frame, 0, 0)
	end


	function GnomeWorks:CreateControlFrame(frame)
		local function AddToQueue(buttonFrame)
--			DoTradeSkill(GetTradeSkillSelectionIndex())
			local recipeLink = GetTradeSkillRecipeLink(GnomeWorks.selectedSkill)

			local recipeID = tonumber(string.match(recipeLink, "enchant:(%d+)"))

			GnomeWorks:AddToQueue(GnomeWorks.player, recipeID, 1)
		end


		local buttons = {
			{ label = "Add To Queue",  operation = AddToQueue, count = 1 },
			{ label = "Queue All", operation = AddToQueue },
		}
		local position = 0

		controlFrame = CreateFrame("Frame", nil, frame)

		controlFrame:SetHeight(20)
		controlFrame:SetWidth(200)

		controlFrame:SetPoint("TOP", self.skillFrame, "BOTTOM", 0, 1)

		for i, config in pairs(buttons) do
			local newButton = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")

			newButton:SetPoint("LEFT", position,0)
			newButton:SetWidth(100)
			newButton:SetHeight(18)
			newButton:SetNormalFontObject("GameFontNormalSmall")
			newButton:SetHighlightFontObject("GameFontHighlightSmall")

			newButton:SetText(config.label)

			newButton.count = config.count
			newButton:SetScript("OnClick", config.operation)

			position = position + 100
		end

		controlFrame:SetWidth(position)

		return controlFrame
	end



	function GnomeWorks:CreateMainWindow()
		frame = self.Window:CreateResizableWindow("GnomeWorksFrame", "GnomeWorks ("..VERSION..")", 600, 400, ResizeMainWindow, GnomeWorksDB.config)

		frame:SetMinResize(500,400)

		self.detailFrame = self:CreateDetailFrame(frame)
		self.reagentFrame = self:CreateReagentFrame(frame)

		BuildScrollingTable()

		self.controlFrame = self:CreateControlFrame(frame)

		local tradeButtonFrame = CreateFrame("Frame", nil, frame)
		tradeButtonFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20,-48)
		tradeButtonFrame:SetWidth(240)
		tradeButtonFrame:SetHeight(18)

		self:CreateTradeButtons(tradeIDList, tradeButtonFrame)

--		self.tradeButtonFrame:ClearAllPoints()


--		self.detailFrame:SetScript("OnShow", function() ResizeMainWindow(frame) end)
--		self.detailFrame:SetScript("OnHide", function() ResizeMainWindow(frame) end)

		local searchBox = CreateFrame("EditBox","GnomeWorksSearch",frame)


		local searchBackdrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 12, right = 10, top = 10, bottom = 10 }
			}

		self.Window:SetBetterBackdrop(searchBox, searchBackdrop)

		searchBox:SetFrameLevel(searchBox:GetFrameLevel()+5)

		searchBox:SetAutoFocus(false)

		searchBox:SetPoint("TOPLEFT", frame, 22,-50)
		searchBox:SetHeight(16)
		searchBox:SetPoint("RIGHT", frame, -300,0)

		searchBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
		searchBox:SetScript("OnEscapePressed", EditBox_ClearFocus)
		searchBox:SetScript("OnTextChanged", function(f) GnomeWorks:SetFilterText(f:GetText()) end)
		searchBox:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
		searchBox:SetScript("OnEditFocusGained", EditBox_HighlightText)

		searchBox:EnableMouse(true)
		searchBox:SetFontObject("GameFontHighlightSmall")

		local clearSearch = CreateFrame("Button", nil, searchBox)
		clearSearch:SetWidth(32)
		clearSearch:SetHeight(32)
		clearSearch:SetPoint("LEFT",searchBox,"RIGHT",-8,-2)
		clearSearch:SetNormalTexture("Interface\\Buttons\\CancelButton-Up")
		clearSearch:SetPushedTexture("Interface\\Buttons\\CancelButton-Down")
		clearSearch:SetHighlightTexture("Interface\\Buttons\\CancelButton-Highlight")
--		clearSearch:SetScale(1)

		clearSearch:SetScript("OnClick", function() searchBox:SetText("") EditBox_ClearFocus(searchBox) end)




		self.searchBoxFrame = searchBox



		local levelBackDrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 12, right = 12, top = 12, bottom = 12 }
			}

		local level = CreateFrame("StatusBar", nil, frame)

		level:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-20,-34)
		level:SetWidth(240)
		level:SetHeight(8)

--		level:SetMinMaxValues(1,10)
--		level:SetValue(5)
		level:SetOrientation("HORIZONTAL")
		level:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
		level:SetStatusBarColor(.05,.05,1,.75)

		self.Window:SetBetterBackdrop(level, levelBackDrop)
		self.Window:SetBetterBackdropColor(level, 1,1,1,.5)

		local levelText = level:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		levelText:SetPoint("CENTER",0,1)
		levelText:SetHeight(13)
		levelText:SetWidth(50)
		levelText:SetJustifyH("CENTER")

		level.text = levelText

		level:SetScript("OnValueChanged", function(frame, value)
			local minValue, maxValue = frame:GetMinMaxValues()

			levelText:SetFormattedText("%d/%d",value,maxValue)
		end)


		self.levelStatusBar = level


		local playerName = CreateFrame("Button", nil, frame)

		playerName:SetWidth(240)
		playerName:SetHeight(16)
		playerName:SetText("UNKNOWN")
		playerName:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-20,-15)

		playerName:SetNormalFontObject("GameFontNormal")
		playerName:SetHighlightFontObject("GameFontHighlight")

--		playerName:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Opaque")

		playerName:EnableMouse(true)

		playerName:RegisterForClicks("AnyUp")

		playerName:SetScript("OnClick", SelectTradeLink)

		playerName:SetFrameLevel(playerName:GetFrameLevel()+1)

		self.playerNameFrame = playerName


		self.SelectTradeLink = SelectTradeLink


		textFilter = nil

		return frame
	end

end
