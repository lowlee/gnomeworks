





GnomeWorks = {}
GnomeWorksDB = {}




LibStub("AceEvent-3.0"):Embed(GnomeWorks)
LibStub("AceTimer-3.0"):Embed(GnomeWorks)


--[[
	options

	alts
		GUID : realm-faction-name

	links
		GUID : link

	trackedItems
		itemID : true

	cooldowns
		GUID
			recipeID : expiration


-- maybe:

	inventory
		GUID
			itemID : link
]]


-- disable standard frame
do


	local function DisableBlizzardTradeSkill()

	end
end


-- main event manager
do
	function GnomeWorks:EventManager(frame, event, ...)
	end
end


-- handle load sequence
do



	function GnomeWorks:OnLoad()
		if LibStub then
			self.libPT = LibStub:GetLibrary("LibPeriodicTable-3.1", true)
		end


		local function InitDBTables(var, ...)
			if var then
				if not GnomeWorksDB[var] then
					GnomeWorksDB[var] = {}
				end

				InitDBTables(...)

				GnomeWorks.data[var] = GnomeWorksDB[var]
			end
		end

		InitDBTables("config", "itemSource", "reagentUsage", "serverData", "vendorItems", "recipeDB")



		local function InitServerDBTables(server, var, ...)
			if var then
				local player = UnitName("player")

				if not GnomeWorksDB.serverData[server] then
					GnomeWorksDB.serverData[server] = { [var] = {}}
				else
					if not GnomeWorksDB.serverData[server][var] then
						GnomeWorksDB.serverData[server][var] = {}
					end
				end

				if not GnomeWorksDB.serverData[server][var][player] then
					GnomeWorksDB.serverData[server][var][player] = {}
				end

				GnomeWorks.data[var] = GnomeWorksDB.serverData[server][var]

				InitServerDBTables(server, ...)
			end
		end


		InitServerDBTables(GetRealmName().."-"..UnitFactionGroup("player"), "playerData", "inventoryData", "queueData", "recipeGroupData")

		GnomeWorks.data.constructionQueue = {}

		GnomeWorks.data.inventoryData["All Recipes"] = {}


		GnomeWorks.blizzardFrameShow = TradeSkillFrame_Show

--		TradeSkillFrame_Show = function()
--		end

		GnomeWorks:ParseSkillList()

		GnomeWorks.MainWindow = GnomeWorks:CreateMainWindow()

		GnomeWorks.QueueWindow = GnomeWorks:CreateQueueWindow()


		-- reset filters
		SetTradeSkillSubClassFilter(0, 1, 1)
		SetTradeSkillItemNameFilter("")
		SetTradeSkillItemLevelFilter(0,0)


		GnomeWorks:RegisterEvent("TRADE_SKILL_SHOW")
		GnomeWorks:RegisterEvent("TRADE_SKILL_UPDATE")
		GnomeWorks:RegisterEvent("TRADE_SKILL_CLOSE")

		GnomeWorks:RegisterEvent("CHAT_MSG_SKILL")


		GnomeWorks:RegisterEvent("MERCHANT_UPDATE")
		GnomeWorks:RegisterEvent("MERCHANT_SHOW")


		hooksecurefunc("SetItemRef", function(s,link,button)
			if string.find(s,"trade:") then
				GnomeWorks:CacheTradeSkillLink(link)
			end
		end)

		collectgarbage("collect")
	end



	if not IsAddOnLoaded("AddOnLoader") then
		GnomeWorks:RegisterEvent("PLAYER_ENTERING_WORLD", function()
			GnomeWorks:ScheduleTimer("OnLoad",1)
			GnomeWorks:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end )
	else
		GnomeWorks:RegisterEvent("ADDON_LOADED", function(self, name)
--			print("gnomeworks detected the loading of "..tostring(name))
			if name == "GnomeWorks" then
				GnomeWorks:ScheduleTimer("OnLoad",1)
				GnomeWorks:UnregisterEvent("ADDON_LOADED")
			end
		end)
	end
end


