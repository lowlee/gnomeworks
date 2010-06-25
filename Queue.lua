



--[[

	queueData[player] = {
		[1] = { command = "iterate", count = count, recipeID = recipeID }
	}





]]



local LARGE_NUMBER = 1000000


do
	local frame
	local sf

	local doTradeEntry


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


	local inventoryIndex = { "bag", "vendor", "bank", "guildBank", "alt" }

	local inventoryColors = {
--		queue = "|cffff0000",
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


	local queueFrame

	local queuePlayer



	local queueColors = {
		needsMaterials = {1,0,0},
		needsVendor = {0,1,0},
		needsCrafting = {0,1,1}
	}


	local columnHeaders = {
		{
			name = "#",
			align = "CENTER",
			width = 30,
			font = "GameFontHighlightSmall",
			OnClick = function(cellFrame, button, source)
							local rowFrame = cellFrame:GetParent()
							if rowFrame.rowIndex>0 then
								local entry = rowFrame.data

								if entry.manualEntry then
									if button == "RightButton" then
										entry.count = entry.count - 1
									else
										entry.count = entry.count + 1
									end

									if entry.count < 0 then
										entry.count = 0
									end


									GnomeWorks:ShowQueueList()
								end
							end
						end,
			OnEnter = function(cellFrame, button)
							local rowFrame = cellFrame:GetParent()
							if rowFrame.rowIndex>0 then
								local entry = rowFrame.data

								if entry and entry.count then
									GameTooltip:SetOwner(rowFrame, "ANCHOR_TOPRIGHT")
									GameTooltip:ClearLines()


									if entry.command == "process" then
--		print("proc",entry.numAvailable, entry.count)
										GameTooltip:AddLine(GetSpellLink(entry.recipeID))

										if entry.numAvailable < entry.count then
											if entry.inQueue > entry.numAvailable then
												GameTooltip:AddLine("Requires craftable reagents",1,1,0)
											elseif entry.numAvailable < 1 then
												GameTooltip:AddLine("No available reagents",1,0,0)
											else
												GameTooltip:AddLine(string.format("Only enough reagents for %d iterations",entry.numAvailable),.8,.8,0)
											end
										else
											GameTooltip:AddLine(string.format("%d craftable",entry.numAvailable))
										end
									elseif entry.command == "purchase" then
										GameTooltip:AddLine(select(2,GetItemInfo(entry.itemID)))

										if entry.numAvailable < entry.count then
											local prevCount = 0
											GameTooltip:AddLine("Current Stock:",1,1,1)

											if entry.inQueue < 0 then
												GameTooltip:AddDoubleLine("|cffff0000Required by Queue:",-1.0 * entry.inQueue)
											elseif entry.inQueue > 0 then
												GameTooltip:AddDoubleLine("|cffffffffProduced by Queue:",entry.inQueue)
											end

											for i,key in pairs(inventoryIndex) do
												local count = entry[key] or 0

												if count ~= prevCount then
													GameTooltip:AddDoubleLine(inventoryTags[key],count)
													prevCount = count
												end
											end
										end
									end

									GameTooltip:Show()
								end
							end
						end,
			OnLeave = function()
							GameTooltip:Hide()
						end,
			draw =	function (rowFrame,cellFrame,entry)
--print(entry.manualEntry,entry.command, entry.recipeID or entry.itemID, entry.count, entry.numAvailable)
							if entry.count > entry.numAvailable then
								if entry.numAvailable < 1 then
									cellFrame.text:SetTextColor(1,0,0)
								else
									cellFrame.text:SetTextColor(.8,.8,0)
								end
							else
								cellFrame.text:SetTextColor(1,1,1)
							end

							if entry.command == "purchase" then
--print(entry.count, entry.numAvailable)
								cellFrame.text:SetText(math.max(entry.count - entry.numAvailable,0))
							else
								cellFrame.text:SetText(entry.count)
							end
						end,
		}, -- [1]
		{
--			font = "GameFontHighlight",
			button = {
				normalTexture = "Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga",
				highlightTexture = "Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga",
				width = 14,
				height = 14,
			},
			name = "Recipe",
			width = 250,
			OnClick = function(cellFrame, button, source)
							if cellFrame:GetParent().rowIndex>0 then
								local entry = cellFrame:GetParent().data

								if entry.subGroup and source == "button" then
									entry.subGroup.expanded = not entry.subGroup.expanded
									sf:Refresh()
								else
									if entry.recipeID then
										GnomeWorks:PushSelection()
										GnomeWorks:SelectRecipe(entry.recipeID)
									end
								end
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
								end
							end
						end,
			draw =	function (rowFrame,cellFrame,entry)
						cellFrame.text:SetPoint("LEFT", cellFrame, "LEFT", entry.depth*8+4+12, 0)
						local craftable

						if entry.subGroup and entry.count > entry.numAvailable then
							if entry.subGroup.expanded then
								cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
								cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_open.tga")
							else
								cellFrame.button:SetNormalTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
								cellFrame.button:SetHighlightTexture("Interface\\AddOns\\GnomeWorks\\Art\\expand_arrow_closed.tga")
							end

--							cellFrame.text:SetFormattedText("%s (%d Recipes)",entry.name,#entry.subGroup.entries)
							cellFrame.button:Show()

							craftable = true
						else
							cellFrame.button:Hide()
						end

						local needsScan = GnomeWorksDB.results[entry.recipeID]==nil

						if entry.manualEntry then
							cellFrame.text:SetFontObject("GameFontHighlight")
						else
							cellFrame.text:SetFontObject("GameFontHighlightsmall")
						end



						if entry.command == "process" then
							local name, rank, icon = GnomeWorks:GetTradeInfo(entry.tradeID)

							if entry.manualEntry then
								if entry.sourcePlayer then
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s (%s)",icon or "",GnomeWorks:GetRecipeName(entry.recipeID), entry.sourcePlayer)
								else
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s",icon or "",GnomeWorks:GetRecipeName(entry.recipeID))
								end
							else

								cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |cffd0d090%s: %s",icon or "",GnomeWorks:GetTradeName(entry.tradeID),GnomeWorks:GetRecipeName(entry.recipeID))
							end
--[[
							if needsScan then
								cellFrame.text:SetTextColor(1,0,0, (entry.manualEntry and 1) or .75)
							elseif entry.manualEntry then
								cellFrame.text:SetTextColor(1,1,1,1)
							else
								cellFrame.text:SetTextColor(.3,1,1,.75)
							end
]]

						elseif entry.command == "purchase" then

							local itemName = GetItemInfo(entry.itemID)

							if craftable and entry.subGroup.expanded then
								cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |ca040ffffCraft|r |cffc0c0c0%s",GetItemIcon(entry.itemID) or "",itemName)
							else
								local c = "|cffb0b000"

								if GnomeWorks:VendorSellsItem(entry.itemID) then
									c = "|cff00b000"
								end



								cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %sPurchase|r |cffc0c0c0%s", GetItemIcon(entry.itemID) or "",c,itemName)
							end
--[[
							if GnomeWorks:VendorSellsItem(entry.itemID) then
								cellFrame.text:SetTextColor(0,.7,0)
							else
								cellFrame.text:SetTextColor(.7,.7,0)
							end
]]
						elseif entry.command == "needs" then
							cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s", GetItemIcon(entry.itemID),(GetItemInfo(entry.itemID)))
							cellFrame.text:SetTextColor(.8,.25,.8)
						end
					end,
		}, -- [2]
	}




	local function ResizeMainWindow()
	end


	local function ReserveReagentsIntoQueue(queue)
		if queue then
			for k,entry in ipairs(queue) do
				if entry.command == "process" then
					for itemID,numNeeded in pairs(GnomeWorksDB.reagents[entry.recipeID]) do
						GnomeWorks:ReserveItemForQueue(queuePlayer, itemID, numNeeded * entry.count)
					end

					for itemID,numMade in pairs(GnomeWorksDB.results[entry.recipeID]) do
						GnomeWorks:ReserveItemForQueue(queuePlayer, itemID, -numMade * entry.count)
					end

					if entry.subGroup then
						ReserveReagentsIntoQueue(entry.subGroup.entries)
					end
				elseif entry.command == "purchase" then
					if entry.subGroup and entry.subGroup.expanded then
						ReserveReagentsIntoQueue(entry.subGroup.entries)
					else
--						GnomeWorks:ReserveItemForQueue(queuePlayer, entry.itemID, entry.count)
					end
				end

--				if entry.subGroup and entry.manualEntry then
--					ReserveReagentsIntoQueue(entry.subGroup.entries)
--				end
			end
		end
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
		queueFrame:SetPoint("TOP", frame, 0, -45)
		queueFrame:SetPoint("RIGHT", frame, -20,0)

--		GnomeWorks.queueFrame = queueFrame

		sf = GnomeWorks:CreateScrollingTable(queueFrame, ScrollPaneBackdrop, columnHeaders, ResizeQueueFrame)

--		sf.childrenFirst = true

		sf.IsEntryFiltered = function(self, entry)
			if entry.manualEntry then return false end

			if entry.command == "purchase" and entry.numAvailable < entry.count then
--print(entry.manualEntry, entry.numAvailable, entry.count)
--print("fitlered out", entry.command, entry.recipeID and GetSpellLink(entry.recipeID) or entry.itemID and GetItemInfo(entry.itemID))

				return true
			else
				return false
			end
		end

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

		local function UpdateRowData(scrollFrame,entry,firstCall)
			local player = queuePlayer
--print("update row data", entry.command, entry.recipeID and GetSpellLink(entry.recipeID) or entry.itemID and GetItemInfo(entry.itemID))
			if firstCall then
				GnomeWorks.data.inventoryData[player].queue = table.wipe(GnomeWorks.data.inventoryData[player].queue or {})

				ReserveReagentsIntoQueue(GnomeWorks.data.constructionQueue[player])
			end

			if entry.command == "purchase" then
				entry.numAvailable = GnomeWorks:GetInventoryCount(entry.itemID, player, "bag")
				entry.inQueue = GnomeWorks:GetInventoryCount(entry.itemID, player, "queue")
				entry.bank = GnomeWorks:GetInventoryCount(entry.itemID, player, "bank")
				entry.guildBank = GnomeWorks:GetInventoryCount(entry.itemID, player, "guildBank")
				entry.alt = GnomeWorks:GetInventoryCount(entry.itemID, "faction", "bank")
			end

			if entry.command == "process" then
				local count = entry.count
--				local inBag = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag")
--				local inQueue = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag queue")

				entry.inQueue = GnomeWorks:GetInventoryCount(entry.itemID, player, "bag queue")
				entry.numAvailable = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag")
--print(GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag"), GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag queue"), count)
--[[

]]

			end

			if entry.numAvailable >= entry.count then
				if entry.subGroup then
					entry.subGroup.expanded = false
				end
			end

--print("done updating")
		end


		sf:RegisterRowUpdate(UpdateRowData)
	end


	local function QueueCommandIterate(tradeID, recipeID, count)
		local entry = { command = "iterate", count = count, tradeID = tradeID, recipeID = recipeID }

		return entry
	end






	local function AddPurchaseToConstructionQueue(itemID, count, data, sourcePlayer, overRide)
		for i=1,#data do
			if data[i].itemID == itemID then
				local addedToQueue

				if overRide then
					addedToQueue = data[i].count - count
					data[i].count = count
				else
					addedToQueue = count
					data[i].count = data[i].count + count
				end

				return data[i], data[i].count
			end
		end

		local newEntry = { index = #data+1, command = "purchase", itemID = itemID, count = count, sourcePlayer = sourcePlayer}

		data[#data + 1] = newEntry

		return newEntry, count
	end


	local function AddRecipeToConstructionQueue(tradeID, recipeID, count, data, sourcePlayer, overRide)

		for i=1,#data do
			if data[i].recipeID == recipeID then
				local addedToQueue

				if overRide then
					addedToQueue = count - data[i].count
					data[i].count = count
				else
					addedToQueue = count
					data[i].count = data[i].count + count
				end

				return data[i], data[i].count
			end
		end



		local newEntry = { index=#data+1, command = "process", tradeID = tradeID, recipeID = recipeID, count = count, sourcePlayer = sourcePlayer }

		data[#data + 1] = newEntry

		return newEntry, count
	end



	local function ZeroConstructionQueue(queue)
		if queue then
			for k,q in pairs(queue) do
				q.count = 0

				if q.subGroup then
					ZeroConstructionQueue(q.subGroup.entries)
				end
			end
		end
	end



	local recursionLimiter = {}
	local cooldownUsed = {}

	local function AddToConstructionQueue(player, tradeID, recipeID, count, data, sourcePlayer, primary, overRide)
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

		local reagents = GnomeWorksDB.reagents
		local results = GnomeWorksDB.results
		local tradeIDs = GnomeWorksDB.tradeIDs

		local itemSourceData = GnomeWorks.data.itemSource
		local reagentUsageData = GnomeWorks.data.reagentUsage

		local subGroup

--		local craftable = GnomeWorks:InventoryRecipeIterations(recipeID, player, "bag")

		local newEntry, newCount = AddRecipeToConstructionQueue(tradeID, recipeID, count, data, sourcePlayer, overRide)

		newEntry.manualEntry = primary
		newEntry.noHide = primary and true

		if  reagents[recipeID] then
			for reagentID, numNeeded in pairs(reagents[recipeID]) do
--				local inBags = GnomeWorks:GetInventoryCount(reagentID, player, "bag")


				local inQueue = newCount * numNeeded

--print((GetItemInfo(reagentInfo.id)), inBags, inQueue)
				if not newEntry.subGroup then
					newEntry.subGroup = { expanded = false, entries = {} }
				end

				local purchase = AddPurchaseToConstructionQueue(reagentID, inQueue, newEntry.subGroup.entries, sourcePlayer, true)			-- last arg true means set count instead of adding

				local source = itemSourceData[reagentID]

				if source then


--						local optionGroup = { index = 1, command = "needs", itemID = reagentID, count = inQueue, subGroup = { entries = {}, expanded = false }}

--						table.insert(newEntry.subGroup.entries, optionGroup)

--						AddPurchaseToConstructionQueue(reagentID, inQueue, optionGroup.subGroup.entries)

					for sourceRecipeID,numMade in pairs(source) do
						if GnomeWorks:IsSpellKnown(sourceRecipeID) then
							if not purchase.subGroup then
								purchase.subGroup = { expanded = false, entries = {} }
							end

							AddToConstructionQueue(player, tradeIDs[sourceRecipeID], sourceRecipeID, math.ceil(inQueue / numMade), purchase.subGroup.entries, sourcePlayer, nil, true)
						end
					end

					if purchase.subGroup and #purchase.subGroup.entries == 0 then
						purchase.subGroup = nil
					end
--					needsCrafting = true
				else
--					AddPurchaseToConstructionQueue(reagentID, inQueue, newEntry.subGroup.entries)
				end
			end
		else
			if newEntry.subGroup then
				ZeroConstructionQueue(newEntry.subGroup.entries)
				newEntry.subGroup.expanded = false
			end
		end

--		newEntry.needsMaterials = needsMaterials
--		newEntry.needsVendor = needsVendor
--		newEntry.needsCrafting = needsCrafting

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

				local entry = AddToConstructionQueue(player, queue[i].tradeID, queue[i].recipeID, queue[i].count, data, queue[i].sourcePlayer, true)

				if entry then
					entry.manualEntry = i
					entry.noHide = true
				end
			end

			sf.numData = #data
		else
			sf.numData = 0
		end
	end


	local function AdjustConstructionQueueCounts(queue)
		if queue then
			local player = queuePlayer

			for k,q in pairs(queue) do
				AddToConstructionQueue(player, q.tradeID, q.recipeID, q.count, queue, q.sourcePlayer, true, true)
			end
		end
	end


	local function UpdateQueue(conQueue, queue)
		local player = queuePlayer

		GnomeWorks.data.inventoryData[player].queue = table.wipe(GnomeWorks.data.inventoryData[player].queue or {})

		if conQueue then
			for k,q in pairs(conQueue) do
				if not queue[k] then
					queue[k] = {}
				end

				queue[k].command = "iterate"
				queue[k].count = q.count
				queue[k].recipeID = q.recipeID
				queue[k].tradeID = q.tradeID
				queue[k].sourcePlayer = q.sourcePlayer
			end

			if queue then
				for i=#conQueue+1,#queue do
					queue[i] = nil
				end
			end

			AdjustConstructionQueueCounts(conQueue)
		end
	end


	function GnomeWorks:AddToQueue(player, tradeID, recipeID, count)
		local sourcePlayer

		if not self.data.playerData[player] then
			sourcePlayer = player
			player = queuePlayer
		end


		local queueData = self.data.constructionQueue[player]

--[[
		for i=1,#queueData do
			if queueData[i].recipeID == recipeID then
				if queueData[i].command == "process" then
					queueData[i].count = queueData[i].count + count

					self:ShowQueueList()

					return
				end
			end
		end


--		table.insert(self.data.queueData[player], QueueCommandIterate(tradeID, recipeID, count))
]]

		AddToConstructionQueue(player, tradeID, recipeID, count, queueData, sourcePlayer, true)

		self:ShowQueueList()
		self:ShowSkillList()

		self:SendMessageDispatch("GnomeWorksDetailsChanged")
	end


	function GnomeWorks:ShowQueueList(player)
		player = player or (self.data.playerData[self.player] and self.player) or UnitName("player")
		queuePlayer = player

		if player then
			frame.playerNameFrame:SetFormattedText("%s Queue",player)

			if not self.data.queueData[player] then
				self.data.queueData[player] = {}
			end

			local queue = self.data.queueData[player]


			if not self.data.constructionQueue[player] then
				self.data.constructionQueue[player] = {}

				GnomeWorks.data.inventoryData[player].queue = table.wipe(GnomeWorks.data.inventoryData[player].queue or {})

				CreateConstructionQueue(player, queue, self.data.constructionQueue[player])
			end

			if not sf.data then
				sf.data = {}
			end

			UpdateQueue(self.data.constructionQueue[player],queue)

			sf.data.entries = self.data.constructionQueue[player]

			sf:Refresh()
			sf:Show()
			frame:Show()

			frame:SetToplevel(true)
		end
	end


	local function FirstCraftableEntry(queue)
		for k,q in pairs(queue) do
			if q.command == "process" and q.numAvailable > 0 and q.count > 0 then
				return q
			end

			if q.subGroup then
				local f = FirstCraftableEntry(q.subGroup.entries)

				if f then return f end
			end
		end
	end

	local function DeleteQueueEntry(queue, entry)
		for k,q in pairs(queue) do
			if q == entry then
				table.remove(queue, k)
				return true
			end

			if q.subGroup then
				if DeleteQueueEntry(q.subGroup.entries, entry) then
					return true
				end
			end
		end
	end


	function GnomeWorks:SpellCastFailed(event,unit,spell,rank)
--print("SPELL CAST FAILED", ...)
		if unit == "player" then
			doTradeEntry = nil
		end
	end


	function GnomeWorks:SpellCastCompleted(event,unit,spell,rank)
--print("SPELL CAST COMPLETED", ...)

		if unit == "player"	and doTradeEntry then
			doTradeEntry.count = doTradeEntry.count - 1

			if doTradeEntry.count == 0 then
				DeleteQueueEntry(self.data.constructionQueue[queuePlayer], doTradeEntry)

				doTradeEntry = nil
			end

			self:ShowQueueList()
		end
	end



	local function CreateControlButtons(frame)
		local function ProcessQueue()
			local entry = FirstCraftableEntry(GnomeWorks.data.constructionQueue[queuePlayer])

			if entry then
				if GnomeWorks:IsPseudoTrade(entry.tradeID) then
					GnomeWorks:print(GnomeWorks:GetTradeName(entry.tradeID),"isn't functional yet.")
				else
--				print(entry.recipeID, GnomeWorks:GetRecipeName(entry.recipeID), entry.count, entry.numAvailable)
					if GetSpellLink((GetSpellInfo(entry.tradeID))) then
						if GnomeWorks:IsTradeSkillLinked() or GnomeWorks.player ~= UnitName("player") or GnomeWorks.tradeID ~= entry.tradeID then
							CastSpellByName((GetSpellInfo(entry.tradeID)))
						end

						local skillIndex

						local enchantString = "enchant:"..entry.recipeID.."|h"

						for i=1,GetNumTradeSkills() do
							local link = GetTradeSkillRecipeLink(i)

							if link and string.find(link, enchantString) then

								skillIndex = i
								break
							end
						end

						doTradeEntry = entry

						if skillIndex then
							GnomeWorks:print("executing ",GnomeWorks:GetRecipeName(entry.recipeID),"x",math.min(entry.count, entry.numAvailable))
							DoTradeSkill(skillIndex,math.min(entry.count, entry.numAvailable))
						else
							GnomeWorks:print("can't find recipe:",GnomeWorks:GetRecipeName(entry.recipeID))
						end

	--					GnomeWorks:ProcessRecipe(entry.tradeID, entry.recipeID, math.max(entry.count, entry.numAvailable))
					else
						GnomeWorks:print("can't process",GnomeWorks:GetRecipeName(entry.recipeID),"on this character")
					end
				end
			else
				GnomeWorks:print("nothing craftable")
			end
		end


		local function ClearQueue()
			table.wipe(GnomeWorks.data.constructionQueue[queuePlayer])
			table.wipe(GnomeWorks.data.inventoryData[queuePlayer]["queue"])

			GnomeWorks:ShowQueueList()
			GnomeWorks:ShowSkillList()
		end


		local function StopProcessing()
			StopTradeSkillRepeat()
		end


		local buttons = {
			{ label = "Process",  operation = ProcessQueue },
			{ label = "Stop", operation = StopProcessing },
			{ label = "Clear", operation = ClearQueue },
		}

		local position = 0

		controlFrame = CreateFrame("Frame", nil, frame)

		controlFrame:SetHeight(20)
		controlFrame:SetWidth(200)

		controlFrame:SetPoint("TOP", queueFrame, "BOTTOM", 0, -2)

		controlFrame.buttons = {}

		for i, config in pairs(buttons) do
			local newButton = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")

			newButton:SetPoint("LEFT", position,0)
			newButton:SetWidth(60)
			newButton:SetHeight(18)
			newButton:SetNormalFontObject("GameFontNormalSmall")
			newButton:SetHighlightFontObject("GameFontHighlightSmall")

			newButton:SetText(config.label)

			newButton:SetScript("OnClick", config.operation)

			position = position + 60

			controlFrame.buttons[i] = newButton
		end

		controlFrame:SetWidth(position)

		return controlFrame
	end



	function GnomeWorks:CreateQueueWindow()
		frame = self.Window:CreateResizableWindow("GnomeWorksQueueFrame", nil, 200, 300, ResizeMainWindow, GnomeWorksDB.config)

		frame:DockWindow(self.MainWindow)


		frame:SetMinResize(240,200)

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


		self:RegisterMessageDispatch("GnomeWorksInventoryScanComplete", function() if frame:IsShown() then GnomeWorks:ShowQueueList() end end)

		CreateControlButtons(frame)



		table.insert(UISpecialFrames, "GnomeWorksQueueFrame")

		frame:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen") end)
		frame:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)


		return frame
	end

end

