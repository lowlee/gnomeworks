





local function DebugSpam(...)
--	print(...)
end


do
	local clientVersion, clientBuild = GetBuildInfo()


	local skillTypeStyle = {
		["unknown"]			= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
		["optimal"]	        = { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
		["medium"]          = { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",  cstring = "|cffffff00"},
		["easy"]            = { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",   cstring = "|cff40c000"},
		["trivial"]	        = { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext="",    cstring = "|cff808080"},
		["header"]          = { r = 1.00, g = 0.82, b = 0,    level = 0, alttext="",    cstring = "|cffffc800"},
	}

	local skillTypeColor = {
		["unknown"]			= { r = 1.00, g = 0.00, b = 0.00,},
		["optimal"]	        = { r = 1.00, g = 0.50, b = 0.25,},
		["medium"]          = { r = 1.00, g = 1.00, b = 0.00,},
		["easy"]            = { r = 0.25, g = 0.75, b = 0.25,},
		["trivial"]	        = { r = 0.50, g = 0.50, b = 0.50,},
		["header"]          = { r = 1.00, g = 0.82, b = 0,   },
	}


	local tradeIDList = {
		2259,           -- alchemy
		2018,           -- blacksmithing
		7411,           -- enchanting
		4036,           -- engineering
		45357,			-- inscription
		25229,          -- jewelcrafting
		2108,           -- leatherworking
--		2575,			-- mining (or smelting?)
		2656,           -- smelting (from mining)
		3908,           -- tailoring
		2550,           -- cooking
		3273,           -- first aid

		53428,			-- runeforging


		51005,			-- milling
		13262,			-- disenchant
		31252,			-- prospecting
	}

--	local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }

	local unlinkableTrades = {
		[2656] = true,           -- smelting (from mining)
		[53428] = true,			-- runeforging
		[51005] = true,			-- milling
		[13262] = true,			-- disenchant
		[31252] = true,			-- prospecting
	}


	local skillIndexLookup = {}


	local tradeIDByName = {}

	for index, id in pairs(tradeIDList) do
		local tradeName = GnomeWorks:GetTradeName(id)
		tradeIDByName[tradeName] = id
	end

	tradeIDByName[GetSpellInfo(2575)] = 2656	-- special case for mining/smelting


	GnomeWorks.data = { skillDB = {}, linkDB = {} }
	local data = GnomeWorks.data

	local linkDB = data.linkDB


	local dataScanned = {}



	local function GetIDFromLink(link)
		if link then
			local id = string.match(link,"item:(%d+)")  or string.match(link,"spell:(%d+)") or string.match(link,"enchant:(%d+)") or string.match(link,"trade:(%d+)")

			return tonumber(id)
		end
	end


	local function AddToDataTable(dataTable, a, b, num)
		if a and b then
			if dataTable[a] then
				dataTable[a][b] = num
			else
				dataTable[a] = { [b] = num }
			end

			return dataTable[a]
		end
	end


	function GnomeWorks:AddToItemCache(itemID, recipeID, numMade)

		if false and not GnomeWorksDB.results[-itemID] then

			local deTable = LSW.getDisenchantResults(itemID)

				if deTable then
	--			itemCache[itemID].deTable = deTable


				GnomeWorksDB.tradeIDs[-itemID] = 13262			-- Disenchant
				GnomeWorksDB.names[-itemID] = "Disenchant "..(GetItemInfo(itemID)) or "item:"..itemID
				GnomeWorksDB.results[-itemID] = deTable

				for resultID, count in pairs(deTable) do
					self:AddToItemCache(resultID, -itemID, count)

					GnomeWorksDB.reagents[-itemID] = GnomeWorksDB.reagents[recipeID] or { [itemID] = 1 }
				end

			end
--[[
			local itemName, itemLink, itemRarity, itemLevel  = GetItemInfo(itemID)
			local reqLevel = 1

			if itemLevel >= 21 and itemLevel <= 60 then
				reqLevel = (math.ceil(itemLevel/5)-4) * 25
			else
				if itemRarity < 5 then
					if itemLevel < 100 then
						reqLevel = 225
					elseif itemLevel < 130 then
						reqLevel = 275
					elseif itemLevel < 154 then
						reqLevel = 325
					else
						reqLevel = 350
					end
				else
					if itemLevel < 90 then
						reqLevel = 225
					elseif itemLevel < 130 then
						reqLevel = 300
					elseif itemLevel < 154 then
						reqLevel = 325
					elseif itemLevel < 200 then
						reqLevel = 350
					end
				end
			end

			recipeCache[-itemID].canCraft = { "playerDisenchantLevel", reqLevel }

			if recipeID then
				if not itemCache[itemID].craftSource then
					itemCache[itemID].craftSource = {}
				end

				itemCache[itemID].craftSource[recipeID] = numMade or 1
			end
]]
		end

--		itemCache[itemID].BOP = itemBOPCheck(itemID)

		return AddToDataTable(GnomeWorks.data.itemSource, itemID, recipeID, numMade)
	end


	function GnomeWorks:AddToReagentCache(reagentID, recipeID, numNeeded)
		return AddToDataTable(GnomeWorks.data.reagentUsage, reagentID, recipeID, numNeeded)
	end



	function GnomeWorks:CacheTradeSkillLink(link)
		if link and string.match(link,"trade:") then
			local isLinked,player = IsTradeSkillLinked()

			if player and isLinked then
				if player == UnitName("player") then -- and (rank ~= self:GetTradeSkillRank(player, tradeID) or rank == 0) then
	--				player = player.." ShoppingList"
					player = "All Recipes"
				end


				if not GnomeWorks.data.playerData[player] then

					local tradeID = tradeIDByName[GetTradeSkillLine()]

					if not linkDB[player] then
						linkDB[player] = {}
					end

					linkDB[player][tradeID] = link
				end
			end
		end
	end



	function GnomeWorks:ParseSkillList()
DebugSpam("parsing skill list")
		local playerName = UnitName("player")

		self.data.playerData[playerName] = { links = {}, build = clientBuild, guild = GetGuildInfo("player") }

		local playerData = self.data.playerData[playerName]

		for k,id in pairs(tradeIDList) do
			local link, tradeLink = GetSpellLink((GetSpellInfo(id)))

			if link then
DebugSpam("found ", link, tradeLink)

				if unlinkableTrades[id] then
					tradeLink = "|cffffd000|Htrade:"..id..":1:1:0:/|h["..GnomeWorks:GetTradeName(id).."]|h|r"			-- fake link for data collection purposes
				end

				playerData.links[id] = tradeLink
			end
		end


		playerName = "All Recipes"
		self.data.playerData[playerName] = { links = {}, build = clientBuild }

		local playerData = self.data.playerData[playerName]

		for k,id in pairs(tradeIDList) do
			local link, tradeLink = GetSpellLink(id)
--print(link, tradeLink)

			if tradeLink then
				local tradeID,ranks,guid,bitMap,tail = string.match(tradeLink,"(|c%x+|Htrade:%d+):(%d+:%d+):([0-9a-fA-F]+:)([A-Za-z0-9+/]+)(|h%[[^]]+%]|h|r)")

				local fullBitMap = string.rep("/",string.len(bitMap or ""))

				playerData.links[id] = string.format("%s:450:450:%s%s%s",tradeID, guid, fullBitMap, tail)

--				print(playerData.links[id])
			else
				playerData.links[id] = "|cffffd000|Htrade:"..id..":1:1:0:/|h["..GnomeWorks:GetTradeName(id).."]|h|r"			-- fake link for data collection purposes
			end
		end
DebugSpam("done parsing skill list")

--[[
		for k,name in pairs({"Smelting", "Mining"}) do
			for k,spellID in pairs({2575, 2656 }) do
				for i=4,10 do
					local bitMap = string.rep("/",i)
					local tradeString = "trade:"..spellID..":1:1:10000000345738B:"..bitMap
					local tradeLink = "|cffffd000|H"..tradeString.."|h["..name.."]|h|r"
					SetItemRef(tradeString,tradeLink,"LeftButton")

					print(tradeString, tradeLink)
				end
			end
		end
]]
	end

	function GnomeWorks:OpenTradeLink(tradeLink, player)
		if tradeLink then
			local tradeString = string.match(tradeLink, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

			local tradeID = string.match(tradeString,"trade:(%d+)")

			tradeID = tonumber(tradeID)

			if not unlinkableTrades[tradeID] then
				SetItemRef(tradeString,tradeLink,"LeftButton")
			else
				self.tradeID = tradeID
				self.player = player
--				self:SelectSkill(1)


				self:ScheduleTimer("UpdateMainWindow",.01)
--				self:UpdateMainWindow()
			end
		end
	end



	function GnomeWorks:SelectSkill(index)
		self.selectedSkill = index

		if unlinkableTrades[self.tradeID] then
			self:ShowDetails(index)
			self:ShowReagents(index)

			self:SkillListDraw(index)

			self:ScrollToIndex(index)
		else
			if index then
				local skillName, skillType = GetTradeSkillInfo(index)

				if skillType ~= "header" then
					SelectTradeSkill(index)
					self:ShowDetails(index)
					self:ShowReagents(index)
					self:SkillListDraw(index)

	--				self:ShowSkillList()

					self:ScrollToIndex(index)
				else
		--			self:HideDetails()
		--			self:HideReagents()

		--			SelectTradeSkill(index)

				end
			end
		end

		self:SendMessageDispatch("GnomeWorksDetailsChanged")
	end


	function GnomeWorks:SelectEntry(entry)
		self.selectedEntry = entry
		self:SelectSkill(entry.index)
	end


	function GnomeWorks:ResetSkillSelect()
		self.selectedEntry = nil
	end



	local function DoRecipeSelection(recipeID)
--		local player = GnomeWorks.player

--		if recipeID and GnomeWorksDB.results[recipeID] and GnomeWorks.data.skillIndexLookup[player] then
--			local tradeID = GnomeWorksDB.tradeIDs[recipeID]
--			local skillIndex = GnomeWorks.data.skillIndexLookup[player][recipeID]

			local skillIndex

			local enchantString = "enchant:"..recipeID.."|h"

			for i=1,GetNumTradeSkills() do
				local link = GetTradeSkillRecipeLink(i)

				if link and string.find(link, enchantString) then

					skillIndex = i
					break
				end
			end

			if skillIndex then
				GnomeWorks:SelectSkill(skillIndex)
			end


--			GnomeWorks:UnregisterMessage("GnomeWorksScanComplete")
--		end

		return true
	end


	function GnomeWorks:SelectRecipe(recipeID)
		if not recipeID then return end

		if type(recipeID) == "table" then
			recipeID = next(recipeID) or recipeID[1]				-- TODO: dropdown for selection?
		end

		local player = self.player
		local tradeID = GnomeWorksDB.tradeIDs[recipeID]

		if tradeID ~= self.tradeID then
			if player == (UnitName("player")) then
				CastSpellByName((GetSpellInfo(tradeID)))
			else
				self:OpenTradeLink(self:GetTradeLink(tradeID, player), player)
			end

			GnomeWorks:RegisterMessageDispatch("GnomeWorksScanComplete", function() DoRecipeSelection(recipeID) return true end)			-- return true = fire once
		else
			DoRecipeSelection(recipeID)
		end
	end



	function GnomeWorks:PushSelection()
		local newEntry = { player = self.player, tradeID = self.tradeID, entry = self.selectedEntry }

		table.insert(self.data.selectionStack, newEntry)
	end


	function GnomeWorks:PopSelection()
		local stack = self.data.selectionStack
		local lastEntry = #stack

		if lastEntry>0 then
			local player,tradeID,entry = stack[lastEntry].player, stack[lastEntry].tradeID, stack[lastEntry].entry
--print(player,tradeID,skill)
			if tradeID ~= self.tradeID then
				if player == (UnitName("player")) then
					CastSpellByName((GetSpellInfo(tradeID)))
				else
					self:OpenTradeLink(self:GetTradeLink(tradeID, player), player)
				end


				GnomeWorks:RegisterMessageDispatch("GnomeWorksScanComplete", function() GnomeWorks:SelectEntry(entry) return true end)
			else
				self:SelectEntry(entry)
			end

			stack[lastEntry] = nil
		end
	end





	function GnomeWorks:ScanTrade()
		if self.scanInProgress == true then
	DebugSpam("SCAN BUSY!")
			return
		end


		self.scanInProgress = true

		local tradeID
		local localPlayer


		local tradeName, rank, maxRank = GetTradeSkillLine()
	DebugSpam("GetTradeSkill: "..(tradeName or "nil").." "..rank)


		-- get the tradeID from the tradeName name (data collected earlier).
		tradeID = tradeIDByName[tradeName]

		if not tradeID then
			self.scanInProgress = nil
			return
		end


		if tradeID == 2656 then				-- stuff the rank info into the fake smelting link for this character
			self.data.playerData[UnitName("player")].links[tradeID] = "|cffffd000|Htrade:2656:"..rank..":"..maxRank..":0:/|h["..GetSpellInfo(tradeID) .."]|h|r"			-- fake link for data collection purposes
		end


		local isLinked, playerLinked = IsTradeSkillLinked()

		if isLinked then
--			self:CacheTradeSkillLink(GetTradeSkillListLink()) -- this makes a temporary slot, then it will be over-written by the hooked method

			player = playerLinked
			if player == UnitName("player") then -- and (rank ~= self:GetTradeSkillRank(player, tradeID) or rank == 0) then
--				player = player.." ShoppingList"
				player = "All Recipes"
			end

--			print(player.." "..rank.."/"..maxRank)
		else
			player = UnitName("player")
			localPlayer = true
		end



		self.tradeID = tradeID
		self.player = player

--[[
		if self.selectedSkill == nil or self.selectedSkill > GetNumTradeSkills() then
			self:SelectSkill(GetFirstTradeSkill())
		end


		GnomeWorks.skillFrame.scrollFrame.selectedIndex = self.selectedSkill
]]

		if not recacheRecipe then
			recacheRecipe = {}
		end


	-- expand all headers, but turn off update events so we don't end up with recursion
		self:UnregisterEvent("TRADE_SKILL_UPDATE")
		for i = 1, GetNumTradeSkills() do
			local skillName, skillType, _, isExpanded = GetTradeSkillInfo(i)

			if skillType == "header" then
				if not isExpanded then
					ExpandTradeSkillSubClass(i)
				end

			end
		end
		self:RegisterEvent("TRADE_SKILL_UPDATE")


		local numSkills = GetNumTradeSkills()


	DebugSpam("Scanning Trade "..(tradeName or "nil")..":"..(tradeID or "nil").." "..numSkills.." recipes")


		local key = player..":"..tradeID


		dataScanned[key] = false


		if not data.skillDB[key] then
			data.skillDB[key] = { difficulty = {}, recipeID = {}, cooldown = {}}
		end


		local recipe = data.skillDB[key].recipeID
		local difficulty = data.skillDB[key].difficulty
		local cooldown = data.skillDB[key].cooldown


		local results = GnomeWorksDB.results
		local tradeIDs = GnomeWorksDB.tradeIDs
		local reagents = GnomeWorksDB.reagents


		local lastHeader = nil
		local gotNil = false



		local currentGroup = nil


		local mainGroup = self:RecipeGroupNew(player,tradeID,"By Category")

		mainGroup.locked = true
		mainGroup.autoGroup = true

		self:RecipeGroupClearEntries(mainGroup)


		local slotGroup = self:RecipeGroupNew(player,tradeID,"By Slot")

		slotGroup.locked = true
		slotGroup.autoGroup = true

		self:RecipeGroupClearEntries(slotGroup)



		local flatGroup = self:RecipeGroupNew(player,tradeID,"Flat")

		flatGroup.locked = true
		flatGroup.autoGroup = true

		self:RecipeGroupClearEntries(flatGroup)




		local groupList = {}



		local numHeaders = 0

		for i = 1, numSkills, 1 do
			repeat
				local subSpell, extra

				local skillName, skillType = GetTradeSkillInfo(i)

				gotNil = false


				if skillName then
					if skillType == "header" then
						numHeaders = numHeaders + 1

						local groupName

						if groupList[skillName] then
							groupList[skillName] = groupList[skillName]+1
							groupName = skillName.." "..groupList[skillName]
						else
							groupList[skillName] = 1
							groupName = skillName
						end

						currentGroup = self:RecipeGroupNew(player, tradeID, "By Category", groupName)
						currentGroup.autoGroup = true

						self:RecipeGroupAddSubGroup(mainGroup, currentGroup, i, true)
					else
						local recipeLink = GetTradeSkillRecipeLink(i)
						local recipeID = GetIDFromLink(recipeLink)

						if not recipeID then
							gotNil = true
							break
						end


						GnomeWorks:RecipeGroupAddRecipe(flatGroup, recipeID, i, true)


						if currentGroup then
							GnomeWorks:RecipeGroupAddRecipe(currentGroup, recipeID, i, true)
						else
							GnomeWorks:RecipeGroupAddRecipe(mainGroup, recipeID, i, true)
						end



						local cd = GetTradeSkillCooldown(i)

						recipe[i] = recipeID
						difficulty[i] = skillType

						if cd then
							cooldown[i] = cd + time()

--							skillDBString = skillDBString.." cd=" .. cd + time()
-- TODO: SaveCooldown info
						end


						skillIndexLookup[recipeID] = i

						if not results[recipeID] or recacheRecipe[recipeID] then
							local itemLink = GetTradeSkillItemLink(i)

							if not itemLink then
								gotNil = true
								break
							end


							local itemID, numMade = -recipeID, 1				-- itemID = RecipeID, numMade = 1 for enchants/item enhancements

							if GetItemInfo(itemLink) then
								itemID = GetIDFromLink(itemLink)

								local minMade,maxMade = GetTradeSkillNumMade(i)

								numMade = (minMade + maxMade) / 2

								GnomeWorks:AddToItemCache(itemID, recipeID, numMade)					-- add a cross reference for the source of particular items
							end




							local reagentData = {}

							for j=1, GetTradeSkillNumReagents(i), 1 do
								local reagentName, _, numNeeded = GetTradeSkillReagentInfo(i,j)

								local reagentID = 0

								if reagentName then
									local reagentLink = GetTradeSkillReagentItemLink(i,j)

									reagentID = GetIDFromLink(reagentLink)
								else
									gotNil = true
									break
								end

								reagentData[reagentID] = numNeeded

								self:AddToReagentCache(reagentID, recipeID, numNeeded)
--								self:ItemDataAddUsedInRecipe(reagentID, recipeID)				-- add a cross reference for where a particular item is used
							end

							reagents[recipeID] = reagentData
							tradeIDs[recipeID] = tradeID
							results[recipeID] = { [itemID] = numMade }

							if gotNil then
								recacheRecipe[recipeID] = true
							end

						end
					end
				else
					gotNil = true
				end
			until true

			if gotNil and recipeID then
				recacheRecipe[recipeID] = true
			end
		end




--	DebugSpam("Scan Complete")



		self:InventoryScan()

		self:ScanSlotGroups(slotGroup)


--		self:RecipeGroupConstructDBString(mainGroup)
--		self:RecipeGroupConstructDBString(flatGroup)
--		self:RecipeGroupConstructDBString(slotGroup)

		self.scanInProgress = false



		collectgarbage("collect")

		if numHeaders > 0 then
			dataScanned[key] = true
		else
			self:ScheduleTimer("ScanTrade",5)
		end


		self:ScheduleTimer("UpdateMainWindow",.1)
		self:SendMessageDispatch("GnomeWorksScanComplete")
--		self:SendMessageDispatch("GnomeWorksDetailsChanged")



		return skillData, player, tradeID
	end


--[[
	function SkilletData:EnchantingRecipeSlotAssign(recipeID, slot)
		local recipeString = Skillet.db.account.recipeDB[recipeID]

		local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)

		if itemString == "0" then
			itemString = "0:"..slot

			Skillet.db.account.recipeDB[recipeID] = tradeID.." 0:"..slot.." "..reagentString.." "..toolString

			Skillet:GetRecipe(recipeID)
	--DEFAULT_CHAT_FRAME:AddMessage(Skillet.data.recipeList[recipeID].name or "noName")

			Skillet.data.recipeList[recipeID].slot = slot
		end
	end



	local invSlotLookup = {
		["HEADSLOT"] = "HeadSlot",
		["NECKSLOT"] = "NeckSlot",
		["SHOULDERSLOT"] = "ShoulderSlot",
		["CHESTSLOT"] = "ChestSlot",
		["WAISTSLOT"] = "WaistSlot",
		["LEGSSLOT"] = "LegsSlot",
		["FEETSLOT"] = "FeetSlot",
		["WRISTSLOT"] = "WristSlot",
		["HANDSSLOT"] = "HandsSlot",
		["FINGER0SLOT"] = "Finger0Slot",
		["TRINKET0SLOT"] = "Trinket0Slot",
		["BACKSLOT"] =	"BackSlot",
		["ENCHSLOT_WEAPON"] = "MainHandSlot",
		["ENCHSLOT_2HWEAPON"] = "MainHandSlot",
		["SHIELDSLOT"] = "SecondaryHandSlot",
	}
]]


	function GnomeWorks:ScanSlotGroups(mainGroup)
		local groupList = {}

		self:UnregisterEvent("TRADE_SKILL_UPDATE")

		if mainGroup then

			local TradeSkillSlots = { GetTradeSkillInvSlots() }

			self:RecipeGroupClearEntries(mainGroup)

			for i=1,#TradeSkillSlots do
				local groupName
				local slotName = TradeSkillSlots[i]

				local invSlot

				if groupList[slotName] then
					groupList[slotName] = groupList[slotName]+1
					groupName = slotName.." "..groupList[slotName]
				else
					groupList[slotName] = 1
					groupName = slotName
				end

				local currentGroup = self:RecipeGroupNew(self.player, self.tradeID, "By Slot", groupName)

				SetTradeSkillInvSlotFilter(i,1,1)

				for s=1,GetNumTradeSkills() do
					local recipeLink = GetTradeSkillRecipeLink(s)


--[[
					if TradeSkillSlots[i] ~= "NONEQUIPSLOT" then
						invSlot = GetInventorySlotInfo(invSlotLookup[ TradeSkillSlots[i] ])
						self:EnchantingRecipeSlotAssign(recipeID, invSlot)
					end
]]


					if recipeLink then
						local recipeID = GetIDFromLink(recipeLink)
DebugSpam("adding "..(recipeLink or "nil").." to "..groupName)
						self:RecipeGroupAddRecipe(currentGroup, recipeID, skillIndexLookup[recipeID], true)
					end

				end

				self:RecipeGroupAddSubGroup(mainGroup, currentGroup, i, true)
			end
		end

		SetTradeSkillInvSlotFilter(0,1,1)

		self:RegisterEvent("TRADE_SKILL_UPDATE")
	end



	function GnomeWorks:GetTradeSkillRank(player, tradeID)
		if not IsTradeSkillLinked() then
			local skill, rank, maxRank = GetTradeSkillLine()

			return rank, maxRank
		end

		tradeID = tradeID or self.tradeID
		player = player or self.player

		if not player then
			print("player is nil")
		end

		if not tradeID then
			print("tradeID is nil")
		end

		local link = (self.data.playerData[player] and self.data.playerData[player].links[tradeID])

		if not link then
			link = linkDB[player] and linkDB[player][tradeID]
		end

		if link then
			local rank, maxRank = string.match(link,"trade:%d+:(%d+):(%d+)")

			return tonumber(rank), tonumber(maxRank)
		end

		return 0, 0
	end



	function GnomeWorks:GetSkillColor(index)
		local skillName, skillType = self:GetTradeSkillInfo(index)

		return skillTypeColor[skillType]
	end

	function GnomeWorks:GetSkillDifficultyLevel(index)
		local skillName, skillType = self:GetTradeSkillInfo(index)

		return skillTypeStyle[skillType or "unknown"].level
	end

	function GnomeWorks:GetSkillDifficulty(index)
		local skillName, skillType = self:GetTradeSkillInfo(index)

		return skilltype
	end


	function GnomeWorks:GetTradeLinkList(player)
		player = player or self.player

		return (self.data.playerData[player] and self.data.playerData[player].links) or linkDB[player]
	end

	function GnomeWorks:GetTradeLink(tradeID, player)
		return self:GetTradeLinkList(player)[tradeID]
	end


	function GnomeWorks:IsSpellKnown(recipeID, player)
		player = player or self.player

		local tradeID = GnomeWorksDB.tradeIDs[recipeID]

		local tradeLink = self.data.playerData[player].links[tradeID]

		if tradeLink and self.libTS then
			return self.libTS:CheckForSpell(tradeLink, recipeID)
		else
			return true
		end

		return false
	end
end
