

--[[
    *  0 = Unspecified (for bags it means any item, for items it means no special bag type)
    * 1 = Quiver
    * 2 = Ammo Pouch
    * 4 = Soul Bag
    * 8 = Leatherworking Bag
    * 16 = Unknown
    * 32 = Herb Bags
    * 64 = Enchanting Bags
    * 128 = Engineering Bag
    * 256 = Keyring
    * 512 = Gem Bag
    * 1024 = Mining Bag
    * 2048 = Unknown
    * 4096 = Vanity Pets
]]

do
	local bankLocked
	local bankBags = { -1, 5,6,7,8,9,10,11 }



	local function FindBagSlot(itemID, count)
		if not itemID then return nil end

		local _, _, _, _, _, _, _, stackSize = GetItemInfo(itemID)

		local itemType = GetItemFamily(itemID)

		-- if item is can go into a special bag, prefer to place it in one of those first
		if itemType then
			for bag = 1, 4 do
				local bagType = GetItemFamily(GetInventoryItemID(ContainerIDToInventoryID(bag)))

				if bagTYpe and bagType ~= 0 and bit.band(bagType, itemType) == bagType then
					for i = 1, GetContainerNumSlots(bag) do
						local link = GetContainerItemLink(bag, i)

						if link then
							local slotItemID = tonumber(string.match(link, "item:(%d+)"))

							if itemID == slotItemID then
								local _, inBag, locked  = GetContainerItemInfo(bag, i)

								if not locked and count + inBag <= stackSize then
									return bag
								end
							end
						else
							return bag
						end
					end
				end
			end
		end

		-- if it can't fit in a special bag, then try any bag
		for bag = 0, 4 do
			local bagType = bag==0 and 0 or GetItemFamily(GetInventoryItemID(ContainerIDToInventoryID(bag)))

			if bagType and bagType == 0 or bit.band(bagType,itemType) == bagType then
				for i = 1, GetContainerNumSlots(bag) do
					local link = GetContainerItemLink(bag, i)

					if link then
						local slotItemID = tonumber(string.match(link, "item:(%d+)"))

						if itemID == slotItemID then
							local _, inBag, locked  = GetContainerItemInfo(bag, i)

							if not locked and count + inBag <= stackSize then
								return bag
							end
						end
					else
						return bag
					end
				end
			end
		end

		return nil
	end


	function GnomeWorks:BANKFRAME_OPENED(...)
		if bankLocked then return end

		-- temporarily disable bag update scanning while we're grabbing items from the bank.  we'll do a manual adjustment after each retrieval
		self:UnregisterEvent("BAG_UPDATE")

		bankLocked = true

		for k,bag in pairs(bankBags) do
			for i = 1, GetContainerNumSlots(bag), 1 do
				local link = GetContainerItemLink(bag, i)


				if link then
					local itemID = tonumber(string.match(link, "item:(%d+)"))

					local onHand = self:GetInventoryCount(itemID, self.player, "craftBag queue")

					if onHand < 0 then
						local count = -onHand

						local _,numAvailable = GetContainerItemInfo(bag, i)

						ClearCursor()

						local itemName, _, _, _, _, _, _, stackSize = GetItemInfo(link)

						local numMoved
	--print(numAvailable)

						if numAvailable < count then
							numMoved = numAvailable
						else
							numMoved = count
						end

						local toBag = FindBagSlot(itemID, numMoved)

						if toBag then
	--						PickupContainerItem(bag, i)
							SplitContainerItem(bag, i, numMoved)
							if toBag == 0 then
								PutItemInBackpack()
							else
								PutItemInBag(ContainerIDToInventoryID(toBag))
							end

							-- "un"reserve items from the queue inventory
							self:ReserveItemForQueue(self.player, itemID, -numMoved)

							self:print("collecting",itemName,"x",numMoved,"from bank")
						end
					end
				end
			end
		end

		bankLocked = nil

		self:RegisterEvent("BAG_UPDATE")

		self:InventoryScan()
	end
end


