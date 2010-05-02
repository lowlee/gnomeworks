





local function DebugSpam(s)
--	print(s)
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
	--	2575,			-- mining (or smelting?)
		2656,           -- smelting (from mining)
		3908,           -- tailoring
		2550,           -- cooking
		3273,           -- first aid

		53428,			-- runeforging
	}

--	local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }


	local tradeIDByName = {}

	for index, id in pairs(tradeIDList) do
		local tradeName = GetSpellInfo(id)
		tradeIDByName[tradeName] = id
	end

	tradeIDByName[GetSpellInfo(2575)] = 2656	-- special case for mining/smelting


	GnomeWorks.data = { skillIndexLookup = {}, skillDB = {}, recipeDB = {}, linkDB = {} }
	local data = GnomeWorks.data

	local skillIndexLookup = data.skillIndexLookup
	local linkDB = data.linkDB


	local dataScanned = {}



	local function GetIDFromLink(link)
		if link then
			local id = string.match(link,"item:(%d+)")  or string.match(link,"spell:(%d+)") or string.match(link,"enchant:(%d+)") or string.match(link,"trade:(%d+)")

			return tonumber(id)
		end
	end


	local function AddToDataTable(dataTable, itemID, recipeID)
		if recipeID and itemID then
			if dataTable[itemID] then
				if type(dataTable[itemID]) == "number" then
					if dataTable[itemID] ~= recipeID then
						dataTable[itemID] = { [dataTable[itemID]] = true, [recipeID] = true }
					end
				else
					dataTable[itemID][recipeID] = true
				end
			else
				dataTable[itemID] = recipeID
			end
		end
	end


	local function AddToItemCache(itemID, recipeID)
--[[
			local deTable = LSW.getDisenchantResults(itemID)

			if deTable then
				itemCache[itemID].deTable = deTable

				for reagentID, count in pairs(deTable) do
					local cache = AddToItemCache(reagentID)

					if not cache.craftSource then
						cache.craftSource = {}
					end

					cache.craftSource[-itemID] = count


					recipeCache[-itemID] = {}

					recipeCache[-itemID].name = "Disenchant "..(GetItemInfo(itemID) or "item:"..itemID)

					recipeCache[-itemID].craftResults = deTable

					if recipeCache[recipeID] then										-- if item is craftable, copy the reagents to the de reagents otherwise just stuff in the itemID as the sole reagent
						recipeCache[-itemID].reagents = recipeCache[recipeID].reagents
					else
						recipeCache[-itemID].reagents = { [itemID] = 1 }
					end
				end

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
			end

			itemCache[itemID].BOP = itemBOPCheck(itemID)
]]

		AddToDataTable(GnomeWorksDB.itemSource, itemID, recipeID)
	end


	local function AddToReagentCache(reagentID, recipeID)
		AddToDataTable(GnomeWorksDB.reagentUsage, reagentID, recipeID)
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
		local playerName = UnitName("player")

		if not self.data.playerData then
			self.data.playerData = {}
		end

		self.data.playerData[playerName] = { links = {}, build = clientBuild }

		local playerData = self.data.playerData[playerName]

		for k,id in pairs(tradeIDList) do
			local link, tradeLink = GetSpellLink((GetSpellInfo(id)))

			if link then
				if id == 2656 then
					tradeLink = "|cffffd000|Htrade:2656:1:1:0:/|h["..GetSpellInfo(id) .."]|h|r"			-- fake link for data collection purposes
				end

				if id == 53428 then
					tradeLink = "|cffffd000|Htrade:53428:1:1:0:/|h["..GetSpellInfo(id) .."]|h|r"		-- fake link for data collection purposes
				end

				playerData.links[id] = tradeLink
			end
		end


		playerName = "All Recipes"
		self.data.playerData[playerName] = { links = {}, build = clientBuild }

		local playerData = self.data.playerData[playerName]

		for k,id in pairs(tradeIDList) do
			local link, tradeLink = GetSpellLink(id)

			if tradeLink then
				local tradeID,ranks,guid,bitMap,tail = string.match(tradeLink,"(|c%x+|Htrade:%d+):(%d+:%d+):([0-9a-fA-F]+:)([A-Za-z0-9+/]+)(|h%[[^]]+%]|h|r)")

				local fullBitMap = string.rep("/",string.len(bitMap or ""))

				playerData.links[id] = string.format("%s:450:450:%s%s%s",tradeID, guid, fullBitMap, tail)

--				print(playerData.links[id])
			end
		end
	end


	function GnomeWorks:OpenTradeLink(tradeLink)
		if tradeLink then
			local tradeString = string.match(tradeLink, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

			if (UnitName("player")) == player then
				local tradeName = GetSpellInfo(string.match(tradeString, "trade:(%d+)"))

				if ((GetTradeSkillLine() == "Mining" and "Smelting") or GetTradeSkillLine()) ~= tradeName or IsTradeSkillLinked() then
					CastSpellByName(tradeName)
				end
			else
				SetItemRef(tradeString,tradeLink,"LeftButton")
			end
		end
	end



	function GnomeWorks:SelectSkill(index)
		if index then
			local skillName, skillType = GetTradeSkillInfo(index)

			if skillType ~= "header" then
				SelectTradeSkill(index)
				self:ShowDetails(index)
				self:ShowReagents(index)

				self.selectedSkill = index

				self:ShowSkillList()

				self:ScrollToIndex(index)
			else
	--			self:HideDetails()
	--			self:HideReagents()

	--			SelectTradeSkill(index)

			end
		end
	end

	local function DoRecipeSelection(recipeID)
	local player = GnomeWorks.player

		if recipeID and GnomeWorks.data.recipeDB[recipeID] and GnomeWorks.data.skillIndexLookup[player] then
			local tradeID = GnomeWorks.data.recipeDB[recipeID].tradeID
			local skillIndex = GnomeWorks.data.skillIndexLookup[player][recipeID]

			if skillIndex then
				GnomeWorks:SelectSkill(skillIndex)
			end
		end
	end


	function GnomeWorks:SelectRecipe(tradeID, recipeID)
		local player = self.player

		if tradeID ~= self.tradeID then
			if player == (UnitName("player")) then
				CastSpellByName((GetSpellInfo(tradeID)))
			else
				self:OpenTradeLink(self:GetTradeLink(tradeID, player))
			end

			GnomeWorks:RegisterMessage("GnomeWorksScanComplete", function() DoRecipeSelection(recipeID) end)
		else
			DoRecipeSelection(recipeID)
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

		if tradeID == 2656 then				-- stuff the rank info into the fake smelting link for this character
			self.data.playerData[UnitName("player")].links[tradeID] = "|cffffd000|Htrade:2656:"..rank..":"..maxRank..":0:/|h["..GetSpellInfo(tradeID) .."]|h|r"			-- fake link for data collection purposes
		end


		local isLinked, playerLinked = IsTradeSkillLinked()

		if isLinked then
			self:CacheTradeSkillLink(GetTradeSkillListLink()) -- this makes a temporary slot, then it will be over-written by the hooked method

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


		if not recacheRecipe then
			recacheRecipe = {}
		end


	-- expand all headers, but turn off update events so we don't end up with recursion (fails under 3.3.3 -- boo)
--		self:UnregisterEvent("TRADE_SKILL_UPDATE")
		for i = 1, GetNumTradeSkills() do
			local skillName, skillType, _, isExpanded = GetTradeSkillInfo(i)

			if skillType == "header" then
				if not isExpanded then
					ExpandTradeSkillSubClass(i)
				end

			end
		end
--		self:RegisterEvent("TRADE_SKILL_UPDATE")


		local numSkills = GetNumTradeSkills()


	DebugSpam("Scanning Trade "..(tradeName or "nil")..":"..(tradeID or "nil").." "..numSkills.." recipes")

		if not skillIndexLookup[player] then
			skillIndexLookup[player] = {}
		end

		local key = player..":"..tradeID


		dataScanned[key] = false


		if not data.skillDB[key] then
			data.skillDB[key] = {}
		end


		local skillData = data.skillDB[key]

		local lastHeader = nil
		local gotNil = false

		local currentGroup = nil

		local mainGroup = self:RecipeGroupNew(player,tradeID,"Blizzard")

		mainGroup.locked = true
		mainGroup.autoGroup = true

		self:RecipeGroupClearEntries(mainGroup)

		local groupList = {}



		local numHeaders = 0

		for i = 1, numSkills, 1 do
			repeat
	--DebugSpam("scanning index "..i)
				local subSpell, extra


				local skillName, skillType = GetTradeSkillInfo(i)


	--DebugSpam("**** skill: "..(skillName or "nil"))

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

						skillData[i] = "header "..skillName
						skillData[i] = nil

						currentGroup = self:RecipeGroupNew(player, tradeID, "Blizzard", groupName)
						currentGroup.autoGroup = true

						self:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
					else
						local recipeLink = GetTradeSkillRecipeLink(i)
						local recipeID = GetIDFromLink(recipeLink)

						if not recipeID then
							gotNil = true
							break
						end

						if currentGroup then
							GnomeWorks:RecipeGroupAddRecipe(currentGroup, recipeID, i)
						else
							GnomeWorks:RecipeGroupAddRecipe(mainGroup, recipeID, i)
						end


						-- break recipes into lists by profession for ease of sorting
						skillData[i] = {}

		--					skillData[i].name = skillName
						skillData[i].id = recipeID
						skillData[i].difficulty = skillType
						skillData[i].color = skillTypeStyle[skillType]
		--				skillData[i].category = lastHeader


						local cd = GetTradeSkillCooldown(i)

						if cd then
							skillData[i].cooldown = cd + time()		-- this is when your cooldown will be up

--							skillDBString = skillDBString.." cd=" .. cd + time()
-- TODO: SaveCooldown info
						end


						skillIndexLookup[player][recipeID] = i

						if not data.recipeDB[recipeID] or recacheRecipe[recipeID] then
							data.recipeDB[recipeID] = {}

							data.recipeDB[recipeID].craftable = localPlayer

							local recipe = data.recipeDB[recipeID]

							recipe.tradeID = tradeID
							recipe.spellID = recipeID

							recipe.name = skillName

							local itemLink = GetTradeSkillItemLink(i)

							if not itemLink then
								gotNil = true
								break
							end


							if GetItemInfo(itemLink) then
								local itemID = GetIDFromLink(itemLink)

								local minMade,maxMade = GetTradeSkillNumMade(i)

								local numMade = (minMade + maxMade) / 2


								recipe.itemID = itemID
								recipe.numMade = (minMade + maxMade)/2

								AddToItemCache(itemID,recipeID)					-- add a cross reference for the source of particular items
							else
								recipe.numMade = 1
								recipe.itemID = 0												-- indicates an enchant
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

								reagentData[j] = {}

								reagentData[j].id = reagentID
								reagentData[j].numNeeded = numNeeded

								AddToReagentCache(reagentID, recipeID)
--								self:ItemDataAddUsedInRecipe(reagentID, recipeID)				-- add a cross reference for where a particular item is used
							end

							recipe.reagentData = reagentData

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


	--	Skillet:RecipeGroupConstructDBString(mainGroup)

--	DebugSpam("Scan Complete")


		GnomeWorks:InventoryScan()
--		GnomeWorks:CalculateCraftableCounts()
--[[
		Skillet:SortAndFilterRecipes()
	DebugSpam("all sorted")
]]



		self.scanInProgress = false



		collectgarbage("collect")

		if numHeaders > 0 then
			dataScanned[key] = true
		else
			GnomeWorks:ScheduleTimer("ScanTrade",5)
		end

		self.currentPlayer = player
		self.currentTradeID = tradeID

		GnomeWorks:ScheduleTimer("UpdateMainWindow",.1)
		GnomeWorks:SendMessage("GnomeWorksScanComplete")

		return skillData, player, tradeID
	--	AceEvent:TriggerEvent("Skillet_Scan_Complete", profession)
	end


	function GnomeWorks:GetTradeSkillRank(player, tradeID)
		tradeID = tradeID or self.tradeID
		player = player or self.player

		local link = (self.data.playerData[player] and self.data.playerData[player].links[tradeID]) or linkDB[player][tradeID]

		if link then
			local rank, maxRank = string.match(link,"trade:%d+:(%d+):(%d+)")

			return tonumber(rank), tonumber(maxRank)
		end

		return 0, 0
	end



	function GnomeWorks:GetSkillColor(index)
		local skillName, skillType = GetTradeSkillInfo(index)

		return skillTypeColor[skillType]
	end

	function GnomeWorks:GetSkillData(skillIndex, key)
		key = key or self.player..":"..self.tradeID

		return self.data.skillDB[key][skillIndex]
	end


	function GnomeWorks:GetRecipeData(recipeID)
		return self.data.recipeDB[recipeID]
	end


	function GnomeWorks:GetTradeLinkList(player)
		player = player or self.player

		return (self.data.playerData[player] and self.data.playerData[player].links) or linkDB[player]
	end

	function GnomeWorks:GetTradeLink(tradeID, player)
		return self:GetTradeLinkList(player)[tradeID]
	end
end
