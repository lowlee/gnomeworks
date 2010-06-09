

do
	local bankLocked
	local bankBags = { -1, 5,6,7,8,9,10,11 }

	local bagCache = { {}, {}, {}, {}, {}}

	local updateTimer


	local function FindBagSlot(itemID, count)
		if not itemID then return nil end

		local _, _, _, _, _, _, _, stackSize = GetItemInfo(itemID)

		local itemType = GetItemFamily(itemID)

		-- if item can go into a special bag, prefer to place it in one of those first
		if itemType then
			for bag = 1, 4 do
				local bagType = GetItemFamily(GetInventoryItemID(ContainerIDToInventoryID(bag)))

				if bagTYpe and bagType ~= 0 and bit.band(bagType, itemType) == bagType then

					for i = 1, GetContainerNumSlots(bag) do
						if not bagCache[bag+1][i] then
							local link = GetContainerItemLink(bag, i)

							if link then
								local slotItemID = tonumber(string.match(link, "item:(%d+)"))

								if itemID == slotItemID then
									local _, inBag, locked  = GetContainerItemInfo(bag, i)

									if not locked and count + inBag <= stackSize then
										bagCache[bag+1][i] = true
										return bag, i
									end
								end
							else
								bagCache[bag+1][i] = true
								return bag,i
							end
						end
					end
				end
			end
		end

		-- if it can't fit in a special bag, then try any bag
		for bag = 0, 4 do
			local bagType = bag==0 and 0 or GetItemFamily(GetInventoryItemID("player",ContainerIDToInventoryID(bag)))

			if bagType == 0 then
				for i = 1, GetContainerNumSlots(bag) do
					if not bagCache[bag+1][i] then

						local link = GetContainerItemLink(bag, i)

						if link then
							local slotItemID = tonumber(string.match(link, "item:(%d+)"))

							if itemID == slotItemID then
								local _, inBag, locked  = GetContainerItemInfo(bag, i)

								if not locked and count + inBag <= stackSize then
									bagCache[bag+1][i] = true
									return bag, i
								end
							end
						else
							bagCache[bag+1][i] = true
							return bag, i
						end
					end
				end
			end
		end

		return nil
	end


	function GnomeWorks:BANKFRAME_OPENED(...)
		if bankLocked then return end
		local itemMoved

		-- temporarily disable bag update scanning while we're grabbing items from the bank.  we'll do a manual adjustment after each retrieval
		self:UnregisterEvent("BAG_UPDATE")

		bankLocked = true

		for id,cache in pairs(bagCache) do
			table.wipe(cache)
		end

		for k,bag in pairs(bankBags) do
			for i = 1, GetContainerNumSlots(bag), 1 do
				local link = GetContainerItemLink(bag, i)


				if link then
					local itemID = tonumber(string.match(link, "item:(%d+)"))

					local onHand = self:GetInventoryCount(itemID, self.player, "craftedBag queue")

					if onHand < 0 then

						local count = -onHand

						local _,numAvailable = GetContainerItemInfo(bag, i)

						ClearCursor()

						local itemName, _, _, _, _, _, _, stackSize = GetItemInfo(link)

						local numMoved

						if numAvailable < count then
							numMoved = numAvailable
						else
							numMoved = count
						end

						local toBag, toSlot = FindBagSlot(itemID, numMoved)

						if toBag then
	--						PickupContainerItem(bag, i)
							SplitContainerItem(bag, i, numMoved)

							PickupContainerItem(toBag, toSlot)

							-- "un"reserve items from the queue inventory
							self:ReserveItemForQueue(self.player, itemID, -numMoved)

							self:print("collecting",itemName,"x",numMoved,"from bank")
							itemMoved = true
						end
					end
				end
			end
		end

		bankLocked = nil

		self:RegisterEvent("BAG_UPDATE")

		if itemMoved then
			self:InventoryScan()
		end
	end


	function GnomeWorks:GUILDBANKFRAME_OPENED(...)
		local numTabs = GetNumGuildBankTabs()

		for tab=1,numTabs do
			QueryGuildBankTab(tab)
		end
	end


	function GnomeWorks:GuildBankScan(...)
		if bankLocked then return end

		bankLocked = true


		local itemMoved

		local player = self.player or UnitName("player")
		local playerData = self.data.playerData

		local guild = playerData[player].guild

		local key = "GUILD:"..guild

		if not self.data.inventoryData[key] then
			self.data.inventoryData[key] = { bank = {} }
		end

		local invData = self.data.inventoryData[key].bank


		table.wipe(invData)


		-- temporarily disable bag update scanning while we're grabbing items from the bank.  we'll do a manual adjustment after each retrieval
		self:UnregisterEvent("BAG_UPDATE")

		for id,cache in pairs(bagCache) do
			table.wipe(cache)
		end

		local numTabs = GetNumGuildBankTabs()

		for tab=1,numTabs do
			local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)

			if numWithdrawals > 0 and remainingWithdrawals > 0 then
				for slot=1,98 do
					local link = GetGuildBankItemLink(tab,slot)

--					self:GuildBankRecordData(tab,slot,itemID,numAvailable)

					if link then
						local _,numAvailable = GetGuildBankItemInfo(tab, slot)
						local itemID = tonumber(string.match(link, "item:(%d+)"))

						if self.data.reagentUsage[itemID] or self.data.itemSource[itemID] then
							invData[itemID] = (invData[itemID] or 0) + numAvailable
						end

						local onHand = self:GetInventoryCount(itemID, self.player, "craftedBag queue")

						if onHand < 0 then
							local count = -onHand

							ClearCursor()

							local itemName, _, _, _, _, _, _, stackSize = GetItemInfo(link)

							local numMoved

							if numAvailable < count then
								numMoved = numAvailable
							else
								numMoved = count
							end

							local toBag, toSlot = FindBagSlot(itemID, numMoved)

							if toBag then
								SplitGuildBankItem(tab, slot, numMoved)

								PickupContainerItem(toBag, toSlot)

								-- "un"reserve items from the queue inventory
								self:ReserveItemForQueue(self.player, itemID, -numMoved)

								self:print("collecting",itemName,"x",numMoved,"from guild bank")
								itemMoved = true
							end
						end
					end
				end
			end
		end

		bankLocked = nil

		self:RegisterEvent("BAG_UPDATE")

		if itemMoved then
			self:InventoryScan()
		end
	end


	function GnomeWorks:GUILDBANKBAGSLOTS_CHANGED(...)
		if updateTimer then
			self:CancelTimer(updateTimer, true)
		end

		updateTimer = self:ScheduleTimer("GuildBankScan",.01)
	end
end


