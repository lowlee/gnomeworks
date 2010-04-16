

--[[
	revised api:
		Create(frame, rowHeight) 		-- returns a blank st that fills the frame and defines the base rowHeight value

		Refresh()							-- redraws table

		DrawRow(rowIndex)					-- draws the entire row (0=header row?)			to be hooked
		CreateRow(rowIndex)				-- handles creation of new row (0=header row?)	to be hooked

		SetRowCompare()					-- sets the compare function for the sort
		SetRowFilter()					-- sets the filter function for filtering

		SetData()							-- sets the data entry point
		SortData()							-- sorts the data table

		row have events if cell doesn't intercept


	support api for column handling:
		InsertColumn(desc, [index])		-- adds a column with the desc table provided (at end if no index is provided)
											-- need to figure out how to provide a map to manage order
											-- returns columnKey for reference to this column for data retrieval?

		DeleteColumn(columnKey)
		HideColumn(columnKey)
		ShowColumn(columnKey)
		ResizeColumn(columnKey)

		CreateColumn

]]


local libScrollKit = {}

do
	local serial = 0

	local lib = libScrollKit


	local function InitColumns(scrollFrame, rowFrame)
		-- user function
	end


	local function DrawColumns(scrollFrame, rowFrame, rowData)
		-- user function
	end


	local function IsEntryFiltered(scrollFrame)
		return false
	end


	local function RowFrameOnEnter(rowFrame)
		local scrollFrame = rowFrame.scrollFrame
		scrollFrame.mouseOverIndex = rowFrame.rowIndex
		if scrollFrame.DrawRowHighlight then
			scrollFrame:DrawRowHighlight(rowFrame)
		end
	end

	local function RowFrameOnLeave(rowFrame)
		local scrollFrame = rowFrame.scrollFrame
		scrollFrame.mouseOverIndex = nil
		if scrollFrame.DrawRowHighlight then
			scrollFrame:DrawRowHighlight(rowFrame)
		end
	end

	local function RowFrameOnClick(rowFrame, ...)
	end


	local function InitRow(scrollFrame, rowIndex)
		if not scrollFrame.rowFrame[rowIndex] then
			local parent = (rowIndex == 0 and scrollFrame) or scrollFrame.scrollChild

			scrollFrame.rowFrame[rowIndex] = CreateFrame("Frame",nil,parent)

			rowFrame = scrollFrame.rowFrame[rowIndex]

			rowFrame:SetPoint("TOPLEFT",scrollFrame,"TOPLEFT",0,-(rowIndex-1)*scrollFrame.rowHeight)
			rowFrame:SetPoint("BOTTOMRIGHT",scrollFrame,"TOPRIGHT",0,-(rowIndex)*scrollFrame.rowHeight)

			rowFrame:SetFrameLevel(rowFrame:GetFrameLevel()+10)

			rowFrame.rowIndex = rowIndex

			rowFrame.highlight = rowFrame:CreateTexture(nil, "OVERLAY")
			rowFrame.highlight:SetTexture(1,1,1,1)
			rowFrame.highlight:SetAllPoints(rowFrame)

			if rowIndex == 0 then
				rowFrame.highlight:Hide()
			end

			rowFrame.highlight:SetVertexColor(.5,.5,.5, .15)

			scrollFrame:InitColumns(rowFrame)

			rowFrame.scrollFrame = scrollFrame

			rowFrame.OnClick = RowFrameOnClick
			rowFrame.OnEnter = RowFrameOnEnter
			rowFrame.OnLeave = RowFrameOnLeave
		end

		return scrollFrame.rowFrame[rowIndex]
	end

	local function DrawRow(scrollFrame, rowIndex)
		if scrollFrame.InitRow then
			local rowFrame = scrollFrame.rowFrame[rowIndex] or scrollFrame:InitRow(rowIndex)

			rowFrame:Show()

			rowIndex = rowIndex + scrollFrame.scrollOffset

			if rowIndex <= scrollFrame.numData then
				if scrollFrame.DrawRowHighlight then
					scrollFrame:DrawRowHighlight(rowFrame, scrollFrame.dataMap[rowIndex])
				end

				scrollFrame:DrawColumns(rowFrame, scrollFrame.dataMap[rowIndex])
			else
				rowFrame:Hide()
			end
		end
	end


	local function Draw(scrollFrame)
		local DrawRow = scrollFrame.DrawRow

		scrollFrame.numRows = math.floor(scrollFrame:GetHeight()/scrollFrame.rowHeight)

		if scrollFrame.numRows < scrollFrame.numData then
			local maxValue = math.floor(scrollFrame.numData * scrollFrame.rowHeight - scrollFrame:GetHeight()+.5)

			scrollFrame.scrollBar:Show()
			scrollFrame:SetPoint("RIGHT",scrollFrame:GetParent(),-18,0)
			scrollFrame.scrollBar:SetMinMaxValues(0, maxValue)
			scrollFrame.scrollBar:SetValueStep(1) --scrollFrame.rowHeight)

			local scrollUpButton = scrollFrame.scrollUpButton
			local scrollDownButton = scrollFrame.scrollDownButton

			-- Arrow button handling

			if ( scrollFrame.scrollBar:GetValue() == 0 ) then
				scrollUpButton:Disable();
			else
				scrollUpButton:Enable();
			end
			if ((scrollFrame.scrollBar:GetValue() - maxValue) == 0) then
				scrollDownButton:Disable();
			else
				scrollDownButton:Enable();
			end

		else
			scrollFrame:SetPoint("RIGHT",scrollFrame:GetParent(),0,0)
			scrollFrame.scrollBar:Hide()
		end

		if DrawRow then
			for i=0,scrollFrame.numRows+2 do
				DrawRow(scrollFrame, i)
			end

			if scrollFrame.numRows+2 < #scrollFrame.rowFrame then
				for i=scrollFrame.numRows+2,#scrollFrame.rowFrame do
					scrollFrame.rowFrame[i]:Hide()
				end
			end
		end
	end


	local function SortCompare(scrollFrame, a,b)
		if a<b then
			return true
		else
			return false
		end
	end


	local function SortData(scrollFrame, data)
		if data and data.entries then
			for i=1,#data.entries do
				local entry = data.entries[i]

				if entry.subGroup then
					SortData(scrollFrame, entry.subGroup)
				end
			end

			table.sort(data, function(a,b) scrollFrame:SortCompare(a,b) end)
		end
	end


	local function FilterData(scrollFrame, data, depth, map, index)
		local num = 0

		if data and data.entries and map then
			for i=1,#data.entries do
				local entry = data.entries[i]
				entry.depth = depth

				if entry.subGroup then
					map[num+index] = entry

					num = num +1

					if entry.subGroup.expanded then
						num = num + FilterData(scrollFrame, entry.subGroup, depth+1, map, num+index)
					end
				else
					if not scrollFrame:IsEntryFiltered(entry) then
						map[num+index] = entry

						num = num + 1
					end
				end
			end
		end

		return num
	end



	local function UpdateData(scrollFrame, data, depth)
		if data and data.entries then
			for i=1,#data.entries do
				local entry = data.entries[i]
				entry.depth = depth

				if entry.subGroup then
					scrollFrame:UpdateRowData(entry)

					if entry.subGroup.expanded then
						UpdateData(scrollFrame, entry.subGroup, depth+1)
					end
				else
					if not scrollFrame:IsEntryFiltered(entry) then
						scrollFrame:UpdateRowData(entry)
					end
				end
			end
		end

		return num
	end

	local function Refresh(scrollFrame)
		if scrollFrame.UpdateRowData then
			scrollFrame:UpdateData(scrollFrame.data, 0)
		end

		scrollFrame:SortData(scrollFrame.data)
		scrollFrame.numData = scrollFrame:FilterData(scrollFrame.data, 0, scrollFrame.dataMap, 1)
		scrollFrame:Draw()
	end


	local function OnEnter(frame)
		if frame.OnEnter then
			if frame:OnEnter() then
				return
			end
		end

		local rowFrame = frame:GetParent()

		rowFrame:OnEnter()
	end

	local function OnLeave(frame)
		if frame.OnLeave then
			if frame:OnLeave() then
				return
			end
		end

		local rowFrame = frame:GetParent()

		rowFrame:OnLeave()
	end

	local function OnClick(frame, ...)
		if frame.OnClick then
			if frame:OnClick(...) then
				return
			end
		end

		local rowFrame = frame:GetParent()

		rowFrame:OnClick(...)
	end


	local function SetHandlerScripts(scrollFrame, cellFrame)
		cellFrame:SetScript("OnClick", scrollFrame.OnClick)
		cellFrame:SetScript("OnEnter", scrollFrame.OnEnter)
		cellFrame:SetScript("OnLeave", scrollFrame.OnLeave)
	end


	function lib:Create(frame, rowHeight, recycle)
		local sf

		if recycle and recycle.scrollChild then
			sf = recycle
		else
			serial = serial + 1

			sf = CreateFrame("ScrollFrame", "ScrollFrame"..serial, frame, "UIPanelScrollFrameTemplate")

			sf.scrollChild = CreateFrame("Frame", nil, sf)


			sf:SetScrollChild(sf.scrollChild)


			sf:SetScript("OnScrollRangeChanged", nil)

			local frameName = sf:GetName()
			sf.scrollUpButton = _G[ frameName.."ScrollBarScrollUpButton" ];
			sf.scrollDownButton = _G[ frameName.."ScrollBarScrollDownButton" ];
		end

		sf:SetPoint("TOP")
		sf:SetPoint("LEFT")
		sf:SetPoint("RIGHT")
		sf:SetPoint("BOTTOM")

		sf.rowHeight = rowHeight
		sf.rowFrame = sf.rowFrame or {}

		sf.numRows = math.floor(frame:GetHeight()/rowHeight+1)

		sf.data = {}
		sf.dataMap = {}
		sf.numData = 0

		sf.scrollOffset = 0


		sf.Draw = Draw
		sf.DrawRow = DrawRow
		sf.InitRow = InitRow

		sf.InitColumns = InitColumns
		sf.DrawColumns = DrawColumns


		sf.UpdateData = UpdateData
		sf.FilterData = FilterData
		sf.SortData = SortData
		sf.SortCompare = SortCompare
		sf.IsEntryFiltered = IsEntryFiltered

		sf.Refresh = Refresh

		sf.SetHandlerScripts = SetHandlerScripts

		sf.OnClick = OnClick
		sf.OnEnter = OnEnter
		sf.OnLeave = OnLeave


		sf:SetScript("OnSizeChanged", Draw)



		sf:SetScript("OnVerticalScroll", function(frame, value) frame.scrollOffset = math.floor(value/frame.rowHeight+.5) sf:Draw() end)



		sf.scrollBar = _G["ScrollFrame"..serial.."ScrollBar"]

		sf.scrollBar:ClearAllPoints()
		sf.scrollBar:SetPoint("TOPRIGHT", frame, -1, -16)
		sf.scrollBar:SetPoint("BOTTOMRIGHT", frame, -1, 16)


		local scrollBarTrough = CreateFrame("Frame", nil, sf.scrollBar)
		scrollBarTrough:SetFrameLevel(scrollBarTrough:GetFrameLevel()-1)

		scrollBarTrough.background = scrollBarTrough:CreateTexture(nil,"BACKGROUND")
		scrollBarTrough.background:SetTexture(0.05,0.05,0.05,1.0)
		scrollBarTrough.background:SetWidth(16)
		scrollBarTrough.background:SetPoint("TOPRIGHT", frame, -1,-16)
		scrollBarTrough.background:SetPoint("BOTTOMRIGHT", frame, -1, 16)

		return sf
	end

	--[[ usage:
			local sf = lib:Create(parentFrame, rowHeight)

			sf.InitColumns = init function
			sf.DrawColumns = draw function

			sf:Enable()

	]]

-- function ScrollingTable:CreateST(cols, numRows, rowHeight, highlight, parent)

end



do
	local colorWhite = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 }
	local colorBlack = { ["r"] = 0.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 0.0 }
	local colorDark = { ["r"] = 1.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.0 }

	local highlightOff = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 }
	local highlightSelected = { .5,.5,.5, .5 }
	local highlightMouseOver = { .9,.9,.7, .35 }
	local highlightSelectedMouseOver = { ["r"] = 1, ["g"] = 1, ["b"] = 0.5, ["a"] = 0.5 }


	local font = "GameFontHighlightSmall"


	function GnomeWorks:CreateScrollingTable(parentFrame, backDrop, columnHeaders, onResize)
--		local rows = floor((parentFrame:GetHeight() - 15) / 15)
--		local LibScrollingTable = LibStub("ScrollingTable")

--		local st = LibScrollingTable:CreateST(columnHeaders,rows,nil,nil,parentFrame)

		local sf = libScrollKit:Create(parentFrame, 15)

		sf.columnHeaders = columnHeaders
		sf.columnWidth = {}
		sf.headerWidth = 0

		sf.columnFrames = {}

		for i=1,#columnHeaders do
			sf.columnWidth[i] = sf.columnHeaders[i].width

			local c = CreateFrame("Frame",nil,sf)

			c:SetPoint("TOP")
			c:SetPoint("BOTTOM")
			c:SetPoint("LEFT", sf, "LEFT", sf.headerWidth, 0)
			c:SetPoint("RIGHT", sf, "LEFT", sf.headerWidth + sf.columnWidth[i],0)

			c:SetFrameLevel(c:GetFrameLevel()-1)

			self.Window:SetBetterBackdrop(c,backDrop)



			sf.columnFrames[i] = c


			sf.headerWidth = sf.headerWidth + sf.columnHeaders[i].width
		end


		sf.InitColumns = function(scrollFrame, rowFrame)
			local width = rowFrame:GetWidth()
			local cols = rowFrame.cols
			local x = 0

			if not cols then
				local rowHeight = scrollFrame.rowHeight
				local header = scrollFrame.columnHeaders

				rowFrame.cols = {}

				for i=1,#scrollFrame.columnHeaders do
					local c = CreateFrame("Button", nil, rowFrame)

					c:EnableMouse(true)
					c:RegisterForClicks("AnyUp")

					c:SetHeight(rowHeight)
					c:SetPoint("LEFT",scrollFrame.columnFrames[i])
					c:SetPoint("RIGHT",scrollFrame.columnFrames[i])
					c:SetPoint("TOP",rowFrame)

					if rowFrame.rowIndex == 0 then
						c.text = c:CreateFontString(nil, "OVERLAY", font)
					else
						c.text = c:CreateFontString(nil, "OVERLAY", header[i].font or font)
					end
					c.text:SetPoint("TOP",c)
					c.text:SetPoint("BOTTOM",c)
					c.text:SetPoint("LEFT", c)
					c.text:SetPoint("RIGHT", c)
					c.text:SetJustifyH(header[i].align or "LEFT")

					scrollFrame:SetHandlerScripts(c)

					c.OnClick = header[i].OnClick
					c.OnEnter = header[i].OnEnter
					c.OnLeave = header[i].OnLeave

					rowFrame.cols[i] = c
				end
			end
		end


		sf.DrawRowHighlight = function(scrollFrame, rowFrame, entry)

			if rowFrame.rowIndex == 0 then
				return
			end

			entry = entry or rowFrame.data

			if scrollFrame.mouseOverIndex == rowFrame.rowIndex then
				rowFrame.highlight:SetVertexColor(unpack(highlightMouseOver))
			elseif entry and entry.skillIndex == GnomeWorks.selectedSkill then
				rowFrame.highlight:SetVertexColor(unpack(highlightSelected))
			else
				if math.floor(rowFrame.rowIndex/2)*2 == rowFrame.rowIndex then
					rowFrame.highlight:SetVertexColor(.5,.5,.5,.03)
--					rowFrame.highlight:Show()
				else
					rowFrame.highlight:SetVertexColor(0,0,0,0)
--					rowFrame.highlight:Show()
				end
			end
		end


		sf.DrawColumns = function(scrollFrame, rowFrame, rowData)
			scrollFrame:InitColumns(rowFrame)
			local headers = scrollFrame.columnHeaders

			rowFrame.data = rowData

			for i=1,#rowFrame.cols do
				if rowFrame.rowIndex == 0 then
					rowFrame.cols[i].text:SetText(headers[i].name)
				else
					if headers[i].draw and rowData then
						headers[i].draw(rowFrame,rowFrame.cols[i],rowData)
					else
						rowFrame.cols[i].text:SetText((rowData and rowData[headers[i].dataField]) or "")
					end
				end
			end
		end



		sf:SetScript("OnSizeChanged", function(frame,...) onResize(frame,...) frame:Draw() end)


		sf:Refresh()

--[[

		local function AdjustColumnWidths()
			for i=1,#st.cols do
				local col = st.head.cols[i]

				if i==1 or i==#st.cols then
					col.frame:SetWidth(columnHeaders[i].width-1)
				else
					col.frame:SetWidth(columnHeaders[i].width-2)
				end
			end
		end

		st.frame:SetPoint("BOTTOMLEFT", 0, 0)
		st.frame:SetPoint("TOPRIGHT",  0,0)

		st.LibraryRefresh = st.Refresh
		st.frame:SetBackdrop(nil)


		st.selectedRows = {}

		for i=1,#st.cols do
			local col = st.head.cols[i]

			col.frame = CreateFrame("Frame", nil, st.frame)
			self.Window:SetBetterBackdrop(col.frame,backDrop)
			col.frame:SetPoint("TOP", st.frame, "TOP", 0,0)
			col.frame:SetPoint("BOTTOM", st.frame, "BOTTOM", 0,0)

			if i > 1 then
				col.frame:SetPoint("LEFT", st.head.cols[i-1].frame, "RIGHT", 2, 0)
			else
				col.frame:SetPoint("LEFT", st.frame, "LEFT", 0, 0)
			end

			if i==1 or i==#st.cols then
				col.frame:SetWidth(columnHeaders[i].width-1)
			else
				col.frame:SetWidth(columnHeaders[i].width-2)
			end

--			col:SetPoint("LEFT",(columnHeaders[i].width-3))
		end


		parentFrame.doResize = function()
			onResize(parentFrame)
			AdjustColumnWidths()
		end


		parentFrame:SetScript("OnShow", parentFrame.doResize)
		parentFrame:SetScript("OnSizeChanged", parentFrame.doResize)


		st.scrollframe:SetScript("OnHide", nil)
		st.scrollframe:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, -2)
		st.scrollframe:SetPoint("BOTTOMRIGHT", st.frame, "BOTTOMRIGHT", -20, 2)


		local scrolltrough = getglobal(st.frame:GetName().."ScrollTrough")
		scrolltrough:SetWidth(17)
		scrolltrough:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", 2, -1);
		scrolltrough:SetPoint("BOTTOMRIGHT", st.frame, "BOTTOMRIGHT", 2, 2);

		st.scrollframe:SetFrameLevel(st.scrollframe:GetFrameLevel()+10)


		st.scrollframe:SetScript("OnShow", parentFrame.doResize)
		st.scrollframe:SetScript("OnHide", parentFrame.doResize)


		st.rows[1]:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, -1);
		st.rows[1]:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", -1, -1);


		st.head:SetPoint("BOTTOMLEFT", st.frame, "TOPLEFT", 2, 2);
		st.head:SetPoint("BOTTOMRIGHT", st.frame, "TOPRIGHT", 0, 2);


		st.data = {}


		st.Refresh = function(st)
			st:LibraryRefresh()

			for i=1,st.displayRows do
				local row = i+(st.offset or 0)

				local filteredRow = st.filtered[row]

				if filteredRow and st.data[filteredRow] then
					if st.selectedRows[st.data[filteredRow].selectKey] then
						if i ~= st.mouseOverRow then
							st:SetHighLightColor(st.rows[i],highlightSelected)
						else
							st:SetHighLightColor(st.rows[i],highlightSelectedMouseOver)
						end
					else
						if i ~= st.mouseOverRow then
							st:SetHighLightColor(st.rows[i],highlightOff)
						else
							st:SetHighLightColor(st.rows[i],st:GetDefaultHighlight())
						end
					end
				end
			end
		end

		st:RegisterEvents({
			["OnEvent"] =  function (rowFrame, cellFrame, data, cols, row, realrow, column, st, event, arg1, arg2, ...)
--	DEFAULT_CHAT_FRAME:AddMessage("EVENT "..tostring(event))
				if event == "MODIFIER_STATE_CHANGED" then
					if arg1 == "LCTRL" or arg1 == "RCTRL" then
						frame.keyCapture:EnableKeyboard(arg2==1)
					end
				end
			end,
			["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, ...)
--				frame.keyCapture:EnableKeyboard(true)
--DEFAULT_CHAT_FRAME:AddMessage("onEnter start")
				if row then
--DEFAULT_CHAT_FRAME:AddMessage("row "..row.." realrow "..realrow.." filtered row "..st.filtered[row].." filter row + offet "..st.filtered[row+st.offset])

					cellFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

					if realrow then -- and st.selectedRows[data[realrow].selectKey or 0] then
						st:SetHighLightColor(rowFrame,highlightSelectedMouseOver)
					else
						st:SetHighLightColor(rowFrame,st:GetDefaultHighlight())
					end

					st.mouseOverRow = row

					local cellData = data[realrow].cols[column]

					if st.fencePicking then
						for i=1,#data do
							st.selectedRows[data[i].selectKey] = false
						end

						local rowStart, rowEnd = st.fencePickStart, row + st.offset

						if rowStart > rowEnd then
							rowStart, rowEnd = rowEnd, rowStart
						end

						for i=rowStart, rowEnd do
							local r = st.filtered[i]
							st.selectedRows[data[r].selectKey] = true
						end

						st:Refresh()
					else

					end
				else
					GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")

					GameTooltip:ClearLines()

					local value = columnHeaders[column].name

					local r,g,b = 1,1,1

					GameTooltip:AddLine(value,r,g,b,true)
					GameTooltip:AddLine(columnHeaders[column].tooltipText,.7,.7,.7)

					GameTooltip:Show()
				end

				return true
--DEFAULT_CHAT_FRAME:AddMessage("onEnter end")
			end,
			["OnMouseDown"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
				if row  then
					if button == "LeftButton" then
						st.fencePicking = true
						st.fencePickStart = row + st.offset
						local r = st.filtered[st.fencePickStart]

						for i=1,#data do
							st.selectedRows[data[i].selectKey] = false
						end

						st.selectedRows[data[r].selectKey] = true

						st:Refresh()
					end
				end
			end,
			["OnMouseUp"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
				if row  then
					if button == "LeftButton" then
						st.fencePicking = false
					end
				end
			end,
			["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, ...)
--DEFAULT_CHAT_FRAME:AddMessage("onLeave start")
--				frame.keyCapture:EnableKeyboard(false)
				cellFrame:UnregisterEvent("MODIFIER_STATE_CHANGED")

				if row  then
					if realrow and st.selectedRows[data[realrow].selectKey or 0] then
						st:SetHighLightColor(rowFrame,highlightSelected)
					else
						st:SetHighLightColor(rowFrame,highlightOff)
					end

					if st.mouseOverRow == row then
						st.mouseOverRow = nil
					end

					GameTooltip:Hide()

					st:Refresh()
				else
					GameTooltip:Hide()
				end

				return true
--DEFAULT_CHAT_FRAME:AddMessage("onLeave end")
			end,
			["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
				if row then
					if button == "LeftButton" then
						if realrow == st.lastSelection then
							if not IsShiftKeyDown() then
								for i=1,#data do
									st.selectedRows[data[i].selectKey] = false
								end
							end

							st.selectedRows[data[realrow].selectKey] = true

							st:Refresh()
						end

							st.lastSelection = realrow

							local cellData = data[realrow].cols[column]

							if cellData.onclick then
								cellData.onclick(rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
							else
								if cols[column].onclick then
									cols[column].onclick(rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
								end
							end

					end
				else
					if button == "LeftButton" then


						local sortorder = "asc";
						if not cols[column].sort and cols[column].defaultsort then
							sortorder = cols[column].defaultsort; -- sort by columns default sort first;
						elseif cols[column].sort and cols[column].sort:lower() == "asc" then
							sortorder = "dsc";
						end
						cols[column].sort = sortorder;

						st:SortData(column, sortorder)
					else
						if columnHeaders[column].rightclick then
							columnHeaders[column].rightclick()
						end
					end
				end

				return true
			end,
			["OnDoubleClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
				if row then
					local cellData = data[realrow].cols[column]

					if cellData.onclick then
						cellData.onclick(rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
					else
						if cols[column].onclick then
							cols[column].onclick(rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
						end
					end
				end
			end,
		})





		local DoFilter = function(self)
			local result = {}
			local maxRow = #self.data

			if self.maxRows and self.maxRows < #self.data then
				maxRow = self.maxRows
			end

			for row = 1, maxRow do
				if self:Filter(self.data[row]) then
					table.insert(result, row)
				end
			end
			return result
		end

		st.DoFilter = DoFilter


		local CompareSortGeneric = function (self, rowa, rowb, sortbycol)
			if self.data[rowa].parent == self.data[rowb].parent then
				local cella, cellb = self.data[rowa].cols[sortbycol], self.data[rowb].cols[sortbycol];
				local a1, b1 = cella.value, cellb.value;
				local column = self.cols[sortbycol];

				if type(a1) == "function" then
					a1 = a1(unpack(cella.args or {self.data, self.cols, rowa, sortbycol, self}));
				end
				if type(b1) == "function" then
					b1 = b1(unpack(cellb.args or {self.data, self.cols, rowb, sortbycol, self}));
				end

				if type(a1) ~= type(b1) then
					local typea, typeb = type(a1), type(b1);
					if typea == "number" and typeb == "string" then
						if tonumber(typeb) then -- is it a number in a string?
							b1 = StringToNumber(b1); -- "" = 0
						else
							a1 = tostring(a1);
						end
					elseif typea == "string" and typeb == "number" then
						if tonumber(typea) then -- is it a number in a string?
							a1 = StringToNumber(a1); -- "" = 0
						else
							b1 = tostring(b1);
						end
					end
				end

				if a1 == b1 and column.sortnext and (not(self.cols[column.sortnext].sort)) then
					local nextcol = self.cols[column.sortnext];
					if nextcol.comparesort then
						return nextcol.comparesort(self, rowa, rowb, column.sortnext);
					else
						return self:CompareSort(rowa, rowb, column.sortnext);
					end
				else
					local direction = column.sort or column.defaultsort or "asc";
					if direction:lower() == "asc" then
						return a1 > b1;
					else
						return a1 < b1;
					end
				end
			else
				local column = self.cols[sortbycol];
				local direction = column.sort or column.defaultsort or "asc";

				if direction:lower() == "asc" then
					return self.data[rowa].parent.skillIndex < self.data[rowb].parent.skillIndex
				else
					return self.data[rowa].parent.skillIndex > self.data[rowb].parent.skillIndex
				end
			end
		end


		local CompareSort = function (self, rowa, rowb, sortbycol)
--print(rowa.."="..tostring(self.data[rowa].parent).." "..rowb.."="..tostring(self.data[rowb].parent))
			if self.data[rowa].parent == self.data[rowb].parent then
				local cella, cellb = self.data[rowa].cols[sortbycol], self.data[rowb].cols[sortbycol];
				local a1, b1 = cella.value, cellb.value;
				local column = self.cols[sortbycol];

				return a1 > b1
			else
				if self.data[rowa].parent.skillIndex == self.data[rowb].skillIndex then
print(rowa.." "..rowb)
					return true
				else
					if self.data[rowb].parent.skillIndex == self.data[rowa].skillIndex then
					print(rowa.." "..rowb)
						return false
					end
				end

				return self.data[rowa].parent.skillIndex > self.data[rowb].parent.skillIndex
			end
		end

		st.CompareSort = CompareSort


		local SortData = function(self, sortColumn, order)


			st.filtered = self:DoFilter()

			if sortColumn then
				local col = st.cols[sortColumn]

				if order=="asc" then
					if col.comparesort then
						table.sort(st.filtered, function(a,b)
							return col.comparesort(st,a,b,sortColumn)
						end)
					else
						table.sort(st.filtered, function(a,b)
							return st:CompareSort(a,b,sortColumn)
						end)
					end
				else
					if col.comparesort then
						table.sort(st.filtered, function(b,a)
							return col.comparesort(st,a,b,sortColumn)
						end)
					else
						table.sort(st.filtered, function(b,a)
							return st:CompareSort(a,b,sortColumn)
						end)
					end
				end
			end

			self:Refresh()
		end

		st.SortData = SortData

		return st
]]

		return sf
	end


end
