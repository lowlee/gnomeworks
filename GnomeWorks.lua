



local VERSION = ("$Revision$"):match("%d+")



GnomeWorks = { plugins = {} }
GnomeWorksDB = {}




LibStub("AceEvent-3.0"):Embed(GnomeWorks)
LibStub("AceTimer-3.0"):Embed(GnomeWorks)


-- execution holds
-- the idea here is to put off processing until a particular event has fired
-- this is needed for syncing data from the server
do
	local executionHoldFrame = CreateFrame("Frame",nil,UIParent)
	executionHoldFrame.hold = {}

--	executionHoldFrame:RegisterAllEvents()

	executionHoldFrame:SetScript("OnEvent", function(frame, event, ...)
--print("execution hold system",event)
		if frame.hold[event] then
			for method, params in pairs(frame.hold[event]) do
				GnomeWorks[method](GnomeWorks, event, ...)
			end

			frame.hold[event] = nil

			frame:UnregisterEvent(event)
		end
	end)


	-- this flags an event as delaying operations that need this particular function
	function GnomeWorks:SetExecutionHold(event)
--print("set hold event",event)
		executionHoldFrame:RegisterEvent(event)

		if not executionHoldFrame.hold[event] then
			executionHoldFrame.hold[event] = {}
		end
	end

	-- this function is called by any method that relies on up-to-date info
	-- if there is a hold for the event, then the method is tabled until the event has fired
	function GnomeWorks:GetExecutionHold(event, method, ...)
--print("check for hold on", event)
		if not executionHoldFrame.hold[event] then
			return false
		else
			if not executionHoldFrame.hold[event][method] then
				executionHoldFrame.hold[event][method] = {...}
			end
		end

		return true
	end
end



-- message dispatch
do
	local dispatchTable = {}

	function GnomeWorks:RegisterMessageDispatch(message, func)
		if dispatchTable[message] then
			local t = dispatchTable[message]
			t[#t+1] = func
		else
			dispatchTable[message] = { func }
		end
	end


	function GnomeWorks:SendMessageDispatch(message)
		if dispatchTable[message] then
			t = dispatchTable[message]

			for k,func in pairs(t) do
				if func ~= "delete" then
					if type(func) == "function" and func() then					-- message returns true when it's set to fire once
						t[k] = "delete"
					elseif type(func) == "string" and GnomeWorks[func](GnomeWorks) then
						t[k] = "delete"
					end
				end
			end

			local s,e = 1,#t

			while s <= e do
				if t[s] == "delete" then
					t[s] = t[e]
					t[e] = nil
					e = e - 1
				else
					s = s + 1
				end
			end
		end
	end

end



-- test
--[[
do
	local function TestEB()
		local eb = CreateFrame("EditBox", nil, UIParent)

		eb:SetWidth(100)
		eb:SetHeight(100)
		eb:SetPoint("CENTER")

		eb:SetNumeric(true)

		eb:SetAutoFocus(false)

		eb:SetFontObject("GameFontNormal")

		eb:SetScript("OnEnterPressed", EditBox_ClearFocus)
		eb:SetScript("OnEscapePressed", EditBox_ClearFocus)
		eb:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
		eb:SetScript("OnEditFocusGained", EditBox_HighlightText)

		eb:SetJustifyH("CENTER")
		eb:SetJustifyV("CENTER")

		local searchBackdrop  = {
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			}

		eb:SetBackdrop(eb, searchBackdrop)

		eb:SetNumber(1000)

		eb:SetMaxLetters(4)
	end


	local testFrame = CreateFrame("Frame")

	testFrame:SetScript("OnUpdate", function(f)
		TestEB()
		f:Hide()
	end)

end
]]


-- handle load sequence
do
	-- To fix Blizzard's bug caused by the new "self:SetFrameLevel(2);"
	local function FixFrameLevel(level, ...)
		for i = 1, select("#", ...) do
			local button = select(i, ...)
			button:SetFrameLevel(level)
		end
	end
	local function FixMenuFrameLevels()
		local f = DropDownList1
		local i = 1
		while f do
			FixFrameLevel(f:GetFrameLevel() + 2, f:GetChildren())
			i = i + 1
			f = _G["DropDownList"..i]
		end
	end

	-- To fix Blizzard's bug caused by the new "self:SetFrameLevel(2);"
	hooksecurefunc("UIDropDownMenu_CreateFrames", FixMenuFrameLevels)

--[[
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
]]

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

	function GnomeWorks:print(...)
		print("|cffa080f0GnomeWorks:",...)
	end


	function GnomeWorks:PLAYER_GUILD_UPDATE(...)
		if self.data.playerData[UnitName("player")] then
			self.data.playerData[UnitName("player")].guild = GetGuildInfo("player")

			self:InventoryScan()
		end
	end


	function GnomeWorks:OnLoad()
		self:print("Initializing (r"..VERSION..")")

		LoadAddOn("Blizzard_TradeSkillUI")

		GnomeWorks.blizzardFrameShow = TradeSkillFrame_Show

		TradeSkillFrame_Show = function()
		end

		if LibStub then
			self.libPT = LibStub:GetLibrary("LibPeriodicTable-3.1", true)
			self.libTS = LibStub:GetLibrary("LibTradeSkill", true)
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



		local function InitServerDBTables(server, player, var, ...)
			if var then
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

				InitServerDBTables(server, player, ...)
			end
		end

--[[
		print("results mem usage = ",math.floor(memUsage(GnomeWorksDB.results)/1024).."kb")
		print("reagents mem usage = ",math.floor(memUsage(GnomeWorksDB.reagents)/1024).."kb")
		print("tradeIDs mem usage = ",math.floor(memUsage(GnomeWorksDB.tradeIDs)/1024).."kb")
]]
		InitServerDBTables(GetRealmName().."-"..UnitFactionGroup("player"), UnitName("player"), "playerData", "inventoryData", "queueData", "recipeGroupData", "cooldowns")
		InitServerDBTables(GetRealmName().."-"..UnitFactionGroup("player"), "All Recipes", "playerData", "inventoryData", "queueData", "recipeGroupData", "cooldowns")


		local itemSource = {}
		GnomeWorks.data.itemSource = itemSource

		for recipeID, results in pairs(GnomeWorksDB.results) do
			for itemID, numMade in pairs(results) do
--				GnomeWorks:AddToItemCache(itemID, recipeID, numMade)

				if itemSource[itemID] then
					itemSource[itemID][recipeID] = numMade
				else
					itemSource[itemID] = { [recipeID] = numMade }
				end
			end
		end

--		print("itemSource mem usage = ",math.floor(memUsage(itemSource)/1024).."kb")

		local reagentUsage = {}
		GnomeWorks.data.reagentUsage = reagentUsage

		for recipeID, reagents in pairs(GnomeWorksDB.reagents) do
			for itemID, numNeeded in pairs(reagents) do
				if reagentUsage[itemID] then
					reagentUsage[itemID][recipeID] = numNeeded
				else
					reagentUsage[itemID] = { [recipeID] = numNeeded }
				end
			end
		end

--		print("reagetUsage mem usage = ",math.floor(memUsage(reagentUsage)/1024).."kb")


--		GnomeWorks.data.inventoryData["All Recipes"] = {}
		GnomeWorks.data.constructionQueue = {}
		GnomeWorks.data.selectionStack = {}

		GnomeWorks:ConstructPseudoTrades("All Recipes")



		GnomeWorks:RegisterEvent("MERCHANT_UPDATE")
		GnomeWorks:RegisterEvent("MERCHANT_SHOW")


		GnomeWorks:RegisterEvent("BAG_UPDATE")

		GnomeWorks:RegisterEvent("BANKFRAME_OPENED")

		GnomeWorks:RegisterEvent("GUILDBANKFRAME_OPENED")
		GnomeWorks:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")

		GnomeWorks:RegisterEvent("PLAYER_GUILD_UPDATE")
	end


	function GnomeWorks:OnTradeSkillShow()
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



		GnomeWorks:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "SpellCastCompleted")

		GnomeWorks:RegisterEvent("UNIT_SPELLCAST_FAILED", "SpellCastFailed")
		GnomeWorks:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "SpellCastFailed")
		GnomeWorks:RegisterEvent("UNIT_SPELLCAST_STOPPED", "SpellCastFailed")



		for name,plugin in pairs(GnomeWorks.plugins) do
--print("initializing",name)
			plugin.loaded = plugin.initialize()
		end


		hooksecurefunc("SetItemRef", function(s,link,button)
			if string.find(s,"trade:") then
				GnomeWorks:CacheTradeSkillLink(link)
			end
		end)

		collectgarbage("collect")

		if not IsAddOnLoaded("AddOnLoader") then
			GnomeWorks:TRADE_SKILL_SHOW()
			GnomeWorks:TRADE_SKILL_UPDATE()
		end
	end

--[[
	local eventFrame = CreateFrame("Frame")

	eventFrame:RegisterAllEvents()

	eventFrame:SetScript("OnEvent", function(frame, event, ...) if string.match(event, "SKILL") then print(event, ...) end end)

--	GetNumSkillLines()
]]



	if not IsAddOnLoaded("AddOnLoader") then
		GnomeWorks:RegisterEvent("ADDON_LOADED", function(event, name)
			if name == "GnomeWorks" then
				GnomeWorks:UnregisterEvent(event)
				GnomeWorks:ScheduleTimer("OnLoad",.01)
			end
		end )

		GnomeWorks:RegisterEvent("TRADE_SKILL_SHOW", function()
			GnomeWorks:UnregisterEvent("TRADE_SKILL_SHOW")
			GnomeWorks:ScheduleTimer("OnTradeSkillShow",.01)
--			GnomeWorks:OnLoad()
		end )
	else
		GnomeWorks:RegisterEvent("ADDON_LOADED", function(event, name)
--			print("gnomeworks detected the loading of "..tostring(name))
			if name == "GnomeWorks" then
--				GnomeWorks:ScheduleTimer("OnLoad",1)
				GnomeWorks:OnLoad()
				GnomeWorks:OnTradeSkillShow()
				GnomeWorks:UnregisterEvent(event)
			end
		end)
	end
end


