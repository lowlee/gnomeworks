







do
	local backDrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 10, right = 10, top = 10, bottom = 10 }
			}

	local detailFrame
	local height = 135
	local detailsWidth = 240

	local reagentFrame
	local sf


	local itemColorVendor = {.25,1.0,.25}
	local itemColorCrafted = {.25,.75,1.0}
	local itemColorNormal = {1,1,1}

	local inventoryIndex = { "bag", "vendor", "bank", "guildBank", "alt" }

	local inventoryColors = {
		bag = "|cffffff80",
		vendor = "|cff80ff80",
		bank =  "|cffffa050",
		guildBank = "|cff5080ff",
		alt = "|cffff80ff",
	}

	local inventoryTags = {}

	for k,v in pairs(inventoryColors) do
		inventoryTags[k] = v..k
	end


	local tooltipScanner =  _G["GWParsingTooltip"] or CreateFrame("GameTooltip", "GWParsingTooltip", getglobal("ANCHOR_NONE"), "GameTooltipTemplate")

	tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")


	local function columnControl(cellFrame,button,source)
		local filterMenuFrame = GnomeWorksFilterMenuFrame
		local scrollFrame = cellFrame:GetParent():GetParent()

		if button == "RightButton" then
			if cellFrame.header.filterMenu then
				local x, y = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()

				EasyMenu(cellFrame.header.filterMenu, filterMenuFrame, UIParent, x/uiScale,y/uiScale, "MENU", 5)
			end
		else
			scrollFrame.sortInvert = (scrollFrame.SortCompare == cellFrame.header.sortCompare) and not scrollFrame.sortInvert

			scrollFrame:HighlightColumn(cellFrame.header.name, scrollFrame.sortInvert)
			scrollFrame.SortCompare = cellFrame.header.sortCompare
			scrollFrame:Refresh()
		end
	end


	local columnHeaders = {
		{
			name= "#",
			align = "CENTER",
			width = 25,
			sortCompare = function(a,b)
				return (a.numNeeded or 0) - (b.numNeeded or 0)
			end,
			dataField = "numNeeded",
			OnEnter = 	function(cellFrame)
							if cellFrame:GetParent().rowIndex == 0 then
								GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
								GameTooltip:ClearLines()
								GameTooltip:AddLine("# Required",1,1,1,true)

								GameTooltip:AddLine("Left-click to Sort")
--								GameTooltip:AddLine("Right-click to Adjust Filterings")

								GameTooltip:Show()
							else
								local entry = cellFrame:GetParent().data

								if entry and entry.id then
									GameTooltip:SetOwner(reagentFrame, "ANCHOR_RIGHT")
									GameTooltip:SetHyperlink("item:"..entry.id)
									GameTooltip:Show()
								end
							end
						end,

			OnClick = function(cellFrame, button, source)
				if cellFrame:GetParent().rowIndex==0 then
					columnControl(cellFrame, button, source)
				end
			end,
		}, -- [1]
		{
			name = "Reagent",
			sortCompare = function(a,b)
				return (a.index or 0) - (b.index or 0)
			end,
			width = 100,
			OnClick = function(cellFrame, button, source)
				if cellFrame:GetParent().rowIndex==0 then
					columnControl(cellFrame, button, source)
				else
					local entry = cellFrame:GetParent().data

					local itemSource = GnomeWorks.data.itemSource[entry.id]

					if itemSource then
						GnomeWorks:PushSelection()
						GnomeWorks:SelectRecipe(itemSource)
					end
				end
			end,
			OnEnter = 	function(cellFrame)
							if cellFrame:GetParent().rowIndex == 0 then
								GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
								GameTooltip:ClearLines()
								GameTooltip:AddLine("Reagent",1,1,1,true)

								GameTooltip:AddLine("Left-click to Sort")
--								GameTooltip:AddLine("Right-click to Adjust Filterings")

								GameTooltip:Show()
							else
								local entry = cellFrame:GetParent().data

								if entry and entry.id then
									GameTooltip:SetOwner(reagentFrame, "ANCHOR_RIGHT")
									GameTooltip:SetHyperlink("item:"..entry.id)
									GameTooltip:Show()
								end
							end
						end,
			OnLeave =	function()
							GameTooltip:Hide()
						end,
			draw =	function (rowFrame,cellFrame,entry)
						cellFrame.text:SetFormattedText(" |T%s:20:20:0:-2|t %s",entry.itcon or "", entry.name or "item:"..entry.id)
						if entry.itemColor then
							cellFrame.text:SetTextColor(unpack(entry.itemColor))
						end
					end,
		}, -- [2]
		{
			name = "Inventory",
			width = 70,
			align = "CENTER",
			OnClick = function(cellFrame, button, source)
				if cellFrame:GetParent().rowIndex==0 then
					columnControl(cellFrame, button, source)
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

								if entry then
									GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
									GameTooltip:ClearLines()
									GameTooltip:AddLine(GnomeWorks.player.."'s inventory")

									local prevCount = 0

									for i,key in pairs(inventoryIndex) do
										local count = entry[key] or 0

										if count ~= prevCount then
											GameTooltip:AddDoubleLine(inventoryTags[key],count)
											prevCount = count
										end
									end


									GameTooltip:Show()
								end
							end
						end,
			draw =	function (rowFrame,cellFrame,entry)
--[[
						local bag = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBag queue")
						local bank = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBank queue")
						local guildBank = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedGuildBank queue")
						local alt = GnomeWorks:GetInventoryCount(entry.id, "faction", "craftedBank queue")
]]

						local bag, bank, guildBank, alt = entry.bag, entry.bank, entry.guildBank, entry.alt

						if alt+guildBank > 0 then
							local display = ""
	--[[
							if bag > 0 then
								display = string.format("%s%d|r",inventoryColors.bag,bag)
							elseif bank > 0 then
								display = string.format("%s%d|r",inventoryColors.bank,bank)
							elseif guildBank > 0 then
								display = string.format("%s%d|r",inventoryColors.guildBank,guildBank)
							elseif alt > 0 then
								display = string.format("%s%d|r",inventoryColors.alt,alt)
							end

							if alt > bank then
								if bank ~= 0 then
									display = string.format("%s/%s%s", display, inventoryColors.alt, alt)
								end
							elseif bank > bag then
								display = string.format("%s/%s%s", display, inventoryColors.bank, bank)
							end
	]]

							if bag > 0 then
								display = string.format("%s%d|r",inventoryColors.bag,bag)
							elseif bank > 0 then
								display = string.format("%s%d|r",inventoryColors.bank,bank)
							elseif guildBank > 0 then
								display = string.format("%s%d|r",inventoryColors.guildBank,guildBank)
							elseif alt > 0 then
								display = string.format("%s%d|r",inventoryColors.alt,alt)
							end

							if alt > guildBank and guildBank > 0 then
								display = string.format("%s/%s%s", display, inventoryColors.alt, alt)
							elseif guildBank > bank and bank > 0 then
								display = string.format("%s/%s%s", display, inventoryColors.guildBank, guildBank)
							elseif bank > bag and bag > 0 then
								display = string.format("%s/%s%s", display, inventoryColors.bank, bank)
							end



							cellFrame.text:SetText(display)
						else
							cellFrame.text:SetText("|cffff00000")
						end
					end,
		}, -- [3]
	}





	function GnomeWorks:CreateReagentFrame(parentFrame)
		local function ResizeReagentFrame(scrollFrame, width, height)
			scrollFrame.columnWidth[2] = scrollFrame.columnWidth[2] + width - scrollFrame.headerWidth
			scrollFrame.headerWidth = width

			local x = 0

			for i=1,#scrollFrame.columnFrames do
				scrollFrame.columnFrames[i]:SetPoint("LEFT",scrollFrame, "LEFT", x,0)
				scrollFrame.columnFrames[i]:SetPoint("RIGHT",scrollFrame, "LEFT", x+scrollFrame.columnWidth[i],0)

				x = x + scrollFrame.columnWidth[i]
			end
		end


		local ScrollPaneBackdrop  = {
				bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 9.5, right = 9.5, top = 9.5, bottom = 9.5 }
			}

		reagentFrame = CreateFrame("Frame",nil,parentFrame)
		reagentFrame:SetPoint("BOTTOM",0,20)
		reagentFrame:SetPoint("TOP", detailFrame, "TOP", 0, -15)
		reagentFrame:SetPoint("RIGHT", parentFrame, -20,0)
		reagentFrame:SetPoint("LEFT", detailFrame, "RIGHT", 5,0)

		GnomeWorks.reagentFrame = reagentFrame

--		GnomeWorks.Window:SetBetterBackdrop(reagentFrame,backDrop)


		columnHeaders[2].width = reagentFrame:GetWidth() - 90

		sf = GnomeWorks:CreateScrollingTable(reagentFrame, ScrollPaneBackdrop, columnHeaders, ResizeReagentFrame)

		reagentFrame.scrollFrame = sf


		sf.data = { entries = {  } }

		for i=1,8 do
			sf.data.entries[i] = { index = i, id = 0, numNeeded = 0 }
		end

		sf.numData = 0
		sf.data.numEntries = 0

		function GnomeWorks:HideReagents()
			reagentFrame:Hide()
		end

		function GnomeWorks:ShowReagents(index)
			if not index or not self.tradeID then return end

			local recipeID = self.data.skillDB[self.player..":"..self.tradeID] and self.data.skillDB[self.player..":"..self.tradeID].recipeID[index]

			if not recipeID then
				if not self.data.pseudoTrade[self.tradeID] then
					return
				end

				recipeID = self.data.pseudoTrade[self.tradeID][index]
			end


			reagentFrame:Show()

--			local skillData = self:GetSkillData(index)

--			local recipeID = self.data.skillDB[self.player..":"..self.tradeID] and self.data.skillDB[self.player..":"..self.tradeID].recipeID[index] or self.data.pseudoTrade[self.tradeID][index]

			if recipeID then
--				local results, reagents, tradeID = self:GetRecipeData(skillData.id)

--				sf.data.entries = recipeData.reagentData

--				sf.numData = #recipeData.reagentData

				local i = 0

				for reagentID, numNeeded in pairs(GnomeWorksDB.reagents[recipeID]) do
					i = i + 1
					sf.data.entries[i].id = reagentID
					sf.data.entries[i].numNeeded = numNeeded
					sf.data.entries[i].index = i
				end

				sf.data.numEntries = i

				sf:Refresh()
			end
		end


		local function UpdateRowData(scrollFrame,entry,firstCall)
			local player = GnomeWorks.player

			local bag = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBag queue")
			local bank = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBank queue")
			local guildBank = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedGuildBank queue")
			local alt = GnomeWorks:GetInventoryCount(entry.id, "faction", "craftedGuildBank queue")

			entry.bag = bag
			entry.bank = bank
			entry.guildBank = guildBank
			entry.alt = math.max(alt, guildBank)

			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(entry.id)



			if GnomeWorks:VendorSellsItem(entry.id) then
				entry.itemColor = itemColorVendor
			elseif GnomeWorks.data.itemSource[entry.id] then
				entry.itemColor = itemColorCrafted
			else
				entry.itemColor = itemColorNormal
			end

			entry.icon = itemTexture

			entry.name = itemName
		end

		sf:RegisterRowUpdate(UpdateRowData)


		return reagentFrame
	end


	function GnomeWorks:CreateDetailFrame(frame)
		detailFrame = CreateFrame("Frame",nil,frame)

		detailFrame.textScroll = CreateFrame("ScrollFrame", "GWDetailFrame", detailFrame)



		detailFrame.scrollChild = CreateFrame("Frame",nil,detailFrame.textScroll)
		detailFrame.textScroll:SetScrollChild(detailFrame.scrollChild)

		GnomeWorks.Window:SetBetterBackdrop(detailFrame.textScroll,backDrop)
		GnomeWorks.Window:SetBetterBackdrop(detailFrame,backDrop)

		detailFrame:SetHeight(height)
		detailFrame:SetWidth(detailsWidth)

		detailFrame:SetPoint("BOTTOMLEFT", 20,20)


		detailFrame.textScroll:SetPoint("BOTTOMRIGHT",detailFrame,-2,2)
		detailFrame.textScroll:SetPoint("TOPLEFT",detailFrame,2,-35)

		detailFrame.scrollChild:SetWidth(detailsWidth-4)
		detailFrame.scrollChild:SetHeight(height-37)

		detailFrame.scrollChild:SetAlpha(1)



--		detailFrame.textScroll:SetScript("OnVerticalScroll", function(frame, value) print(value) end)

		detailFrame.textScroll:SetScript("OnScrollRangeChanged", function(frame, xRange, yRange)
--		print(frame, frame.maxScroll, yRange)
			frame.maxScroll =  yRange
			frame.scroll = 0

			frame:SetVerticalScroll(frame.scroll)
		end)
--[[
		detailFrame.textScroll:SetScript("OnEnter", function(frame)
			detailFrame.textScroll:SetVerticalScroll(detailFrame.maxScroll)
		end)

		detailFrame.textScroll:SetScript("OnLeave", function(frame)
			detailFrame.textScroll:SetVerticalScroll(0)
		end)
]]
		detailFrame.textScroll:SetScript("OnMouseWheel", function(frame, value)
--			print(frame, value, frame.scroll, frame.maxScroll)

			frame.scroll = frame.scroll - value * 16
			if frame.scroll < 0 then
				frame.scroll = 0
			end

			if frame.scroll > frame.maxScroll then
				frame.scroll = frame.maxScroll
			end

			frame:SetVerticalScroll(frame.scroll)
		end)

		detailFrame.textScroll:EnableMouseWheel(true)
		detailFrame.textScroll:EnableMouse(true)

		detailFrame.textScroll.maxScroll = 0
		detailFrame.textScroll.scroll = 0

		detailFrame.textScroll:SetVerticalScroll(0)


		local parentFrame = detailFrame.scrollChild


		local detailIcon = CreateFrame("Button",nil,detailFrame)

		detailIcon:SetScript("OnClick", function(frame,...)
			HandleModifiedItemClick(GnomeWorks:GetTradeSkillRecipeLink(GnomeWorks.selectedSkill))
		end)


		local detailIcon = CreateFrame("Button",nil,detailFrame)

		detailIcon:EnableMouse(true)

		detailIcon:SetWidth(30)
		detailIcon:SetHeight(30)

		detailIcon:SetPoint("TOPLEFT", 3,-3)

		detailIcon:SetScript("OnClick", function(frame,...)
			HandleModifiedItemClick(GnomeWorks:GetTradeSkillItemLink(GnomeWorks.selectedSkill))
		end)

		detailIcon:SetScript("OnEnter", function(frame,...)
			if GnomeWorks.selectedSkill then
				GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(GnomeWorks:GetTradeSkillItemLink(GnomeWorks.selectedSkill))
				GameTooltip:AddLine("Shift-Click to Link Item")
				GameTooltip:Show()
			end
			CursorUpdate(self)
		end)

		detailIcon:SetScript("OnLeave", GameTooltip_HideResetCursor)



		local detailNumMadeLabel = detailIcon:CreateFontString(nil,"OVERLAY", "GameFontGreenSmall")
		detailNumMadeLabel:SetPoint("BOTTOMRIGHT",-2,2)
		detailNumMadeLabel:SetPoint("TOPLEFT",0,0)
		detailNumMadeLabel:SetJustifyH("RIGHT")
		detailNumMadeLabel:SetJustifyV("BOTTOM")


		local detailNameButton = CreateFrame("Button",nil,detailFrame)
		detailNameButton:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 5,0)
		detailNameButton:SetPoint("RIGHT", -5,0)
		detailNameButton:SetHeight(30)


		local detailNameLabel = detailNameButton:CreateFontString(nil,"OVERLAY", "GameFontNormal")
		detailNameLabel:SetPoint("TOPLEFT")
		detailNameLabel:SetPoint("BOTTOMRIGHT")
		detailNameLabel:SetJustifyH("LEFT")
		detailNameLabel:SetTextColor(1,.8,0)


		detailNameButton:EnableMouse(true)

		detailNameButton:RegisterForClicks("AnyUp")


		detailNameButton:SetScript("OnClick", function(frame,...)
			HandleModifiedItemClick(GnomeWorks:GetTradeSkillRecipeLink(GnomeWorks.selectedSkill))
		end)

		detailNameButton:SetScript("OnEnter", function(frame,...)
			GameTooltip:SetOwner(frame, "ANCHOR_TOP")
			GameTooltip:ClearLines()
			GameTooltip:AddLine("Shift-Click to Link Recipe")
			GameTooltip:Show()

			detailNameLabel:SetTextColor(1,1,1)
		end)

		detailNameButton:SetScript("OnLeave", function(...)
			detailNameLabel:SetTextColor(1,.8,0)
			GameTooltip_HideResetCursor(...)
		end)



	-- scrolling part below


		detailFrame.infoFunctionList = {}


		function detailFrame:RegisterInfoFunction(func, plugin)
			local descriptionLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			descriptionLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0,0)
			descriptionLabel:SetWidth(detailsWidth - 10)
			descriptionLabel:SetHeight(0)
			descriptionLabel:SetJustifyH("LEFT")
			descriptionLabel:SetJustifyV("TOP")
			descriptionLabel:SetTextColor(1,1,1)


			local descriptionLabelRight = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			descriptionLabelRight:SetPoint("TOPLEFT", descriptionLabel, "TOPLEFT", 0,0)
			descriptionLabelRight:SetWidth(detailsWidth - 10)
			descriptionLabelRight:SetHeight(0)
			descriptionLabelRight:SetJustifyH("RIGHT")
			descriptionLabelRight:SetJustifyV("TOP")
			descriptionLabelRight:SetTextColor(1,1,1)

			local new = { func = func, plugin = plugin, leftFS = descriptionLabel, rightFS=descriptionLabelRight }

			table.insert(detailFrame.infoFunctionList, new)
		end


		detailFrame:RegisterInfoFunction(function(index,recipeID,left,right)
			if self:GetTradeSkillTools(index) then
				left = left .. string.format("%s %s\n",REQUIRES_LABEL,BuildColoredListString(self:GetTradeSkillTools(index)))
				right = right .. "\n"
			end
			return left,right
		end)

		detailFrame:RegisterInfoFunction(function(index,recipeID,left,right)
			if self:GetTradeSkillCooldown(index) then
				left = left .. string.format("%s %s\n",COOLDOWN_REMAINING,SecondsToTime(self:GetTradeSkillCooldown(index)))
				right = right .. "\n"
			end

			return left,right
		end)

		detailFrame:RegisterInfoFunction(function(index,recipeID,left,right)
			local link = self:GetTradeSkillItemLink(index)

			if link and strfind(link,"item:") then -- or strfind(link,"spell:") or strfind(link,"enchant:") then
				local firstLine = 2

				if strfind(link,"spell:") or strfind(link,"enchant:") then
					firstLine = 4
				end

				tooltipScanner:SetOwner(frame, "ANCHOR_NONE")
				tooltipScanner:SetHyperlink(link)

				local tiplines = tooltipScanner:NumLines()



				for i=firstLine, tiplines do
					local fs = getglobal("GWParsingTooltipTextLeft"..i)

					local r,g,b,a = fs:GetTextColor()

					left = string.format("%s|c%2x%2x%2x%2x%s|r\n",left,a*255,r*255,g*255,b*255,fs:GetText())


					local fs = getglobal("GWParsingTooltipTextRight"..i)

					local r,g,b,a = fs:GetTextColor()

					right = string.format("%s|c%2x%2x%2x%2x%s|r\n",right,a*255,r*255,g*255,b*255,fs:GetText() or "")
				end
			else
				left = left..(self:GetTradeSkillDescription(index) or "").."\n"
				right = right .. "\n"
			end

			return left,right
		end)




		function GnomeWorks:HideDetails()
			detailFrame:Hide()
		end

		function GnomeWorks:ShowDetails(index)
			if not index or not self.tradeID then return end

			local recipeID = self.data.skillDB[self.player..":"..self.tradeID] and self.data.skillDB[self.player..":"..self.tradeID].recipeID[index]

			if not recipeID then
				if not self.data.pseudoTrade[self.tradeID] then
					return
				end

				recipeID = self.data.pseudoTrade[self.tradeID][index]
			end

			detailFrame:Show()

			local skillName = self:GetRecipeName(recipeID)

			detailIcon:SetNormalTexture(self:GetTradeSkillIcon(index))

--			local numMade = next(GnomeWorksDB.results[recipeID])

			local minMade, maxMade = GnomeWorks:GetTradeSkillNumMade(index)

			local numMade = (minMade + maxMade)/2

			if numMade ~= 1 then
				detailNumMadeLabel:SetText(numMade)
				detailNumMadeLabel:Show()
			else
				detailNumMadeLabel:Hide()
			end

--print("vertical scroll range ", detailFrame.textScroll:GetVerticalScrollRange())

			detailNameLabel:SetText(skillName)

			local pos = 0

			for k,entry in pairs(detailFrame.infoFunctionList) do
				local lineTextLeft,lineTextRight = "",""

				lineTextLeft, lineTextRight = entry.func(index, recipeID, lineTextLeft, lineTextRight)

				entry.leftFS:SetText(lineTextLeft)
				entry.rightFS:SetText(lineTextRight)

				entry.leftFS:SetPoint("TOPLEFT", 0,-pos)

				pos = pos + math.max(entry.leftFS:GetStringHeight(), entry.rightFS:GetStringHeight())

	--			descriptionLabel:Show()
	--			descriptionLabelRight:Show()
			end




		end


		return detailFrame
	end



end
