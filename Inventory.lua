

local function DebugSpam(...)
	print(...)
end

do
	local itemVisited = {}


	-- queries periodic table for vendor info for a particual itemID
	function GnomeWorks:VendorSellsItem(itemID)
		if self.libPT then
			if GnomeWorksDB.vendorItems[itemID] then
				return true
			end

			if self.libPT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
				return true
			end
		end
	end


	function GnomeWorks:MERCHANT_UPDATE()
		for i=1,GetMerchantNumItems() do
			local link = GetMerchantItemLink(i)

			if link then
				local itemID = string.match(link, "item:(%d+)")

				itemID = tonumber(itemID)

				local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)

				if numAvailable ~= -1 then
					GnomeWorksDB.vendorItems[itemID] = true
				end
			end
		end
	end


	-- recursive reagent craftability check
	-- not considering alts at the moment
	-- does consider queued recipes
	function GnomeWorks:InventoryReagentCraftability(reagentID, playerOverride)
		if itemVisited[reagentID] then
			return 0, 0			-- we've been here before, so bail out to avoid infinite loop
		end

		local player = playerOverride or GnomeWorks.player

		itemVisited[reagentID] = true


		local recipeSource = GnomeWorksDB.itemSource[reagentID]
		local numReagentsCrafted = 0
		local numReagentsCraftedBank = 0

		local function CalculateRecipeCrafting(childRecipeID)
			local childRecipe = GnomeWorks.data.recipeDB[childRecipeID]

			if childRecipe and childRecipe.craftable then
				local numCraftable = 100000
				local numCraftableBank = 100000

				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]

					local numReagentCraftable, numReagentCraftableBank = self:InventoryReagentCraftability(childReagent.id)

					numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
					numCraftableBank = math.min(numCraftableBank, math.floor(numReagentCraftableBank/childReagent.numNeeded))
				end


				numReagentsCrafted = numReagentsCrafted + numCraftable * childRecipe.numMade
				numReagentsCraftedBank = numReagentsCraftedBank + numCraftableBank * childRecipe.numMade
			end
		end


		if recipeSource then
			if type(recipeSource) == "table" then
				for childRecipeID in pairs(recipeSource) do
					CalculateRecipeCrafting(childRecipeID)
				end
			else
				CalculateRecipeCrafting(recipeSource)
			end
		end


		local queued = 0

		if self.data.playerData[player].reagentsInQueue then
			queued = self.data.playerData[player].reagentsInQueue[reagentID] or 0
		end

		local numInBags, _, numInBank = self:GetInventory(player, reagentID)

		local numCraftable = numReagentsCrafted + numInBags + queued
		local numCraftableBank = numReagentsCraftedBank + numInBank + queued


		self.data.inventoryData[player][reagentID] = numInBags.." "..numCraftable.." "..numInBank.." "..numCraftableBank

		itemVisited[reagentID] = false										-- okay to calculate this reagent again

		return numCraftable, numCraftableBank
	end


	local invscan = 1

	function GnomeWorks:InventoryScan(playerOverride)
	--DEFAULT_CHAT_FRAME:AddMessage("InventoryScan "..invscan)
		invscan = invscan + 1
		local player = playerOverride or self.player
		local cachedInventory = self.data.inventoryData[player]

		local inventoryData = {}
		local numInBags, numInBank

		local reagent

		if GnomeWorksDB.reagentUsage then
			for reagentID in pairs(GnomeWorksDB.reagentUsage) do

		--DebugSpam("reagent "..GetItemInfo(reagentID).." "..(inventoryData[reagentID] or "nil"))

				if reagentID and not inventoryData[reagentID] then								-- have we calculated this one yet?
					if self.player == (UnitName("player")) then								-- if this is the current player, use the api
						numInBags = GetItemCount(reagentID)
						numInBank = GetItemCount(reagentID,true)								-- both bank and bags, actually
					elseif cachedInventory and cachedInventory[reagentID] then										-- otherwise, use the what cached data is available
	--[[
						local data = { string.split(" ", cachedInventory[reagentID]) }

						if #data == 1 then
							numInBags = data[1]
							numInBank = data[1]
						elseif #data == 2 then
							numInBags = data[1]
							numInBank = data[2]
						else
							numInBags = data[1]
							numInBank = data[3]
						end
	]]
						local a,b,c,d = string.match(cachedInventory[reagentID],"(%d+) (%d+) (%d+) (%d+)")

						numInBags = tonumber(a)
						numInBank = tonumber(c)
					else
						numInBags = 0
						numInBank = 0
					end


					inventoryData[reagentID] = string.format("%d %d %d %d",numInBags, numInBags, numInBank, numInBank)							-- if items are all in bags, then leave off bank

		--DebugSpam(inventoryData[reagentID])
				end
			end
		end

		self.data.inventoryData[player] = inventoryData


		itemVisited = {}							-- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice

		if inventoryData then
			-- now calculate the craftability of these same reagents
			for reagentID,inventory in pairs(inventoryData) do
				self:InventoryReagentCraftability(reagentID, player)
			end

			-- remove any reagents that don't show up in our inventory
			for reagentID,inventory in pairs(inventoryData) do
				if inventoryData[reagentID] == "0 0 0 0" then
					inventoryData[reagentID] = nil
				end
			end
		end

--	DebugSpam("InventoryScan Complete")
	end




	-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
	-- (not to be confused with the reagent craftability which is designed to determine how many craftable reagents are available for recipe iterations)
	function GnomeWorks:InventoryRecipeIterations(recipeID, playerOverride)
		local player = playerOverride or self.player
		local recipe = GnomeWorks.data.recipeDB[recipeID]

		if recipe and recipe.reagentData then							-- make sure that recipe is in the database before continuing
			local numCraftable = 100000000
			local numCraftableVendor = 100000000
			local numCraftableBank = 100000000
			local numCraftableAlts = 100000000

			local vendorOnly = true

			for i=1,#recipe.reagentData,1 do
				if recipe.reagentData[i].id then

					local reagentID = recipe.reagentData[i].id
					local numNeeded = recipe.reagentData[i].numNeeded

					local reagentAvailabilityAlts = 0

					local _, reagentAvailability, _, reagentAvailabilityBank = self:GetInventory(player, reagentID)
	--[[
					if self:VendorSellsReagent(reagentID) then								-- maybe should be an option, but if the item is available at vendors then assume the player could easily get some
						local _,_,_,_,_,_,_,stackSize = GetItemInfo(reagentID)
						local _,_,_,_,_,_,_,stackSizeMade = GetItemInfo(recipe.itemID)

						reagentAvailabilityBank = math.max((stackSize or 1), math.floor((stackSizeMade or 1)/recipe.numMade)*numNeeded)
						reagentAvailabilityAlts = reagentAvailabilityBank
					else
						for player in pairs(self.db.server.inventoryData) do

							local _,_,_, altBank = self:GetInventory(player, reagentID)

							reagentAvailabilityAlts = reagentAvailabilityAlts + (altBank or 0)
						end
					end
	]]



					for player in pairs(self.data.inventoryData) do
						local _,_,_, altBank = self:GetInventory(player, reagentID)

						reagentAvailabilityAlts = reagentAvailabilityAlts + (altBank or 0)
					end

					if self:VendorSellsItem(reagentID) then											-- if it's available from a vendor, then only worry about bag inventory
						numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
					else
						vendorOnly = nil

						numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
						numCraftableVendor = math.min(numCraftableVendor, math.floor(reagentAvailability/numNeeded))
						numCraftableBank = math.min(numCraftableBank, math.floor(reagentAvailabilityBank/numNeeded))
						numCraftableAlts = math.min(numCraftableAlts, math.floor(reagentAvailabilityAlts/numNeeded))
					end


					if (numCraftableAlts == 0) then
						break
					end

				else												-- no data means no craftability
					numCraftable = 0
					numCraftableVendor = 0
					numCraftableBank = 0
					numCraftableAlts = 0

--					self.dataScanned = false						-- mark the data as needing to be rescanned since a reagent id seems corrupt
				end
			end

			recipe.unlimited = vendorOnly


			return math.max(0,numCraftable), math.max(0,numCraftableVendor), math.max(0,numCraftableBank), math.max(0,numCraftableAlts)
		else
			DEFAULT_CHAT_FRAME:AddMessage("can't calc craft iterations!")
		end

		return 0, 0, 0, 0
	end




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
end
