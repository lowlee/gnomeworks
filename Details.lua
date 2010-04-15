







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



	local columnHeaders = {
		{
			["name"] = "#",
			["align"] = "CENTER",
			["width"] = 20,
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["dataField"] = "numNeeded",
		}, -- [1]
		{
			["name"] = "Reagent",
			["width"] = 100,
			["bgcolor"] = colorDark,
			["sortnext"]= 4,
			["tooltipText"] = "click to sort\rright-click to filter",
			["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
--								GnomeWorks:SelectSkill(realrow)
							end,
			["dataField"]= "id",
			["OnEnter"] = 	function(cellFrame)
								local entry = cellFrame:GetParent().data
								if entry and entry.id then
									GameTooltip:SetOwner(reagentFrame, "ANCHOR_RIGHT")
									GameTooltip:SetHyperlink("item:"..entry.id)
									GameTooltip:Show()
								end
							end,
			["OnLeave"] =	function()
								GameTooltip:Hide()
							end,
			["draw"] =	function (rowFrame,cellFrame,entry)
							local itemName, itemLink = GetItemInfo(entry.id)

							if GnomeWorks:VendorSellsItem(entry.id) then
								cellFrame.text:SetTextColor(.25,1.0,.25)
							elseif GnomeWorksDB.itemData[entry.id] then
								cellFrame.text:SetTextColor(.25,.75,1.0)
							else
								cellFrame.text:SetTextColor(1,1,1)
							end

							cellFrame.text:SetFormattedText("%s",itemName or "item:"..id)
						end,
		}, -- [2]
		{
			["name"] = "Inventory",
			["width"] = 70,
			["align"] = "CENTER",
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["sortnext"]= 1,
			["rightclick"] = 	function()
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

--									EasyMenu(levelFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end,
			["dataField"] = "numAvailable",
			["draw"] =	function (rowFrame,cellFrame,entry)
							local _, bag, _, bank = GnomeWorks:GetInventory(GnomeWorks.player, entry.id)
							local _,_,_, alt = GnomeWorks:GetFactionInventory(entry.id)

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

	local extraStuff = {
		{
			["name"] = "Value",
			["width"] = 50,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 },
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["sortnext"] = 4,
			["dataField"] = "value",
		}, -- [4]
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

		sf.data = { entries = {} }

		for i=1,8 do
			sf.data.entries[i] = { }
		end

		sf.numData = 0

		function GnomeWorks:HideReagents()
			reagentFrame:Hide()
		end

		function GnomeWorks:ShowReagents(index)
			reagentFrame:Show()

			local skillData = self:GetSkillData(index)
			local recipeData = self:GetRecipeData(skillData.id)

			sf.data.entries = recipeData.reagentData

			sf.numData = #recipeData.reagentData

			sf:Refresh()
		end

		return reagentFrame
	end


	function GnomeWorks:CreateDetailFrame(parentFrame)
		detailFrame = CreateFrame("Frame",nil,parentFrame)

		GnomeWorks.Window:SetBetterBackdrop(detailFrame,backDrop)

		detailFrame:SetHeight(height)
		detailFrame:SetWidth(detailsWidth)

		detailFrame:SetPoint("BOTTOMLEFT", 20,20)

		local detailIcon = CreateFrame("Button",nil,detailFrame)

		detailIcon:EnableMouse(true)

		detailIcon:SetWidth(30)
		detailIcon:SetHeight(30)

		detailIcon:SetPoint("TOPLEFT", 3,-3)

		detailIcon:SetScript("OnClick", function(frame,...)
			HandleModifiedItemClick(GetTradeSkillItemLink(GnomeWorks.selectedSkill))
		end)

		detailIcon:SetScript("OnEnter", function(frame,...)
			if GnomeWorks.selectedSkill then
				GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
				GameTooltip:SetTradeSkillItem(GnomeWorks.selectedSkill)
			end
			CursorUpdate(self)
		end)

		detailIcon:SetScript("OnLeave", GameTooltip_HideResetCursor)

--[[
		<OnClick>
			HandleModifiedItemClick(GetTradeSkillItemLink(TradeSkillFrame.selectedSkill));
		</OnClick>
		<OnEnter function="TradeSkillItem_OnEnter"/>
		<OnLeave function="GameTooltip_HideResetCursor"/>
		<OnUpdate>
			if ( GameTooltip:IsOwned(self) ) then
				TradeSkillItem_OnEnter(self);
			end
			CursorOnUpdate(self);
		</OnUpdate>
]]

		local detailNumMadeLabel = detailIcon:CreateFontString(nil,"OVERLAY", "GameFontGreenSmall")
		detailNumMadeLabel:SetPoint("BOTTOMRIGHT",-2,2)
		detailNumMadeLabel:SetPoint("TOPLEFT",0,0)
		detailNumMadeLabel:SetJustifyH("RIGHT")
		detailNumMadeLabel:SetJustifyV("BOTTOM")

		local detailNameLabel = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		detailNameLabel:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 5,0)
		detailNameLabel:SetPoint("RIGHT", -5,0)
		detailNameLabel:SetHeight(30)
		detailNameLabel:SetJustifyH("LEFT")
		detailNameLabel:SetTextColor(1,1,1)

		local toolsLabel = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		toolsLabel:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0,0)
		toolsLabel:SetPoint("RIGHT", -5,0)
		toolsLabel:SetHeight(20)
		toolsLabel:SetJustifyH("LEFT")
		toolsLabel:SetJustifyV("TOP")
		toolsLabel:SetTextColor(1,1,1)

		local cooldownLabel = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cooldownLabel:SetPoint("TOPLEFT", toolsLabel, "BOTTOMLEFT", 0,0)
		cooldownLabel:SetPoint("RIGHT", -5,0)
		cooldownLabel:SetHeight(20)
		cooldownLabel:SetJustifyH("LEFT")
		cooldownLabel:SetJustifyV("TOP")
		cooldownLabel:SetTextColor(1,1,1)

		local descriptionLabel = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		descriptionLabel:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0,0)
		descriptionLabel:SetPoint("RIGHT", -5,0)
		descriptionLabel:SetHeight(20)
		descriptionLabel:SetJustifyH("LEFT")
		descriptionLabel:SetJustifyV("TOP")
		descriptionLabel:SetTextColor(1,1,1)


		function GnomeWorks:HideDetails()
			detailFrame:Hide()
		end

		function GnomeWorks:ShowDetails(index)
			detailFrame:Show()
			local skillName = GetTradeSkillInfo(index)

			detailIcon:SetNormalTexture(GetTradeSkillIcon(index))

			local minMade, maxMade = GetTradeSkillNumMade(index)

			if maxMade > 1 then
				if minMade ~= maxMade then
					detailNumMadeLabel:SetFormattedText("%s/%s",minMade, maxMade)
				else
					detailNumMadeLabel:SetText(minMade)
				end

				detailNumMadeLabel:Show()
			else
				detailNumMadeLabel:Hide()
			end


			detailNameLabel:SetText(skillName)

			if GetTradeSkillTools(index) then
				toolsLabel:SetFormattedText("%s %s",REQUIRES_LABEL,BuildColoredListString(GetTradeSkillTools(index)))
				toolsLabel:Show()
				toolsLabel:SetHeight(15)
			else
				toolsLabel:Hide()
				toolsLabel:SetHeight(1)
			end

			if GetTradeSkillCooldown(index) then
				cooldownLabel:SetFormattedText("%s %s",COOLDOWN_REMAINING,SecondsToTime(GetTradeSkillCooldown(index)))
				cooldownLabel:Show()
				cooldownLabel:SetHeight(15)
			else
				cooldownLabel:Hide()
				cooldownLabel:SetHeight(1)
			end

			if GetTradeSkillDescription(index) then
				descriptionLabel:SetText(GetTradeSkillDescription(index))
				descriptionLabel:SetHeight(1000)
				descriptionLabel:Show()
				descriptionLabel:SetHeight(descriptionLabel:GetHeight())
			else
				descriptionLabel:Hide()
			end
		end


		return detailFrame
	end



end
