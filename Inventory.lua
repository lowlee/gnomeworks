

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


	function GnomeWorks:MERCHANT_SHOW(...)
		for i=1,GetMerchantNumItems() do
			local link = GetMerchantItemLink(i)

			if link then
				local itemID = string.match(link, "item:(%d+)")

				itemID = tonumber(itemID)

				if self.data.reagentUsage[itemID] and not GnomeWorksDB.vendorItems[itemID] then
					local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)

					if numAvailable == -1 then
						print("|c008080ffGnomeWorks recording vendor item: ",link)
						GnomeWorksDB.vendorItems[itemID] = true
					end
				end
			end
		end
	end

	function GnomeWorks:MERCHANT_UPDATE(...)
		self:MERCHANT_SHOW(...)
	end


	local function CalculateRecipeCrafting(craftabilityTable, childRecipe, player, containerList)

		local numCraftable = 100000

		for i=1,#childRecipe.reagentData,1 do
			local childReagent = childRecipe.reagentData[i]

			local numReagentCraftable = GnomeWorks:InventoryReagentCraftability(craftabilityTable, childReagent.id, player, containerList)

			numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
		end

		return  numCraftable * childRecipe.numMade
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


		local recipeDB = self.data.recipeDB

		local recipeSource = GnomeWorksDB.itemSource[reagentID]

		local numReagentsCraftable = 0

		if recipeSource then
			if type(recipeSource) == "table" then
				for childRecipeID in pairs(recipeSource) do
					local childRecipe = recipeDB[childRecipeID]

					if childRecipe and childRecipe.craftable then
						numReagentsCraftable = numReagentsCraftable + CalculateRecipeCrafting(craftabilityTable, childRecipe, player, containerList)
					end
				end
			else
				local childRecipe = recipeDB[recipeSource]

				if childRecipe and childRecipe.craftable then
					numReagentsCraftable = numReagentsCraftable + CalculateRecipeCrafting(craftabilityTable, childRecipe, player, containerList)
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
		local recipe = GnomeWorks.data.recipeDB[recipeID]

		if recipe and recipe.reagentData then							-- make sure that recipe is in the database before continuing
			local numCraftable = 100000000

			local vendorOnly = true

			for i=1,#recipe.reagentData,1 do
				if recipe.reagentData[i].id then

					local reagentID = recipe.reagentData[i].id
					local numNeeded = recipe.reagentData[i].numNeeded

					local reagentAvailability = self:GetInventoryCount(reagentID, player, containerList)

					if not self:VendorSellsItem(reagentID) then
						vendorOnly = nil
					end

					numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
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


	function GnomeWorks:GetInventoryCount(itemID, player, containerList)
		if player ~= "faction" then
			local inventoryData = self.data.inventoryData[player]

			if inventoryData then
				local count = 0

				for container in string.gmatch(containerList, "%a+") do
					if container == "vendor" then
						if self:VendorSellsItem(itemID) then
							return 100000
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
							return 100000
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
				for reagentID in pairs(GnomeWorksDB.reagentUsage) do

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

			for reagentID in pairs(GnomeWorksDB.reagentUsage) do

				if GnomeWorksDB.itemSource[reagentID] then
					self:InventoryReagentCraftability(craftedBag, reagentID, player, "craftedBag queue")
					self:InventoryReagentCraftability(craftedBank, reagentID, player, "craftedBank queue")
				end
			end
		end

--	DebugSpam("InventoryScan Complete")
		DebugSpam("Inventory Scanned in ",math.floor((GetTime()-scanTime)*100)/100," seconds")
	end

end
