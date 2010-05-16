



--[[

	queueData[player] = {
		[1] = { command = "iterate", count = count, recipeID = recipeID }
	}





]]






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


	local queueFrame


	local queueColors = {
		needsMaterials = {1,0,0},
		needsVendor = {0,1,0},
		needsCrafting = {0,1,1}
	}


	local columnHeaders = {
		{
			["name"] = "#",
			["align"] = "CENTER",
			["width"] = 30,
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["font"] = "GameFontHighlightSmall",
			["dataField"] = "count",
			["OnEnter"] = function(cellFrame, button)
								local rowFrame = cellFrame:GetParent()
								if rowFrame.rowIndex>0 then
									local entry = rowFrame.data

									if entry and entry.needsMaterials then
										GameTooltip:SetOwner(rowFrame, "ANCHOR_TOPRIGHT")
										GameTooltip:ClearLines()

										GameTooltip:AddLine("missing reagent",1,0,0)

										GameTooltip:Show()
									end
								end
							end,
			["OnLeave"] = function()
							GameTooltip:Hide()
						end,
			["draw"] =	function (rowFrame,cellFrame,entry)
							if entry.needsMaterials then
								cellFrame.text:SetTextColor(1,0,0)
							else
								cellFrame.text:SetTextColor(1,1,1)
							end

							cellFrame.text:SetText(entry.count)
						end,
		}, -- [1]
		{
--			["font"] = "GameFontHighlight",
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
										if entry.tradeID and entry.recipeID then
											GnomeWorks:SelectRecipe(entry.tradeID, entry.recipeID)
										end
									end
								end
							end,
			["draw"] =	function (rowFrame,cellFrame,entry)
							cellFrame.data = entry

							local texExpanded = "|TTexturePath:Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga:0|t"
							local texClosed = "|TTexturePath:Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga:0|t"

							cellFrame.text:SetPoint("LEFT", cellFrame, "LEFT", entry.depth*16+4, 0)
							cellFrame.text:SetPoint("RIGHT", cellFrame, "RIGHT", -4, 0)

							local needsScan = GnomeWorks.data.recipeDB[entry.recipeID]==nil


							local tex = ""

							if entry.subGroup then
								if entry.subGroup.expanded then
									tex = "+ " -- texExpanded
								else
									tex = "-  " -- texClosed
								end
							end

							if entry.command == "process" then

								cellFrame.text:SetFormattedText("%sProcess %s",tex,(GetSpellInfo(entry.recipeID)))


								if needsScan then
									cellFrame.text:SetTextColor(1,0,0, (entry.manualEntry and 1) or .75)
								else
									cellFrame.text:SetTextColor(.3,1,1, (entry.manualEntry and 1) or .75)
								end
							elseif entry.command == "purchase" then
								cellFrame.text:SetFormattedText("%sPurchase %s", tex,(GetItemInfo(entry.itemID)))

								if GnomeWorks:VendorSellsItem(entry.itemID) then
									cellFrame.text:SetTextColor(0,.7,0)
								else
									cellFrame.text:SetTextColor(.7,.7,0)
								end
							elseif entry.command == "needs" then
								cellFrame.text:SetFormattedText("%sRequires %s", tex,(GetItemInfo(entry.itemID)))
								cellFrame.text:SetTextColor(.8,.25,.8)
							end
						end,
		}, -- [2]
	}




	local function ResizeMainWindow()
	end



	local function BuildScrollingTable()

		local function ResizeQueueFrame(scrollFrame,width,height)
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

		queueFrame = CreateFrame("Frame",nil,frame)
		queueFrame:SetPoint("BOTTOMLEFT",20,40)
		queueFrame:SetPoint("TOP", frame, 0, -35)
		queueFrame:SetPoint("RIGHT", frame, -20,0)

--		GnomeWorks.queueFrame = queueFrame

		sf = GnomeWorks:CreateScrollingTable(queueFrame, ScrollPaneBackdrop, columnHeaders, ResizeQueueFrame)

--		sf.childrenFirst = true

--[[
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
]]

--[[
		sf.UpdateRowData = function(scrollFrame,entry)
			if not entry.subGroup then
				local bag,vendor,bank,alts = GnomeWorks:InventoryRecipeIterations(entry.recipeID)

				entry.craftBag = bag
				entry.craftVendor = vendor
				entry.craftBank = bank
				entry.craftAlt = alts
			end
		end
]]


	end


	local function QueueCommandIterate(tradeID, recipeID, count)
		local entry = { command = "iterate", count = count, tradeID = tradeID, recipeID = recipeID }

		return entry
	end



	function GnomeWorks:AddToQueue(player, tradeID, recipeID, count)
		if not self.data.queueData[player] then
			self.data.queueData[player] = {}
		end

		local queueData = self.data.queueData[player]

		for i=1,#queueData do
			if queueData[i].recipeID == recipeID then
				if queueData[i].command == "iterate" then
					queueData[i].count = queueData[i].count + count

					self:ShowQueueList()

					return
				end
			end
		end


		table.insert(self.data.queueData[player], QueueCommandIterate(tradeID, recipeID, count))

		self:ShowQueueList()
	end


	local function AddPurchaseToConstructionQueue(itemID, count, data)

		for i=1,#data do
			if data[i].itemID == itemID then
				data[i].count = data[i].count + count

				return data[i], count
			end
		end

		local newEntry = { command = "purchase", itemID = itemID, count = count}

		data[#data + 1] = newEntry

		return newEntry, count
	end


	local function AddRecipeToConstructionQueue(tradeID, recipeID, count, data, needsMaterials, needsVendor, needsCrafting)
		for i=1,#data do
			if data[i].recipeID == recipeID then
				data[i].count = data[i].count + count
				data[i].needsMaterials = data[i].needsMaterials or needsMaterials
				data[i].needsVendor = data[i].needsVendor or needsVendor
				data[i].needsCrafting = data[i].needsCrafting or needsCrafting

				return data[i], count
			end
		end

		local newEntry = { command = "process", tradeID = tradeID, recipeID = recipeID, count = count, needsMaterials = needsMaterials, needsCrafting = needsCrafting, needsVendor = needsVendor }

		data[#data + 1] = newEntry

		return newEntry, count
	end


	local recursionLimiter = {}
	local cooldownUsed = {}

	local function AddToConstructionQueue(player, tradeID, recipeID, count, data, primary)
		if not recipeID then return nil, 0 end

		if recursionLimiter[recipeID] then return nil, 0 end

		local cooldownGroup = GnomeWorks:GetSpellCooldownGroup(recipeID)

		if cooldownGroup then
			if cooldownUsed[cooldownGroup] then
				return nil, 0
			end

			cooldownUsed[cooldownGroup] = true
		end


		recursionLimiter[recipeID] = true

		local needsMaterials
		local needsCrafting
		local needsVendor

		local recipeData = GnomeWorks.data.recipeDB
		local itemSourceData = GnomeWorks.data.itemSource
		local reagentUsageData = GnomeWorks.data.reagentUsage

		local numCraftable = count

		local subGroup

		local newEntry = AddRecipeToConstructionQueue(tradeID, recipeID, count, data)

		if recipeData[recipeID] then
			for r,reagentInfo in pairs(recipeData[recipeID].reagentData) do
				local inBags = GnomeWorks:GetInventoryCount(reagentInfo.id, player, "bag")


				local inQueue = count * reagentInfo.numNeeded

--print((GetItemInfo(reagentInfo.id)), inBags, inQueue)

				if inQueue > inBags then

					if not newEntry.subGroup then
						newEntry.subGroup = { expanded = false, entries = {} }
					end

					needsMaterials = true

					local childRecipe = itemSourceData[reagentInfo.id]

					if childRecipe then
						local optionGroup = { command = "needs", itemID = reagentInfo.id, count = inQueue-inBags, subGroup = { entries = {}, expanded = false }}

						table.insert(newEntry.subGroup.entries, optionGroup)

						numCraftable = math.min(numCraftable, inBags / reagentInfo.numNeeded)
						AddPurchaseToConstructionQueue(reagentInfo.id, inQueue - inBags, optionGroup.subGroup.entries)

						if type(childRecipe) == "table" then
							for childRecipe in pairs(childRecipe) do
								local childData = GnomeWorks.data.recipeDB[childRecipe]
								local numMade = (childData and childData.numMade) or 1

								local newEntry, numQueued = AddToConstructionQueue(player, childData and childData.tradeID, childRecipe, math.ceil((inQueue - inBags) / numMade), optionGroup.subGroup.entries)

								numCraftable = math.min(numCraftable, (inBags + numQueued * numMade) / reagentInfo.numNeeded)
							end
						else
							local childData = GnomeWorks.data.recipeDB[childRecipe]
							local numMade = (childData and childData.numMade) or 1

							local _, numQueued = AddToConstructionQueue(player, childData and childData.tradeID, childRecipe, math.ceil((inQueue - inBags) / numMade), optionGroup.subGroup.entries)

							numCraftable = math.min(numCraftable, (inBags + numQueued * numMade) / reagentInfo.numNeeded)
						end
						needsCrafting = true
					else
						if GnomeWorks:VendorSellsItem(reagentInfo.id) then
							needsVendor = true
						end

						numCraftable = math.min(numCraftable, inBags / reagentInfo.numNeeded)
						AddPurchaseToConstructionQueue(reagentInfo.id, inQueue - inBags, newEntry.subGroup.entries)
					end
				end
			end
		end

		newEntry.needsMaterials = needsMaterials
		newEntry.needsVendor = needsVendor
		newEntry.needsCrafting = needsCrafting

--[[
		if count > 0 then
			recursionLimiter[recipeID] = nil

			if cooldownGroup then
				cooldownUsed[cooldownGroup] = nil
			end

			local newEntry, count =  AddRecipeToConstructionQueue(tradeID, recipeID, count, data, needsMaterials, needsVendor, needsCrafting)

			if subGroup then
				newEntry.subGroup = subGroup
			end

			return newEntry, count
		end
]]

		if cooldownGroup then
			cooldownUsed[cooldownGroup] = nil
		end

		recursionLimiter[recipeID] = nil
		return newEntry, count
	end



	local function CreateConstructionQueue(player, queue, data)
		if queue then
			for i=1,#queue do

				local entry = AddToConstructionQueue(player, queue[i].tradeID, queue[i].recipeID, queue[i].count, data, true)

				if entry then
					entry.manualEntry = i
				end
			end

			sf.numData = #data
		else
			sf.numData = 0
		end
	end



	function GnomeWorks:ShowQueueList(player)
		player = player or self.player

		if player then
			frame.playerNameFrame:SetFormattedText("%s Queue",player)

			local queue = self.data.queueData[player]

			self.data.constructionQueue[player] = table.wipe(self.data.constructionQueue[player] or {})

			if not sf.data then
				sf.data = {}
			end

			CreateConstructionQueue(player, queue, self.data.constructionQueue[player])

			sf.data.entries = self.data.constructionQueue[player]

			sf:Refresh()
			sf:Show()
			frame:Show()

			frame:SetToplevel(true)
		end
	end




	local function CreateControlButtons(frame)

		local function ProcessQueue()

		end


		local function ClearQueue()
			table.wipe(GnomeWorks.data.queueData[GnomeWorks.player])

			GnomeWorks:ShowQueueList(GnomeWorks.player)
		end


		local buttons = {
			{ label = "Process",  operation = ProcessQueue},
			{ label = "Clear", operation = ClearQueue },
		}

		local position = 0

		controlFrame = CreateFrame("Frame", nil, frame)

		controlFrame:SetHeight(20)
		controlFrame:SetWidth(200)

		controlFrame:SetPoint("TOP", queueFrame, "BOTTOM", 0, 1)

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



	function GnomeWorks:CreateQueueWindow()
		frame = self.Window:CreateResizableWindow("GnomeWorksQueueFrame", nil, 200, 300, ResizeMainWindow, GnomeWorksDB.config)


		frame:SetMinResize(200,100)

		BuildScrollingTable()

		local playerName = CreateFrame("Button", nil, frame)

		playerName:SetWidth(240)
		playerName:SetHeight(16)
		playerName:SetText("UNKNOWN")
		playerName:SetPoint("TOP",frame,"TOP",0,-10)

		playerName:SetNormalFontObject("GameFontNormal")
		playerName:SetHighlightFontObject("GameFontHighlight")

--		playerName:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Opaque")

		playerName:EnableMouse(false)


--		playerName:RegisterForClicks("AnyUp")

--		playerName:SetScript("OnClick", self.SelectTradeLink)

		playerName:SetFrameLevel(playerName:GetFrameLevel()+1)


		frame.playerNameFrame = playerName


--		frame:SetParent(self.MainWindow)


		CreateControlButtons(frame)

		return frame
	end

end

