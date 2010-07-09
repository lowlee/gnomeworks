



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
--print(entry.manualEntry)

								if entry.manualEntry then
									if button == "RightButton" then
										entry.count = entry.count - 1
									else
										entry.count = entry.count + 1
									end

									if entry.count < 1 then
										entry.count = 1
									end

									GnomeWorks:SendMessageDispatch("GnomeWorksQueueChanged")
									GnomeWorks:SendMessageDispatch("GnomeWorksSkillListChanged")
									GnomeWorks:SendMessageDispatch("GnomeWorksDetailsChanged")

--									GnomeWorks:ShowQueueList()
								end
							end
						end,
			OnEnter = function(cellFrame, button)
							local rowFrame = cellFrame:GetParent()
							if rowFrame.rowIndex>0 then
								local entry = rowFrame.data

								if entry then
									GameTooltip:SetOwner(rowFrame, "ANCHOR_TOPRIGHT")
									GameTooltip:ClearLines()


									if entry.itemID then
										GameTooltip:AddLine(select(2,GetItemInfo(entry.itemID)))

										local required = entry.numNeeded
										local deficit = entry.inQueue

										if entry.command == "create" then
											local required = entry.inQueue
											local deficit = entry.numNeeded
										end

										if required>0 then
											local prevCount = 0

											GameTooltip:AddDoubleLine("Required", required)

											GameTooltip:AddLine("Current Stock:",1,1,1)

											for i,key in pairs(inventoryIndex) do
												if key ~= "vendor" then
													local count = entry[key] or 0

													if count ~= prevCount then
														GameTooltip:AddDoubleLine(inventoryTags[key],count)
														prevCount = count
													end
												end
											end

											if entry.command == "create" then
												if entry.numCraftable > 0 then
													GameTooltip:AddDoubleLine("craftable",entry.numCraftable * entry.results[entry.itemID])
													prevCount = entry.numCraftable * entry.results[entry.itemID]
												else
	--													GameTooltip:AddLine("None craftable")
												end
											end

											if prevCount == 0 then
	--												GameTooltip:AddLine("None available")
											end

											if prevCount ~= 0 then
												if deficit < 0 then
													GameTooltip:AddDoubleLine("|cffff0000total deficit:",math.abs(deficit))
												elseif deficit > 0 then
													GameTooltip:AddDoubleLine("|cfffffffftotal surplus:",deficit)
												end
											end
										end
									else
										GameTooltip:AddLine(GetSpellLink(entry.recipeID))
										GameTooltip:AddDoubleLine("Requested", entry.count)
										GameTooltip:AddDoubleLine("Craftable", entry.numCraftable)
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

							if entry.command ~= "options" then
								if entry.numCraftable then
									if entry.numCraftable == 0 then
										cellFrame.text:SetTextColor(1,0,0)
									elseif entry.count > entry.numCraftable then
										cellFrame.text:SetTextColor(.8,.8,0)
									else
										cellFrame.text:SetTextColor(1,1,1)
									end
								end
							else
								cellFrame.text:SetTextColor(1,1,1)
							end

							if entry.command == "purchase" then
								cellFrame.text:SetText(entry.numNeeded)
							elseif entry.command == "process" or entry.command == "create" then
								cellFrame.text:SetText(entry.count)
							else
								cellFrame.text:SetText("")
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
						cellFrame.button:SetPoint("LEFT", cellFrame, "LEFT", entry.depth*8, 0)
						local craftable

						if entry.subGroup and (entry.command == "options" or entry.count > entry.numCraftable) then
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



						if entry.command == "process" or entry.command == "create" then
							local name, rank, icon = GnomeWorks:GetTradeInfo(entry.tradeID)

							if entry.manualEntry then
								if entry.sourcePlayer then
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s (%s)",icon or "",GnomeWorks:GetRecipeName(entry.recipeID), entry.sourcePlayer)
								else
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t %s",icon or "",GnomeWorks:GetRecipeName(entry.recipeID))
								end
							else
--[[
								if entry.command == "create" then
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |cffd0d090%s: %s (x%d)",icon or "",GnomeWorks:GetTradeName(entry.tradeID),GnomeWorks:GetRecipeName(entry.recipeID),entry.results[entry.itemID])
								else
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |cffd0d090%s: %s",icon or "",GnomeWorks:GetTradeName(entry.tradeID),GnomeWorks:GetRecipeName(entry.recipeID))
								end
]]
								if entry.command == "create" and entry.results[entry.itemID] ~= 1 then
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |cffd0d090 %s (x%d)",icon or "",GnomeWorks:GetRecipeName(entry.recipeID),entry.results[entry.itemID])
								else
									cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t |cffd0d090 %s",icon or "",GnomeWorks:GetRecipeName(entry.recipeID))
								end
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

							local itemName = GetItemInfo(entry.itemID) or "item:"..entry.itemID

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
						elseif entry.command == "options" then
							cellFrame.text:SetFormattedText("|T%s:16:16:0:-2|t Crafting Options for %s", GetItemIcon(entry.itemID),(GetItemInfo(entry.itemID)))
							cellFrame.text:SetTextColor(.8,.25,.8)
						end
					end,
		}, -- [2]
	}




	local function ResizeMainWindow()
	end


	local function AdjustQueueCounts(player, entry)
		if entry.subGroup then
			local count = entry.count
			local reagents = entry.reagents

			for k,reagent in ipairs(entry.subGroup.entries) do
				local numNeeded = reagents[reagent.itemID] * count

				if reagent.numNeeded then
					reagent.numNeeded = numNeeded
				end

				if reagent.results then
					reagent.count = math.ceil(numNeeded / reagent.results[reagent.itemID])
				end

				AdjustQueueCounts(player, reagent)
			end
		end
	end


	local function ReserveReagentsIntoQueue(player, queue)
--print("RESERVE", player, queue)
		if queue then
			for k,entry in ipairs(queue) do
				if entry.command == "process" then
					entry.numCraftable = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag queue")
--print((GetSpellLink(entry.recipeID)),entry.numCraftable)

					AdjustQueueCounts(player, entry)

					if entry.manualEntry then
						entry.manualEntry.count = entry.count
					end

					if entry.subGroup then
						ReserveReagentsIntoQueue(player, entry.subGroup.entries)
					end

					for itemID,numMade in pairs(entry.results) do
						GnomeWorks:ReserveItemForQueue(player, itemID, -numMade * entry.count)
					end

					for reagentID,numNeeded in pairs(entry.reagents) do
						GnomeWorks:ReserveItemForQueue(player, reagentID, numNeeded * entry.count)
					end
				elseif entry.command == "create" then
					local numAvailable = GnomeWorks:GetInventoryCount(entry.itemID, player, "bag queue")

					entry.numCraftable = GnomeWorks:InventoryRecipeIterations(entry.recipeID, player, "bag queue")


					entry.count = math.ceil((entry.numNeeded - numAvailable)/entry.results[entry.itemID])

					if entry.count < 0 then
						entry.count = 0
					end

					if entry.manualEntry then
						entry.manualEntry.count = entry.count
					end

					entry.noHide = true

					AdjustQueueCounts(player, entry)

					if entry.subGroup then
						ReserveReagentsIntoQueue(player, entry.subGroup.entries)
					end

					for itemID,numMade in pairs(entry.results) do
						GnomeWorks:ReserveItemForQueue(player, itemID, -numMade * entry.count)
					end

					for reagentID,numNeeded in pairs(entry.reagents) do
						GnomeWorks:ReserveItemForQueue(player, reagentID, numNeeded * entry.count)
					end
				elseif entry.command == "purchase" then
					local numAvailable = GnomeWorks:GetInventoryCount(entry.itemID, player, "bag queue")
					local inQueue = math.min(entry.numNeeded, numAvailable)

					entry.numNeeded = entry.numNeeded - inQueue

--					GnomeWorks:ReserveItemForQueue(player, entry.itemID, entry.numNeeded)

				elseif entry.command == "options" then
					local numAvailable = GnomeWorks:GetInventoryCount(entry.itemID, player, "bag queue")
					local inQueue = math.min(entry.numNeeded, numAvailable)

					entry.numNeeded = entry.numNeeded - inQueue

					for k,option in pairs(entry.subGroup.entries) do
						local count = math.ceil(entry.numNeeded / option.results[option.itemID])

						local reagents = entry.reagents

						for k,reagent in ipairs(entry.subGroup.entries) do
							local numNeeded = reagents[reagent.itemID] * count

							if reagent.numNeeded then
								reagent.numNeeded = numNeeded
							end

							if reagent.count then
								reagent.count = math.ceil(numNeeded / reagent.results[reagent.itemID])
							end

							AdjustQueueCounts(player, reagent)
						end
					end
				end

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
		queueFrame:SetPoint("BOTTOMLEFT",20,60)
		queueFrame:SetPoint("TOP", frame, 0, -45)
		queueFrame:SetPoint("RIGHT", frame, -20,0)

--		GnomeWorks.queueFrame = queueFrame

		sf = GnomeWorks:CreateScrollingTable(queueFrame, ScrollPaneBackdrop, columnHeaders, ResizeQueueFrame)

--		sf.childrenFirst = true

		sf.IsEntryFiltered = function(self, entry)
			if entry.manualEntry then
--			print("manual entry", entry.command, GetItemInfo(entry.itemID), entry.numAvailable, entry.count, entry.numBag, entry.numNeeded)
				return false
			end

--			if true then return false end

--print("filter", entry.command, GetItemInfo(entry.itemID), entry.numAvailable, entry.count, entry.numNeeded)
			if entry.command == "purchase" and entry.numNeeded < 1 then
				return true
			elseif (entry.command == "process" or entry.command == "create") and entry.count < 1 then
				return true
			else
--print("filter", entry.command, GetItemInfo(entry.itemID), entry.numAvailable, entry.count, entry.numBag, entry.numNeeded)
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

			local itemID = entry.itemID
			local recipeID = entry.recipeID

			if itemID then
				entry.inQueue = GnomeWorks:GetInventoryCount(itemID, player, "queue")

				entry.bag = GnomeWorks:GetInventoryCount(itemID, player, "bag")
				entry.bank = GnomeWorks:GetInventoryCount(itemID, player, "bank")
				entry.guildBank = GnomeWorks:GetInventoryCount(itemID, player, "guildBank")
				entry.alt = GnomeWorks:GetInventoryCount(itemID, "faction", "bank")
			end

			if entry.command ~= "options" and entry.command ~= "purchase" then
				if entry.numCraftable >= entry.count then
					if entry.subGroup then
						entry.subGroup.expanded = false
					end
				end
			end

--print("done updating")
		end


		sf:RegisterRowUpdate(UpdateRowData)
	end


	local function QueueCommandIterate(tradeID, recipeID, count, sourcePlayer)
		local entry = { command = "iterate", count = count, tradeID = tradeID, recipeID = recipeID, sourcePlayer = sourcePlayer }

		return entry
	end






	local function AddPurchaseToConstructionQueue(itemID, numNeeded, data, sourcePlayer, overRide)
		for i=1,#data do
			if data[i].itemID == itemID then
				local addedToQueue

				if overRide then
					addedToQueue = data[i].numNeeded - numNeeded
					data[i].numNeeded = numNeeded
					data[i].count = data[i].numNeeded
				else
					addedToQueue = numNeeded
					data[i].numNeeded = data[i].numNeeded + numNeeded
					data[i].count = data[i].numNeeded
				end

				return data[i], data[i].numNeeded
			end
		end

		local newEntry = { index = #data+1, command = "purchase", itemID = itemID, numNeeded = numNeeded, count=numNeeded, sourcePlayer = sourcePlayer}

		data[#data + 1] = newEntry

		return newEntry, numNeeded
	end


	local function AddRecipeToConstructionQueue(tradeID, recipeID, numMade, itemID, numNeeded, data, sourcePlayer, overRide)

		for i=1,#data do
			if data[i].recipeID == recipeID then
				local addedToQueue

				if overRide then
					data[i].numNeeded = numNeeded
					count = math.ceil(numNeeded / numMade)
					data[i].count = count
					addedToQueue = count - data[i].count
				else
					data[i].numNeeded = data[i].numNeeded + numNeeded
					count = math.ceil(data[i].numNeeded  / numMade)
					data[i].count = count
					addedToQueue = count - data[i].count
				end

				return data[i], data[i].count
			end
		end



		local newEntry = { index=#data+1, command = "process", tradeID = tradeID, recipeID = recipeID, numMade = numMade, count = math.ceil(numNeeded / numMade), itemID = itemID, numNeeded = numNeeded, sourcePlayer = sourcePlayer }

		data[#data + 1] = newEntry

		return newEntry, newEntry.count
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

	local function AddToConstructionQueue(queue, reagentID, numNeeded, player)
		if not reagentID then return nil, 0 end

		if recursionLimiter[reagentID] then return nil, 0 end

		recursionLimiter[reagentID] = true

		local source = GnomeWorks.data.itemSource

--		numNeeded = numNeeded - GnomeWorks:GetInventoryCount(reagentID, player, "bag queue")




		if source[reagentID] then

			local reagents = GnomeWorksDB.reagents
			local results = GnomeWorksDB.results
			local tradeIDs = GnomeWorksDB.tradeIDs

			local craftingOptions = 0

--[[
			for recipeID, numMade in pairs(source[reagentID]) do
				if GnomeWorks:IsSpellKnown(sourceRecipeID, player) then
					craftingOptions = craftingOptions + 1
				end
			end
]]

--[[
				for recipeID, numMade in pairs(source[reagentID]) do
					local cooldownGroup = GnomeWorks:GetSpellCooldownGroup(recipeID)

					if cooldownGroup then
						if cooldownUsed[cooldownGroup] then
							break
						end

						cooldownUsed[cooldownGroup] = true
					end
]]



			local craftOptions = {}

			for recipeID,numMade in pairs(source[reagentID]) do
				local cooldownGroup = GnomeWorks:GetSpellCooldownGroup(recipeID)

				if GnomeWorks:IsSpellKnown(recipeID, player) and not cooldownUsed[cooldownGroup] then
					local count = math.ceil(numNeeded / numMade)

					local queueEntry = {
						index = #queue.subGroup.entries+1,
						recipeID = recipeID,
						count = count,

						itemID = reagentID,
						numNeeded = numNeeded,

						command = "create",

						tradeID = tradeIDs[recipeID],
						results = results[recipeID],
						reagents = reagents[recipeID],
					}

					table.insert(craftOptions, queueEntry)

					if reagents[recipeID] then
						queueEntry.subGroup = {expanded = false, entries = {} }

						for reagentID,numNeeded in pairs(reagents[recipeID]) do
							AddToConstructionQueue(queueEntry, reagentID, numNeeded * count, player)
						end
					end
				end
			end


			for recipeID,numMade in pairs(source[reagentID]) do
				if GnomeWorks:IsSpellKnown(recipeID, player) then
					local cooldownGroup = GnomeWorks:GetSpellCooldownGroup(recipeID)

					if cooldownGroup then
						cooldownUsed[cooldownGroup] = true
					end
				end
			end

--print("crafting options for", (GetItemInfo(reagentID)), #craftOptions)
			if #craftOptions>1 then
				local optionGroup = { index = 1, command = "options", itemID = reagentID, numNeeded = inQueue, subGroup = { entries = {}, expanded = false }}

				table.insert(queue.subGroup.entries, optionGroup)

				for i=1,#craftOptions do
					table.insert(optionGroup.subGroup.entries, craftOptions[i])
				end
			elseif #craftOptions>0 then
				table.insert(queue.subGroup.entries, craftOptions[1])
			else
print("can't craft", (GetItemInfo(reagentID)))

				local newEntry = {
					index = #queue+1,
					command = "purchase",
					itemID = reagentID,
					numNeeded = numNeeded,
					count=numNeeded,
				}

				table.insert(queue.subGroup.entries, newEntry)
			end
		else
			local newEntry = {
				index = #queue+1,
				command = "purchase",
				itemID = reagentID,
				numNeeded = numNeeded,
				count=numNeeded,
			}

			table.insert(queue.subGroup.entries, newEntry)

		end


--		if cooldownGroup then
--			cooldownUsed[cooldownGroup] = nil
--		end

		recursionLimiter[reagentID] = nil

		return newEntry, count
	end


	local function CreateConstructionQueue(player, entry, index)
		if entry then
			local reagents = GnomeWorksDB.reagents[entry.recipeID]

			local queue = {
				index = index,
				recipeID = entry.recipeID,
				count = entry.count,
				tradeID = entry.tradeID,
				sourcePlayer = entry.sourcePlayer,
				manualEntry = entry,

				noHide = true,

				command = "process",

				results = GnomeWorksDB.results[entry.recipeID],
				reagents = reagents,
			}

			if reagents then
				queue.subGroup = {expanded = false, entries = {} }

				for reagentID,numNeeded in pairs(reagents) do
					AddToConstructionQueue(queue, reagentID, numNeeded * entry.count, player)
				end
			end

			return queue
		end
	end


	local function AdjustConstructionQueueCounts(queue)
--[[
		if queue then
			local player = queuePlayer

			for k,q in ipairs(queue) do
				AddToConstructionQueue(player, q.tradeID, q.recipeID, q.numMade, q.itemID, q.numNeeded, queue, q.sourcePlayer, true, true)
			end

			GnomeWorks.data.inventoryData[player].queue = table.wipe(GnomeWorks.data.inventoryData[player].queue or {})

			for k,q in ipairs(queue) do
				GnomeWorks:ReserveItemForQueue(player, q.itemID, -q.numNeeded)

				q.numAvailable = 0
				q.inQueue = q.count * (q.numMade or 1)

				ReserveReagentsIntoQueue(q.subGroup.entries, 1)
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
		end
]]
	end



	function GnomeWorks:AddToQueue(player, tradeID, recipeID, count)
		local sourcePlayer

		if not self.data.playerData[player] then
			sourcePlayer = player
			player = queuePlayer
		end


		local queueData = self.data.queueData[player]
		local constructionQueue = self.data.constructionQueue[player]

		local queueAdded

		for i=1,#constructionQueue do
			if constructionQueue[i].recipeID == recipeID then
				if constructionQueue[i].sourcePlayer == sourcePlayer then
					constructionQueue[i].count = constructionQueue[i].count + count

					queueAdded = true

--					AdjustConstructionQueueCounts(constructionQueue[i])
					break
				end
			end
		end

		if not queueAdded then
			local qEntry = QueueCommandIterate(tradeID, recipeID, count, sourcePlayer)
			table.insert(queueData, qEntry)
			table.insert(constructionQueue, CreateConstructionQueue(player, qEntry, #queueData))
		end

--[[
		local itemID, made = next(GnomeWorksDB.results[recipeID])

		AddToConstructionQueue(player, tradeID, recipeID, made, itemID, made*count, queueData, sourcePlayer, true)

		AdjustConstructionQueueCounts(queueData)

		self:ShowQueueList()
		self:ShowSkillList()
]]

		self:SendMessageDispatch("GnomeWorksSkillsChanged")
		self:SendMessageDispatch("GnomeWorksDetailsChanged")
		self:SendMessageDispatch("GnomeWorksQueueChanged")
	end


	function GnomeWorks:PopulateQueues()
		for player,queue in pairs(self.data.queueData) do
			self.data.constructionQueue[player] = {}

			local constructionQueue = self.data.constructionQueue[player]

			for i=1,#queue do
				table.insert(constructionQueue, CreateConstructionQueue(player, queue[i], i))
			end

		end
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

--[[
			if not self.data.constructionQueue[player] then
				self.data.constructionQueue[player] = {}

				GnomeWorks.data.inventoryData[player].queue = table.wipe(GnomeWorks.data.inventoryData[player].queue or {})

				CreateConstructionQueue(player, queue, self.data.constructionQueue[player])
			end
]]
			if not sf.data then
				sf.data = {}
			end

--			UpdateQueue(self.data.constructionQueue[player],queue)

--			AdjustConstructionQueueCounts(self.data.constructionQueue[player])



			self.data.inventoryData[player].queue = table.wipe(self.data.inventoryData[player].queue or {})

			ReserveReagentsIntoQueue(player, self.data.constructionQueue[player])

			self:SendMessageDispatch("GnomeWorksQueueCountsChanged")

			sf.data.entries = self.data.constructionQueue[player]


			sf:Refresh()
			sf:Show()
			frame:Show()

			frame:SetToplevel(true)
		end
	end


	local function FirstCraftableEntry(queue)
		if queue then
			for k,q in pairs(queue) do
				if (q.command == "process" or q.command == "create") and (q.numCraftable or 0) > 0 and (q.count or 0) > 0 then
					return q
				end

				if q.subGroup then
					local f = FirstCraftableEntry(q.subGroup.entries)

					if f then return f end
				end
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
							GnomeWorks:print("executing",GnomeWorks:GetRecipeName(entry.recipeID),"x",math.min(entry.count, entry.numCraftable))
							DoTradeSkill(skillIndex,math.min(entry.count, entry.numCraftable))
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
			table.wipe(GnomeWorks.data.queueData[queuePlayer])
			table.wipe(GnomeWorks.data.constructionQueue[queuePlayer])
			table.wipe(GnomeWorks.data.inventoryData[queuePlayer]["queue"])

			GnomeWorks:SendMessageDispatch("GnomeWorksDetailsChanged")
			GnomeWorks:SendMessageDispatch("GnomeWorksSkillListChanged")
			GnomeWorks:SendMessageDispatch("GnomeWorksQueueChanged")
		end


		local function StopProcessing()
			StopTradeSkillRepeat()
		end


		local buttons = {}


		local function SetProcessLabel(button)
			local entry = FirstCraftableEntry(GnomeWorks.data.constructionQueue[queuePlayer])

			if entry then
				button:SetFormattedText("Process %s x %d",GetSpellInfo(entry.recipeID),math.min(entry.numCraftable,entry.count))
				button:Enable()
			else
				button:Disable()
				button:SetText("Nothing To Process")
			end
		end


		local buttonConfig = {
			{ text = "Process", operation = ProcessQueue, width = 250, validate = SetProcessLabel, lineBreak = true },
			{ text = "Stop", operation = StopProcessing, width = 125 },
			{ text = "Clear", operation = ClearQueue, width = 125 },
		}





		local position = 0
		local line = 0

		controlFrame = CreateFrame("Frame", nil, frame)


--		controlFrame:SetPoint("LEFT",20,0)
--		controlFrame:SetPoint("RIGHT",-20,0)


		local function CreateButton(parent, height)
			local newButton = CreateFrame("Button", nil, parent)
			newButton:SetHeight(height)
			newButton:SetWidth(50)
			newButton:SetPoint("CENTER")

			newButton.state = {}

			for k,state in pairs({"Disabled", "Up", "Down", "Highlight"}) do
				local f = CreateFrame("Frame",nil,newButton)
				f:SetAllPoints()

				f:SetFrameLevel(f:GetFrameLevel()-1)

				local leftTexture = f:CreateTexture(nil,"BACKGROUND")
				local rightTexture = f:CreateTexture(nil,"BACKGROUND")
				local middleTexture = f:CreateTexture(nil,"BACKGROUND")

				leftTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-"..state)
				rightTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-"..state)
				middleTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-"..state)

				leftTexture:SetTexCoord(0,.25*.625, 0,.6875)
				rightTexture:SetTexCoord(.75*.625,1*.625, 0,.6875)
				middleTexture:SetTexCoord(.25*.625,.75*.625, 0,.6875)

				leftTexture:SetPoint("LEFT")
				leftTexture:SetWidth(height)
				leftTexture:SetHeight(height)

				rightTexture:SetPoint("RIGHT")
				rightTexture:SetWidth(height)
				rightTexture:SetHeight(height)

				middleTexture:SetPoint("LEFT", height, 0)
				middleTexture:SetPoint("RIGHT", -height, 0)
				middleTexture:SetHeight(height)

				if state == "Highlight" then
					leftTexture:SetBlendMode("ADD")
					rightTexture:SetBlendMode("ADD")
					middleTexture:SetBlendMode("ADD")
				end

--				middleTexture:Hide()

				newButton.state[state] = f

				if state ~= "Up" then
					f:Hide()
				end
			end

			newButton:HookScript("OnEnter", function(b) b.state.Highlight:Show() end)
			newButton:HookScript("OnLeave", function(b) b.state.Highlight:Hide() end)

			newButton:HookScript("OnMouseDown", function(b) b.state.Down:Show() b.state.Up:Hide() end)
			newButton:HookScript("OnMouseUp", function(b) b.state.Down:Hide() b.state.Up:Show() end)

			return newButton
		end


		for i, config in pairs(buttonConfig) do
			if not config.style or config.style == "Button" then
--				local newButton = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")

				local newButton = CreateButton(controlFrame, 18)

				newButton:SetPoint("LEFT", position,-line*20)
				if config.width then
					newButton:SetWidth(config.width)
				else
					newButton:SetPoint("RIGHT")
					line = line + 1
				end


				newButton:SetNormalFontObject("GameFontNormalSmall")
				newButton:SetHighlightFontObject("GameFontHighlightSmall")
				newButton:SetDisabledFontObject("GameFontDisableSmall")

				newButton:SetText(config.text)

				newButton:SetScript("OnClick", config.operation)

				newButton.validate = config.validate

				buttons[i] = newButton


				if newButton.validate then
					newButton:validate()
				end


				position = position + (config.width or 0)
			else
				local newButton = CreateFrame(config.style, nil, controlFrame)

				newButton:SetPoint("LEFT", position,line*20)
				if config.width then
					newButton:SetWidth(config.width)
				else
					newButton:SetPoint("RIGHT")
					line = line + 1
				end
				newButton:SetHeight(18)
				newButton:SetFontObject("GameFontHighlightSmall")
--				newButton:SetHighlightFontObject("GameFontHighlightSmall")

--				newButton:SetText(config.text or "")

				newButton.validate = config.validate

				if config.style == "EditBox" then
					newButton:SetAutoFocus(false)

					newButton:SetNumeric(true)

--					newButton:SetScript("OnEnterPressed", EditBox_ClearFocus)
					newButton:SetScript("OnEscapePressed", EditBox_ClearFocus)
					newButton:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
					newButton:SetScript("OnEditFocusGained", EditBox_HighlightText)


					newButton:SetScript("OnEnterPressed", function(f)
						local n = f:GetNumber()

						if n<=0 then
							f:SetNumber(1)

							buttons[1].count = 1
							buttons[2].count = 1
						else
							buttons[1].count = n
							buttons[2].count = n
						end

						EditBox_ClearFocus(f)
					end)

					newButton:SetJustifyH("CENTER")
					newButton:SetJustifyV("CENTER")

					local searchBackdrop  = {
							bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBackground.tga",
							edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\frameInsetSmallBorder.tga",
							tile = true, tileSize = 16, edgeSize = 16,
							insets = { left = 10, right = 10, top = 8, bottom = 10 }
						}

					self.Window:SetBetterBackdrop(newButton, searchBackdrop)

					buttons[1].count = config.default
					buttons[2].count = config.default

--					newButton:SetNumber()

					newButton:SetText("")
					newButton:SetMaxLetters(4)

				end

				buttons[i] = newButton

				position = position + (config.width or 0)
			end

			if config.lineBreak then
				line = line + 1
				position = 0
			end
		end

		controlFrame:SetHeight(20+line*20)
		controlFrame:SetWidth(position)

		GnomeWorks:RegisterMessageDispatch("GnomeWorksQueueCountsChanged", function()
			for i, b in pairs(buttons) do
				if b.validate then
					b:validate()
				end
			end
		end)

		return controlFrame
	end



	function GnomeWorks:CreateQueueWindow()
		frame = self.Window:CreateResizableWindow("GnomeWorksQueueFrame", nil, 300, 300, ResizeMainWindow, GnomeWorksDB.config)

		frame:DockWindow(self.MainWindow)


		frame:SetMinResize(300,200)

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


		self:RegisterMessageDispatch("GnomeWorksQueueChanged GnomeWorksTradeScanComplete GnomeWorksInventoryScanComplete", function() if frame:IsShown() then GnomeWorks:ShowQueueList() end end)


		local control = CreateControlButtons(frame)

		control:SetPoint("TOP", sf, "BOTTOM", 0,0)


		table.insert(UISpecialFrames, "GnomeWorksQueueFrame")

		frame:HookScript("OnShow", function() PlaySound("igCharacterInfoOpen")  GnomeWorks:ShowQueueList() end)
		frame:HookScript("OnHide", function() PlaySound("igCharacterInfoClose") end)


		frame:Hide()

		return frame
	end

end

