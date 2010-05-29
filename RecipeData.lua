



do
	local millingBrackets = {
		[39151] = { [39151] = 3 },
		[43105] = { { [43105] = 0.5, [39339] = 2.5 } , { [43105] = 1, [39339] = 3 } },
	}

	local millingResults = {
		[3818] = { -- Fadeleaf
			[43105] = 0.5, --Indigo Pigment
			[39339] = 2.5, --Emerald Pigment
		},
		[3821] = { -- Goldthorn
			[43105] = 0.5, --Indigo Pigment
			[39339] = 2.5, --Emerald Pigment
		},

		[3358] = { -- Khadgar\'s Whisker
			[43105] = 1, --Indigo Pigment
			[39339] = 3, --Emerald Pigment
		},
		[3819] = { -- Wintersbite
			[43105] = 1, --Indigo Pigment
			[39339] = 3, --Emerald Pigment
		},



		[765] = { -- Silverleaf
			[39151] = 3, --Alabaster Pigment
		},
		[2449] = { -- Earthroot
			[39151] = 3, --Alabaster Pigment
		},
		[2447] = { -- Peacebloom
			[39151] = 3, --Alabaster Pigment
		},

		[8831] = { -- Purple Lotus
			[39340] = 2.5, --Violet Pigment
			[43106] = 0.5, --Ruby Pigment
		},
		[8836] = { -- Arthas\' Tears
			[39340] = 2.5, --Violet Pigment
			[43106] = 0.5, --Ruby Pigment
		},
		[8838] = { -- Sungrass
			[39340] = 2.5, --Violet Pigment
			[43106] = 0.5, --Ruby Pigment
		},
		[4625] = { -- Firebloom
			[39340] = 2.5, --Violet Pigment
			[43106] = 0.5, --Ruby Pigment
		},
		[8839] = { -- Blindweed
			[39340] = 3, --Violet Pigment
			[43106] = 1, --Ruby Pigment
		},
		[8845] = { -- Ghost Mushroom
			[39340] = 3, --Violet Pigment
			[43106] = 1, --Ruby Pigment
		},
		[8846] = { -- Gromsblood
			[39340] = 3, --Violet Pigment
			[43106] = 1, --Ruby Pigment
		},

		[785] = { -- Mageroyal
			[43103] = 0.5, --Verdant Pigment
			[39334] = 2.5, --Dusky Pigment
		},
		[2453] = { -- Bruiseweed
			[43103] = 1, --Verdant Pigment
			[39334] = 3, --Dusky Pigment
		},
		[3820] = { -- Stranglekelp
			[43103] = 1, --Verdant Pigment
			[39334] = 3, --Dusky Pigment
		},
		[2450] = { -- Briarthorn
			[43103] = 0.5, --Verdant Pigment
			[39334] = 3, --Dusky Pigment
		},
		[2452] = { -- Swiftthistle
			[43103] = 0.5, --Verdant Pigment
			[39334] = 3, --Dusky Pigment
		},


		[13463] = { -- Dreamfoil
			[39341] = 2.5, --Silvery Pigment
			[43107] = 0.5, --Sapphire Pigment
		},
		[13464] = { -- Golden Sansam
			[39341] = 2.5, --Silvery Pigment
			[43107] = 0.5, --Sapphire Pigment
		},
		[13465] = { -- Mountain Silversage
			[39341] = 3, --Silvery Pigment
			[43107] = 1, --Sapphire Pigment
		},
		[13466] = { -- Plaguebloom
			[39341] = 3, --Silvery Pigment
			[43107] = 1, --Sapphire Pigment
		},
		[13467] = { -- Icecap
			[39341] = 3, --Silvery Pigment
			[43107] = 1, --Sapphire Pigment
		},


		[39969] = { -- Fire Seed
			[43109] = 0.5, --Icy Pigment
			[39343] = 2.5, --Azure Pigment
		},
		[36901] = { -- Goldclover
			[43109] = 0.5, --Icy Pigment
			[39343] = 2.5, --Azure Pigment
		},
		[36907] = { -- Talandra\'s Rose
			[43109] = 0.5, --Icy Pigment
			[39343] = 2.5, --Azure Pigment
		},
		[39970] = { -- Fire Leaf
			[43109] = 0.5, --Icy Pigment
			[39343] = 2.5, --Azure Pigment
		},
		[37921] = { -- Deadnettle
			[43109] = 0.5, --Icy Pigment
			[39343] = 3, --Azure Pigment
		},
		[36904] = { -- Tiger Lily
			[43109] = 0.5, --Icy Pigment
			[39343] = 3, --Azure Pigment
		},
		[36905] = { -- Lichbloom
			[43109] = 1, --Icy Pigment
			[39343] = 3, --Azure Pigment
		},
		[36906] = { -- Icethorn
			[43109] = 1, --Icy Pigment
			[39343] = 3, --Azure Pigment
		},
		[36903] = { -- Adder\'s Tongue
			[43109] = 1.25, --Icy Pigment
			[39343] = 3, --Azure Pigment
		},



		[22789] = { -- Terocone
			[39342] = 2.5, --Nether Pigment
			[43108] = 0.5, --Ebon Pigment
		},
		[22786] = { -- Dreaming Glory
			[39342] = 2.5, --Nether Pigment
			[43108] = 0.5, --Ebon Pigment
		},
		[22787] = { -- Ragveil
			[39342] = 2.5, --Nether Pigment
			[43108] = 0.5, --Ebon Pigment
		},
		[22785] = { -- Felweed
			[39342] = 3, --Nether Pigment
			[43108] = 0.5, --Ebon Pigment
		},
		[22790] = { -- Ancient Lichen
			[39342] = 3, --Nether Pigment
			[43108] = 1, --Ebon Pigment
		},
		[22792] = { -- Nightmare Vine
			[39342] = 3, --Nether Pigment
			[43108] = 1, --Ebon Pigment
		},
		[22793] = { -- Mana Thistle
			[39342] = 3, --Nether Pigment
			[43108] = 1, --Ebon Pigment
		},
		[22791] = { -- Netherbloom
			[39342] = 3, --Nether Pigment
			[43108] = 1, --Ebon Pigment
		},



		[3355] = { -- Wild Steelbloom
			[43104] = 0.5, --Burnt Pigment
			[39338] = 2.5, --Golden Pigment
		},
		[3369] = { -- Grave Moss
			[43104] = 0.5, --Burnt Pigment
			[39338] = 2.5, --Golden Pigment
		},
		[3357] = { -- Liferoot
			[43104] = 1, --Burnt Pigment
			[39338] = 3, --Golden Pigment
		},

		[3356] = { -- Kingsblood
			[43104] = 1, --Burnt Pigment
			[39338] = 3, --Golden Pigment
		},
	}

	local millBrackets =
	{
		[2449] = 1,
		[2447] = 1,
		[765] = 1,

		[2450] = 25,
		[2453] = 25,
		[785] = 25,
		[3820] = 25,
		[2452] = 25,

		[3369] = 75,
		[3356] = 75,
		[3357] = 75,
		[3355] = 75,

		[3818] = 125,
		[3821] = 125,
		[3358] = 125,
		[3819] = 125,

		[8836] = 175,
		[8839] = 175,
		[4625] = 175,
		[8845] = 175,
		[8846] = 175,
		[8831] = 175,
		[8838] = 175,

		[13463] = 225,
		[13464] = 225,
		[13467] = 225,
		[13465] = 225,
		[13466] = 225,

		[22790] = 275,
		[22786] = 275,
		[22785] = 275,
		[22793] = 275,
		[22791] = 275,
		[22792] = 275,
		[22787] = 275,
		[22789] = 275,

		[36903] = 325,
		[37921] = 325,
		[39970] = 325,
		[36901] = 325,
		[36906] = 325,
		[36905] = 325,
		[36907] = 325,
		[36904] = 325,
	}


	local millingLevels = {
		[1] = { "playerMillLevel", 1},
		[25] = { "playerMillLevel", 25},
		[75] = { "playerMillLevel", 75},
		[125] = { "playerMillLevel", 125},
		[175] = { "playerMillLevel", 175},
		[225] = { "playerMillLevel", 225},
		[275] = { "playerMillLevel", 275},
		[325] = { "playerMillLevel", 325},
	}

	local pigmentSources = {}


	local prospectingResults = {
		[36912] = { --Saronite Ore
			[36929] = 0.275, --Huge Citrine
			[36930] = 0.062, --Monarch Topaz
			[36923] = 0.275, --Chalcedony
			[36924] = 0.062, --Sky Sapphire
			[36932] = 0.275, --Dark Jade
			[36918] = 0.062, --Scarlet Ruby
			[36926] = 0.275, --Shadow Crystal
			[36927] = 0.06, --Twilight Opal
			[36920] = 0.27, --Sun Crystal
			[36933] = 0.06, --Forest Emerald
			[36921] = 0.06, --Autumn\'s Glow
			[36917] = 0.27, --Bloodstone
		},
		[23424] = { --Fel Iron Ore
			[23441] = 0.012, --Nightseye
			[23438] = 0.012, --Star of Elune
			[23112] = 0.27, --Golden Draenite
			[23439] = 0.012, --Noble Topaz
			[23437] = 0.012, --Talasite
			[23117] = 0.26, --Azure Moonstone
			[23436] = 0.012, --Living Ruby
			[23440] = 0.012, --Dawnstone
			[21929] = 0.27, --Flame Spessarite
			[23079] = 0.27, --Deep Peridot
			[23077] = 0.265, --Blood Garnet
			[23107] = 0.265, --Shadow Draenite
		},
		[2771] = { --Tin Ore
			[3864] = 0.034, --Citrine
			[1210] = 0.575, --Shadowgem
			[1529] = 0.032, --Jade
			[7909] = 0.032, --Aquamarine
			[1705] = 0.58, --Lesser Moonstone
			[1206] = 0.585, --Moss Agate
		},
		[23425] = { --Adamantite Ore
			[23441] = 0.034, --Nightseye
			[23438] = 0.034, --Star of Elune
			[23112] = 0.275, --Golden Draenite
			[23439] = 0.036, --Noble Topaz
			[23079] = 0.275, --Deep Peridot
			[23437] = 0.036, --Talasite
			[23117] = 0.27, --Azure Moonstone
			[23436] = 0.034, --Living Ruby
			[23440] = 0.034, --Dawnstone
			[21929] = 0.28, --Flame Spessarite
			[24243] = 1, --nil
			[23077] = 0.275, --Blood Garnet
			[23107] = 0.27, --Shadow Draenite
		},
		[2770] = { --Copper Ore
			[818] = 0.5, --Tigerseye
			[1210] = 0.1, --Shadowgem
			[774] = 0.5, --Malachite
		},
		[36909] = { --Cobalt Ore
			[36929] = 0.375, --Huge Citrine
			[36930] = 0.012, --Monarch Topaz
			[36923] = 0.375, --Chalcedony
			[36924] = 0.012, --Sky Sapphire
			[36932] = 0.375, --Dark Jade
			[36918] = 0.014, --Scarlet Ruby
			[36926] = 0.37, --Shadow Crystal
			[36927] = 0.012, --Twilight Opal
			[36920] = 0.37, --Sun Crystal
			[36917] = 0.365, --Bloodstone
			[36921] = 0.012, --Autumn\'s Glow
			[36933] = 0.012, --Forest Emerald
		},
		[36910] = { --Titanium Ore
			[36917] = 0.37, --Bloodstone
			[36918] = 0.064, --Scarlet Ruby
			[36919] = 0.064, --nil
			[36920] = 0.355, --Sun Crystal
			[36921] = 0.06, --Autumn\'s Glow
			[36922] = 0.064, --nil
			[36923] = 0.365, --Chalcedony
			[36924] = 0.062, --Sky Sapphire
			[36925] = 0.064, --nil
			[36926] = 0.365, --Shadow Crystal
			[36927] = 0.062, --Twilight Opal
			[36928] = 0.066, --nil
			[46849] = 0.875, --nil
			[36930] = 0.064, --Monarch Topaz
			[36931] = 0.07, --nil
			[36932] = 0.37, --Dark Jade
			[36933] = 0.06, --Forest Emerald
			[36934] = 0.068, --nil
			[36929] = 0.37, --Huge Citrine
		},
		[3858] = { --Mithril Ore
			[12364] = 0.024, --Huge Emerald
			[12361] = 0.024, --Blue Sapphire
			[3864] = 0.52, --Citrine
			[12800] = 0.024, --Azerothian Diamond
			[7909] = 0.525, --Aquamarine
			[7910] = 0.53, --Star Ruby
			[12799] = 0.026, --Large Opal
		},
		[10620] = { --Thorium Ore
			[12799] = 0.4, --Large Opal
			[23112] = 0.002, --Golden Draenite
			[23079] = 0.002, --Deep Peridot
			[12361] = 0.39, --Blue Sapphire
			[23117] = 0.002, --Azure Moonstone
			[12800] = 0.39, --Azerothian Diamond
			[23077] = 0.002, --Blood Garnet
			[21929] = 0.002, --Flame Spessarite
			[12364] = 0.395, --Huge Emerald
			[23107] = 0.002, --Shadow Draenite
			[7910] = 0.3, --Star Ruby
		},
		[2772] = { --Iron Ore
			[3864] = 0.525, --Citrine
			[1529] = 0.535, --Jade
			[7909] = 0.05, --Aquamarine
			[1705] = 0.525, --Lesser Moonstone
			[7910] = 0.05, --Star Ruby
		},
	}

	local commonRecipes = {
		[44122] = {
			name = "Lesser Cosmic Essence",
			reagents = {
				[34055] = 1, --Greater Cosmic Essence
			},
			results = {
				[34056] = 3, --Lesser Cosmic Essence
			},
		},
		[32977] = {
			name = "Greater Planar Essence",
			reagents = {
				[22447] = 3, --Lesser Planar Essence
			},
			results = {
				[22446] = 1, --Greater Planar Essence
			},
		},
		[56041] = {
			name = "Crystallized Earth",
			reagents = {
				[35624] = 1, --Eternal Earth
			},
			results = {
				[37701] = 10, --Crystallized Earth
			},
		},
		[56043] = {
			name = "Crystallized Life",
			reagents = {
				[35625] = 1, --Eternal Life
			},
			results = {
				[37704] = 10, --Crystallized Life
			},
		},
		[56045] = {
			name = "Crystallized Air",
			reagents = {
				[35623] = 1, --Eternal Air
			},
			results = {
				[37700] = 10, --Crystallized Air
			},
		},
		[49245] = {
			name = "Create Eternal Water",
			reagents = {
				[37705] = 10, --Crystallized Water
			},
			results = {
				[35622] = 1, --Eternal Water
			},
		},
		[13497] = {
			name = "Greater Astral Essence",
			reagents = {
				[10998] = 3, --Lesser Astral Essence
			},
			results = {
				[11082] = 1, --Greater Astral Essence
			},
		},
		[13498] = {
			name = "Lesser Astral Essence",
			reagents = {
				[11082] = 1, --Greater Astral Essence
			},
			results = {
				[10998] = 3, --Lesser Astral Essence
			},
		},
		[59926] = {
			name = "Borean Leather",
			reagents = {
				[33567] = 5, --Borean Leather Scraps
			},
			results = {
				[33568] = 1, --Borean Leather
			},
		},
		[61755] = {
			name = "Create Dream Shard",
			reagents = {
				[34053] = 3, --Small Dream Shard
			},
			results = {
				[34052] = 1, --Dream Shard
			},
		},
		[13632] = {
			name = "Greater Mystic Essence",
			reagents = {
				[11134] = 3, --Lesser Mystic Essence
			},
			results = {
				[11135] = 1, --Greater Mystic Essence
			},
		},
		[13633] = {
			name = "Lesser Mystic Essence",
			reagents = {
				[11135] = 1, --Greater Mystic Essence
			},
			results = {
				[11134] = 3, --Lesser Mystic Essence
			},
		},
		[44123] = {
			name = "Greater Cosmic Essence",
			reagents = {
				[34056] = 3, --Lesser Cosmic Essence
			},
			results = {
				[34055] = 1, --Greater Cosmic Essence
			},
		},
		[49234] = {
			name = "Create Eternal Air",
			reagents = {
				[37700] = 10, --Crystallized Air
			},
			results = {
				[35623] = 1, --Eternal Air
			},
		},
		[56040] = {
			name = "Crystallized Water",
			reagents = {
				[35622] = 1, --Eternal Water
			},
			results = {
				[37705] = 10, --Crystallized Water
			},
		},
		[56042] = {
			name = "Crystallized Fire",
			reagents = {
				[36860] = 1, --Eternal Fire
			},
			results = {
				[37702] = 10, --Crystallized Fire
			},
		},
		[56044] = {
			name = "Crystallized Shadow",
			reagents = {
				[35627] = 1, --Eternal Shadow
			},
			results = {
				[37703] = 10, --Crystallized Shadow
			},
		},
		[49244] = {
			name = "Create Eternal Fire",
			reagents = {
				[37702] = 10, --Crystallized Fire
			},
			results = {
				[36860] = 1, --Eternal Fire
			},
		},
		[49246] = {
			name = "Create Eternal Shadow",
			reagents = {
				[37703] = 10, --Crystallized Shadow
			},
			results = {
				[35627] = 1, --Eternal Shadow
			},
		},
		[49248] = {
			name = "Create Eternal Earth",
			reagents = {
				[37701] = 10, --Crystallized Earth
			},
			results = {
				[35624] = 1, --Eternal Earth
			},
		},
		[20040] = {
			name = "Lesser Eternal Essence",
			reagents = {
				[16203] = 1, --Greater Eternal Essence
			},
			results = {
				[16202] = 3, --Lesser Eternal Essence
			},
		},
		[13361] = {
			name = "Greater Magic Essence",
			reagents = {
				[10938] = 3, --Lesser Magic Essence
			},
			results = {
				[10939] = 1, --Greater Magic Essence
			},
		},
		[13362] = {
			name = "Lesser Magic Essence",
			reagents = {
				[10939] = 1, --Greater Magic Essence
			},
			results = {
				[10938] = 3, --Lesser Magic Essence
			},
		},
		[56307] = {
			name = "Saronite Sharpening Stone",
			reagents = {
				[22573] = 3, --Mote of Earth
			},
			results = {
				[23446] = 1, --Adamantite Bar
			},
		},
		[32978] = {
			name = "Lesser Planar Essence",
			reagents = {
				[22446] = 1, --Greater Planar Essence
			},
			results = {
				[22447] = 3, --Lesser Planar Essence
			},
		},
		[28100] = {
			name = "Create Primal Air",
			reagents = {
				[22572] = 10, --Mote of Air
			},
			results = {
				[22451] = 1, --Primal Air
			},
		},
		[28101] = {
			name = "Create Primal Earth",
			reagents = {
				[22573] = 10, --Mote of Earth
			},
			results = {
				[22452] = 1, --Primal Earth
			},
		},
		[28102] = {
			name = "Create Primal Fire",
			reagents = {
				[22574] = 10, --Mote of Fire
			},
			results = {
				[21884] = 1, --Primal Fire
			},
		},
		[28103] = {
			name = "Create Primal Water",
			reagents = {
				[22578] = 10, --Mote of Water
			},
			results = {
				[21885] = 1, --Primal Water
			},
		},
		[28104] = {
			name = "Create Primal Shadow",
			reagents = {
				[22577] = 10, --Mote of Shadow
			},
			results = {
				[22456] = 1, --Primal Shadow
			},
		},
		[28105] = {
			name = "Create Primal Mana",
			reagents = {
				[22576] = 10, --Mote of Mana
			},
			results = {
				[22457] = 1, --Primal Mana
			},
		},
		[28106] = {
			name = "Create Primal Life",
			reagents = {
				[22575] = 10, --Mote of Life
			},
			results = {
				[21886] = 1, --Primal Life
			},
		},
		[20039] = {
			name = "Greater Eternal Essence",
			reagents = {
				[16202] = 3, --Lesser Eternal Essence
			},
			results = {
				[16203] = 1, --Greater Eternal Essence
			},
		},
		[49247] = {
			name = "Create Eternal Life",
			reagents = {
				[37704] = 10, --Crystallized Life
			},
			results = {
				[35625] = 1, --Eternal Life
			},
		},
		[13739] = {
			name = "Greater Nether Essence",
			reagents = {
				[11174] = 3, --Lesser Nether Essence
			},
			results = {
				[11175] = 1, --Greater Nether Essence
			},
		},
		[13740] = {
			name = "Lesser Nether Essence",
			reagents = {
				[11175] = 1, --Greater Nether Essence
			},
			results = {
				[11174] = 3, --Lesser Nether Essence
			},
		},
	}






	-- spoof recipes for milled herbs -> pigments
	local function AddMillingRecipes()
		for herbID, pigmentTable in pairs(millingResults) do
			local reagentTable = {}
			local recipeName = "Mill "..(GetItemInfo(herbID) or "item:"..herbID)

			reagentTable[herbID] = 5

			GnomeWorks:AddRecipe(-herbID, recipeName, pigmentTable, reagentTable, millingLevels[herbID])
		end
	end

end


do

-- courtesy of nandini

	local cooldownGroups = {
	Alchemy = {
	  ["Transmute"] = {
	   duration = 72000 , -- 20 hours, in seconds
	   spells = {
		11479 , -- Transmute: Iron to Gold
		11480 , -- Transmute: Mithril to Truesilver
		60350 , -- Transmute: Titanium

		17559 , -- Transmute: Air to Fire
		17560 , -- Transmute: Fire to Earth
		17561 , -- Transmute: Earth to Water
		17562 , -- Transmute: Water to Air
		17563 , -- Transmute: Undeath to Water
		17565 , -- Transmute: Life to Earth
		17566 , -- Transmute: Earth to Life

		28585 , -- Transmute: Primal Earth to Life
		28566 , -- Transmute: Primal Air to Fire
		28567 , -- Transmute: Primal Earth to Water
		28568 , -- Transmute: Primal Fire to Earth
		28569 , -- Transmute: Primal Water to Air
		28580 , -- Transmute: Primal Shadow to Water
		28581 , -- Transmute: Primal Water to Shadow
		28582 , -- Transmute: Primal Mana to Fire
		28583 , -- Transmute: Primal Fire to Mana
		28584 , -- Transmute: Primal Life to Earth
		53771 , -- Transmute: Eternal Life to Shadow
		53773 , -- Transmute: Eternal Life to Fire
		53774 , -- Transmute: Eternal Fire to Water
		53775 , -- Transmute: Eternal Fire to Life
		53776 , -- Transmute: Eternal Air to Water
		53777 , -- Transmute: Eternal Air to Earth
		53779 , -- Transmute: Eternal Shadow to Earth
		53780 , -- Transmute: Eternal Shadow to Life
		53781 , -- Transmute: Eternal Earth to Air
		53782 , -- Transmute: Eternal Earth to Shadow
		53783 , -- Transmute: Eternal Water to Air
		53784 , -- Transmute: Eternal Water to Fire

		66658 , -- Transmute: Ametrine
		66659 , -- Transmute: Cardinal Ruby
		66660 , -- Transmute: King's Amber
		66662 , -- Transmute: Dreadstone
		66663 , -- Transmute: Majestic Zircon
		66664 , -- Transmute: Eye of Zul
	   } ,
	  } ,
	 } ,
	 Mining = {
	  ["Titansteel"] = {
	   duration = 72000 , -- 20 hours, in seconds
	   spells = {
		52208 , -- Smelt Titansteel
	   } ,
	  } ,
	 } ,
	 Inscription = {
	  ["Minor research"]  = {
	   duration = 72000 , -- 20 hours, in seconds
	   spells = {
		61288 , -- Minor Inscription Research
	   } ,
	  } ,
	  ["Northrend research"] = {
	   duration = 72000 , -- 20 hours, in seconds
	   spells = {
		61177 , -- Northrend Inscription Research
	   } ,
	  } ,
	 } ,
	 Enchanting = {
	  ["Void Sphere"] = {
	   duration = 172800 , -- 48 hours, in seconds
	   spells = {
		28028 , -- Void Sphere
	   } ,
	  } ,
	 } ,
	}

	local spellCooldown = {}

	for tradeSkill, cooldownGroup in pairs(cooldownGroups) do
		for groupName, data in pairs(cooldownGroup) do
			for i=1,#data.spells do
				spellCooldown[ data.spells[i] ] = cooldownGroup
			end
		end
	end

	function GnomeWorks:GetSpellCooldownGroup(recipeID)
		return spellCooldown[recipeID]
	end

	local tradeName = {
		[100000] = "Common Skills",
		[100001] = "Vendor Conversion",
	}

	local tradeLink = {
		[100000] = "[Common Skills]",
		[100001] = "[Vendor Conversion]",
	}

	local tradeName = {
		[100000] = "-",
		[100001] = "-",
	}



	function GnomeWorks:GetRecipeName(recipeID)
		if recipeID then
			return GnomeWorksDB.names[recipeID] or (GetSpellInfo(recipeID))
		end
	end

	function GnomeWorks:GetTradeName(tradeID)
		return tradeName[tradeID] or (GetSpellInfo(tradeID))
	end

	function GnomeWorks:GetTradeInfo(tradeID)
		if tradeName[tradeID] then
			return tradeName[tradeID], tradeLink[tradeID], tradeIcon[tradeID]
		else
			return GetSpellInfo(tradeID)
		end
	end


	function GnomeWorks:GetRecipeTradeID(recipeID)
		return GnomeWorksDB.tradeIDs[recipeID]
	end
end


