

-- ARL support

do
	local function Initialize()
		local ARL = AckisRecipeList

		local ARLSourceFlags = {}

		if ARL then


			local L			= LibStub("AceLocale-3.0"):GetLocale("Ackis Recipe List")
			local BFAC		= LibStub("LibBabble-Faction-3.0"):GetLookupTable()
			local Player	= ARL.Player


			local FACTION_HORDE			= BFAC["Horde"]
			local FACTION_ALLIANCE		= BFAC["Alliance"]
			local FACTION_NEUTRAL		= BFAC["Neutral"]


			local A_TRAINER, A_VENDOR, A_MOB, A_QUEST, A_SEASONAL, A_REPUTATION, A_WORLD_DROP, A_CUSTOM, A_PVP, A_MAX = 1, 2, 3, 4, 5, 6, 7, 8, 9, 9

	-- ripped from arl frame.lua
			local function GetTipFactionInfo(comp_faction)
				local display_tip = false
				local color = ARL:hexcolor("NEUTRAL")
				local faction = FACTION_NEUTRAL

				if comp_faction == FACTION_HORDE then
					color = ARL:hexcolor("HORDE")

					if Player["Faction"] == FACTION_HORDE then
						display_tip = true
					else
						faction = FACTION_HORDE
					end
				elseif comp_faction == FACTION_ALLIANCE then
					color = ARL:hexcolor("ALLIANCE")

					if Player["Faction"] == FACTION_ALLIANCE then
						display_tip = true
					else
						faction = FACTION_ALLIANCE
					end
				else
					display_tip = true
				end
				return display_tip, color, faction
			end

			local function GenerateAcquireText(recipe_entry)
				local leftText, rightText = "", ""

				local rep_list = ARL.reputation_list

				for index, acquire in pairs(recipe_entry["Acquire"]) do
					local acquire_type = acquire["Type"]
					local display_tip = false

					if acquire_type == A_TRAINER then
						local trainer = ARL.trainer_list[acquire["ID"]]

						color_1 = ARL:hexcolor("TRAINER")
						display_tip, color_2 = GetTipFactionInfo(trainer["Faction"])

						if display_tip then
							local coord_text = ""

							if trainer["Coordx"] ~= 0 and trainer["Coordy"] ~= 0 then
								coord_text = "(" .. trainer["Coordx"] .. ", " .. trainer["Coordy"] .. ")"
							end
							leftText = leftText .. "|cff" .. color_1 .. L["Trainer"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 .. trainer["Name"] .. "|r\n"

		--					ttAdd(0, -2, false, L["Trainer"], color_1, trainer["Name"], color_2)

							color_1 = ARL:hexcolor("NORMAL")
							color_2 = ARL:hexcolor("HIGH")

		--					ttAdd(1, -2, true, trainer["Location"], color_1, coord_text, color_2)

							leftText = leftText .. "|cff" .. color_1 .. trainer["Location"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 .. coord_text .. "|r\n"
						end
					elseif acquire_type == A_VENDOR then
						local vendor = ARL.vendor_list[acquire["ID"]]
						local faction

						color_1 = ARL:hexcolor("VENDOR")
						display_tip, color_2, faction = GetTipFactionInfo(vendor["Faction"])

						if display_tip then
							local coord_text = ""

							if vendor["Coordx"] ~= 0 and vendor["Coordy"] ~= 0 then
								coord_text = "(" .. vendor["Coordx"] .. ", " .. vendor["Coordy"] .. ")"
							end

							leftText = leftText .. "|cff" .. color_1 .. L["Vendor"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 .. vendor["Name"] .. "|r\n"

		--					ttAdd(0, -1, false, L["Vendor"], color_1, vendor["Name"], color_2)

							color_1 = ARL:hexcolor("NORMAL")
							color_2 = ARL:hexcolor("HIGH")

							leftText = leftText .. "|cff" .. color_1 .. vendor["Location"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 .. coord_text .. "|r\n"

		--					ttAdd(1, -2, true, vendor["Location"], color_1, coord_text, color_2)
						elseif faction then
							leftText = leftText .. "|cff" .. color_1 .. faction.." "..L["Vendor"] .. "|r\n"
							rightText = rightText .. "\n"
		--					ttAdd(0, -1, false, faction.." "..L["Vendor"], color_1)
						end
					elseif acquire_type == A_MOB then
						local mob = ARL.mob_list[acquire["ID"]]
						local coord_text = ""

						if mob["Coordx"] ~= 0 and mob["Coordy"] ~= 0 then
							coord_text = "(" .. mob["Coordx"] .. ", " .. mob["Coordy"] .. ")"
						end
						color_1 = ARL:hexcolor("MOBDROP")
						color_2 = ARL:hexcolor("HORDE")

						leftText = leftText .. "|cff" .. color_1 .. L["Mob Drop"] .. "|r\n"
						rightText = rightText .. "|cff" .. color_2 .. mob["Name"] .. "|r\n"

		--				ttAdd(0, -1, false, L["Mob Drop"], color_1, mob["Name"], color_2)

						color_1 = ARL:hexcolor("NORMAL")
						color_2 = ARL:hexcolor("HIGH")

						leftText = leftText .. "|cff" .. color_1 .. mob["Location"] .. "|r\n"
						rightText = rightText .. "|cff" .. color_2 .. coord_text .. "|r\n"

		--				ttAdd(1, -2, true, mob["Location"], color_1, coord_text, color_2)
					elseif acquire_type == A_QUEST then
						local quest = ARL.quest_list[acquire["ID"]]

						if quest then
							local faction

							color_1 = ARL:hexcolor("QUEST")
							display_tip, color_2, faction = GetTipFactionInfo(quest["Faction"])

							if display_tip then
								local coord_text = ""

								if quest["Coordx"] ~= 0 and quest["Coordy"] ~= 0 then
									coord_text = "(" .. quest["Coordx"] .. ", " .. quest["Coordy"] .. ")"
								end
								leftText = leftText .. "|cff" .. color_1 .. L["Quest"] .. "|r\n"
								rightText = rightText .. "|cff" .. color_2 ..  quest["Name"] .. "|r\n"

		--						ttAdd(0, -1, false, L["Quest"], color_1, quest["Name"], color_2)

								color_1 = ARL:hexcolor("NORMAL")
								color_2 = ARL:hexcolor("HIGH")

								leftText = leftText .. "|cff" .. color_1 ..quest["Location"] .. "|r\n"
								rightText = rightText .. "|cff" .. color_2 ..  coord_text .. "|r\n"

		--						ttAdd(1, -2, true, quest["Location"], color_1, coord_text, color_2)
							elseif faction then
								leftText = leftText .. "|cff" .. color_1 .. faction.." "..L["Quest"] .. "|r\n"
								rightText = rightText .. "\n"
		--						ttAdd(0, -1, false, faction.." "..L["Quest"], color_1)
							end
						end
					elseif acquire_type == A_SEASONAL then
						color_1 = ARL:hexcolor("SEASON")
						leftText = leftText .. "|cff" .. color_1 .. ARL.seasonal_list[acquire["ID"]]["Name"] .. "|r\n"
						rightText = rightText .. "\n"
		--				ttAdd(0, -1, 0, SEASONAL_CATEGORY, color_1, ARL.seasonal_list[acquire["ID"]]["Name"], color_1)
					elseif acquire_type == A_REPUTATION then
						local repvendor = ARL.vendor_list[acquire["RepVendor"]]
						local coord_text = ""

						if repvendor["Coordx"] ~= 0 and repvendor["Coordy"] ~= 0 then
							coord_text = "(" .. repvendor["Coordx"] .. ", " .. repvendor["Coordy"] .. ")"
						end
						local repfac = rep_list[acquire["ID"]]
						local repname = repfac["Name"]

						color_1 = ARL:hexcolor("REP")
						color_2 = ARL:hexcolor("NORMAL")

						leftText = leftText .. "|cff" .. color_1 .. _G.REPUTATION .. "|r\n"
						rightText = rightText .. "|cff" .. color_2 ..  repname .. "|r\n"

		--				ttAdd(0, -1, false, _G.REPUTATION, color_1, repname, color_2)

						local rStr = ""
						local rep_level = acquire["RepLevel"]

						if rep_level == 0 then
							rStr = FACTION_NEUTRAL
							color_1 = ARL:hexcolor("NEUTRAL")
						elseif rep_level == 1 then
							rStr = BFAC["Friendly"]
							color_1 = ARL:hexcolor("FRIENDLY")
						elseif rep_level == 2 then
							rStr = BFAC["Honored"]
							color_1 = ARL:hexcolor("HONORED")
						elseif rep_level == 3 then
							rStr = BFAC["Revered"]
							color_1 = ARL:hexcolor("REVERED")
						else
							rStr = BFAC["Exalted"]
							color_1 = ARL:hexcolor("EXALTED")
						end
						display_tip, color_2 = GetTipFactionInfo(repvendor["Faction"])

						if display_tip then
							leftText = leftText .. "|cff" .. color_1 .. rStr .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 ..  repvendor["Name"] .. "|r\n"

		--					ttAdd(1, -2, false, rStr, color_1, repvendor["Name"], color_2)

							color_1 = ARL:hexcolor("NORMAL")
							color_2 = ARL:hexcolor("HIGH")

							leftText = leftText .. "|cff" .. color_1 .. repvendor["Location"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 ..  coord_text .. "|r\n"

		--					ttAdd(2, -2, true, repvendor["Location"], color_1, coord_text, color_2)
						end
					elseif acquire_type == A_WORLD_DROP then
						local acquire_id = acquire["ID"]

						if acquire_id == 1 then
							color_1 = ARL:hexcolor("COMMON")
						elseif acquire_id == 2 then
							color_1 = ARL:hexcolor("UNCOMMON")
						elseif acquire_id == 3 then
							color_1 = ARL:hexcolor("RARE")
						elseif acquire_id == 4 then
							color_1 = ARL:hexcolor("EPIC")
						else
							color_1 = ARL:hexcolor("NORMAL")
						end
		--				ttAdd(0, -1, false, L["World Drop"], color_1)
						leftText = leftText .. "|cff" .. color_1 .. L["World Drop"] .. "|r\n"
						rightText = rightText .. "\n"
					elseif acquire_type == A_CUSTOM then
		--				ttAdd(0, -1, false, ARL.custom_list[acquire["ID"]]["Name"], ARL:hexcolor("NORMAL"))
						leftText = leftText .. "|cff" .. ARL:hexcolor("NORMAL") .. ARL.custom_list[acquire["ID"]]["Name"] .. "|r\n"
						rightText = rightText .. "\n"
					elseif acquire_type == A_PVP then
						local vendor = ARL.vendor_list[acquire["ID"]]
						local faction

						color_1 = ARL:hexcolor("VENDOR")
						display_tip, color_2, faction = GetTipFactionInfo(vendor["Faction"])

						if display_tip then
							local coord_text = ""

							if vendor["Coordx"] ~= 0 and vendor["Coordy"] ~= 0 then
								coord_text = "(" .. vendor["Coordx"] .. ", " .. vendor["Coordy"] .. ")"
							end
		--					ttAdd(0, -1, false, L["Vendor"], color_1, vendor["Name"], color_2)

							leftText = leftText .. "|cff" .. color_1 .. L["Vendor"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 ..  vendor["Name"] .. "|r\n"

							color_1 = ARL:hexcolor("NORMAL")
							color_2 = ARL:hexcolor("HIGH")

							leftText = leftText .. "|cff" .. color_1 .. vendor["Location"] .. "|r\n"
							rightText = rightText .. "|cff" .. color_2 ..  coord_text .. "|r\n"

		--					ttAdd(1, -2, true, vendor["Location"], color_1, coord_text, color_2)
						elseif faction then
		--					ttAdd(0, -1, false, faction.." "..L["Vendor"], color_1)
							leftText = leftText .. "|cff" .. color_1 .. faction.." "..L["Vendor"] .. "|r\n"
							rightText = rightText .. "\n"
						end
						--[===[@alpha@
					else	-- Unhandled
						ttAdd(0, -1, 0, L["Unhandled Recipe"], ARL:hexcolor("NORMAL"))
						--@end-alpha@]===]
					end
				end

				return leftText, rightText
			end



			local GWFrame = GnomeWorks:GetMainFrame()
			local GWScrollFrame = GnomeWorks:GetSkillListScrollFrame()
			local recipeFilterMenu = GWScrollFrame.filterMenu

			local GWDetailFrame = GnomeWorks:GetDetailFrame()

			local ARLFilterMenu = {} do
				local ARLSourceSubMenu = {
				}

--[[
    * 1 = Alliance faction
    * 2 = Horde faction
    * 3 = Trainer
    * 4 = Vendor
    * 5 = Instance
    * 6 = Raid
    * 7 = Seasonal
    * 8 = Quest
    * 9 = PVP
    * 10 = World Drop
    * 11 = Mob drop
    * 12 = Discovery
    * 13-20 = Reserved for future use
]]

				local sourceFlags = {
					[3] = "Trainer",
					[4] = "Vendor",
					[5] = "Instance",
					[6] = "Raid",
					[7] = "Seasonal",
					[8] = "Quest",
					[9] = "PVP",
					[10] = "World Drop",
					[11] = "Mob Drop",
					[12] = "Discovery",
				}

				local ARLFilterParameters = {
					{
						text = "ARL: Filter by Recipe Source",
						enabled = false,
						func = function(entry)
							if entry and entry.arlData and entry.arlData.Flags then
								local arlFlag = entry.arlData.Flags

								for flag, value in pairs(ARLSourceFlags) do

									if arlFlag[flag] then
										return false
									end
								end
							end

							return true
						end,

						menuList = ARLSourceSubMenu,
					},
				}


				for flag,name in pairs(sourceFlags) do
					local button = {
						text = name,
						func = function()
							if not ARLSourceFlags[flag] then
								ARLSourceFlags[flag] = true
							else
								ARLSourceFlags[flag] = nil
							end

							GWScrollFrame:Refresh()
						end,
						checked = function() return ARLSourceFlags[flag] end
					}

					ARLSourceFlags[flag] = true

					table.insert(ARLSourceSubMenu, button)
				end


				GnomeWorks:CreateFilterMenu(ARLFilterParameters, ARLFilterMenu, GWScrollFrame.columnHeaders[2])


				for k,v in pairs(ARLFilterMenu) do
					table.insert(GWScrollFrame.columnHeaders[2].filterMenu, v)
				end
			end


			local function updateData(scrollFrame, entry)

				ARL:InitializeRecipe(GetTradeSkillLine())

				if not entry.subGroup then
					entry.arlData = ARL.recipe_list[entry.recipeID]
				end
			end


			GWDetailFrame:RegisterInfoFunction(function(index,recipeID,left,right)
				local recipe = ARL.recipe_list[recipeID]

				left = left .. "ARL Recipe Source:\n"
				right = right .. "\n"


				if recipe then
					local l,r = GenerateAcquireText(recipe)

					return left..l, right..r
				else
					return left,right
				end

			end)





			local hiddenFrame = CreateFrame("Frame",nil,UIParent)

			ARL.scan_button:SetParent(GWFrame)
			ARL.scan_button:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT", -100,-100)

--			ARL.scan_button:Hide()

			plugin:AddButton("Scan", function() ARL:Scan(false) end)
			plugin:AddButton("Text Dump", function() ARL:Scan(true) end)
			plugin:AddButton("Clear Map", function() ARL:ClearMap() end)
--			plugin:AddButton("Hide", function() ARL.frame:Hide() end)
			plugin:AddButton("Setup Map", function() ARL:SetupMap() end)


			GWScrollFrame:RegisterRowUpdate(updateData, plugin)


			return true
		else
			return false
		end
	end

	plugin = GnomeWorks:RegisterPlugin("Ackis Recipe List", Initialize)
end


