

-- ARL support

do
	local function Initialize()
		local ARL = AckisRecipeList

		local ARLSourceFlags = {}

		if ARL then

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

				local sourceFlagBitValue = {}

				local ARLFilterParameters = {
					{
						text = "ARL: Filter by Recipe Source",
						enabled = false,
						func = function(entry)
							if entry and entry.arlFlags then
								local arlFlag = entry.arlFlags.common1

								for flag, value in pairs(ARLSourceFlags) do
									if bit.band(sourceFlagBitValue[flag], arlFlag)==sourceFlagBitValue[flag] then
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

					sourceFlagBitValue[flag] = math.pow(2,flag-1)

					table.insert(ARLSourceSubMenu, button)
				end


				GnomeWorks:CreateFilterMenu(ARLFilterParameters, ARLFilterMenu, GWScrollFrame.columnHeaders[2])


				for k,v in pairs(ARLFilterMenu) do
					table.insert(GWScrollFrame.columnHeaders[2].filterMenu, v)
				end
			end


			local function updateData(scrollFrame, entry)

				ARL:InitializeProfession(GetTradeSkillLine())

				if not entry.subGroup then
					entry.arlFlags = ARL:GetRecipeData(entry.recipeID,"flags")
				end
			end

--

--function ARL:DisplayAcquireData(recipe_id, acquire_id, location, quality_color, addline_func)

			local leftInfoText, rightInfoText

--[[
local function ttAdd(
			leftPad,		-- number of times to pad two spaces on left side
			textSize,		-- add to or subtract from addon.db.profile.frameopts.fontsize to get fontsize
			narrow,			-- if 1, use ARIALN instead of FRITZQ
			str1,			-- left-hand string
			hexcolor1,		-- hex color code for left-hand side
			str2,			-- if present, this is the right-hand string
			hexcolor2)		-- if present, hex color code for right-hand side
]]

			local function constructInfoText(leftPad, textSize, narrow, leftText, leftColor, rightText, rightColor)
				leftInfoText = string.format("%s|cff%s%s|r\n",leftInfoText, leftColor or "ffffff", leftText or "")
				rightInfoText = string.format("%s|cff%s%s|r\n",rightInfoText, rightColor or "ffffff", rightText or "")
			end


			GWDetailFrame:RegisterInfoFunction(function(index,recipeID,left,right)
				if ARL.DisplayAcquireData then

					leftInfoText = left .. "ARL Recipe Source:\n"
					rightInfoText = right .. "\n"

					ARL:DisplayAcquireData(recipeID, nil, nil, constructInfoText)

					return leftInfoText, rightInfoText
				end
			end)




			if ARL.InitializeLookups then
				ARL:InitializeLookups()
			end



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


