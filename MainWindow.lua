



local VERSION = ("$Revision$"):match("%d+")


local LARGE_NUMBER = 1000000


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


	local colorFilteringEnabled = { 1,1,.0, .25 }


	local inventoryColors = {
		bag = "|cffffff80",
		vendor = "|cff80ff80",
		bank =  "|cffffa050",
		alt = "|cffff80ff",
	}




	local selectedRows = {}

	local detailsOpen


	local textFilter


	local playerSelectMenu
	local pluginMenu


	local columnHeaders


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


		13262,			-- disenchant
		51005,			-- milling
		31252,			-- prospecting
	}


	local unlinkableTrades = {
		[2656] = true,           -- smelting (from mining)
		[53428] = true,			-- runeforging
		[51005] = true,			-- milling
		[13262] = true,			-- disenchant
		[31252] = true,			-- prospecting
	}




	local filterMenuFrame = CreateFrame("Frame", "GnomeWorksFilterMenuFrame", UIParent, "UIDropDownMenuTemplate")


	local activeFilterList = {}


	function GnomeWorks:CreateFilterMenu(filterParameters, menu, column)
		local function filterSet(button, setting)
			filterParameters[setting].enabled = not filterParameters[setting].enabled

			if filterParameters[setting].OnClick then
				filterParameters[setting].OnClick(filterParameters,setting)
			end


			if filterParameters[setting].enabled then
				activeFilterList[setting] = filterParameters[setting]
			else
				activeFilterList[setting] = nil
			end


			local filtersEnabled = false

			for filterName,filter in pairs(filterParameters) do
				if filter.enabled then
					filtersEnabled = true
					break;
				end
			end

			if filtersEnabled then
				column.headerBgColor = colorFilteringEnabled
			else
				column.headerBgColor = nil
			end

			sf:Refresh()
		end


		menu.parameters = filterParameters

		for filterName,filter in pairs(filterParameters) do
			local menuEntry = {
				text = filter.text,
				icon = filter.icon,
				tooltipText = filter.tooltip,
				func = filterSet,
				arg1 = filterName,
				notCheckable = notCheckable,
				menuList = filter.menuList,
				hasArrow = filter.menuList ~= nil,
			}

			if filter.checked then
				menuEntry.checked = filter.checked
			else
				menuEntry.checked = function()
					return filterParameters[filterName].enabled
				end
			end

			if filter.coords then
				menuEntry.tCoordLeft,menuEntry.tCoordRight,menuEntry.tCoordBottom,menuEntry.tCoordTop = unpack(filter.coords)
			end


			table.insert(menu, menuEntry)
		end
	end

	local function radioButton(parameters, index)
		for k,v in pairs(parameters) do
			if k ~= index then
				v.enabled = false
			end
		end

		CloseDropDownMenus()
	end



	local craftSourceMenu = {
	}

	local craftFilterMenu

	craftFilterMenu = {
		{
			text = "Filter by Inventory: "..inventoryColors.alt.."alts",
			menuList = craftSourceMenu,
			hasArrow = true,
			filterIndex = 4,
			func = function()
				local parameters = craftSourceMenu.parameters
				local index = craftFilterMenu[1].filterIndex

				craftSourceMenu[index].func(nil, craftSourceMenu[index].arg1)
				craftFilterMenu[1].checked = parameters[index].enabled
			end,
			checked = false,
		},
	}


	local function adjustCraftFilterSource(parameters, index)
		radioButton(parameters, index)

		craftFilterMenu[1].checked = parameters[index].enabled
		craftFilterMenu[1].filterIndex = index
		craftFilterMenu[1].text = "Filter by Inventory: "..parameters[index].text
	end


	local craftFilterParameters = {
		{
			text = inventoryColors.bag.."bag",
			enabled = false,
			func = function(entry)
				if entry and entry.craftBag and entry.craftBag > 0 then
					return false
				end

				return true
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustCraftFilterSource,
		},
		{
			text = inventoryColors.vendor.."vendor",
			func = function(entry)
				if entry and entry.craftVendor and entry.craftVendor > 0 then
					return false
				end

				return true
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustCraftFilterSource,
		},
		{
			text = inventoryColors.bank.."bank",
			enabled = false,
			func = function(entry)
				if entry and entry.craftBank and entry.craftBank > 0 then
					return false
				end

				return true
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustCraftFilterSource,
		},
		{
			text = inventoryColors.alt.."alts",
			enabled = false,
			func = function(entry)
				if entry and entry.craftAlt and entry.craftAlt > 0 then
					return false
				end

				return true
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustCraftFilterSource,
		},
	}




	local levelFilterMenu = {
	}

	local levelFilterParameters = {
		{
			text = "Player Meets Level Requirement",
			enabled = false,
			func = function(entry)
				if entry and UnitLevel("player") >= (entry.itemLevel or 0) then
					return false
				else
					return true
				end
			end,
		},
	}




	local recipeLevelMenu = {
	}

	local recipeFilterMenu

	recipeFilterMenu = {
--		{ text = "Collapse All", func = function() GnomeWorks:CollapseAllHeaders(sf.data.entries) sf:Refresh() end,},
--		{ text = "Expand All", func = function() GnomeWorks:ExpandAllHeaders(sf.data.entries) sf:Refresh() end,},
		{
			text = "Filter by Difficulty",
			menuList = recipeLevelMenu,
			icon = "Interface\\AddOns\\GnomeWorks\\Art\\skill_colors.tga",
			tCoordLeft=0, tCoordRight=1, tCoordBottom=.5, tCoordTop=.75,
			hasArrow = true,
			filterIndex = 3,
			func = function()
				local parameters = recipeLevelMenu.parameters
				local index = recipeFilterMenu[1].filterIndex

--				filterSet(button, setting)

				recipeLevelMenu[index].func(nil, recipeLevelMenu[index].arg1)

--				parameters[index].enabled = not parameters[index].enabled

				recipeFilterMenu[1].checked = parameters[index].enabled

				--sf:Refresh()
			end,
			checked = false,
		},
	}

	local function adjustFilterIcon(parameters, index)
		radioButton(parameters, index)

		recipeFilterMenu[1].checked = parameters[index].enabled
		recipeFilterMenu[1].tCoordBottom = index/4-.25
		recipeFilterMenu[1].tCoordTop = index/4
		recipeFilterMenu[1].filterIndex = index

	end

	local recipeLevelParameters = {
		{
			text = "",
			icon = "Interface\\AddOns\\GnomeWorks\\Art\\skill_colors.tga",
			coords = {0,1,0,.25},
			enabled = false,
			func = function(entry)
				local difficulty = GnomeWorks:GetSkillDifficultyLevel(entry.index)
				if difficulty > 3 then
					return false
				else
					return true
				end
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustFilterIcon,
		},
		{
			text = "",
			icon = "Interface\\AddOns\\GnomeWorks\\Art\\skill_colors.tga",
			coords = {0,1,.25,.5},
			func = function(entry)
				local difficulty = GnomeWorks:GetSkillDifficultyLevel(entry.index)
				if difficulty > 2 then
					return false
				else
					return true
				end
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustFilterIcon,
		},
		{
			text = "",
			icon = "Interface\\AddOns\\GnomeWorks\\Art\\skill_colors.tga",
			coords = {0,1,.5,.75},
			enabled = false,
			func = function(entry)
				local difficulty = GnomeWorks:GetSkillDifficultyLevel(entry.index)
				if difficulty > 1 then
					return false
				else
					return true
				end
			end,
			notCheckable = true,
			checked = false,
			OnClick = adjustFilterIcon,
		},
	}






	columnHeaders = {
		{
			name = "Level",
			align = "CENTER",
			width = 36,
			font = "GameFontHighlightSmall",
			sortCompare = function(a,b)
				return (a.itemLevel or 0) - (b.itemLevel or 0)
			end,
			enabled = function()
				return GnomeWorks.tradeID ~= 53428
			end,
			filterMenu = levelFilterMenu,
			draw = function (rowFrame,cellFrame,entry)
							if entry.subGroup then
								cellFrame.text:SetText("")
								return
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
						end,
			OnClick = function(cellFrame, button, source)
							if cellFrame:GetParent().rowIndex == 0 then
								if button == "RightButton" then
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(cellFrame.header.filterMenu, filterMenuFrame, UIParent, x/uiScale,y/uiScale, "MENU", 5)
								else
									sf.sortInvert = (sf.SortCompare == cellFrame.header.sortCompare) and not sf.sortInvert

									sf:HighlightColumn(cellFrame.header.name, sf.sortInvert)
									sf.SortCompare = cellFrame.header.sortCompare
									sf:Refresh()
								end
							end
						end,
			OnEnter =	function (cellFrame)
								if cellFrame:GetParent().rowIndex == 0 then
									GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
									GameTooltip:ClearLines()
									GameTooltip:AddLine("Required Skill Level",1,1,1,true)

									GameTooltip:AddLine("Left-click to Sort")
									GameTooltip:AddLine("Right-click to Adjust Filterings")

									GameTooltip:Show()
								end
							end,
			OnLeave = 	function()
								GameTooltip:Hide()
							end,
		}, -- [1]
		{
			button = {
				normalTexture = "Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga",
				highlightTexture = "Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga",
				width = 14,
				height = 14,
			},
			font = "GameFontHighlight",
			name = "     Recipe",
			width = 250,
			sortCompare = function(a,b)
				return (a.index or 0) - (b.index or 0)
			end,
			filterMenu = recipeFilterMenu,
			OnClick = function(cellFrame, button, source)
							if cellFrame:GetParent().rowIndex>0 then
								local entry = cellFrame:GetParent().data

								if entry.subGroup and source == "button" then
									entry.subGroup.expanded = not entry.subGroup.expanded
									sf:Refresh()
								else
									GnomeWorks:SelectSkill(entry.index)
									sf:Draw()
								end
							else
								if button == "RightButton" then
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(cellFrame.header.filterMenu, filterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								else
									if source == "button" then
										cellFrame.collapsed = not cellFrame.collapsed

										if not cellFrame.collapsed then
											GnomeWorks:CollapseAllHeaders(sf.data.entries)
											sf:Refresh()

											cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
											cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
										else
											GnomeWorks:ExpandAllHeaders(sf.data.entries)
											sf:Refresh()

											cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
											cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
										end
									else
										sf.sortInvert = (sf.SortCompare == cellFrame.header.sortCompare) and not sf.sortInvert

										sf:HighlightColumn(cellFrame.header.name, sf.sortInvert)
										sf.SortCompare = cellFrame.header.sortCompare
										sf:Refresh()
									end
								end
							end
						end,
			draw =	function (rowFrame,cellFrame,entry)
						cellFrame.text:SetPoint("LEFT", cellFrame, "LEFT", entry.depth*8+4+12, 0)

						if entry.subGroup then
							if entry.subGroup.expanded then
								cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
								cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
							else
								cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
								cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
							end

							cellFrame.text:SetFormattedText("%s (%d Recipes)",entry.name,#entry.subGroup.entries)
							cellFrame.button:Show()
						else
							local itemLink = GnomeWorks:GetTradeSkillItemLink(entry.index)
							local spellName = GnomeWorks:GetRecipeName(entry.recipeID)

							cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s", GnomeWorks:GetTradeSkillIcon(entry.index) or "", spellName)

							cellFrame.button:Hide()
						end


						local cr,cg,cb = 1,0,0

						if entry.subGroup then
							cr,cg,cb = 1,.82,0
						else
							if not entry.skillColor then
								entry.skillColor = GnomeWorks:GetSkillColor(entry.index)
							end

							cr,cg,cb = entry.skillColor.r, entry.skillColor.g, entry.skillColor.b
						end

						cellFrame.text:SetTextColor(cr,cg,cb)
					end,

			OnEnter =	function (cellFrame)
							if cellFrame:GetParent().rowIndex == 0 then
								GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
								GameTooltip:ClearLines()
								GameTooltip:AddLine("Recipe Name",1,1,1,true)

								GameTooltip:AddLine("Left-click to Sort")
								GameTooltip:AddLine("Right-click to Adjust Filterings")

								GameTooltip:Show()
							end
						end,
			OnLeave = 	function()
							GameTooltip:Hide()
						end,
		}, -- [2]
		{
			font = "GameFontHighlightSmall",
			name = "Craftable",
			width = 60,
			align = "CENTER",
			sortCompare = function(a,b)
				return (a.craftAlt or 0) - (b.craftAlt or 0)
			end,
			enabled = function()
				return GnomeWorks.tradeID ~= 53428
			end,
			filterMenu = craftFilterMenu,
			OnClick = 	function(cellFrame, button, source)
							if cellFrame:GetParent().rowIndex == 0 then
								if button == "RightButton" then
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(cellFrame.header.filterMenu, filterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								else
									sf.sortInvert = (sf.SortCompare == cellFrame.header.sortCompare) and not sf.sortInvert

									sf:HighlightColumn(cellFrame.header.name, sf.sortInvert)
									sf.SortCompare = cellFrame.header.sortCompare
									sf:Refresh()
								end
							end
						end,
			draw =	function (rowFrame,cellFrame,entry)
							if entry.subGroup then
								cellFrame.text:SetText("")
								return
							end

							if GnomeWorksDB.vendorOnly[entry.recipeID] then
								if entry.craftBag and entry.craftBag ~= 0 then
									cellFrame.text:SetFormattedText("%s%d|r/\226\136\158",inventoryColors.bag,entry.craftBag)
								else
									cellFrame.text:SetText("\226\136\158")
								end
							else
								local bag,vendor,bank,alt = entry.craftBag or -1, entry.craftVendor or -1, entry.craftBank or -1 , entry.craftAlt or -1

								if alt > 0 then
									local display = ""

									if bag > 0 then
										display = string.format("%s%d|r",inventoryColors.bag,bag)
									elseif vendor > 0 then
										display = string.format("%s%d|r",inventoryColors.vendor,vendor)
									elseif bank > 0 then
										display = string.format("%s%d|r",inventoryColors.bank,bank)
									elseif alt > 0 then
										display = string.format("%s%d|r",inventoryColors.alt,alt)
									end

									if alt > bank and bank > 0 then
										display = string.format("%s/%s%s", display, inventoryColors.alt, alt)
									elseif bank > vendor and vendor > 0 then
										display = string.format("%s/%s%s", display, inventoryColors.bank, bank)
									elseif vendor > bag and bag > 0 then
										display = string.format("%s/%s%s", display, inventoryColors.vendor, vendor)
									end


									cellFrame.text:SetText(display)
								else
									cellFrame.text:SetText("")
								end
							end
						end,

			OnEnter =	function (cellFrame)
							if cellFrame:GetParent().rowIndex == 0 then
								GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
								GameTooltip:ClearLines()
								GameTooltip:AddLine("Craftability Counts",1,1,1,true)

								GameTooltip:AddLine("Left-click to Sort")
								GameTooltip:AddLine("Right-click to Adjust Filterings")

								GameTooltip:Show()
							else
								local entry = cellFrame:GetParent().data

								if entry and entry.recipeID then
									if GnomeWorksDB.vendorOnly[entry.recipeID] then
										GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
										GameTooltip:ClearLines()
										GameTooltip:AddLine("Recipe Craftability",1,1,1,true)
										GameTooltip:AddLine(GnomeWorks.player.."'s Inventory")

										if entry.craftBag and entry.craftBag>0 then
											GameTooltip:AddDoubleLine("|cffffff80bags",entry.craftBag)
										end

										GameTooltip:AddLine("\226\136\158 = unlimited through vendor")
										GameTooltip:Show()

									elseif entry.craftAlt and entry.craftAlt > 0 then
										GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
										GameTooltip:ClearLines()
										GameTooltip:AddLine("Recipe Craftability",1,1,1,true)
										GameTooltip:AddLine(GnomeWorks.player.."'s inventory")

										if entry.craftBag and entry.craftBag>0 then
											GameTooltip:AddDoubleLine("|cffffff80bags",entry.craftBag)
										end

										if entry.craftVendor and entry.craftVendor>0  then
											GameTooltip:AddDoubleLine("|cff80ff80vendor",entry.craftVendor)
										end

										if entry.craftBank and entry.craftBank>0 then
											GameTooltip:AddDoubleLine("|cffffa050bank",entry.craftBank)
										end

										if entry.craftAlt and entry.craftAlt>0 then
											GameTooltip:AddDoubleLine("|cffff80ffalts",entry.craftAlt)
										end

										GameTooltip:Show()
									end
								end
							end
						end,
			OnLeave = 	function()
							GameTooltip:Hide()
						end,
		}, -- [3]
	}


	GnomeWorks:CreateFilterMenu(levelFilterParameters, levelFilterMenu, columnHeaders[1])
	GnomeWorks:CreateFilterMenu(recipeLevelParameters, recipeLevelMenu, columnHeaders[2])
	GnomeWorks:CreateFilterMenu(craftFilterParameters, craftSourceMenu, columnHeaders[3])



	local function ResizeMainWindow()
		if sf then
			if not GnomeWorks.selectedSkill then
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
					local w = scrollFrame.columnFrames[i]:IsShown() and scrollFrame.columnWidth[i] or 0

					scrollFrame.columnFrames[i]:SetPoint("LEFT",scrollFrame, "LEFT", x,0)
					scrollFrame.columnFrames[i]:SetPoint("RIGHT",scrollFrame, "LEFT", x+w,0)

					x = x + w
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

		sf = GnomeWorks:CreateScrollingTable(skillFrame, ScrollPaneBackdrop, columnHeaders, ResizeSkillFrame)

		skillFrame.scrollFrame = sf


		sf.IsEntryFiltered = function(self, entry)
			for k,filter in pairs(activeFilterList) do
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



		local function UpdateRowData(scrollFrame,entry,firstCall)
			local player = GnomeWorks.player

			if not entry.subGroup then
				local bag = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "craftedBag queue")
				local vendor = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "vendor craftedBag queue")
				local bank = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "vendor craftedBank queue")
				local alts = GnomeWorks:InventoryRecipeIterations(entry.recipeID, "faction", "vendor craftedBank queue")

				entry.craftBag = bag
				entry.craftVendor = vendor
				entry.craftBank = bank
				entry.craftAlt = alts

				if not entry.itemColor then
					local itemLink = GnomeWorks:GetTradeSkillItemLink(entry.index)

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

			end
		end


		sf:RegisterRowUpdate(UpdateRowData)


		return skillFrame
	end


	function GnomeWorks:ScanComplete()
		local index = self.selectedSkill

		if index then
			self:ShowDetails(index)
			self:ShowReagents(index)
		end

		self:ShowQueueList()

		ResizeMainWindow()
	end


	function GnomeWorks:DoTradeSkillUpdate()
		if frame:IsVisible() then
			self:ScanTrade()
		end
	end


	function GnomeWorks:CHAT_MSG_SKILL()
		self:ParseSkillList()
	end


	function GnomeWorks:TRADE_SKILL_SHOW()
		frame:Show()
		frame.title:Show()
		sf:Show()
	end


	function GnomeWorks:ShowSkillList()
		local player = self.player
		local tradeID = self.tradeID

		if player and tradeID then
			local key = player..":"..tradeID

			local group = self:RecipeGroupFind(player, tradeID, "Blizzard", nil)

			sf.data = group
			sf:Refresh()
			sf:Show()
		end
	end


	function GnomeWorks:SkillListDraw(selected)
		sf.selectedIndex = selected or self.selectedSkill
		self.selectedSkill = selected
		sf:Draw()
	end

	function GnomeWorks:ShowStatus()
		local rank, maxRank = self:GetTradeSkillRank()
		self.levelStatusBar:SetMinMaxValues(0,maxRank)
		self.levelStatusBar:SetValue(rank)
		self.levelStatusBar:Show()


		self.playerNameFrame:SetFormattedText("%s - %s", self.player or "??", self:GetTradeName(self.tradeID) or "??")
	end


	function GnomeWorks:UpdateMainWindow()
		self:ShowSkillList()
		self:ShowStatus()
		self:UpdateTradeButtons(self.player,self.tradeID)
	end


	function GnomeWorks:TRADE_SKILL_UPDATE(...)
		if self.updateTimer then
			self:CancelTimer(self.updateTimer, true)
		end

		self.updateTimer = self:ScheduleTimer("DoTradeSkillUpdate",.1)
	end


	function GnomeWorks:TRADE_SKILL_CLOSE()
		frame.title:Hide()
		frame:Hide()
	end

	function GnomeWorks:SetFilterText(text)
		textFilter = string.lower(text)
		sf:Refresh()
	end


	function GnomeWorks:ScrollToIndex(skillIndex)
		local rowIndex = 1

		for i=1,#sf.dataMap do
			if sf.dataMap[i].index == skillIndex then
				rowIndex = i
				break
			end
		end

		if rowIndex <= sf.scrollOffset then
			sf.scrollBar:SetValue((rowIndex-1) * sf.rowHeight)
		elseif rowIndex > sf.scrollOffset + sf.numRows then
			sf.scrollBar:SetValue((rowIndex - sf.numRows)*sf.rowHeight)
		end
	end


	local SelectTradeLink do
		local function SelectTradeSkill(menuFrame, player, tradeLink)
			ToggleDropDownMenu(1, nil, playerSelectMenu, menuFrame, menuFrame:GetWidth(), 0)
			local tradeString = string.match(tradeLink, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

			if (UnitName("player")) == player then
				local tradeName = GetSpellInfo(string.match(tradeString, "trade:(%d+)"))

				if ((GnomeWorks:GetTradeSkillLine() == "Mining" and "Smelting") or GnomeWorks:GetTradeSkillLine()) ~= tradeName or GnomeWorks:IsTradeSkillLinked() then
					CastSpellByName(tradeName)
				end
			else
				GnomeWorks:OpenTradeLink(tradeLink,player)
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
				local skillButton = {}

				for index, tradeID in ipairs(tradeIDList) do
					if links[tradeID] then
						local rank, maxRank = string.match(links[tradeID], "trade:%d+:(%d+):(%d+)")
						local spellName, spellLink, spellIcon = GnomeWorks:GetTradeInfo(tradeID)

						skillButton.text = string.format("%s |cff00ff00[%s/%s]|r", spellName, rank, maxRank)
						skillButton.value = tradeID

						skillButton.icon = spellIcon

						skillButton.arg1 = UIDROPDOWNMENU_MENU_VALUE
						skillButton.arg2 = links[tradeID]
						skillButton.func = SelectTradeSkill

						skillButton.checked = (tradeID == GnomeWorks.tradeID and UIDROPDOWNMENU_MENU_VALUE == GnomeWorks.player)

						skillButton.disabled = false

						UIDropDownMenu_AddButton(skillButton, level)
					end
				end
			end
		end

		function SelectTradeLink(frame)
			if not playerSelectMenu then
				playerSelectMenu = CreateFrame("Frame", "GWPlayerSelectMenu", UIParent, "UIDropDownMenuTemplate")
			end

			UIDropDownMenu_Initialize(playerSelectMenu, InitMenu, "MENU")
			ToggleDropDownMenu(1, nil, playerSelectMenu, frame, 0, 0)
		end
	end


	function GnomeWorks:CreateControlFrame(frame)
		local function AddToQueue(button)
			local numItems = button.count or 1

			local recipeLink = self:GetTradeSkillRecipeLink(GnomeWorks.selectedSkill)

			local recipeID = tonumber(string.match(recipeLink, "enchant:(%d+)"))

			if not numItems then
				local entry = sf.dataMap[GnomeWorks.selectedSkill]

				local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(next(GnomeWorksDB.results[recipeID]))

				if entry.craftAlt < 1 then
					numItems = itemStackCount
				else
					if entry.craftBag > 1 then
						numItems = entry.craftBag
					elseif entry.craftVendor > 1 then
						numItems = entry.craftVendor
					elseif entry.craftBank > 1 then
						numItems = entry.craftBank
					else
						numItems = entry.craftAlt
					end
				end



				if numItems == LARGE_NUMBER then
					numItems = itemStackCount
				end
			end

			GnomeWorks:AddToQueue(GnomeWorks.player, GnomeWorks.tradeID, recipeID, numItems)
		end

		local function PopRecipe()
			GnomeWorks:PopSelection()
		end


		local ShowPlugins do
			local function InitMenu(menuFrame, level)
				if (level == 1) then  -- plugins
					local title = {}
					local button = {}

					title.text = "Plugins"
					title.fontObject = "GameFontNormal"

					UIDropDownMenu_AddButton(title)

					local count = 0

					for name,data in pairs(GnomeWorks.plugins) do
						if data.loaded then
							button.text = name
							button.hasArrow = #data.menuList>0
							button.value = data.menuList
							button.disabled = false

							UIDropDownMenu_AddButton(button)
							count = count + 1
						end
					end

					if count == 0 then
						button.text = "No Plugins Found"
						button.disabled = true

						UIDropDownMenu_AddButton(button)
					end
				end

				if (level == 2) then  -- functions per plugin
					for index, button in ipairs(UIDROPDOWNMENU_MENU_VALUE) do
						UIDropDownMenu_AddButton(button, level)
					end
				end
			end

			function ShowPlugins(frame)
				if not pluginMenu then
					pluginMenu = CreateFrame("Frame", "GWPluginMenu", UIParent, "UIDropDownMenuTemplate")
				end

				UIDropDownMenu_Initialize(pluginMenu, InitMenu, "MENU")
				ToggleDropDownMenu(1, nil, pluginMenu, frame, 0, 0)
			end
		end


		local buttons = {
			{ text = "Add To Queue",  operation = AddToQueue, count = 1 },
			{ text = "Queue All", operation = AddToQueue },
			{ text = "Plugins", operation = ShowPlugins },
--			{ text = "Back", operation = PopRecipe },
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

			newButton:SetText(config.text)

			newButton.count = config.count
			newButton:SetScript("OnClick", function(button) config.operation(button) end )

			position = position + 100
		end

		controlFrame:SetWidth(position)

		return controlFrame
	end



	function GnomeWorks:CreateMainWindow()
		frame = self.Window:CreateResizableWindow("GnomeWorksFrame", "GnomeWorks (r"..VERSION..")", 600, 400, ResizeMainWindow, GnomeWorksDB.config)

		frame:SetMinResize(500,400)

		local rightSideWidth = 300


		self.detailFrame = self:CreateDetailFrame(frame)
		self.reagentFrame = self:CreateReagentFrame(frame)

		self.skillFrame = BuildScrollingTable()

		self.controlFrame = self:CreateControlFrame(frame)

		local tradeButtonFrame = CreateFrame("Frame", nil, frame)
		tradeButtonFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20,-48)
		tradeButtonFrame:SetWidth(rightSideWidth)
		tradeButtonFrame:SetHeight(18)



		self:CreateTradeButtons(tradeIDList, tradeButtonFrame)
--[[
		local t = tradeButtonFrame:CreateTexture(nil,"OVERLAY")
		t:SetTexture(1,1,1,.5)
		t:SetPoint("TOPLEFT",-5,5)
		t:SetPoint("BOTTOMRIGHT",5,-5)
]]

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

		searchBox:SetFrameLevel(searchBox:GetFrameLevel()+1)

		searchBox:SetAutoFocus(false)

		searchBox:SetPoint("TOPLEFT", frame, 22,-50)
		searchBox:SetHeight(16)
		searchBox:SetPoint("RIGHT", tradeButtonFrame, "LEFT", -30,0)

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
--		level:SetWidth(rightSideWidth)
		level:SetPoint("LEFT",tradeButtonFrame)
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

		playerName:SetPoint("LEFT",tradeButtonFrame)
--		playerName:SetWidth(rightSideWidth)
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


		table.insert(UISpecialFrames, "GnomeWorksFrame")

		frame:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen") end)
		frame:SetScript("OnHide", function() CloseTradeSkill() PlaySound("igCharacterInfoClose") end)


		self:RegisterMessage("GnomeWorksScanComplete", "ScanComplete")

		return frame
	end

end
