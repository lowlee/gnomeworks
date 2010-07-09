


--[[


	GnomeWorks public API


	]]






do
	local function AddButton(plugin, text, func)
		local new = { text = text, func = func }

		table.insert(plugin.menuList, new)

		return new
	end


	--[[

		GnomeWorks:RegisterPlugin(name, shortName)

		name - name of plugin (eg "LilSparky's Workshop")
		initialize - function to call prior to initializing gnomeworks

		returns plugin table (used for connecting other functions to plugin)
	]]

	function GnomeWorks:RegisterPlugin(name, initialize)
		local plugin = {
			AddButton = AddButton,
			enabled = true,
			initialize = initialize,
			menuList = {
			},
		}

		GnomeWorks.plugins[name] = plugin

		return plugin
	end





	--[[

		GnomeWorks:GetMainFrame()

		returns the blizzard "Frame" object for the main gnomeworks main window
	]]

	function GnomeWorks:GetMainFrame()
		return self.MainWindow
	end

	function GnomeWorks:GetDetailFrame()
		return self.detailFrame
	end

	function GnomeWorks:GetSkillListFrame()
		return self.skillFrame
	end


	--[[
		GnomeWorks:GetSkillListScrollFrame()

		returns the gnomeworks "ScrollFrame" object for the main window skill list
	]]
	function GnomeWorks:GetSkillListScrollFrame()
		return self.skillFrame.scrollFrame
	end

	function GnomeWorks:GetReagentListScrollFrame()
		return self.reagentFrame.scrollFrame
	end


	--[[
		GnomeWorks:GetQueue(player)

		returns the queue object for a particular player (or the current player if player is not passed)

		queue object methods:
			CraftItem(itemID, count)
			CraftRecipe(recipeID, count)
			DeleteItem(itemID)
			DeleteRecipe(itemID)
			CreateProcessButton()
	]]
--	function GnomeWorks:GetQueue(player)
--		return self.data.queue
--	end

end



