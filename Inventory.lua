

local function DebugSpam(...)
	print(...)
end


local LARGE_NUMBER = 1000000

do
	local itemVisited = {}
	local GnomeWorks = GnomeWorks
	local GnomeworksDB = GnomeWorksDB

	local bagThrottleTimer


	-- queries periodic table for vendor info for a particual itemID
	function GnomeWorks:VendorSellsItem(itemID)

		if itemID>0 then
			if self.libPT then
				if GnomeWorksDB.vendorItems[itemID] then
					return true
				end

				if self.libPT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
					return true
				end
			end
		end
	end


	function GnomeWorks:BAG_UPDATE(event,bag)
		if bagThrottleTimer then
			self:CancelTimer(bagThrottleTimer, true)
		end

		bagThrottleTimer = self:ScheduleTimer("InventoryScan",.01)
	end


	function GnomeWorks:MERCHANT_SHOW(...)
		for i=1,GetMerchantNumItems() do
			local link = GetMerchantItemLink(i)

			if link then
				local itemID = string.match(link, "item:(%d+)")
				local spoofedRecipeID = itemID+200000

				itemID = tonumber(itemID)

				if GnomeWorks.data.reagentUsage[itemID] and not GnomeWorksDB.vendorItems[itemID] and not GnomeWorksDB.results[spoofedRecipeID] then
					local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)

					if numAvailable == -1 then
						local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(i)

						if not extendedCost then
							print("|c008080ffGnomeWorks recording vendor item: ",link)
							GnomeWorksDB.vendorItems[itemID] = true
						elseif arenaPoints == 0 and honorPoints == 0 then
							local reagents = {}
							GnomeWorksDB.results[spoofedRecipeID] = { [itemID] = quantity }
							GnomeWorksDB.names[spoofedRecipeID] = "Purchase "..GetItemInfo(itemID)
							GnomeWorksDB.tradeIDs[spoofedRecipeID] = 100001

							for n=1,itemCount do
								local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(i, n)

								local costItemID = tonumber(string.match(itemLink,"item:(%d+)"))

								reagents[costItemID] = itemValue

								GnomeWorks:AddToReagentCache(costItemID, spoofedRecipeID, itemValue)
							end

							GnomeWorksDB.reagents[spoofedRecipeID] = reagents


							GnomeWorks:AddToItemCache(itemID, spoofedRecipeID, quantity)


							print("|c008080ffGnomeWorks recording vendor conversion for item: ",link)
						end
					end
				end
			end
		end
	end

	function GnomeWorks:MERCHANT_UPDATE(...)
		self:MERCHANT_SHOW(...)
	end


	local function CalculateRecipeCrafting(craftabilityTable, reagents, player, containerList)
		local numCraftable = LARGE_NUMBER

		for reagentID, numNeeded in pairs(reagents) do
			local numReagentCraftable = GnomeWorks:InventoryReagentCraftability(craftabilityTable, reagentID, player, containerList)

			numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/numNeeded))
		end

		return  numCraftable
	end


	-- recursive reagent craftability check
	-- utilizes all containers passed to it ("bag", "bank", "queue", "guildbank", "mail", etc)
	function GnomeWorks:InventoryReagentCraftability(craftabilityTable, reagentID, player, containerList)
		if itemVisited[reagentID] then
			return 0, 0			-- we've been here before, so bail out to avoid infinite loop
		end

		if craftabilityTable[reagentID] then
			return craftabilityTable[reagentID]
		end


		itemVisited[reagentID] = true


		local recipeSource = GnomeWorks.data.itemSource[reagentID]

		local numReagentsCraftable = 0

		if recipeSource then
			for childRecipeID, count in pairs(recipeSource) do
				if count >= .1 then
--print("Child Recipe", reagentID, childRecipeID)
					numReagentsCraftable = numReagentsCraftable + CalculateRecipeCrafting(craftabilityTable, GnomeWorksDB.reagents[childRecipeID], player, containerList) * count
				end
			end
		end

		local inventoryCount = self:GetInventoryCount(reagentID, player, containerList) + numReagentsCraftable

		if inventoryCount ~= 0 then
			craftabilityTable[reagentID] = inventoryCount
		else
			craftabilityTable[reagentID] = nil
		end

		itemVisited[reagentID] = false										-- okay to calculate this reagent again

		return inventoryCount
	end





	-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
	-- (not to be confused with the reagent craftability which is designed to determine how many craftable reagents are available for recipe iterations)
	function GnomeWorks:InventoryRecipeIterations(recipeID, player, containerList)
--		local recipe = GnomeWorksDB.recipeDB[recipeID]

		local reagents = GnomeWorksDB.reagents[recipeID]


		if reagents then													-- make sure that recipe is in the database before continuing
			local numCraftable

			local vendorOnly = true

			for reagentID, numNeeded in pairs(reagents) do
				local reagentAvailability = self:GetInventoryCount(reagentID, player, containerList)

				if not self:VendorSellsItem(reagentID) then
					vendorOnly = nil
				end

				numCraftable = math.min(numCraftable or LARGE_NUMBER, math.floor(reagentAvailability/numNeeded))
			end

			if not numCraftable then
				numCraftable = 0
			end

			GnomeWorksDB.vendorOnly[recipeID] = vendorOnly

			return math.max(0,numCraftable)
		else
			DEFAULT_CHAT_FRAME:AddMessage("can't calc craft iterations!")
		end

		return 0
	end



--[[
	function GnomeWorks:InventoryRecipeIterationsBagOnly(recipeID, playerOverride)
		local player = playerOverride or self.player
		local recipe = GnomeWorks.data.recipeDB[recipeID]

		if recipe and recipe.reagentData then							-- make sure that recipe is in the database before continuing
			local numCraftable = 100000000

			local vendorOnly = true

			for i=1,#recipe.reagentData,1 do
				if recipe.reagentData[i].id then

					local reagentID = recipe.reagentData[i].id
					local numNeeded = recipe.reagentData[i].numNeeded

					local reagentAvailability = self:GetInventory(player, reagentID)

					if self:VendorSellsItem(reagentID) then											-- if it's available from a vendor, then only worry about bag inventory
						numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
					else
						vendorOnly = nil

						numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
					end


					if (numCraftable == 0) then
						break
					end

				else												-- no data means no craftability
					numCraftable = 0

--					self.dataScanned = false						-- mark the data as needing to be rescanned since a reagent id seems corrupt
				end
			end

			recipe.unlimited = vendorOnly


			return math.max(0,numCraftable)
		else
			DEFAULT_CHAT_FRAME:AddMessage("can't calc craft iterations!")
		end

		return 0
	end


	-- returns item count in bag, craftable from bag, in bank, craftable from bank

	function GnomeWorks:GetInventory(player, reagentID)
		if player and reagentID then
			local inventoryData = self.data.inventoryData[player]
			if inventoryData[reagentID] then
				local a,b,c,d = string.match(inventoryData[reagentID],"(%d+) (%d+) (%d+) (%d+)")

				return tonumber(a), tonumber(b), tonumber(c), tonumber(d)
			end
		end

		return 0, 0, 0, 0			-- bags, bagsCraftable, bank, bankCraftable, alt, altCraftable
	end


	function GnomeWorks:GetFactionInventory(reagentID)
		if reagentID then
			local alt, altCraftable, altBank, altBankCraftable = 0,0,0,0

			for player, inventoryData in pairs(self.data.inventoryData) do
				if inventoryData[reagentID] then
					local a,b,c,d = string.match(inventoryData[reagentID],"(%d+) (%d+) (%d+) (%d+)")

					alt = alt + a
					altCraftable = altCraftable + b
					altBank = altBank + c
					altBankCraftable = altBankCraftable + d
				end
			end

			return alt, altCraftable, altBank, altBankCraftable
		end

		return 0, 0, 0, 0			-- bags, bagsCraftable, bank, bankCraftable, alt, altCraftable
	end
]]


	function GnomeWorks:SetInventoryCount(itemID, player, container, count)
		self.data.inventoryData[player][container][itemID] = count
	end


	function GnomeWorks:ReserveItemForQueue(player, itemID, count)
		local inv = self.data.inventoryData[player]["queue"]

		inv[itemID] = (inv[itemID] or 0) - count					-- queue "inventory" is negative meaning that it requires these items
	end


	function GnomeWorks:GetInventoryCount(itemID, player, containerList)
		if player ~= "faction" then
			local inventoryData = self.data.inventoryData[player]

			if inventoryData then
				local count = 0

				for container in string.gmatch(containerList, "%a+") do
					if container == "vendor" then
						if self:VendorSellsItem(itemID) then
							return LARGE_NUMBER
						end
					else
						if inventoryData[container] then
							count = count + (inventoryData[container][itemID] or 0)
						end
					end
				end

				return count
			end

			return 0
		else
			local count = 0

			for player, inventoryData in pairs(self.data.inventoryData) do

				for container in string.gmatch(containerList, "%a+") do

					if container == "vendor" then
						if self:VendorSellsItem(itemID) then
							return LARGE_NUMBER
						end
					else
						if inventoryData[container] then
							count = count + (inventoryData[container][itemID] or 0)
						end
					end
				end
			end

			return count
		end

		return 0
	end


	local invscan = 1

	function GnomeWorks:InventoryScan(playerOverride)
		local scanTime = GetTime()
	--DEFAULT_CHAT_FRAME:AddMessage("InventoryScan "..invscan)
		invscan = invscan + 1
		local player = playerOverride or self.player
		local inventory = self.data.inventoryData[player]

		if inventory then
			if not inventory["bag"] then
				inventory["bag"] = {}
			end

			if not inventory["bank"] then
				inventory["bank"] = {}
			end

			if not inventory["craftedBag"] then
				inventory["craftedBag"] = {}
			end

			if not inventory["craftedBank"] then
				inventory["craftedBank"] = {}
			end


			if player == (UnitName("player")) then
				for reagentID in pairs(GnomeWorks.data.reagentUsage) do

					if reagentID then
						local inBag = GetItemCount(reagentID)
						local inBank = GetItemCount(reagentID,true)

						if inBag>0 then
							inventory["bag"][reagentID] = inBag
						else
							inventory["bag"][reagentID] = nil
						end

						if inBank>0 then
							inventory["bank"][reagentID] = inBank
						else
							inventory["bank"][reagentID] = nil
						end
			--DebugSpam(inventoryData[reagentID])
					end
				end
			end

			local craftedBag = table.wipe(inventory["craftedBag"])
			local craftedBank = table.wipe(inventory["craftedBank"])

			for reagentID, count in pairs(inventory["bag"]) do
				craftedBag[reagentID] = count
			end

			for reagentID, count in pairs(inventory["bank"]) do
				craftedBank[reagentID] = count
			end


			table.wipe(itemVisited)							-- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice

			for reagentID in pairs(GnomeWorks.data.reagentUsage) do

				if GnomeWorks.data.itemSource[reagentID] then
					self:InventoryReagentCraftability(craftedBag, reagentID, player, "craftedBag queue")
					self:InventoryReagentCraftability(craftedBank, reagentID, player, "craftedBank queue")
				end
			end
		end

--	DebugSpam("InventoryScan Complete")
		local elapsed = GetTime()-scanTime

		if elapsed > .5 then
			DebugSpam("|cffff0000WARNING: GnomeWorks Inventory Scan took ",math.floor(elapsed*100)/100," seconds")
		end

		GnomeWorks:SendMessage("GnomeWorksInventoryScanComplete")
	end

end
