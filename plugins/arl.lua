--[[
 if addon.Frame:IsVisible() then
					      if IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() then
						      -- Shift only (Text dump)
						      addon:Scan(true)
					      elseif not IsShiftKeyDown() and IsAltKeyDown() and not IsControlKeyDown() then
						      -- Alt only (Wipe icons from map)
						      addon:ClearMap()
					      elseif not IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() and current_prof == cprof then
						      -- If we have the same profession open, then we close the scanned window
						      addon.Frame:Hide()
					      elseif not IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() then
						      -- If we have a different profession open we do a scan
						      addon:Scan(false)
						      addon:SetupMap()
					      end
				      else
					      if IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() then
						      -- Shift only (Text dump)
						      addon:Scan(true)
					      elseif not IsShiftKeyDown() and IsAltKeyDown() and not IsControlKeyDown() then
						      -- Alt only (Wipe icons from map)
						      addon:ClearMap()
					      elseif not IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() then
						      -- No modification
						      addon:Scan(false)
						      addon:SetupMap()
					      end
				      end
]]

-- ARL support

do
	local function Initialize()
		if AckisRecipeList then
			local GWFrame = GnomeWorks:GetMainFrame()

			local hiddenFrame = CreateFrame("Frame",nil,UIParent)

			AckisRecipeList.scan_button:SetParent(GWFrame)
			AckisRecipeList.scan_button:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT", -100,-100)

--			AckisRecipeList.scan_button:Hide()

			plugin:AddButton("Scan", function() AckisRecipeList:Scan(false) end)
			plugin:AddButton("Text Dump", function() AckisRecipeList:Scan(true) end)
			plugin:AddButton("Clear Map", function() AckisRecipeList:ClearMap() end)
--			plugin:AddButton("Hide", function() AckisRecipeList.frame:Hide() end)
			plugin:AddButton("Setup Map", function() AckisRecipeList:SetupMap() end)

			return true
		else
			return false
		end
	end

	plugin = GnomeWorks:RegisterPlugin("Ackis Recipe List", Initialize)
end


