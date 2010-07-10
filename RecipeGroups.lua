
local function DebugSpam(...)
-- print(...)
end


local groupLabelAdded = {}
local groupLabels = {}



local OVERALL_PARENT_GROUP_NAME = "*ALL*"

local skillLevel = {
	["optimal"]	        = 4,
	["medium"]          = 3,
	["easy"]            = 2,
	["trivial"]	        = 1,
}


function GnomeWorks:RecipeGroupRename(oldName, newName)
	local oldKey =  self.player..":"..self.tradeID..":"..oldName
	local key = self.player..":"..self.tradeID..":"..newName

	if self.data.groupList[oldKey] then
		self.data.groupList[newKey] = self.data.groupList[oldKey]
		self.data.groupList[oldKey] = nil

		local list = self.data.groupList[newKey]

		self.data.recipeGroupData[key] = self.data.recipeGroupData[oldKey]
		self.data.recipeGroupData[oldKey] = nil

		for groupName, groupData in pairs(list) do
			groupData.key = key
		end
	end
end


function GnomeWorks:RecipeGroupFind(player, tradeID, label, name)
	if player and tradeID and label then
		local key = player..":"..tradeID..":"..label
		local groupList = self.data.groupList

		if groupList and groupList[key] then
			return self.data.groupList[key][name or OVERALL_PARENT_GROUP_NAME]
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

		local newGroup = { expanded = true, key = key, label = label, name = name or OVERALL_PARENT_GROUP_NAME, entries = {}, index = serial, locked = false }

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

		if not self.data.groupList[key] then
			self.data.groupList[key] = {}
		end

		self.data.groupList[key][newGroup.name] = newGroup

		if not groupLabelAdded[key] and newGroup.name == OVERALL_PARENT_GROUP_NAME then
			if not groupLabels[player..":"..tradeID] then
				groupLabels[player..":"..tradeID] = {}
			end

			table.insert(groupLabels[player..":"..tradeID], { name = label, subGroup = newGroup } )

			groupLabelAdded[key] = true
		end



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

		d.index = s.nidex
		d.expanded = s.expanded
		d.entries = {}

		for i=1,#s.entries do
			if s.entries[i].subGroup then
				local newGroup = self:RecipeGroupNew(player, tradeID, label, s.entries[i].name)

				self:RecipeGroupCopy(s.entries[i].subGroup, newGroup, noDB)

				self:RecipeGroupAddSubGroup(d, newGroup, s.entries[i].index, noDB)
			else
				self:RecipeGroupAddRecipe(d, s.entries[i].recipeID, s.entries[i].index, noDB)
			end
		end
	end
end




function GnomeWorks:RecipeGroupAddRecipe(group, recipeID, index, noDB)
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
			local newEntry = { recipeID = recipeID, name = self:GetRecipeName(recipeID), index = index, parent = group }

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
			currentEntry.index = index
			currentEntry.name = self:GetRecipeName(recipeID)
			currentEntry.parent = group
		end

		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end

		return currentEntry
	end
end


function GnomeWorks:RecipeGroupAddSubGroup(group, subGroup, index, noDB)
	if group and subGroup then
		local currentEntry

		for i=1,#group.entries do
			if group.entries[i].subGroup == subGroup then
				currentEntry = group.entries[i]
				break
			end
		end

		if not currentEntry then
			local newEntry = { subGroup = subGroup, index = index, name = subGroup.name, parent = group }

			subGroup.parent = group
			subGroup.index = index
--[[
			newEntry.subGroup = subGroup
			newEntry.skillIndex = skillIndex
			newEntry.name = subGroup.name
			newEntry.parent = group
]]
			table.insert(group.entries, newEntry)
		else
			subGroup.parent = group
			subGroup.index = index

			currentEntry.subGroup = subGroup
			currentEntry.index = index
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
		local player = self.player
		local tradeID = self.tradeID
		local label = self.groupLabel
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

		local groupList = self.data.groupList[key]

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


		if entry.subGroup then
			local oldName = entry.subGroup.name
			local groupList = self.data.groupList[key]

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
					return sortMethod(self.tradeID, b, a)
				end)
			else
				table.sort(group.entries, function(a,b)
					return sortMethod(self.tradeID, a, b)
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
		local groupString = group.key.."/"..group.name.."="..group.index

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

		if not self.data.groupList[key].autoGroup then
			local groupString = group.index

			for v,entry in pairs(group.entries) do
				if not entry.subGroup then
					groupString = groupString..":"..entry.recipeID
				else
					groupString = groupString..":g"..entry.index	--entry.subGroup.name
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
		for key, group in pairs(self.data.groupList) do
			if type(group)=="table" and name ~= OVERALL_PARENT_GROUP_NAME and group.parent == nil then
				self.data.groupList[key] = nil
				if self.data.recipeGroupData and self.data.recipeGroupData[key] then
					self.data.recipeGroupData[key][name] = nil
				end
			end
		end
	end
end


function GnomeWorks:InitGroupList(key, autoGroup)
	if not self.data.groupList then
		self.data.groupList = {}
	end

	self.data.groupList[key].autoGroup = autoGroup
end



function GnomeWorks:RecipeGroupDeconstructDBStrings()
-- pass 1: create all groups
	local groupNames = {}
	local serial = 1

	for key, groupList in pairs(self.data.recipeGroupData) do
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)

		if player == self.player and tradeID == self.tradeID and self.data.skillIndexLookup then
			self:InitGroupList(key)

			for name,list in pairs(groupList) do
				local group = self:RecipeGroupNew(player, tradeID, label, name)

				local groupContents = { string.split(":",list) }
				local groupIndex = tonumber(groupContents[1]) or serial

				serial = serial + 1
				group.index = groupIndex

				groupNames[groupIndex] = name
			end
		end
	end


	for key, groupList in pairs(self.data.recipeGroupData) do
		local player, tradeID, label = string.split(":", key)

		tradeID = tonumber(tradeID)

		if player == self.player and tradeID == self.trade and self.data.skillIndexLookup then

			for name,list in pairs(groupList) do
				local group = self:RecipeGroupFind(player, tradeID, label, name)

				local groupIndex = group.index

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
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.index, true)
							else
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.index, true)		--?? wtf?
							end
						else
							recipeID = tonumber(recipeID)
--DEFAULT_CHAT_FRAME:AddMessage(recipeID)
							local index = self.data.skillIndexLookup[player][recipeID]
--DEFAULT_CHAT_FRAME:AddMessage("adding recipe "..recipeID.." to "..group.name.."/"..player..":"..index)
							self:RecipeGroupAddRecipe(group, recipeID, index, true)
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
	local player = self.player

	local dataModule = self.dataGatheringModules[player]

	if dataModule then
		dataModule.RecipeGroupGenerateAutoGroups(dataModule)
	end
end



do
	-- Called when the user selects an item in the group drop down
	function RecipeGroupSelect(menuFrame,group,dropDown)
	DebugSpam("select grouping",label,dropDown)
--		self:SetTradeSkillOption("grouping", label)
		CloseDropDownMenus()

		GnomeWorks.groupLabel = group.label
		GnomeWorks.group = group.name

		GnomeWorks:RecipeGroupDropdown_OnShow(dropDown)

--		self:RecipeGroupGenerateAutoGroups()
--		self:SortAndFilterRecipes()
--		self:UpdateTradeSkillWindow()

		GnomeWorks:SendMessageDispatch("GnomeWorksSkillListChanged")
	end


	function GnomeWorks:RecipeGroupIsLocked()
--		if self.groupLabel == "Flat" or self.groupLabel == "By Category" then return true end

		return self:GetTradeSkillOption(self.groupLabel.."-locked")
	end


	local function DropDown_Init(menuFrame,level,entries,depth,parent)
		if not depth then
			depth = 1
			if GnomeWorks.tradeID and GnomeWorks.player then
				entries = groupLabels[GnomeWorks.player..":"..GnomeWorks.tradeID]
			end
		end

		local numGroupsAdded = 0

		local entry = {}

		if entries and level then
			for i=1,#entries do
				if entries[i].subGroup then
					if depth <= level then
						local group = entries[i].subGroup

						if UIDROPDOWNMENU_MENU_VALUE == group then
							DropDown_Init(menuFrame,level,group.entries,depth+1,group)
						end

						if depth == level  then
							entry.hasArrow = false

							for k,v in ipairs(group.entries) do
								if v.subGroup then
									entry.hasArrow = true
									break
								end
							end

							entry.text = entries[i].name
							entry.value = group

							entry.func = RecipeGroupSelect
							entry.arg1 = group
							entry.arg2 = menuFrame

							entry.checked = false

							if level == 1 and GnomeWorks.groupLabel == group.label and not GnomeWorks.group then
								entry.checked = true
							end

							if GnomeWorks.groupLabel == group.label and GnomeWorks.group == group.name then
								entry.checked = true
							end

							UIDropDownMenu_AddButton(entry, level)
						end
					end

					numGroupsAdded = numGroupsAdded + 1
				end
			end
		end

		return numGroupsAdded
	end



	-- Called when the grouping drop down is displayed
	function GnomeWorks:RecipeGroupDropdown_OnShow(dropDown)
		UIDropDownMenu_Initialize(dropDown, DropDown_Init)
		dropDown.displayMode = "MENU"
		self:RecipeGroupDeconstructDBStrings()

		local groupLabel = self.groupLabel or "By Category"

		if self.group and self.group ~= OVERALL_PARENT_GROUP_NAME then
			groupLabel = groupLabel.."/"..self.group
		end

		UIDropDownMenu_SetSelectedName(dropDown, groupLabel, true)
		UIDropDownMenu_SetText(dropDown, "Group "..groupLabel)
	end


	--[[
	function GnomeWorks:ToggleTradeSkillOptionDropDown(option)
		self:ToggleTradeSkillOption(option)
		self:RecipeGroupDropdown_OnShow()

		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
	]]
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
	local player = self.player
	local tradeID = self.tradeID

	local groupList = self.data.groupList

	while groupList[player..":"..tradeID..":"..label] do
		serial = serial + 1
		label = "Custom "..serial
	end

	local newMain = self:RecipeGroupNew(player, tradeID, label)

	for recipeID,recipe in pairs(self.data.recipeList) do
		if recipe.tradeID == tradeID then
			local index = self.data.skillIndexLookup[player][recipeID]

			if index then
				self:RecipeGroupAddRecipe(newMain, recipeID, index, true)
			end
		end
	end

	self:RecipeGroupConstructDBString(newMain)

	self:SetTradeSkillOption("grouping", label)
	self.groupLabel = label

	UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

	self:SortAndFilterRecipes()
end


function GnomeWorks:RecipeGroupOpCopy()
	local label = "Custom"
	local serial = 1
	local player = self.player
	local tradeID = self.tradeID

	local groupList = self.data.groupList

	while groupList[player..":"..tradeID..":"..label] do
		serial = serial + 1
		label = "Custom "..serial
	end

	local newMain = self:RecipeGroupNew(player, tradeID, label)
	local oldMain = self:RecipeGroupFind(player, tradeID, self.groupLabel)

	self:RecipeGroupCopy(oldMain, newMain, false)

	self:RecipeGroupConstructDBString(newMain)

	self:SetTradeSkillOption("grouping", label)
	self.groupLabel = label

	UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

	self:SortAndFilterRecipes()
end



function GnomeWorks:GroupNameEditSave()
	local newName = GroupButtonNameEdit:GetText()

	self:RecipeGroupRename(self.groupLabel, newName)

	GroupButtonNameEdit:Hide()
	GnomeWorksRecipeGroupDropdownText:Show()
	GnomeWorksRecipeGroupDropdownText:SetText(newName)

	self.groupLabel = newName
end


function GnomeWorks:RecipeGroupOpRename()
	if not self:RecipeGroupIsLocked() then
		GroupButtonNameEdit:SetText(self.groupLabel)
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
	local label = self.groupLabel

	if label ~= "Blizzard" and label ~= "Flat" then
		self:ToggleTradeSkillOption(label.."-locked")
	end
end


function GnomeWorks:RecipeGroupOpDelete()
	if not self:RecipeGroupIsLocked() then
		local player = self.player
		local tradeID = self.tradeID
		local label = self.groupLabel

		self.data.groupList[player..":"..tradeID..":"..label] = nil
		self.data.recipeGroupData[player..":"..tradeID..":"..label] = nil

		collectgarbage("collect")


		label = "Blizzard"

		self:SetTradeSkillOption("grouping", label)
		self.groupLabel = label

		UIDropDownMenu_SetSelectedName(GnomeWorksRecipeGroupDropdown, label, true)
		UIDropDownMenu_SetText(GnomeWorksRecipeGroupDropdown, label)

		self:SortAndFilterRecipes()
		self:UpdateTradeSkillFrame()
	end
end

