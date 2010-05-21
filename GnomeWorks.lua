





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


	function GnomeWorks:ConvertRecipeDB()
		local reagentTable, itemTable, tradeTable = {}, {}, {}

		for recipeID, recipeData in pairs(GnomeWorksDB.recipeDB) do
			local rtable = {}

			for i=1,#recipeData.reagentData do
				rtable[recipeData.reagentData[i].id] = recipeData.reagentData[i].numNeeded
			end

			reagentTable[recipeID] = rtable

			itemTable[recipeID] = { [recipeData.itemID] = recipeData.numMade }
			tradeTable[recipeID] = recipeData.tradeID
		end


--		GnomeWorksDB.recipeDB = nil
		GnomeWorksDB.reagentTable = reagentTable
		GnomeWorksDB.itemTable = itemTable
		GnomeWorksDB.tradeTable = tradeTable

	end


	function GnomeWorks:ConvertRecipeDB2()
		local recipeDB = {}

		for recipeID, reagents in pairs(GnomeWorksDB.reagents) do
			recipeDB[recipeID] = { reagents = reagents, results = GnomeWorksDB.results[recipeID], tradeID = GnomeWorksDB.tradeIDs[recipeID] }
		end

		GnomeWorks.data.recipeDB = recipeDB
	end


	function memUsage(t)
		local slots = 0
		local bytes = 0
		local size = 1

		for k,v in pairs(t) do
			if type(v)=="table" then
				bytes = bytes + memUsage(v)
			end
			slots = slots + 1
			if slots > size then
				size = size * 2
			end
		end

		return bytes + size * 40
	end


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

--				GnomeWorks.data[var] = GnomeWorksDB[var]
			end
		end

		InitDBTables("config", "serverData", "vendorItems", "results", "names", "reagents", "tradeIDs", "vendorOnly")



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

--[[
		print("results mem usage = ",math.floor(memUsage(GnomeWorksDB.results)/1024).."kb")
		print("reagents mem usage = ",math.floor(memUsage(GnomeWorksDB.reagents)/1024).."kb")
		print("tradeIDs mem usage = ",math.floor(memUsage(GnomeWorksDB.tradeIDs)/1024).."kb")
]]
		InitServerDBTables(GetRealmName().."-"..UnitFactionGroup("player"), "playerData", "inventoryData", "queueData", "recipeGroupData", "cooldowns")

		GnomeWorks.data.constructionQueue = {}

		local itemSource = {}
		for recipeID, results in pairs(GnomeWorksDB.results) do
			for itemID, numMade in pairs(results) do
				if itemSource[itemID] then
					itemSource[itemID][recipeID] = numMade
				else
					itemSource[itemID] = { [recipeID] = numMade }
				end
			end
		end
		GnomeWorks.data.itemSource = itemSource
--		print("itemSource mem usage = ",math.floor(memUsage(itemSource)/1024).."kb")

		local reagentUsage = {}
		for recipeID, reagents in pairs(GnomeWorksDB.reagents) do
			for itemID, numNeeded in pairs(reagents) do
				if reagentUsage[itemID] then
					reagentUsage[itemID][recipeID] = numNeeded
				else
					reagentUsage[itemID] = { [recipeID] = numNeeded }
				end
			end
		end
		GnomeWorks.data.reagentUsage = reagentUsage
--		print("reagetUsage mem usage = ",math.floor(memUsage(reagentUsage)/1024).."kb")


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


		GnomeWorks:RegisterEvent("BAG_UPDATE")



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


