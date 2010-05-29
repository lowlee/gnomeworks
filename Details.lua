







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


	local cbag = "|cffffff80"
	local cvendor = "|cff80ff80"
	local cbank =  "|cffffa050"
	local calt = "|cffff80ff"


	local tooltipScanner = CreateFrame("GameTooltip", "GWParsingTooltip", getglobal("ANCHOR_NONE"), "GameTooltipTemplate")

	tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")


	local function columnControl(cellFrame,button,source)
		local filterMenuFrame = getglobal("GnomeWorksFilterMenuFrame")
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
			bgcolor = colorBlack,
			tooltipText = "click to sort\rright-click to filter",
			dataField = "numNeeded",
			sortCompare = function(a,b)
				return (a.numNeeded or 0) - (b.numNeeded or 0)
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
			tooltipText = "click to sort\rright-click to filter",
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
							local entry = cellFrame:GetParent().data
							if entry and entry.id then
								GameTooltip:SetOwner(reagentFrame, "ANCHOR_RIGHT")
								GameTooltip:SetHyperlink("item:"..entry.id)
								GameTooltip:Show()
							end
						end,
			OnLeave =	function()
								GameTooltip:Hide()
							end,
			draw =	function (rowFrame,cellFrame,entry)
						local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(entry.id)

						if GnomeWorks:VendorSellsItem(entry.id) then
							cellFrame.text:SetTextColor(.25,1.0,.25)
						elseif GnomeWorks.data.itemSource[entry.id] then
							cellFrame.text:SetTextColor(.25,.75,1.0)
						else
							cellFrame.text:SetTextColor(1,1,1)
						end

						cellFrame.text:SetFormattedText(" |T%s:20:20:0:-2|t %s",itemTexture or "", itemName or "item:"..entry.id)
					end,
		}, -- [2]
		{
			name = "Inventory",
			width = 70,
			align = "CENTER",
			tooltipText = "click to sort\rright-click to filter",
			sortnext= 1,
			OnClick = function(cellFrame, button, source)
				if cellFrame:GetParent().rowIndex==0 then
					columnControl(cellFrame, button, source)
				end
			end,
			draw =	function (rowFrame,cellFrame,entry)
						local bag = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBag queue")
						local bank = GnomeWorks:GetInventoryCount(entry.id, GnomeWorks.player, "craftedBank queue")
						local alt = GnomeWorks:GetInventoryCount(entry.id, "faction", "craftedBank queue")

						if alt > 0 then
							local display = ""

							if bag > 0 then
								display = string.format("%s%d|r",cbag,bag)
							elseif bank > 0 then
								display = string.format("%s%d|r",cbank,bank)
							elseif alt > 0 then
								display = string.format("%s%d|r",calt,alt)
							end

							if alt > bank then
								if bank ~= 0 then
									display = string.format("%s/%s%s", display, calt, alt)
								end
							elseif bank > bag then
								display = string.format("%s/%s%s", display, cbank, bank)
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

		return reagentFrame
	end


	function GnomeWorks:CreateDetailFrame(frame)
		detailFrame = CreateFrame("Frame",nil,frame)

		detailFrame.textScroll = CreateFrame("ScrollFrame", nil, detailFrame)



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



		detailFrame.textScroll:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
			detailFrame.maxScroll =  yRange
		end)


		detailFrame.textScroll:EnableMouse(true)

		detailFrame.maxScroll = 0

		detailFrame.textScroll:SetVerticalScroll(0)


		local parentFrame = detailFrame.scrollChild

--[[
		local linkIcon = CreateFrame("Button",nil,detailFrame)

		linkIcon:EnableMouse(true)

		linkIcon:SetWidth(16)
		linkIcon:SetHeight(16)

		linkIcon:SetPoint("TOPRIGHT",-3,-3)

		local normalTexture = linkIcon:CreateTexture(nil,"OVERLAY")
		normalTexture:SetTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton")
		normalTexture:SetTexCoord(0,1,0,.5)

		linkIcon:SetNormalTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton")

		local highlightTexture = linkIcon:CreateTexture(nil,"OVERLAY")
		highlightTexture:SetTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton")
		highlightTexture:SetTexCoord(0,1,0.5,1.0)
		highlightTexture:SetBlendMode("ADD")

		linkIcon:SetHighlightTexture(highlightTexture)
]]

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


		local toolsLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		toolsLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0,0)
		toolsLabel:SetPoint("RIGHT", -5,0)
		toolsLabel:SetHeight(0)
		toolsLabel:SetJustifyH("LEFT")
		toolsLabel:SetJustifyV("TOP")
		toolsLabel:SetTextColor(1,1,1)

		local cooldownLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cooldownLabel:SetPoint("TOPLEFT", toolsLabel, "BOTTOMLEFT", 0,0)
		cooldownLabel:SetPoint("RIGHT", -5,0)
		cooldownLabel:SetHeight(0)
		cooldownLabel:SetJustifyH("LEFT")
		cooldownLabel:SetJustifyV("TOP")
		cooldownLabel:SetTextColor(1,1,1)

		local descriptionLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		descriptionLabel:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0,0)
		descriptionLabel:SetWidth(detailsWidth - 10)
		descriptionLabel:SetHeight(0)
		descriptionLabel:SetJustifyH("LEFT")
		descriptionLabel:SetJustifyV("TOP")
		descriptionLabel:SetTextColor(1,1,1)


		local descriptionLabelRight = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		descriptionLabelRight:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0,0)
		descriptionLabelRight:SetWidth(detailsWidth - 10)
		descriptionLabelRight:SetHeight(0)
		descriptionLabelRight:SetJustifyH("RIGHT")
		descriptionLabelRight:SetJustifyV("TOP")
		descriptionLabelRight:SetTextColor(1,1,1)



		detailFrame.textScroll:SetScript("OnEnter", function(frame)
			detailFrame.textScroll:SetVerticalScroll(detailFrame.maxScroll)
		end)

		detailFrame.textScroll:SetScript("OnLeave", function(frame)
			detailFrame.textScroll:SetVerticalScroll(0)
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

			if self:GetTradeSkillTools(index) then
				toolsLabel:SetFormattedText("%s %s\n",REQUIRES_LABEL,BuildColoredListString(self:GetTradeSkillTools(index)))
				toolsLabel:Show()
			else
				toolsLabel:Hide()
				toolsLabel:SetText("")
			end

			if self:GetTradeSkillCooldown(index) then
				cooldownLabel:SetFormattedText("%s %s\n",COOLDOWN_REMAINING,SecondsToTime(self:GetTradeSkillCooldown(index)))
				cooldownLabel:Show()
			else
				cooldownLabel:Hide()
				cooldownLabel:SetText("")
			end

			local link = self:GetTradeSkillItemLink(index)

			if strfind(link,"item:") or strfind(link,"spell:") then
--print(link)
				tooltipScanner:SetOwner(frame, "ANCHOR_NONE")
				tooltipScanner:SetHyperlink(link)
--tooltipScanner:Hide()

				local tiplines = tooltipScanner:NumLines()
--print(tiplines)

				local lineText,lineTextRight = "",""

				for i=2, tiplines do
					local fs = getglobal("GWParsingTooltipTextLeft"..i)

					local r,g,b,a = fs:GetTextColor()

					lineText = string.format("%s|c%2x%2x%2x%2x%s|r\n",lineText,a*255,r*255,g*255,b*255,fs:GetText())


					local fs = getglobal("GWParsingTooltipTextRight"..i)

					local r,g,b,a = fs:GetTextColor()

					lineTextRight = string.format("%s|c%2x%2x%2x%2x%s|r\n",lineTextRight,a*255,r*255,g*255,b*255,fs:GetText() or "")

--print(i,lineText)
				end

				descriptionLabel:SetText(lineText)
				descriptionLabelRight:SetText(lineTextRight)

				descriptionLabel:Show()
				descriptionLabelRight:Show()
			else
				descriptionLabel:SetText(self:GetTradeSkillDescription(index))
				descriptionLabelRight:SetText("")
				descriptionLabelRight:Hide()
				descriptionLabel:Show()
			end
		end


		return detailFrame
	end



end
