




--[[
	CloseTradeSkill() - Closes an open trade skill window.
	CollapseTradeSkillSubClass(index) - Collapses the specified subclass header row.
	DoTradeSkill(index[, repeatTimes]) - Performs the tradeskill a specified # of times.
	ExpandTradeSkillSubClass(index) - Expands the specified subclass header row.
	GetFirstTradeSkill() - Returns the index of the first non-header trade skill entry.
	GetNumTradeSkills() - Get the number of trade skill entries (including headers).
	GetTradeSkillCooldown(index) - Returns the number of seconds left for a skill to cooldown.
	GetTradeSkillDescription(index) - Returns the description text of the indicated trade skill.
	GetTradeSkillIcon(index) - Returns the texture name of a tradeskill's icon.
	GetTradeSkillInfo(index) - Retrieves information about a specific trade skill.
	GetTradeSkillInvSlotFilter(slotIndex) - Returns 1 if items corresponding to slotIndex are currently visible, otherwise nil.
	GetTradeSkillInvSlots() - Returns a list of the available inventory slot types.
	GetTradeSkillItemLink(index) - Returns the itemLink for a trade skill item.
	GetTradeSkillLine() - Returns information about the selected skill line.
	GetTradeSkillListLink() - Returns the TradeSkillLink for a trade skill.
	GetTradeSkillNumMade(index) - Gets the number of items made in a single use of a skill.
	GetTradeSkillNumReagents(tradeSkillRecipeId) - Returns the number of different reagents required.
	GetTradeSkillReagentInfo(tradeSkillRecipeId, reagentId) - Returns data on the reagent, including a count of the player's inventory.
	GetTradeSkillReagentItemLink(index, reagentId) - Returns the itemLink for one of the reagents needed to craft the given item
	GetTradeSkillRecipeLink(index) - Returns the EnchantLink for a trade skill.
	GetTradeSkillSelectionIndex() - Returns the Id of the currently selected trade skill, 0 if none selected.
	GetTradeSkillSubClassFilter(filterIndex) - Returns 1 if items corresponding to filterIndex are currently visible, otherwise nil.
	GetTradeSkillSubClasses() - Returns a list of the valid subclasses.
	GetTradeSkillTools(index) - Returns information about the tools needed for a tradeskill.
	GetTradeskillRepeatCount() - Returns the number of times the current item is being crafted.
	IsTradeskillTrainer() - Returns 1 if trainer is for a tradeskill.
	IsTradeSkillLinked() - Returns true if you're inspecting a tradeskill link rather then looking at your own tradeskills
	SelectTradeSkill(index) - Select a specific trade skill in the list.
	SetTradeSkillInvSlotFilter(slotIndex, onOff[, exclusive] ) - Set the inventory slot type filter.
	SetTradeSkillSubClassFilter(slotIndex, onOff[,exclusive] ) - Set the subclass filter.
	StopTradeSkillRepeat() - Stops creating additional queued items.
	TradeSkillOnlyShowMakeable(onlyMakable) - Controls whether only recipes you have the reagents to craft are shown.
]]--

do


	local unlinkableTrades = {
		[2656] = true,           -- smelting (from mining)
		[53428] = true,			-- runeforging
		[51005] = true,			-- milling
		[13262] = true,			-- disenchant
		[31252] = true,			-- prospecting
	}

	local tradeIcon = {
	}



	function GnomeWorks:ConstructPseudoTrades(player)
		self.data.pseudoTrade = {}

		for k,v in pairs(unlinkableTrades) do
			local list = {}

			local mainGroup = self:RecipeGroupNew(player,k,"Blizzard")

			for recipeID,tradeID in pairs(GnomeWorksDB.tradeIDs) do
				local index = #list + 1

				if tradeID == k then
					list[index] = recipeID

					GnomeWorks:RecipeGroupAddRecipe(mainGroup, recipeID, index)
				end
			end

			self.data.pseudoTrade[k] = list
		end
	end


	local PseudoTrade = {}

	function PseudoTrade:GetNumTradeSkills()
		return #GnomeWorks.data.pseudoTrade[self.tradeID]
	end

	function PseudoTrade:GetTradeSkillItemLink(index)
		local recipeID = self.data.pseudoTrade[self.tradeID][index]

		if recipeID < 0 then
			local _,link = GetItemInfo(-recipeID)

			return link
		else
			local _,link = GetItemInfo(next(GnomeWorksDB.results[recipeID]))

			return link
		end
	end


	function PseudoTrade:GetTradeSkillRecipeLink(index)
		local recipeID = self.data.pseudoTrade[self.tradeID][index]

		if recipeID < 0 then
			return "enchant:"..recipeID
		else
			return GetSpellLink(recipeID)
		end
	end



	function PseudoTrade:GetTradeSkillLine()
		return GnomeWorks:GetTradeName(self.tradeID), 1, 1
	end

	function PseudoTrade:GetTradeSkillInfo(index)
		local recipeID = self.data.pseudoTrade[self.tradeID][index]

		return self:GetRecipeName(recipeID) or "nil", "optimal"
	end

	function PseudoTrade:GetTradeSkillIcon(index)
		local recipeID = self.data.pseudoTrade[self.tradeID][index]
		if recipeID < 0 then
			return GetItemIcon(-recipeID)
		else
			local _,_,icon = GetSpellInfo(recipeID)
			return icon or ""
		end
	end

	function PseudoTrade:IsTradeSkillLinked()
		return true
	end

	function PseudoTrade:GetTradeSkillTools()
		return
	end

	function PseudoTrade:GetTradeSkillCooldown()
		return
	end

--[[
	function PseudoTrade:GetTradeSkillNumMade(index)
		local recipeID = self.data.pseudoTrade[self.tradeID][index]
		local itemID,count = next(GnomeWorksDB.results[recipeID])

		return count,count
	end
]]


	function GnomeWorks:GetTradeIcon(tradeID)
		if tradeIcon[tradeID] then
			return tradeIcon[tradeID]
		end

		local _,_,icon = GetSpellInfo(tradeID)

		return icon
	end




	local tradeSkillAPIs = {
--		"GetFirstTradeSkill",
		"GetNumTradeSkills",
		"GetTradeSkillCooldown",
		"GetTradeSkillDescription",
		"GetTradeSkillIcon",
		"GetTradeSkillInfo",
--		"GetTradeSkillInvSlotFilter",
--		"GetTradeSkillInvSlots",
		"GetTradeSkillItemLink",
		"GetTradeSkillLine",
--		"GetTradeSkillListLink",
		"GetTradeSkillNumMade",
--		"GetTradeSkillNumReagents",
--		"GetTradeSkillReagentInfo",
--		"GetTradeSkillReagentItemLink",
		"GetTradeSkillRecipeLink",
		"GetTradeSkillSelectionIndex",
--		"GetTradeSkillSubClassFilter",
--		"GetTradeSkillSubClasses",
		"GetTradeSkillTools",
--		"GetTradeskillRepeatCount",
		"IsTradeSkillLinked",
	}


	for k,api in pairs(tradeSkillAPIs) do
		if PseudoTrade[api] then
			GnomeWorks[api] = function(self, ...)
				if self.data.pseudoTrade[self.tradeID] then
					if self.player ~= UnitName("player") then
						return PseudoTrade[api](self, ...)
					end
					local currentTradeSkill = GetTradeSkillLine()

					if currentTradeSkill == GetSpellInfo(2575) then
						currentTradeSkill = GetSpellInfo(2656)
					end

					if currentTradeSKill ~= GetSpellInfo(self.tradeID) then
						return PseudoTrade[api](self, ...)
					end
				end

				return _G[api](...)
			end
		else
			GnomeWorks[api] = function(self,...)
				return _G[api](...)
			end
		end
	end
end
