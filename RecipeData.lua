




do

	function GnomeWorks:GetRecipeName(recipeID)
		return (GetSpellInfo(recipeID))

--[[	if self.data.recipeDB[recipeID] then
			return self.data.recipeDB[recipeID].name
		end

		return "recipe:"..recipeID
		]]
	end

end
