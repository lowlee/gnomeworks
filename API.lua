


--[[


	GnomeWorks public API


	]]






do
	--[[

		GnomeWorks:RegisterPlugin(name, shortName)

		name - name of plugin (eg "LilSparky's Workshop")
		shortName - short name of plugin (eg "LSW")


		returns plugin table (used for connecting other functions to plugin)
	]]

	function GnomeWorks:RegisterPlugin(name, shortName)
		GnomeWorks.plugins[name] = { shortName = shortName, enabled = true }

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

end



