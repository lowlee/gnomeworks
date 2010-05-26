
-- LSW plugin Interface
local pluginToken

local function RegisterWithLSW()
	if not LSW then return end

	local valueColumn
	local costColumn
	local scrollFrame

	local reagentCostColumn
	local reagentScrollFrame

	local itemCache


	local itemFateColor={
		["d"]="ff008000",
		["a"]="ff909050",
		["v"]="ff206080",
		["?"]="ff800000",
	}

	local fateString={["a"]="Auction", ["v"]="Vendor", ["d"]="Disenchant"}



	local costFilterMenu = {
	}

	local costFilterParameters = {
		hideUnprofitable = {
			label = "Hide Unprofitable",
			enabled = false,
			func = function(entry)
				return (entry.value or 0) < (entry.cost or 0)
			end,
		},
	}





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

	local function columnTooltip(cellFrame, text)
		GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(text,1,1,1,true)

		GameTooltip:AddLine("Left-click to Sort")
		GameTooltip:AddLine("Right-click to Adjust Filterings")

		GameTooltip:Show()
	end


	local valueColumnHeader = {
		name = "Value",
		width = 50,
		headerAlign = "CENTER",
		align = "RIGHT",
		font = "GameFontHighlightSmall",
--		filterMenu = costFilterMenu,
		sortCompare = function(a,b)
			return (a.value or 0) - (b.value or 0)
		end,
		draw = function (rowFrame, cellFrame, entry)
			if not entry.subGroup then
				local itemFate = entry.fate or "?"
				local costAmount = entry.cost
				local valueAmount = entry.value

				local itemFateString = string.format("|c%s%s|r", itemFateColor[itemFate], itemFate)
				local hilight = (costAmount or 0) < (valueAmount or 0)
				local valueText

				if itemFate == "a" and itemCache[itemID] and itemCache[itemID].BOP then
					valueText = BOP_STRING
				elseif itemFate == "d" and itemCache[itemID] and not itemCache[itemID].disenchantValue then
					valueText = NO_DE_STRING
				else
					if LSWConfig.valueAsPercent then
						if (costAmount > 0 and valueAmount >= 0) then
							local per = valueAmount / costAmount

							if per < .1 then
								per = math.floor(per*1000)/10
								valueText = string.format("%2.1f%%",per)
							elseif per > 10 then
								per = math.floor(per*10)/10
								valueText = string.format("%2.1fx",per)
							else
								per = math.floor(per*100)
								valueText = per.."%"
							end

							if (hilight) then
								valueText = "|cffd0d0d0"..valueText..itemFateString
							else
								valueText = "|cffd02020"..valueText..itemFateString
							end

						elseif (valueAmount >= 0) then
							valueText = "inf"..itemFateString
						end
					else
						if LSWConfig.singleColumn then
							valueText = (LSW:FormatMoney((valueAmount or 0) - (costAmount or 0),hilight) or "--")..itemFateString
						else
							if valueAmount < 0 then
								valueText = "   --"..itemFateString
							else
								valueText = (LSW:FormatMoney(valueAmount,hilight) or "--")..itemFateString
							end
						end
					end
				end


				cellFrame.text:SetText(valueText)
			else
				cellFrame.text:SetText("")
			end
		end,
		OnClick = function (cellFrame, button, source)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.valueButton.OnClick(cellFrame, button)
			else
				columnControl(cellFrame, button, source)
			end
		end,
		OnEnter = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.valueButton.OnEnter(cellFrame)
			else
				columnTooltip(cellFrame, "LSW Skill Value")
			end
		end,
		OnLeave = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.valueButton.OnLeave(cellFrame)
			else
				GameTooltip:Hide()
			end
		end,

		enabled = function()
			return GnomeWorks.tradeID ~= 53428
		end,
	}



	local costColumnHeader = {
		name = "Cost",
		width = 50,
		headerAlign = "CENTER",
		align = "RIGHT",
		font = "GameFontHighlightSmall",
		filterMenu = costFilterMenu,
		sortCompare = function(a,b)
			return (a.cost or 0) - (b.cost or 0)
		end,
		draw = function (rowFrame, cellFrame, entry)
			if not entry.subGroup then
				cellFrame.text:SetText((LSW:FormatMoney(entry.cost,false) or "").."  ")
			else
				cellFrame.text:SetText("")
			end
		end,
		OnClick = function (cellFrame, button, source)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.costButton.OnClick(cellFrame, button)
			else
				columnControl(cellFrame,button,source)
			end
		end,
		OnEnter = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.costButton.OnEnter(cellFrame)
			else
				columnTooltip(cellFrame, "LSW Skill Cost")
			end
		end,
		OnLeave = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
				cellFrame:SetID(entry.index)
				LSW.buttonScripts.costButton.OnLeave(cellFrame)
			else
				GameTooltip:Hide()
			end
		end,

		enabled = function()
			return GnomeWorks.tradeID ~= 53428 and not LSWConfig.singleColumn
		end,
	}



	local function ReagentCost_Tooltip(itemID, numNeeded)
		local LSWTooltip = GameTooltip

		LSWTooltip:SetOwner(LSW.parentFrame, "ANCHOR_NONE")
		LSWTooltip:SetPoint("BOTTOMLEFT", LSW.parentFrame, "BOTTOMRIGHT")

		local total = 0

		local pad = ""


		LSWTooltip:AddLine("Cost Breakdown for "..GetItemInfo(itemID))

		local residualMaterials = {}

		local total = LSW.buttonScripts.CostButton_AddItem(itemID, numNeeded, 1, residualMaterials)

		if LSWConfig.costBasis == COST_BASIS_PURCHASE then
			LSWTooltip:AddDoubleLine("Total estimated purchase cost: ", LSW:FormatMoney(total,true).."  ")
		else
			LSWTooltip:AddDoubleLine("Total estimated reagent value: ", LSW:FormatMoney(total,true).."  ")
		end

		local residualsShow

		for residualID, residualCount in pairs(residualMaterials) do
			if residualCount > 0 then
				residualsShow = true
			end
		end

		if residualsShow then
			local totalResidualValue = 0

			LSWTooltip:AddLine(" ")
			LSWTooltip:AddLine("Residual Reagents:")

			for residualID, residualCount in pairs(residualMaterials) do
				if residualCount > 0.001 then
					local residualValue
					local _, reagentName = GetItemInfo(residualID)

					if LSWConfig.residualPricing == COST_BASIS_RESALE then
						LSW.UpdateItemValue(residualID)
						residualValue = itemCache[residualID].bestValue * residualCount
						LSWTooltip:AddDoubleLine("    "..reagentName.." x "..residualCount, LSW:FormatMoney(residualValue, true)..(itemCache[residualID].fate or "?"))
					else
						LSW.UpdateItemCost(residualID)
						residualValue = itemCache[residualID].bestCost * residualCount
						LSWTooltip:AddDoubleLine("    "..reagentName.." x "..residualCount, LSW:FormatMoney(residualValue, true)..(itemCache[residualID].source or "?"))
					end

					totalResidualValue = totalResidualValue + residualValue
				end
			end

			LSWTooltip:AddDoubleLine("Total residual reagent value: ", LSW:FormatMoney(totalResidualValue,true).."  ")
		end

		LSWTooltip:Show()

		return total
	end


	local reagentCostColumnHeader = {
		name = "Cost",
		width = 50,
		headerAlign = "CENTER",
		align = "RIGHT",
		font = "GameFontHighlightSmall",
--		filterMenu = costFilterMenu,
		sortCompare = function(a,b)
			return (a.cost or 0) - (b.cost or 0)
		end,
		draw = function (rowFrame, cellFrame, entry)
			if not entry.subGroup then
				cellFrame.text:SetText((LSW:FormatMoney(entry.cost,true) or "").."  ")
			else
				cellFrame.text:SetText("")
			end
		end,
		OnClick = function (cellFrame, button, source)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
--				cellFrame:SetID(entry.skillIndex)
--				LSW.buttonScripts.costButton.OnClick(cellFrame, button)
			else
				columnControl(cellFrame,button,source)
			end
		end,
		OnEnter = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data

				ReagentCost_Tooltip(entry.id, entry.numNeeded)

--				cellFrame:SetID(entry.skillIndex)
--				LSW.buttonScripts.costButton.OnEnter(cellFrame)
			else
				columnTooltip(cellFrame, "LSW Reagent Cost")
			end
		end,
		OnLeave = function (cellFrame)
			if cellFrame:GetParent().rowIndex>0 then
				local entry = cellFrame:GetParent().data
--				cellFrame:SetID(entry.skillIndex)
--				LSW.buttonScripts.costButton.OnLeave(cellFrame)
			else
				GameTooltip:Hide()
			end
		end,
	}


	local function updateData(scrollFrame, entry)
		local skillName, skillType, itemLink, recipeLink, itemID, recipeID = LSW:GetTradeSkillData(entry.index)

		if skillType ~= "header" then
			entry.value, entry.fate = LSW:GetSkillValue(recipeID, globalFate)
			entry.cost = LSW:GetSkillCost(recipeID)
		end
	end


	local function updateReagentData(scrollFrame, entry)
		entry.cost = LSW:GetItemCost(entry.id) * entry.numNeeded
--[[
		local skillName, skillType, itemLink, recipeLink, itemID, recipeID = LSW:GetTradeSkillData(entry.skillIndex)

		if skillType ~= "header" then
			entry.value, entry.fate = LSW:GetSkillValue(recipeID, globalFate)
			entry.cost = LSW:GetSkillCost(recipeID)
		end
]]
	end


	local function refreshWindow()
		if LSWConfig.singleColumn then
			valueColumn.name = "Profit"
		else
			valueColumn.name = "Value"
		end

		scrollFrame:Refresh()
		reagentScrollFrame:Refresh()
	end


	local function Init()
--		LSW:ChatMessage("LilSparky's Workshop plugging into Skillet (v"..Skillet.version..")");





		scrollFrame = GnomeWorks:GetSkillListScrollFrame()

		scrollFrame:RegisterRowUpdate(updateData, pluginToken)

		valueColumn = scrollFrame:AddColumn(valueColumnHeader, pluginToken)
		costColumn = scrollFrame:AddColumn(costColumnHeader, pluginToken)

		GnomeWorks:CreateFilterMenu(costFilterParameters, costFilterMenu, costColumnHeader)



		reagentScrollFrame = GnomeWorks:GetReagentListScrollFrame()
		reagentScrollFrame:RegisterRowUpdate(updateReagentData, pluginToken)

		reagentCostColumn = reagentScrollFrame:AddColumn(reagentCostColumnHeader, pluginToken)

--		GnomeWorks:CreateFilterMenu(costFilterParameters, reagentCostFilterMenu, reagentCostColumnHeader)



		itemCache = LSW.itemCache


		LSW.parentFrame = GnomeWorks:GetMainFrame()

		LSW.RefreshWindow = refreshWindow

	end


	local function Test()
		if GnomeWorks then
			return true
		end

		return false
	end


	LSW:RegisterFrameSupport("GnomeWorks", Test, Init)
end


pluginToken = GnomeWorks:RegisterPlugin("LilSparky's Workshop", "LSW", RegisterWithLSW)


