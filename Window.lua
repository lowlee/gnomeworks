




local Window = {}

--[[
 the SetBackdrop system has some texture coordinate problems, so i wrote this to emulate

 i'm creating an invisible frame for sizing simplicity, but the textures are actually parented to the real frame (so they are place in the correct drawing layer)
 even tho they are referenced from this invisible frame (as indices into the frame table)
]]

do
	local textureQuads = {
		LEFT = 0,
		RIGHT = 1,
		TOP = 2,
		BOTTOM = 3,
		TOPLEFT = 4,
		TOPRIGHT = 5,
		BOTTOMLEFT = 6,
		BOTTOMRIGHT = 7,
	}

	local LEFTRIGHT = {"LEFT", "RIGHT"}
	local TOPBOTTOM = {"TOP", "BOTTOM"}
	local ALLQUADS = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "TOP", "BOTTOM"}
	local CORNERS = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}

	local mouseHintTexture


	local function ResizeBetterBackdrop(frame)
		if not frame then
			return
		end

		local w,h = frame:GetWidth()-frame.edgeSize*2, frame:GetHeight()-frame.edgeSize*2

		for k,i in pairs(LEFTRIGHT) do
			local t = frame["texture"..i]

			local y = h/frame.edgeSize

			local q = textureQuads[i]

			t:SetTexCoord(q*.125, q*.125+.125, 0, y)
		end

		for k,i in pairs(TOPBOTTOM) do
			local t = frame["texture"..i]

			local y = w/frame.edgeSize

			local q = textureQuads[i]

			local x1 = q*.125
			local x2 = q*.125+.125

			t:SetTexCoord(x1,0, x2,0, x1,y, x2, y)
		end

		frame.textureBG:SetTexCoord(0,w/frame.tileSize, 0,h/frame.tileSize)
	end


	function Window:SetBetterBackdropColor(frame,...)
		if not frame or not frame.backDrop then
			return
		end

		local backDrop = frame.backDrop

		backDrop.textureLEFT:SetVertexColor(...)
		backDrop.textureRIGHT:SetVertexColor(...)
		backDrop.textureBOTTOM:SetVertexColor(...)
		backDrop.textureTOP:SetVertexColor(...)

		backDrop.textureTOPLEFT:SetVertexColor(...)
		backDrop.textureTOPRIGHT:SetVertexColor(...)
		backDrop.textureBOTTOMLEFT:SetVertexColor(...)
		backDrop.textureBOTTOMRIGHT:SetVertexColor(...)

		backDrop.textureBG:SetVertexColor(...)
	end



	function Window:SetBetterBackdrop(frame, bd)
		if not frame.backDrop then
			frame.backDrop = CreateFrame("Frame", nil, frame)


			for k,i in pairs(ALLQUADS) do
				frame.backDrop["texture"..i] =  frame:CreateTexture(nil, "ARTWORK")
			end

			frame.backDrop.textureBG = frame:CreateTexture(nil,"ARTWORK")
		end

		frame.backDrop.edgeSize = bd.edgeSize
		frame.backDrop.tileSize = bd.tileSize

		frame.backDrop:SetPoint("TOPLEFT",frame,"TOPLEFT",-bd.insets.left, bd.insets.top)
		frame.backDrop:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT", bd.insets.right, -bd.insets.bottom)

		local w,h = frame:GetWidth()-bd.edgeSize*2, frame:GetHeight()-bd.edgeSize*2

		frame.backDrop.textureBG:SetTexture(bd.bgFile, bd.tile)

		for k,i in pairs(CORNERS) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile)
			t:SetPoint(i, frame.backDrop)
			t:SetWidth(bd.edgeSize)
			t:SetHeight(bd.edgeSize)

			local q = textureQuads[i]

			t:SetTexCoord(q*.125,q*.125+.125, 0,1)

		end

		for k,i in pairs(LEFTRIGHT) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile, true)
			t:SetPoint(i, frame.backDrop)
			t:SetPoint("BOTTOM", frame.backDrop, "BOTTOM", 0, bd.edgeSize)
			t:SetPoint("TOP", frame.backDrop, "TOP", 0, -bd.edgeSize)
			t:SetWidth(bd.edgeSize)

			local y = h/bd.edgeSize

			local q = textureQuads[i]

			t:SetTexCoord(q*.125, q*.125+.125, 0, y)
		end

		for k,i in pairs(TOPBOTTOM) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile, true)
			t:SetPoint(i, frame.backDrop)
			t:SetPoint("LEFT", frame.backDrop, "LEFT", bd.edgeSize, 0)
			t:SetPoint("RIGHT", frame.backDrop, "RIGHT", -bd.edgeSize, 0)
			t:SetHeight(bd.edgeSize)

			local y = w/bd.edgeSize

			local q = textureQuads[i]

			local x1 = q*.125
			local x2 = q*.125+.125

			if i == "TOP" then
				x1,x2 = x2, x1
			end

			t:SetTexCoord(x1,0, x2,0, x1,y, x2, y)
		end

		frame.backDrop.textureBG:SetPoint("TOPLEFT", frame.backDrop, "TOPLEFT", bd.edgeSize, -bd.edgeSize)
		frame.backDrop.textureBG:SetPoint("BOTTOMRIGHT", frame.backDrop, "BOTTOMRIGHT", -bd.edgeSize, bd.edgeSize)


		frame.backDrop.textureBG:SetTexCoord(0,w/bd.tileSize, 0,h/bd.tileSize)

		frame.backDrop:SetScript("OnSizeChanged", ResizeBetterBackdrop)
	end



	local function GetSizingPoint(frame)
		local x,y = GetCursorPosition()
		local s = frame:GetEffectiveScale()

		local left,bottom,width,height = frame:GetRect()

		x = x/s - left
		y = y/s - bottom

		if x < 10 then
			if y < 10 then return "BOTTOMLEFT" end

			if y > height-10 then return "TOPLEFT" end

			return "LEFT"
		end

		if x > width-10 then
			if y < 10 then return "BOTTOMRIGHT" end

			if y > height-10 then return "TOPRIGHT" end

			return "RIGHT"
		end

		if y < 10 then return "BOTTOM" end

		if y > height-10 then return "TOP" end

		return "UNKNOWN"
	end


	function Window:CreateResizableWindow(frameName,windowTitle, width, height, resizeFunction, config)
		local frame = CreateFrame("Frame",frameName,UIParent)
		frame:Hide()

--		frame:SetFrameStrata("DIALOG")


		frame:SetResizable(true)
		frame:SetMovable(true)
--		frame:SetUserPlaced(true)
		frame:EnableMouse(true)

		if not config.window then
			config.window = {}
		end

		if not config.window[frameName] then
			config.window[frameName] = { x = 0, y = 0, width = width, height = height}
		end

		local x, y = config.window[frameName].x, config.window[frameName].y
		local width, height = config.window[frameName].width, config.window[frameName].height


		frame:SetPoint("CENTER",x,y)
		frame:SetWidth(width)
		frame:SetHeight(height)


		self:SetBetterBackdrop(frame,{bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\newFrameBackground.tga",
												edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\newFrameBorder.tga",
												tile = true, tileSize = 48, edgeSize = 48,
												insets = { left = 4, right = 4, top = 4, bottom = 4 }})
--[[
		self:SetBetterBackdrop(frame,{bgFile = "Interface\\AddOns\\GnomeWorks\\Art\\resizableBarberFrameBG.tga",
												edgeFile = "Interface\\AddOns\\GnomeWorks\\Art\\resizableBarberFrameBorder.tga",
												tile = true, tileSize = 48, edgeSize = 48,
												insets = { left = 4, right = 4, top = 4, bottom = 4 }})
]]

		frame:SetScript("OnSizeChanged", function() resizeFunction() end)

		frame.SavePosition = function(f)
			local frameName = f:GetName()

			if frameName then
				config.window[frameName].width = f:GetWidth()
				config.window[frameName].height = f:GetHeight()

				local cx, cy = f:GetCenter()
				local ux, uy = UIParent:GetCenter()

				config.window[frameName].x = cx - ux
				config.window[frameName].y = cy - uy
			end
		end


--[[
		mouseHintTexture = frame:CreateTexture(nil,"OVERLAY")
		mouseHintTexture:SetWidth(32)
		mouseHintTexture:SetHeight(32)
		mouseHintTexture:Show()
		mouseHintTexture:SetTexture("Interface\\AddOns\\GnomeWorks\\Art\\arrow.tga")

--		mouseHintTexture:SetPoint("CENTER",UIParent,"BOTTOMLEFT",100,100)

		frame:SetScript("OnUpdate", function()

			if mouseHintTexture:IsShown() then
				local x, y = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()

				mouseHintTexture:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/uiScale,y/uiScale)

--				mouseHintTexture:
			end
		end)

		frame:SetScript("OnEnter", function() print("OnEnter") mouseHintTexture:Show() end)
		frame:SetScript("OnLeave", function() print("OnLeave") mouseHintTexture:Hide() end)
]]

		frame:SetScript("OnMouseDown", function() frame:StartSizing(GetSizingPoint(frame)) end)
		frame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
		frame:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)


		local windowMenu = {
			{ text = "Raise Frame", func = function() frame:SetFrameStrata("DIALOG")  if frame.title then frame.title:SetFrameStrata("DIALOG") end end },
			{ text = "Lower Frame", func = function() frame:SetFrameStrata("LOW") if frame.title then frame.title:SetFrameStrata("LOW") end end },
		}

		windowMenuFrame = CreateFrame("Frame", "GWWindowMenuFrame", getglobal("UIParent"), "UIDropDownMenuTemplate")


		local mover = CreateFrame("Frame",nil,frame)
		mover:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		mover:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)

		mover:EnableMouse(true)

		mover:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				frame:StartMoving()
			else
				local x, y = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()

				EasyMenu(windowMenu, windowMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
			end
		end)
		mover:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
		mover:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)



		mover:SetHitRectInsets(10,10,10,10)

		frame.mover = mover



		if windowTitle then
			local title = CreateFrame("Button",nil,UIParent)

			local titleSize = 20

			title:SetHeight(titleSize)

			title.textureLeft = title:CreateTexture(nil, "BORDER")
			title.textureLeft:SetTexture("Interface\\AddOns\\GnomeWorks\\Art\\headerTexture.tga")
			title.textureLeft:SetPoint("LEFT",0,0)
			title.textureLeft:SetWidth(titleSize*2)
			title.textureLeft:SetHeight(titleSize)
			title.textureLeft:SetTexCoord(0, 1, 0, .5)

			title.textureRight = title:CreateTexture(nil, "BORDER")
			title.textureRight:SetTexture("Interface\\AddOns\\GnomeWorks\\Art\\headerTexture.tga")
			title.textureRight:SetPoint("RIGHT",0,0)
			title.textureRight:SetWidth(titleSize*2)
			title.textureRight:SetHeight(titleSize)
			title.textureRight:SetTexCoord(0, 1.0, 0.5, 1.0)


			title.textureCenter = title:CreateTexture(nil, "BORDER")
			title.textureCenter:SetTexture("Interface\\AddOns\\GnomeWorks\\Art\\headerTextureCenter.tga", true)
			title.textureCenter:SetHeight(titleSize)
	--		title.textureCenter:SetWidth(30)
			title.textureCenter:SetPoint("LEFT",titleSize*2,0)
			title.textureCenter:SetPoint("RIGHT",-titleSize*2,0)
			title.textureCenter:SetTexCoord(0.0, 1.0, 0.0, 1.0)


			title:SetPoint("BOTTOM",frame,"TOP",0,0)

			title:EnableMouse(true)

			title:Hide()


--			title:SetFrameStrata("DIALOG")

			title:SetScript("OnDoubleClick", function(self, button)
				if button == "LeftButton" then
					PlaySound("igMainMenuOptionCheckBoxOn")
					if frame:IsVisible() then
						frame:Hide()
					else
						frame:Show()
					end
				end
			end)

			title:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then
					frame:StartMoving()
				else
					local x, y = GetCursorPosition()
					local uiScale = UIParent:GetEffectiveScale()

					EasyMenu(windowMenu, windowMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
				end
			end)
			title:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
			title:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)



			local text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			text:SetJustifyH("CENTER")
			text:SetPoint("CENTER",0,0)
			text:SetTextColor(1,1,.4)
			text:SetText(windowTitle)

			title:SetWidth(text:GetStringWidth()+titleSize*4)


			local w = title.textureCenter:GetWidth()
			local h = title.textureCenter:GetHeight()
			title.textureCenter:SetTexCoord(0.0, (w/h), 0.0, 1.0)


			title:SetToplevel(true)

			frame.title = title
		end

		frame:SetToplevel(true)

--[[
		local x = frame:CreateTexture(nil,"ARTWORK")

		x:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		x:SetTexture("Interface/DialogFrame/UI-DialogBox-Corner")
		x:SetWidth(32)
		x:SetHeight(32)
]]

		local closeButton = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
		closeButton:SetPoint("TOPRIGHT",6,6)
		closeButton:SetScript("OnClick", function() frame:Hide() if frame.title then frame.title:Hide() end end)
		closeButton:SetFrameLevel(closeButton:GetFrameLevel()+1)
		closeButton:SetHitRectInsets(8,8,8,8)

		return frame
	end

	GnomeWorks.Window = Window
end
