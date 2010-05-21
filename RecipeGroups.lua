

local OVERALL_PARENT_GROUP_NAME = "*ALL*"

local skillLevel = {
	["optimal"]	        = 4,
	["medium"]          = 3,
	["easy"]            = 2,
	["trivial"]	        = 1,
}


function GnomeWorks:RecipeGroupRename(oldName, newName)
	if self.data.groupList[self.currentPlayer][self.currentTrade][oldName] then
		self.data.groupList[self.currentPlayer][self.currentTrade][newName] = self.data.groupList[self.currentPlayer][self.currentTrade][oldName]
		self.data.groupList[self.currentPlayer][self.currentTrade][oldName] = nil

		local list = self.data.groupList[self.currentPlayer][self.currentTrade][newName]

		local oldKey =  self.currentPlayer..":"..self.currentTrade..":"..oldName
		local key = self.currentPlayer..":"..self.currentTrade..":"..newName

		self.data.recipeGroupData[key] = self.data.recipeGroupData[oldKey]
		self.data.recipeGroupData[oldKey] = nil

		for groupName, groupData in pairs(list) do
			groupData.key = key
		end
	end
end


function GnomeWorks:RecipeGroupFind(player, tradeID, label, name)
	if player and tradeID and label then
--		local key = player..":"..tradeID..":"..label
		local groupList = self.data.groupList

		if groupList and groupList[player] and groupList[player][tradeID] and groupList[player][tradeID][label] then
			return self.data.groupList[player][tradeID][label][name or OVERALL_PARENT_GROUP_NAME]
		end
	end
end


function GnomeWorks:RecipeGroupFindRecipe(group, recipeID)
	if group then
		local entries = group.entries

		if entries then
			for i=1,#entries do
				if entries[i].recipeID then
					return entries[i]
				end
			end
		end
	end
end


-- creates a new recipe group
-- player = for whom the group is being created
-- tradeID = tradeID of the group
-- label = meta-group of groups.  for example, "blizzard" is defined for the standard blizzard groups.  this allows multiple group settings
-- name = new group name (optional -- not specified means the overall parent group)
--
-- returns the newly created group record
local serial = 0
function GnomeWorks:RecipeGroupNew(player, tradeID, label, name)
	local existingGroup = self:RecipeGroupFind(player, tradeID, label, name)

	if existingGroup then
--DebugSpam("group "..existingGroup.key.."/"..existingGroup.name.." exists")
		return existingGroup
	else
--DebugSpam("new group "..(name or OVERALL_PARENT_GROUP_NAME))

		local key = player..":"..tradeID..":"..label

		local newGroup = { expanded = true, key = key, name = name or OVERALL_PARENT_GROUP_NAME, entries = {}, skillIndex = serial, locked = false }

--[[
		newGroup.expanded = true
		newGroup.key = key
		newGroup.name = name or OVERALL_PARENT_GROUP_NAME
		newGroup.entries = {}
		newGroup.skillIndex = serial
		newGroup.locked = nil
]]

		serial = serial + 1

		if not self.data.groupList then
			self.data.groupList = {}
		end

		if not self.data.groupList[player] then
			self.data.groupList[player] = {}
		end

		if not self.data.groupList[player][tradeID] then
			self.data.groupList[player][tradeID] = {}
		end

		if not self.data.groupList[player][tradeID][label] then
			self.data.groupList[player][tradeID][label] = {}
		end

		self.data.groupList[player][tradeID][label][newGroup.name] = newGroup


		return newGroup
	end
end


function GnomeWorks:RecipeGroupClearEntries(group)
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self:RecipeGroupClearEntries(group.entries[i].subGroup)
			end
		end

		group.entries = {}
	end
end


function GnomeWorks:RecipeGroupCopy(s, d, noDB)
	if s and d then
		local player, tradeID, label = string.split(":", d.key)

		d.skillIndex = s.skillIndex
		d.expanded = s.expanded
		d.entries = {}

		for i=1,#s.entries do
			if s.entries[i].subGroup then
				local newGroup = self:RecipeGroupNew(player, tradeID, label, s.entries[i].name)

				self:RecipeGroupCopy(s.entries[i].subGroup, newGroup, noDB)

				self:RecipeGroupAddSubGroup(d, newGroup, s.entries[i].skillIndex, noDB)
			else
				self:RecipeGroupAddRecipe(d, s.entries[i].recipeID, s.entries[i].skillIndex, noDB)
			end
		end
	end
end




function GnomeWorks:RecipeGroupAddRecipe(group, recipeID, skillIndex, noDB)
	recipeID = tonumber(recipeID)

	if group and recipeID then
		local currentEntry

		for i=1,#group.entries do
			if group.entries[i].recipeID == recipeID then
				currentEntry = group.entries[i]
				break
			end
		end

		if not currentEntry then
			local newEntry = { recipeID = recipeID, name = self:GetRecipeName(recipeID), skillIndex = skillIndex, parent = group }

--[[
			newEntry.recipeID = recipeID
			newEntry.name = self:GetRecipeName(recipeID)
			newEntry.skillIndex = skillIndex
			newEntry.parent = group
]]

			table.insert(group.entries, newEntry)

			currentEntry = newEntry
		else
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name = self:GetRecipeName(recipeID)
			currentEntry.parent = group
		end

		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end

		return currentEntry
	end
end


function GnomeWorks:RecipeGroupAddSubGroup(group, subGroup, skillIndex, noDB)
	if group and subGroup then
		local currentEntry

		for i=1,#group.entries do
			if group.entries[i].subGroup == subGroup then
				currentEntry = group.entries[i]
				break
			end
		end

		if not currentEntry then
			local newEntry = { subGroup = subGroup, skillIndex = skillIndex, name = subGroup.name, parent = group }

			subGroup.parent = group
			subGroup.skillIndex = skillIndex
--[[
			newEntry.subGroup = subGroup
			newEntry.skillIndex = skillIndex
			newEntry.name = subGroup.name
			newEntry.parent = group
]]
			table.insert(group.entries, newEntry)
		else
			subGroup.parent = group
			subGroup.skillIndex = skillIndex

			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name = subGroup.name
			currentEntry.parent = group
		end

		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end
	end
end


function GnomeWorks:RecipeGroupPasteEntry(entry, group)
	if entry and group and entry.parent ~= group then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
DEFAULT_CHAT_FRAME:AddMessage("paste "..entry.name.." into "..group.name)

--		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		local parentGroup = group

		if entry.subGroup then
			 if entry.subGroup == group then
			 	return
			end

			local newName, newIndex = self:RecipeGroupNewName(group.key, entry.name)

			local newGroup = self:RecipeGroupNew(player, tradeID, label, newName)

			self:RecipeGroupAddSubGroup(parentGroup, newGroup, newIndex)

			if entry.subGroup.entries then
DEFAULT_CHAT_FRAME:AddMessage((entry.subGroup.name or "nil") .. " " .. #entry.subGroup.entries)
				for i=1,#entry.subGroup.entries do
DEFAULT_CHAT_FRAME:AddMessage((entry.subGroup.entries[i].name or "nil") .. " " .. newGroup.name)

					self:RecipeGroupPasteEntry(entry.subGroup.entries[i], newGroup)
				end
			end
		else
			local newIndex = self.data.skillIndexLookup[player][entry.recipeID]

			if not newIndex then
				newIndex = #self.db.server.skillDB[player][tradeID]+1
				self.db.server.skillDB[player][tradeID][newIndex] = "x"..entry.recipeID
			end

			self:RecipeGroupAddRecipe(parentGroup, entry.recipeID, newIndex)
		end
	end
end


function GnomeWorks:RecipeGroupMoveEntry(entry, group)
	if entry and group and entry.parent ~= group then

		if entry.subGroup then
			 if entry.subGroup == group then
			 	return
			end
		end

		local entryGroup = entry.parent
		local loc

		for i=1,#entryGroup.entries do
			if entryGroup.entries[i] == entry then
				loc = i
				break
			end
		end


		table.remove(entryGroup.entries, loc)

		table.insert(group.entries, entry)

		entry.parent = group

		self:RecipeGroupConstructDBString(group)
		self:RecipeGroupConstructDBString(entryGroup)
	end
end



function GnomeWorks:RecipeGroupDeleteGroup(group)
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self.RecipeGroupDeleteGroup(group.entries[i].subGroup)
			end
		end

		group.entries = nil

		self.data.recipeGroupData[group.key][group.name] = nil
	end
end


function GnomeWorks:RecipeGroupDeleteEntry(entry)
	if entry then

		local entryGroup = entry.parent
		local loc

		if not entryGroup.entries then return end

		for i=1,#entryGroup.entries do
			if entryGroup.entries[i] == entry then
				loc = i
				break
			end
		end

		table.remove(entryGroup.entries, loc)

		if entry.subGroup then
			self:RecipeGroupDeleteGroup(entry.subGroup)
		end

		self:RecipeGroupConstructDBString(entryGroup)
	end
end


function GnomeWorks:RecipeGroupNewName(key, name)
	local index = 1

	if key and name then
		local player, tradeID, label = string.split(":", key)

		tradeID = tonumber(tradeID)

		local groupList = self.data.groupList[player][tradeID][label]

		for v in pairs(groupList) do
			index = index + 1
		end

		if groupList[name] then
			local tempName = name.." "
			local suffix = 2

			while groupList[tempName..suffix] do
				suffix = suffix + 1
			end

			name = tempName..suffix
		end
	end

	return name, index
end


function GnomeWorks:RecipeGroupRenameEntry(entry, name)
	if entry and name then
		local key = entry.parent.key

		local player, tradeID, label = string.split(":", key)

		tradeID = tonumber(tradeID)

		if entry.subGroup then
			local oldName = entry.subGroup.name
			local groupList = self.data.groupList[player][tradeID][label]

			if oldName ~= name then

				name = self:RecipeGroupNewName(key, name)

				entry.subGroup.name = name

				groupList[name] = groupList[oldName]
				groupList[oldName] = nil

				entry.name = name
			end
		end

		self:RecipeGroupConstructDBString(entry.parent)
	end
end


function GnomeWorks:RecipeGroupSort(group, sortMethod, reverse)
	if group then
		for v, entry in pairs(group.entries) do
			if entry.subGroup and entry.subGroup ~= group then
				self:RecipeGroupSort(entry.subGroup, sortMethod, reverse)
			end
		end

		if group.entries and #group.entries>1 then
			if reverse then
				table.sort(group.entries, function(a,b)
					return sortMethod(self.currentTrade, b, a)
				end)
			else
				table.sort(group.entries, function(a,b)
					return sortMethod(self.currentTrade, a, b)
				end)
			end
		end
	end
end



function GnomeWorks:RecipeGroupFlatten(group, depth, list, index)
	local num = 0

	if group and list then
		for v, entry in pairs(group.entries) do
			if entry.subGroup then
				local newSkill = entry
				local inSub = 0

				newSkill.depth = depth

				if (index>0) then
					newSkill.parentIndex = index
				else
					newSkill.parentIndex = nil
				end


				num = num + 1
				list[num + index] = newSkill

				if entry.subGroup.expanded then
					inSub = self:RecipeGroupFlatten(entry.subGroup, depth+1, list, num+index)
				end

				num = num + inSub

--[[
				if inSub == 0 and entry.subGroup.expanded then			-- if no items are added in a sub-group, then don't add the sub-group header
					num = num - 1
				else
					num = num + inSub
				end
]]
			else
				entry.depth = depth

--DEFAULT_CHAT_FRAME:AddMessage("id: "..newSkill.spellID)

				if (index>0) then
					entry.parentIndex = index
				else
					entry.parentIndex = nil
				end

				num = num + 1
				list[num + index] = entry

--[[
				local skillData = self:GetSkill(self.currentPlayer, self.currentTrade, entry.skillIndex)
				local recipe = self:GetRecipe(entry.recipeID)

				if skillData then
					local 	filterLevel = ((skillLevel[entry.difficulty] or skillLevel[skillData.difficulty] or 4) < (self:GetTradeSkillOption("filterLevel")))
					local filterCraftable = false

					if self:GetTradeSkillOption("hideuncraftable") then
						if not (skillData.numCraftable > 0 and self:GetTradeSkillOption("filterInventory-bag")) and
						   not (skillData.numCraftableVendor > 0 and self:GetTradeSkillOption("filterInventory-vendor")) and
						   not (skillData.numCraftableBank > 0 and self:GetTradeSkillOption("filterInventory-bank")) and
						   not (skillData.numCraftableAlts > 0 and self:GetTradeSkillOption("filterInventory-alts")) then
							filterCraftable = true
						end
					end


					if self.recipeFilters then
						for _,f in pairs(self.recipeFilters) do
							if f.filterMethod(f.namespace, entry.skillIndex) then
								filterCraftable = true
							end
						end
					end


					local newSkill = entry

					newSkill.depth = depth
					newSkill.skillData = skillData
					newSkill.spellID = recipe.spellID
--DEFAULT_CHAT_FRAME:AddMessage("id: "..newSkill.spellID)

					if (index>0) then
						newSkill.parentIndex = index
					else
						newSkill.parentIndex = nil
					end

					if not (filterLevel or filterCraftable) then
						num = num + 1
						list[num + index] = newSkill
					end
				end
	]]
			end
		end
	end

	return num
end




function GnomeWorks:RecipeGroupDump(group)
	if group then
		local groupString = group.key.."/"..group.name.."="..group.skillIndex

		for v,entry in pairs(group.entries) do
			if not entry.subGroup then
				groupString = groupString..":"..entry.recipeID
			else
				groupString = groupString..":"..entry.subGroup.name
				self:RecipeGroupDump(entry.subGroup)
			end
		end

		DebugSpam(groupString)
	else
		DebugSpam("no match")
	end
end


-- make a db string for saving groups
function GnomeWorks:RecipeGroupConstructDBString(group)
--DEFAULT_CHAT_FRAME:AddMessage("constructing group db strings "..group.name)

	if group and not group.autoGroup then
		local key = group.key
		local player, tradeID, label = string.split(":",key)

		tradeID = tonumber(tradeID)

		if not self.data.groupList[player][tradeID][label].autoGroup then
			local groupString = group.skillIndex

			for v,entry in pairs(group.entries) do
				if not entry.subGroup then
					groupString = groupString..":"..entry.recipeID
				else
					groupString = groupString..":g"..entry.skillIndex	--entry.subGroup.name
					self:RecipeGroupConstructDBString(entry.subGroup)
				end
			end

			if not self.data.recipeGroupData[key] then
				self.data.recipeGroupData[key] = {}
			end

			self.data.recipeGroupData[key][group.name] = groupString
		end
	end
end




function GnomeWorks:RecipeGroupPruneList()
	if self.data.groupList then
		for player, perPlayerList in pairs(self.data.groupList) do
			for trade, perTradeList in pairs(perPlayerList) do
				for label, perLabelList in pairs(perTradeList) do
					for name, group in pairs(perLabelList) do
						if type(group)=="table" and name ~= OVERALL_PARENT_GROUP_NAME and group.parent == nil then
							perLabelList[name] = nil
							if self.data.recipeGroupData and self.data.recipeGroupData[player..":"..trade..":"..label] then
								self.data.recipeGroupData[player..":"..trade..":"..label][name] = nil
							end
						end
					end
				end
			end
		end
	end
end


function GnomeWorks:InitGroupList(player, tradeID, label, autoGroup)
	if not self.data.groupList then
		self.data.groupList = {}
	end

	if not self.data.groupList[player] then
		self.data.groupList[player] = {}
	end

	if not self.data.groupList[player][tradeID] then
		self.data.groupList[player][tradeID] = {}
	end

	if not self.data.groupList[player][tradeID][label] then
		self.data.groupList[player][tradeID][label] = {}
	end

	self.data.groupList[player][tradeID][label].autoGroup = autoGroup
end



function GnomeWorks:RecipeGroupDeconstructDBStrings()
-- pass 1: create all groups
	local groupNames = {}
	local serial = 1

	for key, groupList in pairs(self.data.recipeGroupData) do
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)

		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then
			self:InitGroupList(player, tradeID, label)

			for name,list in pairs(groupList) do
				local group = self:RecipeGroupNew(player, tradeID, label, name)

				local groupContents = { string.split(":",list) }
				local groupIndex = tonumber(groupContents[1]) or serial

				serial = serial + 1
				group.skillIndex = groupIndex

				groupNames[groupIndex] = name
			end
		end
	end


	for key, groupList in pairs(self.data.recipeGroupData) do
		local player, tradeID, label = string.split(":", key)

		tradeID = tonumber(tradeID)

		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then

			for name,list in pairs(groupList) do
				local group = self:RecipeGroupFind(player, tradeID, label, name)

				local groupIndex = group.skillIndex

				if not group.initialized then
					group.initialized = true

					local groupContents = { string.split(":",list) }
--DEFAULT_CHAT_FRAME:AddMessage(groupContents)

					for j=2,#groupContents do
						local recipeID = groupContents[j]

						if not tonumber(recipeID) then
							local id = tonumber(string.sub(recipeID,2))

--							local subGroup = self:RecipeGroupNew(player, tradeID, label, groupContents[j])
							local subGroup = self:RecipeGroupFind(player, tradeID, label, groupNames[id])

							if subGroup then
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.skillIndex, true)
							else
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.skillIndex, true)		--?? wtf?
							end
						else
							recipeID = tonumber(recipeID)
--DEFAULT_CHAT_FRAME:AddMessage(recipeID)
							local skillIndex = self.data.skillIndexLookup[player][recipeID]
--DEFAULT_CHAT_FRAME:AddMessage("adding recipe "..recipeID.." to "..group.name.."/"..player..":"..skillIndex)
							self:RecipeGroupAddRecipe(group, recipeID, skillIndex, true)
						end
					end
				end
			end

			self:RecipeGroupPruneList()
		end
	end

	DebugSpam("done making groups")
end


function GnomeWorks:RecipeGroupGenerateAutoGroups()
	local player = self.currentPlayer

	local dataModule = self.dataGatheringModules[player]

	if dataModule then
		dataModule.RecipeGroupGenerateAutoGroups(dataModule)
	end
end


-- Called when the grouping drop down is displayed
function GnomeWorks:RecipeGroupDropdown_OnShow()
    UIDropDownMenu_Initialize(GnomeWorksRecipeGroupDropdown, GnomeWorksRecipeGroupDropdown_Initialize)
    GnomeWorksRecipeGroupDropdown.displayMode = "MENU"
	self:RecipeGroupDeconstructDBStrings()

	local groupLabel = self:GetTradeSkillOption("grouping") or self.currentGroupLabel

	UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, groupLabel, true)
	UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, groupLabel)
end


-- The method we use the initialize the grouping drop down.
function GnomeWorksRecipeGroupDropdown_Initialize(menuFrame,level)
DebugSpam("init dropdown")
    if level == 1 then  -- group labels
--		self:RecipeGroupDeconstructDBStrings()


		local entry = {}
		local null = {}

		null.text = ""
		null.disabled = true


		entry.text = "Flat"
		entry.value = "Flat"

		entry.func = self.RecipeGroupSelect
		entry.arg1 = self
		entry.arg2 = "Flat"

		if self.currentGroupLabel == "Flat" then
			entry.checked = true
		else
			entry.checked = false
		end

		entry.icon = "Interface\\Addons\\GnomeWorks\\Icons\\locked.tga"

		UIDropDownMenu_AddButton(entry)


		if self.data.groupList[self.currentPlayer] then
--[[
			entry.text = "Blizzard"
			entry.value = "Blizzard"

			entry.func = GnomeWorks.RecipeGroupSelect
			entry.arg1 = GnomeWorks
			entry.arg2 = "Blizzard"

			if GnomeWorks.currentGroupLabel == "Blizzard" then
				entry.checked = true
			else
				entry.checked = false
			end

			entry.icon = "Interface\\Addons\\GnomeWorks\\Icons\\locked.tga"

			UIDropDownMenu_AddButton(entry)
]]


			local numGroupsAdded = 0

			if self.data.groupList[self.currentPlayer][self.currentTrade] then
				for labelName, groupData in pairs(self.data.groupList[self.currentPlayer][self.currentTrade]) do
					entry.text = labelName
					entry.value = labelName

					entry.func = self.RecipeGroupSelect
					entry.arg1 = self
					entry.arg2 = labelName


					if self.currentGroupLabel == "Blizzard" or self:GetTradeSkillOption(labelName.."-locked") then
						entry.icon = "Interface\\Addons\\GnomeWorks\\Icons\\locked.tga"
					else
--						entry.icon = "Interface\\Addons\\GnomeWorks\\Icons\\unlocked.tga"
						entry.icon = nil
					end


					if self.currentGroupLabel == labelName then
						entry.checked = true
					else
						entry.checked = false
					end

					UIDropDownMenu_AddButton(entry)
					numGroupsAdded = numGroupsAdded + 1
				end
			end
		end
	end
end

-- Called when the user selects an item in the sorting drop down
function GnomeWorks:RecipeGroupSelect(menuFrame,label)
DebugSpam("select grouping "..label)
	self:SetTradeSkillOption("grouping", label)

	self.currentGroupLabel = label
	self.currentGroup = nil

	self:RecipeGroupDropdown_OnShow()

	self:RecipeGroupGenerateAutoGroups()
    self:SortAndFilterRecipes()
    self:UpdateTradeSkillWindow()
end


function GnomeWorks:RecipeGroupIsLocked()
	if self.currentGroupLabel == "Flat" or self.currentGroupLabel == "Blizzard" then return true end

	return self:GetTradeSkillOption(self.currentGroupLabel.."-locked")
end


function GnomeWorks:ToggleTradeSkillOptionDropDown(option)
	self:ToggleTradeSkillOption(option)
	self:RecipeGroupDropdown_OnShow()

	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end



-- Called when the grouping operators drop down is displayed
function GnomeWorks:RecipeGroupOperations_OnClick()
	if not RecipeGroupOpsMenu then
		RecipeGroupOpsMenu = CreateFrame("Frame", "RecipeGroupOpsMenu", getglobal("UIParent"), "UIDropDownMenuTemplate")
	end

	UIDropDownMenu_Initialize(RecipeGroupOpsMenu, GnomeWorksRecipeGroupOpsMenu_Init, "MENU")
	ToggleDropDownMenu(1, nil, RecipeGroupOpsMenu, this, this:GetWidth(), 0)
end


-- The method we use the initialize the group ops drop down.
function GnomeWorksRecipeGroupOpsMenu_Init(menuFrame,level)
    if level == 1 then
		local entry = {}
		local null = {}

		null.text = ""
		null.disabled = true



		entry.text = "New"
		entry.value = "New"

		entry.func = self.RecipeGroupOpNew

		UIDropDownMenu_AddButton(entry)



		entry.text = "Copy"
		entry.value = "Copy"

		entry.func = self.RecipeGroupOpCopy

		UIDropDownMenu_AddButton(entry)


		entry.text = "Rename"
		entry.value = "Rename"

		entry.func = self.RecipeGroupOpRename

		UIDropDownMenu_AddButton(entry)


		entry.text = "Lock/Unlock"
		entry.value = "Lock/Unlock"

		entry.func = self.RecipeGroupOpLock

		UIDropDownMenu_AddButton(entry)



		entry.text = "Delete"
		entry.value = "Delete"

		entry.func = self.RecipeGroupOpDelete

		UIDropDownMenu_AddButton(entry)
	end

end


function GnomeWorks:RecipeGroupOpNew()
	local label = "Custom"
	local serial = 1
	local player = self.currentPlayer
	local tradeID = self.currentTrade

	local groupList = self.data.groupList

	while groupList[player][tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end

	local newMain = self:RecipeGroupNew(player, tradeID, label)

	for recipeID,recipe in pairs(self.data.recipeList) do
		if recipe.tradeID == tradeID then
			local skillIndex = self.data.skillIndexLookup[player][recipeID]

			if skillIndex then
				self:RecipeGroupAddRecipe(newMain, recipeID, skillIndex, true)
			end
		end
	end

	self:RecipeGroupConstructDBString(newMain)

	self:SetTradeSkillOption("grouping", label)
	self.currentGroupLabel = label

	UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

	self:SortAndFilterRecipes()
end


function GnomeWorks:RecipeGroupOpCopy()
	local label = "Custom"
	local serial = 1
	local player = self.currentPlayer
	local tradeID = self.currentTrade

	local groupList = self.data.groupList

	while groupList[player][tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end

	local newMain = self:RecipeGroupNew(player, tradeID, label)
	local oldMain = self:RecipeGroupFind(player, tradeID, self.currentGroupLabel)

	self:RecipeGroupCopy(oldMain, newMain, false)

	self:RecipeGroupConstructDBString(newMain)

	self:SetTradeSkillOption("grouping", label)
	self.currentGroupLabel = label

	UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

	self:SortAndFilterRecipes()
end



function GnomeWorks:GroupNameEditSave()
	local newName = GroupButtonNameEdit:GetText()

	self:RecipeGroupRename(self.currentGroupLabel, newName)

	GroupButtonNameEdit:Hide()
	GnomeWorksRecipeGroupDropdownText:Show()
	GnomeWorksRecipeGroupDropdownText:SetText(newName)

	self.currentGroupLabel = newName
end


function GnomeWorks:RecipeGroupOpRename()
	if not self:RecipeGroupIsLocked() then
		GroupButtonNameEdit:SetText(self.currentGroupLabel)
		GroupButtonNameEdit:SetParent(GnomeWorksRecipeGroupDropdownText:GetParent())

		local numPoints = GnomeWorksRecipeGroupDropdownText:GetNumPoints()

		for p=1,numPoints do
			GroupButtonNameEdit:SetPoint(GnomeWorksRecipeGroupDropdownText:GetPoint(p))
		end


		GroupButtonNameEdit:Show()
		GnomeWorksRecipeGroupDropdownText:Hide()
	end
end


function GnomeWorks:RecipeGroupOpLock()
	local label = self.currentGroupLabel

	if label ~= "Blizzard" and label ~= "Flat" then
		self:ToggleTradeSkillOption(label.."-locked")
	end
end


function GnomeWorks:RecipeGroupOpDelete()
	if not self:RecipeGroupIsLocked() then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel

		self.data.groupList[player][tradeID][label] = nil
		self.data.recipeGroupData[player..":"..tradeID..":"..label] = nil

		collectgarbage("collect")


		label = "Blizzard"

		self:SetTradeSkillOption("grouping", label)
		self.currentGroupLabel = label

		UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
		UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

		self:SortAndFilterRecipes()
		self:UpdateTradeSkillFrame()
	end
end

