


--[[


	GnomeWorks public API


	]]






do
	--[[

		GnomeWorks:RegisterPlugin(name, shortName)

		name - name of plugin (eg "LilSparky's Workshop")
		shortName - short name of plugin (eg "LSW")
		initialize - function to call prior to initializing gnomeworks

		returns plugin table (used for connecting other functions to plugin)
	]]

	function GnomeWorks:RegisterPlugin(name, shortName, initialize)
		GnomeWorks.plugins[name] = { shortName = shortName, enabled = true, initialize = initialize }

		return GnomeWorks.plugins[name]
	end



	--[[

		GnomeWorks:GetMainFrame()

		returns the blizzard "Frame" object for the main gnomeworks main window
	]]

	function GnomeWorks:GetMainFrame()
		return self.MainWindow
	end


	function GnomeWorks:GetSkillListFrame()
		return self.skillFrame
	end


	function GnomeWorks:GetSkillListScrollFrame()
		return self.skillFrame.scrollFrame
	end


	function GnomeWorks:GetReagentListScrollFrame()
		return self.reagentFrame.scrollFrame
	end

end



