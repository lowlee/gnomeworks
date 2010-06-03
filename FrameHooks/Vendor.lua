




do

	local function RecordMerchantItem(itemID, i)
		local spoofedRecipeID = itemID+200000

		if GnomeWorks.data.reagentUsage[itemID] and not GnomeWorksDB.vendorItems[itemID] and not GnomeWorksDB.results[spoofedRecipeID] then
			local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)

			if numAvailable == -1 then
				local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(i)

				if not extendedCost then
					self:print("recording vendor item: ",name)
					GnomeWorksDB.vendorItems[itemID] = true
				elseif arenaPoints == 0 and honorPoints == 0 then
					local reagents = {}
					GnomeWorksDB.results[spoofedRecipeID] = { [itemID] = quantity }
					GnomeWorksDB.names[spoofedRecipeID] = "Purchase "..name
					GnomeWorksDB.tradeIDs[spoofedRecipeID] = 100001

					for n=1,itemCount do
						local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(i, n)

						local costItemID = tonumber(string.match(itemLink,"item:(%d+)"))

						reagents[costItemID] = itemValue

						GnomeWorks:AddToReagentCache(costItemID, spoofedRecipeID, itemValue)
					end

					GnomeWorksDB.reagents[spoofedRecipeID] = reagents


					GnomeWorks:AddToItemCache(itemID, spoofedRecipeID, quantity)


					self:print("recording vendor conversion for item: ",name)
				end
			end
		end
	end

	local function QuickMoneyFormat(copper)
		local silver = copper/100
		local gold = silver/100
		local kgold = gold/1000


		if kgold > 1 then
			return "|cffffd100"..math.floor(kgold*10+.5)/10 .."k"
		end

		if gold > 1 then
			return "|Cffffd100"..math.floor(gold*100+.5)/100 .."g"
		end

		if silver > 1 then
			return "|cffe6e6e6"..math.floor(silver*100+.5)/100 .."s"
		end

		return "|cffc8602c"..copper .. "c"
	end


	local merchantLocked
	function GnomeWorks:MERCHANT_SHOW(...)
		if merchantLocked then return end

		merchantLocked = true

		local totalSpent = 0

		for i=1,GetMerchantNumItems() do
			local link = GetMerchantItemLink(i)

			if link then
				local itemID = tonumber(string.match(link, "item:(%d+)"))

				RecordMerchantItem(itemID, i)


				local onHand = self:GetInventoryCount(itemID, self.player, "craftedBag queue")

				if onHand < 0 then
					local count = -onHand

					local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)
					local _, _, _, _, _, _, _, stackSize = GetItemInfo(link)

					local numPurchase = math.ceil(count/quantity)
--print(numAvailable)
					if numAvailable ~= 0 then
						local numStacksNeeded    		= math.floor(count/stackSize);
						local numVendorStacksPerStack 	= math.floor(stackSize/quantity);
						local subStackCount        		= math.ceil((count-(numStacksNeeded*stackSize))/quantity);
						if numStacksNeeded > 0 then
							for l=1,numStacksNeeded do
								BuyMerchantItem(i,numVendorStacksPerStack)
							end
						end
						if subStackCount > 0 then
							BuyMerchantItem(i,subStackCount)
						end
						self:print("auto-purchased",name,"x",numPurchase * quantity)

						self:ReserveItemForQueue(self.player, itemID, -numPurchase * quantity)

						totalSpent = totalSpent + price * numPurchase
					end

				end
			end
		end

		GnomeWorks:InventoryScan()

		if totalSpent>0 then
			self:print("spent on reagents: ",QuickMoneyFormat(totalSpent))
		end

		merchantLocked = nil
	end

	function GnomeWorks:MERCHANT_UPDATE(...)
		self:MERCHANT_SHOW(...)
	end
end

