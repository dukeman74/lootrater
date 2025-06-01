----------------------------------------------------------------
-- Global Variables
----------------------------------------------------------------

ItemProperties = {}

ItemProperties.DETAIL_SHORT = 1
ItemProperties.DETAIL_LONG = 2

ItemProperties.CurrentItemData = {}

ItemProperties.TITLE_COLOR = { r=243, g=227, b=49 }
ItemProperties.BODY_COLOR = { r=255, g=255, b=255 }

ItemProperties.VirtueData = {}
ItemProperties.VirtueData[1]	= { iconId = 701, nameTid = 1051005, detailTid=1052058 } -- Honor
ItemProperties.VirtueData[2]	= { iconId = 706, nameTid = 1051001, detailTid=1052053 } -- Sacrifice
ItemProperties.VirtueData[3]	= { iconId = 700, nameTid = 1051004, detailTid=1052057 } -- Valor
ItemProperties.VirtueData[4]	= { iconId = 702, nameTid = 1051002, detailTid=1053000 } -- Compassion
ItemProperties.VirtueData[5]	= { iconId = 704, nameTid = 1051007, detailTid=1052060 } -- Honesty
ItemProperties.VirtueData[6]	= { iconId = 707, nameTid = 1051000, detailTid=1052051 } -- Humility
ItemProperties.VirtueData[7]	= { iconId = 703, nameTid = 1051006, detailTid=1052059 } -- Justice
ItemProperties.VirtueData[8]	= { iconId = 705, nameTid = 1051003, detailTid=1052056 } -- Spirituality

---------------------------------------------------------------
-- MainMenuWindow Functions
----------------------------------------------------------------

-- OnInitialize Handler
function ItemProperties.Initialize()
	WindowSetAlpha("ItemPropertiesWindowBackground", 0.8)
	
	WindowData.ItemProperties.numLabels = 0
	
	RegisterWindowData(WindowData.ItemProperties.Type, 0)
	WindowRegisterEventHandler( "ItemProperties", SystemData.Events.UPDATE_ITEM_PROPERTIES, "ItemProperties.UpdateItemPropertiesData")
end

function ItemProperties.Shutdown()
	UnregisterWindowData(WindowData.ItemProperties.Type, 0)
end

function ItemProperties.UpdateItemPropertiesData()
	if WindowData.ItemProperties.CurrentHover == 0 then
		return
	end

	--Debug.Print("UpdateItemPropertiesData Enter")

	local this = WindowUtils.GetActiveDialog()
	local id = WindowData.ItemProperties.CurrentHover
	local labelText = {}
	local labelColors = {}
	local numLabels = 0
	
	-- update the item type incase it has changed from code
	ItemProperties.CurrentItemData.itemType = WindowData.ItemProperties.CurrentType
	
	ItemProperties.HideAllPropsLabels()
	--ebm - this is the real list of item properties:
	if( ItemProperties.CurrentItemData.itemType == WindowData.ItemProperties.TYPE_ITEM ) then
		-- use instance id 0 for the current item properties object
		data = WindowData.ItemProperties[0]
		--Debug.Print(data)
		if data and data.PropertiesList then
			propList = data.PropertiesList
			propLen = table.getn(propList)			
			colorList = data.ColorList
			colorLen = table.getn(colorList)
			local score = ItemProperties.score(data)
			if score.print~="NAI" then
				numLabels = numLabels + 1
				labelText[numLabels] = towstring(score.print)
				if score.take then
					labelColors[numLabels] = {r=12,g=200,b=10}
				else
					labelColors[numLabels] = {r=200,g=8,b=10}
				end
			end
			for i = 1, propLen do
				if( i==1 ) then 
					numLabels = numLabels + 1
					-- DAB TODO: Show bold strings, for now just rip out the tag
					-- Debug.Print(propList[i])
					labelText[numLabels] = WindowUtils.translateMarkup(propList[i])

					if(id == Interface.CurrentHonor )then
						labelColors[numLabels] = {r=163, g=73, b=164}
					elseif ( (WindowData.ItemProperties.CustomColorTitle) and (WindowData.ItemProperties.CustomColorTitle.Enable) and (i == WindowData.ItemProperties.CustomColorTitle.LabelIndex) and (WindowData.ItemProperties.CustomColorTitle.NotorietyEnable) ) then
						labelColors[numLabels] = NameColor.TextColors[WindowData.ItemProperties.CustomColorTitle.NotorietyIndex+1]						
					else
						labelColors[numLabels] = ItemProperties.TITLE_COLOR
					end
				elseif( ItemProperties.CurrentItemData.detail == nil or ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
					numLabels = numLabels + 1
					-- DAB TODO: Show bold strings, for now just rip out the tag
					labelText[numLabels] = WindowUtils.translateMarkup(propList[i])
					
					if WindowData.ItemProperties.CustomColorBody and WindowData.ItemProperties.CustomColorBody.Enable and i == WindowData.ItemProperties.CustomColorBody.LabelIndex then
						labelColors[numLabels] = WindowData.ItemProperties.CustomColorBody.Color
					elseif WindowData.ItemProperties.CustomColorBody2 and WindowData.ItemProperties.CustomColorBody2.Enable and i == WindowData.ItemProperties.CustomColorBody2.LabelIndex then
						labelColors[numLabels] = WindowData.ItemProperties.CustomColorBody2.Color
					else
						local colorIdx = (numLabels * 4) - 3
						labelColors[numLabels] = { r=colorList[colorIdx+1], g=colorList[colorIdx+2], b=colorList[colorIdx+3]}
					end
				end 
			end
		end	
	elseif( ItemProperties.CurrentItemData.itemType == WindowData.ItemProperties.TYPE_ACTION ) then
		-- first get its location if it has one and set the subindex to 0 by default
		local itemLoc = ItemProperties.CurrentItemData.itemLoc
		if( itemLoc ~= nil and itemLoc.subIndex == nil ) then
			itemLoc.subIndex = 0
		end
		
		if( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_SKILL ) then
			-- NOTE: Need to fix this. Id 0 is also a null check, so no tooltip for Alchemy
			local skillId = id - 1
			
			-- translate the server id into a row into the ability csv
			local abilityId = CSVUtilities.getRowIdWithColumnValue(WindowData.SkillsCSV, "ServerId", skillId)

			numLabels = numLabels + 1
			labelText[numLabels] = GetStringFromTid(WindowData.SkillsCSV[abilityId].NameTid)
			labelColors[numLabels] = ItemProperties.TITLE_COLOR
			
			local detailTid = WindowData.SkillsCSV[abilityId].DescriptionTid
			if( detailTid ~= nil and ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(detailTid)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			end
		elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_SPELL ) then
			local icon, serverId, tid, desctid = GetAbilityData(id)

			if( desctid ~= nil and ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
				if( tid ~= nil ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(tid)
					labelColors[numLabels] = ItemProperties.TITLE_COLOR		
				end				
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(desctid)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			elseif( tid ~= nil ) then
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(tid)
				labelColors[numLabels] = ItemProperties.TITLE_COLOR		
			end		
			
			if(ItemProperties.CurrentItemData.body ~= nil and ItemProperties.CurrentItemData.body ~= L"") then
				numLabels = numLabels + 1
				labelText[numLabels] = WindowUtils.translateMarkup(ItemProperties.CurrentItemData.body)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			end
		elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_INVOKE_VIRTUE ) then
			local nameTid = ItemProperties.VirtueData[id].nameTid
			local detailTid = ItemProperties.VirtueData[id].detailTid
			if( nameTid ~= nil and nameTid ~= 0 ) then
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(nameTid)	
				labelColors[numLabels] = ItemProperties.TITLE_COLOR
			end
			if( detailTid ~= nil and detailTid ~= 0 ) then
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(detailTid)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			end
		elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_WEAPON_ABILITY ) then
			if( EquipmentData.CurrentWeaponAbilities[id] ~= nil and EquipmentData.CurrentWeaponAbilities[id] ~= 0 ) then
				local abilityId = EquipmentData.CurrentWeaponAbilities[id] + EquipmentData.WEAPONABILITY_ABILITYOFFSET
				local icon, serverId, tid, desctid = GetAbilityData(abilityId)
				
				-- Always show the ability name
				if( tid ~= nil ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(tid)
					labelColors[numLabels] = ItemProperties.TITLE_COLOR
				end

				if( desctid ~= nil and ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(desctid)	
					labelColors[numLabels] = ItemProperties.BODY_COLOR			
				end
			end
		elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_RACIAL_ABILITY ) then
			-- NOTE: Need to fix this. Hotbar slot loses ability id because of racial ability id conversion.
			local iconId = UserActionGetIconId(itemLoc.hotbarId, itemLoc.itemIndex, itemLoc.subIndex)
			local icon, serverId, tid, desctid = GetAbilityData(iconId)

			if( desctid ~= nil and ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
				if( tid ~= nil ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(tid)
					labelColors[numLabels] = ItemProperties.TITLE_COLOR		
				end				
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(desctid)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			elseif( tid ~= nil ) then
				numLabels = numLabels + 1
				labelText[numLabels] = GetStringFromTid(tid)
				labelColors[numLabels] = ItemProperties.TITLE_COLOR		
			end		
			
			if(ItemProperties.CurrentItemData.body ~= nil and ItemProperties.CurrentItemData.body ~= L"") then
				numLabels = numLabels + 1
				labelText[numLabels] = WindowUtils.translateMarkup(ItemProperties.CurrentItemData.body)
				labelColors[numLabels] = ItemProperties.BODY_COLOR	
			end
		elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_USE_OBJECTTYPE) then
			RegisterWindowData(WindowData.ObjectTypeQuantity.Type, ItemProperties.CurrentItemData.itemId)
			item = WindowData.ObjectTypeQuantity[ItemProperties.CurrentItemData.itemId]
			if( item ~= nil ) then
				if( item.name ~= nil ) then
					numLabels = numLabels + 1
					local itemName = Shopkeeper.stripFirstNumber(item.name)
				    labelText[numLabels] = item.quantity..L" "..itemName
				    labelColors[numLabels] = ItemProperties.TITLE_COLOR	
				end				
			end			
			UnregisterWindowData(WindowData.ObjectTypeQuantity.Type, ItemProperties.CurrentItemData.itemId)		
		elseif(ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_PLAYER_STATS) then
			--If the user action is TYPE_PLAYER_STATS just show the tid of the stats ex: strength, dexterity
				tid = WindowData.PlayerStatsDataCSV[id].tid
				detailTid = WindowData.PlayerStatsDataCSV[id].detailTid
				-- Always show the ability name
				if( tid ~= nil ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(tid)
					labelColors[numLabels] = ItemProperties.TITLE_COLOR
				end
				if( detailTid ~= nil and detailTid ~= 0 and ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
					numLabels = numLabels + 1
					labelText[numLabels] = GetStringFromTid(detailTid)
					labelColors[numLabels] = ItemProperties.BODY_COLOR
				end
			
		-- Blanket case for generic actions
		else
			local actionData = ActionsWindow.GetActionDataForType(ItemProperties.CurrentItemData.actionType)
			
			if( actionData ~= nil ) then
			    if( actionData.nameTid ~= nil and actionData.nameTid ~= 0 ) then
				    numLabels = numLabels + 1
				    labelText[numLabels] = GetStringFromTid(actionData.nameTid)
				    labelColors[numLabels] = ItemProperties.TITLE_COLOR	
			    end
			    if( actionData.detailTid ~= nil and actionData.detailTid ~= 0 and
						ItemProperties.CurrentItemData.detail == ItemProperties.DETAIL_LONG ) then
				    numLabels = numLabels + 1
				    labelText[numLabels] = GetStringFromTid(actionData.detailTid)
				    labelColors[numLabels] = ItemProperties.BODY_COLOR	
			    end						
			end
		end
		
		-- add aditional information if the action has a hotbar location
		if( itemLoc ~= nil ) then
			if( UserActionIsSpeechType(itemLoc.hotbarId, itemLoc.itemIndex, itemLoc.subIndex) ) then
				local speechText = UserActionSpeechGetText(itemLoc.hotbarId, itemLoc.itemIndex, itemLoc.subIndex)
				if( speechText ~= L"" ) then
					numLabels = numLabels + 1
					labelText[numLabels] = speechText
					labelColors[numLabels] = ItemProperties.BODY_COLOR
				end
			elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_DELAY ) then
				local delay = UserActionDelayGetDelay(itemLoc.hotbarId, itemLoc.itemIndex, itemLoc.subIndex)				
				numLabels = numLabels + 1
				labelText[numLabels] = wstring.format(L"%.1f",delay)
				labelColors[numLabels] = ItemProperties.BODY_COLOR				
			elseif( ItemProperties.CurrentItemData.actionType == SystemData.UserAction.TYPE_MACRO ) then
				local macroName = UserActionMacroGetName(itemLoc.hotbarId, itemLoc.itemIndex)
				if( macroName ~= L"" ) then
					numLabels = numLabels + 1
					labelText[numLabels] = macroName
					labelColors[numLabels] = ItemProperties.BODY_COLOR
				end
			end
		end
		
	elseif( ItemProperties.CurrentItemData.itemType == WindowData.ItemProperties.TYPE_WSTRINGDATA ) then
		if( ItemProperties.CurrentItemData.title ~= nil and ItemProperties.CurrentItemData.title ~= L"" ) then
			numLabels = numLabels + 1
			labelText[numLabels] = ItemProperties.CurrentItemData.title
			labelColors[numLabels] = ItemProperties.TITLE_COLOR	
		end
		if( ItemProperties.CurrentItemData.body ~= nil and ItemProperties.CurrentItemData.body ~= L"" ) then
			numLabels = numLabels + 1
			labelText[numLabels] = ItemProperties.CurrentItemData.body
			labelColors[numLabels] = ItemProperties.BODY_COLOR	
		end	
	end
	
	if( ItemProperties.CurrentItemData.binding ~= nil and ItemProperties.CurrentItemData.binding ~= L"" ) then
		numLabels = numLabels + 1
		labelText[numLabels] = ItemProperties.CurrentItemData.binding
		labelColors[numLabels] = ItemProperties.BODY_COLOR	
	end

	if( ItemProperties.CurrentItemData.myTarget ~= nil and ItemProperties.CurrentItemData.myTarget ~= L"" ) then
		numLabels = numLabels + 1
		labelText[numLabels] = ItemProperties.CurrentItemData.myTarget
		labelColors[numLabels] = ItemProperties.BODY_COLOR	
	end
			
	numLabels = table.getn(labelText)
	--ebm
	--Debug.Print("numLabels: "..numLabels)
	--ebm
	if( numLabels > 0 ) then
		ItemProperties.CreatePropsLabels(numLabels)
	
		local propWindowWidth = 100
		local propWindowHeight = 4
		
		for i = 1, numLabels do
			--Debug.Print("inside numlabel loop") -- ebm
			--Debug.Print(labelText) -- ebm
			labelName = "ItemPropertiesItemLabel"..i
			LabelSetText(labelName, labelText[i])
			LabelSetTextColor(labelName, labelColors[i].r, labelColors[i].g, labelColors[i].b)
			w, h = LabelGetTextDimensions(labelName)
			propWindowWidth = math.max(propWindowWidth, w)
			propWindowHeight = propWindowHeight + h + 3 -- Allow for spacing
			WindowSetShowing(labelName, true)
		end
	
		propWindowWidth = propWindowWidth + 12
		WindowSetDimensions("ItemProperties", propWindowWidth, propWindowHeight)

		-- Set the window position
		windowOffset = 16
		scaleFactor = 1/InterfaceCore.scale	
		
		mouseX = SystemData.MousePosition.x
		propWindowX = mouseX - windowOffset - (propWindowWidth / scaleFactor)
		if propWindowX < 0 then
			propWindowX = mouseX + windowOffset
		end
			
		mouseY = SystemData.MousePosition.y
		propWindowY = mouseY - windowOffset - (propWindowHeight / scaleFactor)
		if propWindowY < 0 then
			propWindowY = mouseY + windowOffset
		end

		WindowSetOffsetFromParent("ItemProperties", propWindowX * scaleFactor, propWindowY * scaleFactor)
		WindowSetShowing("ItemProperties",true)
	end

end

-- Values in itemdata table
--   windowName - name of base window that contains hover
--   itemId     - unique id of item
--   itemType   - WindowData.ItemProperties
--	 binding    - (default L"") shown on last line
--   detail     - (default SHORT) ItemProperties.DETAIL_SHORT
--				  ItemProperties.DETAIL_LONG 
--   actionType - (default NONE) SystemData.UserAction
--	title		- Used for item properties that have the title wstring (default L"")
--	body		- Outputs the body of your text given a wstring, goes below the title (default L"")	
function ItemProperties.SetActiveItem(itemData)
	if( itemData == nil ) then
		itemData = {}
	end
	
	-- USE_ITEM actions are the same information as item
	if( itemData.actionType == SystemData.UserAction.TYPE_USE_ITEM ) then
		itemData.itemType = WindowData.ItemProperties.TYPE_ITEM
	end

	--ebm
	--Debug.Print("ItemProperties.SetActiveItem: id="..tostring(itemData.itemId).." type="..tostring(itemData.itemType).." action="..tostring(itemData.actionType))
	--ebm

	WindowData.ItemProperties.CurrentHover = itemData.itemId
	WindowData.ItemProperties.CurrentType = itemData.itemType
	ItemProperties.CurrentItemData = itemData
end

function ItemProperties.CreatePropsLabels(numLabelsNeeded)
	-- Dynamically create a bunch of labels for the individual property lines.
	numHave = WindowData.ItemProperties.numLabels 
	
	if numHave >= numLabelsNeeded then
		return
	end

	for i = numHave + 1, numLabelsNeeded do
		labelName = "ItemPropertiesItemLabel"..i
		
		if i == 1 then
			CreateWindowFromTemplate(labelName, "ItemPropItemDef", "ItemProperties")
			WindowAddAnchor(labelName, "top", "ItemProperties", "top", 0, 3)
		else
			CreateWindowFromTemplate(labelName, "ItemPropItemDef", "ItemProperties")
			WindowAddAnchor(labelName, "bottom", "ItemPropertiesItemLabel"..i-1, "top", 0, 3)
		end
	end
	
	WindowData.ItemProperties.numLabels = numLabelsNeeded
end

function ItemProperties.HideAllPropsLabels()
	numHave = WindowData.ItemProperties.numLabels 
	
	if numHave then
		for i = 1, numHave do
			WindowSetShowing("ItemPropertiesItemLabel"..i, false)
		end
	end
end

function ItemProperties.ClearMouseOverItem()
	--Debug.Print("ItemProperties.ClearMouseOverItem")
	WindowData.ItemProperties.CurrentHover = 0
	WindowData.ItemProperties.CurrentType = WindowData.ItemProperties.TYPE_NONE
	ItemProperties.CurrentItemData = {}
end

function ItemProperties.GetCurrentWindow()
    local windowName = nil
    if( ItemProperties.CurrentItemData ~= nil ) then
        windowName = ItemProperties.CurrentItemData.windowName
    end
    
    return windowName
end

function ItemProperties.OnPlayerBackpackMouseover()
	local backpackId = WindowData.PlayerEquipmentSlot[EquipmentData.EQPOS_BACKPACK].objectId
	
	if backpackId ~= 0 then
		local itemData = {
			windowName = dialog,
			itemId = backpackId,
			itemType = WindowData.ItemProperties.TYPE_ITEM,
		}
		ItemProperties.SetActiveItem(itemData)
	end
end

function ItemProperties.GetObjectPropertiesArray( objectId, caller )
	if Interface.DebugMode and caller then
	--Debug.Print("ItemProperties.GetObjectProperties (" .. caller ..  ")")
	end
	local data
	if (objectId == 0) then
		return
	end
	
	if WindowData.ItemProperties[objectId] then
		data = WindowData.ItemProperties[objectId]
	else
		RegisterWindowData(WindowData.ItemProperties.Type, objectId)
		if WindowData.ItemProperties[objectId] then
			data = WindowData.ItemProperties[objectId]
		end
		UnregisterWindowData(WindowData.ItemProperties.Type, objectId)
	end
	return data
end

function ItemProperties.GetObjectProperties( objectId, number, caller )
	if Interface.DebugMode and caller then
	--	Debug.Print("ItemProperties.GetObjectProperties (" .. caller ..  ")")
	end
	local data = ItemProperties.GetObjectPropertiesArray( objectId, caller )
	local properties
	local property = {}
	if (objectId == 0) then
		return
	end

	if data then

		properties = data.PropertiesList
		if ( number ) and ( type( number ) == "number" ) then
			property[1] =  towstring( WindowUtils.translateMarkup(properties[number]) )
			return property[1]
		elseif ( number ) and ( number == "last" ) then
			property[1] =  towstring( WindowUtils.translateMarkup(properties[#properties]) )
			return property[1]
		else
			for i = 1, #properties do
				local value = towstring( WindowUtils.translateMarkup(properties[i]) )
				table.insert( property, value )
			end	
			return property
		end
	else
		return nil
	end	
end

function ItemProperties.GetObjectPropertiesTid( objectId, number, caller )
	if Interface.DebugMode and caller then
	--	Debug.Print("ItemProperties.GetObjectPropertiesTid (" .. caller ..  ")")
	end
	local data = ItemProperties.GetObjectPropertiesArray( objectId, caller )
	local properties
	local property = {}
	if (objectId == 0) then
		return
	end

	if data then

		properties = data.PropertiesTids
		
		if ( number ) and ( type( number ) == "number" ) then
			return properties[number]
		elseif ( number ) and ( number == "last" ) then
			return properties[#property]
		else
			for i = 1, #properties do
				table.insert( property, properties[i] )
			end	
			return property
		end
	else
		return nil
	end	
end

function ItemProperties.GetObjectPropertiesTidParams( objectId, number, caller )
	if Interface.DebugMode and caller then
	--	Debug.Print("ItemProperties.GetObjectPropertiesTid (" .. caller ..  ")")
	end
	local data = ItemProperties.GetObjectPropertiesArray( objectId, caller )
	local properties
	local property = {}
	if (objectId == 0) then
		return
	end
	
	if data then
		
		properties = data.PropertiesTidsParams
		
		local params = ItemProperties.BuildParamsArray( data )
		
		local newParams = {}
		for i = 1, #data.PropertiesTids do
			newParams[i] = params[data.PropertiesTids[i]]
		end	
		
		if ( number ) and ( type( number ) == "number" ) then
			return newParams[number]
		elseif ( number ) and ( number == "last" ) then
			return newParams[#params]
		else
			return newParams
		end
	else
		return nil
	end	
end

function ItemProperties.GetObjectPropertiesParamsForTid( objectId, tid, caller )
	if Interface.DebugMode and caller then
	--	Debug.Print("ItemProperties.GetObjectPropertiesTid (" .. caller ..  ")")
	end
	local data = ItemProperties.GetObjectPropertiesArray( objectId, caller )
	local properties
	local property = {}
	if (objectId == 0) then
		return
	end
	
	if data then
		
		local params = ItemProperties.BuildParamsArray( data )
		
		return params[tid]

	else
		return nil
	end	
end

function ItemProperties.BuildParamsArray( propertiesData )
	if not propertiesData then
		return
	end
	local params = {}
	
	local tid
	for i = 1, #propertiesData.PropertiesTidsParams do
		if wstring.find(propertiesData.PropertiesTidsParams[i], L"@") then
			tid = tostring(wstring.gsub(propertiesData.PropertiesTidsParams[i], L"@", L""))
			tid = tonumber(tid)
			if tid ~= nil then
				params[tid] = {}
			end
		else
			if tid ~= nil then
				table.insert(params[tid], propertiesData.PropertiesTidsParams[i])
			end
		end
	end

	return params
end

function ItemProperties.GetActiveProperties()
	
	local playerId = WindowData.PlayerStatus.PlayerId
	local paperdollWindowName = "PaperdollWindow"..playerId 	
	local numTotalItemProps = CSVUtilities.getNumRows(WindowData.PlayerItemPropCSV)
	
	if(WindowData.Paperdoll[playerId] == nil ) then			
		return
	end	

	-- Show available item properties	
	PropertyTable = {}
	for index = 1, WindowData.Paperdoll[playerId].numSlots do
		if (WindowData.Paperdoll[playerId][index].slotId ~= 0) then
			local objectId = WindowData.Paperdoll[playerId][index].slotId
			RegisterWindowData(WindowData.ObjectInfo.Type, objectId)			
			local props = ItemProperties.GetObjectPropertiesTid(objectId, nil, "ItemProperties - get active properties")						
			if not props then
				continue
			end						
			for i = 1, #props do				
				local currentTID = 0				
				for propIndex = 1, numTotalItemProps do
					currentTID = WindowData.PlayerItemPropCSV[propIndex].TID
					if (currentTID ~= 0 and currentTID == props[i]) then
						-- Append to active List								
						PropertyTable[propIndex] = propIndex							
						break
					end
				end					
			end
			UnregisterWindowData(WindowData.ObjectInfo.Type, objectId)
		end		
	end
	return PropertyTable
end

function ItemProperties.GetCharges(objectId)
	local noObjectFound = 0
	if(not WindowData.ObjectInfo[objectId])then		
		RegisterWindowData(WindowData.ObjectInfo.Type, objectId)
		noObjectFound = 1
	end

	local props = ItemProperties.GetObjectPropertiesArray( objectId, "ItemProperties.GetCharges" )
	local params = ItemProperties.BuildParamsArray( props )
	if not props then
		return
	end
	
	local tempTable = nil
	for j = 1, #props.PropertiesTids do
		local indexTID = props.PropertiesTids[j]
		if ItemPropertiesInfo.ChargesTid[indexTID] then
			local token = ItemPropertiesInfo.ChargesTid[indexTID]
			local val = tostring(params[indexTID][token])								
			local TIDString = GetStringFromTid(indexTID)			
			local updatedWString = ReplaceTokens(TIDString, {WindowUtils.AddCommasToNumber(val)})			
			tempTable = { updatedWString, tonumber(val)}		

			local containerID = GetParentContainer(objectId)
			if(containerID ~= 0) then
				if(ContainerWindow.CurrentUses[containerID] == nil)then
					ContainerWindow.CurrentUses[containerID] = {}
				end
				ContainerWindow.CurrentUses[containerID][objectId] = tempTable  
				if ContainerWindow.LastUsesDelta[containerID] == nil or ContainerWindow.LastUsesDelta[containerID] == 0 then				
					ContainerWindow.LastUsesDelta[containerID] = 1
				end
			end
			break
		end
	end

	if noObjectFound == 1 then		
		UnregisterWindowData(WindowData.ObjectInfo.Type, objectId)
	end

	return tempTable
end

--ebm
--start of added code 

function ReplaceValues(inputString, val)
    local outputString = inputString
	for i = 1, #val do
		outputString = outputString:gsub("~([^~]+)~", tostring(val[i]),1)
	end
    return outputString
end

function ItemProperties.prop_has_reqs(props,reqs)
	local params = ItemProperties.BuildParamsArray( props )
	local needed_prop
	local needed_value
	local this_valid
	for i = 1, #reqs do
		this_valid=false
		needed_prop=reqs[i][1]
		needed_value=reqs[i][2]
		--Debug.Print("looking for: "..needed_prop)
		for j = 1, #props.PropertiesTids do
			local x = tostring(GetStringFromTid(props.PropertiesTids[j]))
			local val = params[props.PropertiesTids[j]]
			if val then
				--Debug.Print(x)
				if x:find(needed_prop) then
					--Debug.Print("found: "..needed_prop.." on the item")
					--Debug.Print("of strength " .. tostring(val[1]) .. " we wanted at least " .. tostring(needed_value))
					if tonumber(val[1])>=needed_value then
						this_valid=true
						break
					end
				end
			end
		end
		if not this_valid then
			return false
		end
	end
	return true
end

function ItemProperties.score_prop(props,reqs)
	local params = ItemProperties.BuildParamsArray( props )
	local needed_prop
	local weight
	local score=0
	for i = 1, #reqs do
		needed_prop=reqs[i][1]
		weight=reqs[i][2]
		for j = 1, #props.PropertiesTids do
			local x = tostring(GetStringFromTid(props.PropertiesTids[j]))
			local val = params[props.PropertiesTids[j]]
			if val then
				if x:find(needed_prop) then
					score=score+tonumber(val[1])*weight
					break
				end
			end
		end
	end
	return score
end

local lrc = "lower reagent cost"
local lmc = "lower mana cost"
local sdi = "spell damage increase"
local fcr = "faster cast recovery"
local fc = "faster casting"
local hci = "hit chance increase"
local dci = "defence chance increase"
local ssi = "swing speed increase"
local luck = "luck"
local strength_bonus = "strength bonus"
local dex_bonus = "dexterity bonus"
local int_bonus = "intelligence bonus"
local hpi = "hit point increase"
local stamina_increase = "stamina increase"
local mana_increase = "mana increase"
local mr = "mana regeneration"
local physical_resist = "physical resist"
local fire_resist = "fire resist"
local cold_resist = "cold resist"
local poison_resist = "poison resist"
local energy_resist = "energy resist"
local mage_armor = "mage armor"
local spell_channeling = "spell channeling"


function ItemProperties.score_as_mage_jewelry(props)
	local reqs = {{sdi,15},{fcr,3}}
	if not ItemProperties.prop_has_reqs(props,reqs) then
		return 0
	end
	reqs = {{luck,1./20},{fc,20},{fcr,5},{lmc,2},{sdi,20./18}}
	return ItemProperties.score_prop(props,reqs)+20
end

function ItemProperties.score_as_tamer_jewelry(props)
	local reqs = {{luck,100}}
	if ItemProperties.prop_has_reqs(props,reqs) then 
		reqs = {{lrc,1},{fc,20},{fcr,5},{lmc,2}}
		return ItemProperties.score_prop(props,reqs)+20
	end
	return 0
end

function ItemProperties.score_as_fighter_jewelry(props)
	local reqs = {{hci,15},{ssi,10}}
	return ItemProperties.prop_has_reqs(props,reqs)
end

function ItemProperties.score_as_mage_armor(props)
	local requirements = {{lrc, 15}, {lmc, 6}}
	if not ItemProperties.prop_has_reqs(props,requirements) then
		return 0
	end
	local reqs = {{lrc,2},{strength_bonus,.5},{hpi,2},{int_bonus,.5},
	{mana_increase,.2},{lmc,.6},{mr,1},
	{physical_resist,.7},{fire_resist,.6},{cold_resist,.4},{poison_resist,.4},{energy_resist,.5}}
	return ItemProperties.score_prop(props,reqs)
end


function ItemProperties.score_as_tamer_armor(props)
	local requirements = {{lrc, 15}, {lmc, 6}, {luck, 1}}
	if not ItemProperties.prop_has_reqs(props,requirements) then
		return 0
	end
	local reqs = {{lrc,1},{strength_bonus,.2},{hpi,.4},{int_bonus,.8},{luck,.2},
	{mana_increase,.5},{lmc,2},{mr,1},
	{physical_resist,.7},{fire_resist,.6},{cold_resist,.4},{poison_resist,.4},{energy_resist,.5}}
	return ItemProperties.score_prop(props,reqs)
end 

function ItemProperties.score_as_bard_armor(props)
	local requirements = {{mr, 3}, {lmc,6}}
	if not ItemProperties.prop_has_reqs(props,requirements) then
		return 0
	end
	local reqs = {{lmc,2},{mr,10},{int_bonus,.8},{luck,.2},
	{physical_resist,.7},{fire_resist,.6},{cold_resist,.4},{poison_resist,.4},{energy_resist,.5}}
	return ItemProperties.score_prop(props,reqs)
end

function ItemProperties.score_as_fighter_armor(props)
	local score=0
	local reqs = {{strength_bonus,1},{hpi,.4},{int_bonus,1},{dex_bonus,1},{stamina_increase,2},
	{mana_increase,1},{lmc,3},{mr,1},
	{physical_resist,.6},{fire_resist,.5},{cold_resist,.3},{poison_resist,.3},{energy_resist,.4}}
	if ItemProperties.prop_has_reqs(props,{{mage_armor,-100}}) then
		score=score-30
	end
	return score+ItemProperties.score_prop(props,reqs)
end

function ItemProperties.score_as_shield(props)
	-- doesn't work
	--if not ItemProperties.prop_has_reqs(props,{{spell_channeling,-100}}) then
	--	return -1000
	--end
	local casting = ItemProperties.score_prop(props,{{fc, 10}})
	if casting < 0 then
		return -1000
	end
	local reqs = {{lrc,2},{strength_bonus,.5},{hpi,2},{int_bonus,.5},
	{mana_increase,.2},{lmc,.6},{mr,1}, {luck, .1}, {fc, 10}, {fcr, 2},
	{physical_resist,.7},{fire_resist,.6},{cold_resist,.4},{poison_resist,.4},{energy_resist,.5}}
	return ItemProperties.score_prop(props,reqs)
end


function ItemProperties.is_helmet(item_name)
	local helmet_names = {
		"Leather Cap",
		"Leather Jingasa",
		"Leather Ninja Hood",
		"Bone Helmet",
		"Orc Helm",
		"Dragon Turtle Helm",
		"Tiger Pelt Helm",

		"Chainmail Coif",
		"Bascinet",
		"Close Helmet",
		"Helmet",
		"Norse Helm",
		"Plate Helm",
		"Chainmail Hatsuburi",
		"Platemail Hatsuburi",
		"Heavy Platemail Jingasa",
		"Light Platemail Jingasa",
		"Small Platemail Jingasa",
		"Decorative Platemail Kabuto",
		"Platemail Battle Kabuto",
		"Standard Platemail Kabuto",
		"Circlet",
		"Royal Circlet",
		"Gemmed Circlet",
		"Dragon Helm",

		"Raven Helm",
		"Vulture Helm",
		"Winged Helm",

		"Elven Glasses",
		"Kabuto",
		"Helm of Spirituality",
		"Helm of Swiftness",
	
		"Skullcap",
		"Bandana",
		"Floppy Hat",
		"Cap",
		"Brim Hat",
		"Straw Hat",
		"Tall Straw Hat",
		"Wizard's Hat",
		"Bonnet",
		"Feathered Hat",
		"Tricorne Hat",
		"Jester Hat",
		"Flower Garland",
		"Cloth Ninja Hood",
		"Kasa",
		"Bear Mask",
		"Deer Mask",
		"Orc Mask",
		"Tribal Mask",

		"earring" --gargoyle moment
	}
	for i=1, #helmet_names do
		if item_name:find(helmet_names[i]) then
			return true
		end
	end
	return false
end

function ItemProperties.is_bis(item_name)
	local bis_list = {
		"Shroud Of The",
		"Robe Of",
		"Crimson",
		"Tangle",
		"Quiver",
		"Paroxysmus Swamp",
		"Enchanted Sash",
		"Of The Royal Guard",
		"Lieutenant",
		"Hawkwind",
		"Mana Phasing",
		"Of Sending",
	}
	for i=1, #bis_list do
		if item_name:find(bis_list[i]) then
			return true
		end
	end
	return false
end

function ItemProperties.is_shield(item_name)
	local shield_list = {
		"Shield",
		"Hephaestus",
	}
	for i=1, #shield_list do
		if item_name:find(shield_list[i]) then
			return true
		end
	end
	return false
end

function ItemProperties.is_medable(item_name, props)
	if ItemProperties.prop_has_reqs(props,{{mage_armor,-100}}) then
		return true
	end
	-- definitely not medable if
	local non_medable = {
		"Studded",
		"Hide",
		"Stone",
		"Bone",
		"Ring",
		"Chain",
		"Plate",
		"Barbed",
		"Dragon",
		"Woodland",
	}
	for i=1, #non_medable do
		if item_name:find(non_medable[i]) then
			return false
		end
	end
	return true
end

function ItemProperties.score(props)
	local diagnosis={}
	local weight = ItemProperties.GetPropWeight(props)
	if weight==0 then
		diagnosis.take=false
		diagnosis.print="NAI"
		return diagnosis
	end
	if weight>50 then
		diagnosis.take=false
		diagnosis.print="NAI"
		return diagnosis
	end
	if weight==50 then
		diagnosis.take=false
		diagnosis.print="HEAVY TRASH"
		return diagnosis
	end

	
	



	local item_title = tostring(props.PropertiesList[1])
	if (item_title:find("Ring") and not item_title:find("Ringm")) or item_title:find("Bracelet") then
		local mjscore = ItemProperties.score_as_mage_jewelry(props)
		if mjscore>0 then
			diagnosis.take=true
			diagnosis.print=string.format("Wizard Jewelry %.2f", tostring(mjscore))
			return diagnosis
		end
		if ItemProperties.score_as_fighter_jewelry(props) then
			diagnosis.take=true
			diagnosis.print="Fighter Jewelry"
			return diagnosis
		end
		local tjscore = ItemProperties.score_as_tamer_jewelry(props)
		if tjscore >= 50 then
			diagnosis.take=true
			diagnosis.print=string.format("Tamer Jewelry %.2f", tostring(tjscore))
			return diagnosis
		end
		diagnosis.take=false
		diagnosis.print="JEWELRY TRASH"
		return diagnosis
	end
	if ItemProperties.is_bis(item_title) then
		diagnosis.take=true
		diagnosis.print="BIS"
		return diagnosis
	end
	if ItemProperties.is_shield(item_title) then
		-- cant get spell channeling. sadge

		local shield_score = ItemProperties.score_as_shield(props)
		if shield_score > 0 then
			diagnosis.take=true
			diagnosis.print=string.format("Shield, Maybe %.2f", tostring(shield_score))
		else
			diagnosis.take=false
			diagnosis.print="Bad Shield"
		end
		
		return diagnosis
	end
	
	local medable = ItemProperties.is_medable(item_title, props)
	local wscore = 0
	local tscore = 0
	local fscore = 0
	local bscore = 0
	local format_string = "|No| wiz: %.2f dex: %.2f tame: %.2f bard: %.2f"
	if medable then
		format_string = "|Med| wiz: %.2f dex: %.2f tame: %.2f bard: %.2f"
		wscore = ItemProperties.score_as_mage_armor(props)
		tscore = ItemProperties.score_as_tamer_armor(props)
		bscore = ItemProperties.score_as_bard_armor(props)
	end
	local item_is_lmc_overcapper = item_title:find("Studded")  or item_title:find("Hide")  or item_title:find("Stone") or item_title:find("Bone")
	local item_is_helmet = ItemProperties.is_helmet(item_title)
	if item_is_lmc_overcapper or item_is_helmet then
		fscore = ItemProperties.score_as_fighter_armor(props)
	end
	diagnosis.take=false
	diagnosis.print=string.format(format_string,wscore,fscore,tscore,bscore)
	if wscore >= 85 or fscore>60 or tscore>60 or bscore>30 then
		diagnosis.take=true
	end
	return diagnosis
end


function ItemProperties.worth_looting(itemId)
	local props = ItemProperties.GetObjectPropertiesArray( itemId, "worth_looting" )
	if (props) then
		return ItemProperties.score(props).take
	end
	return false
end

function ItemProperties.GetPropWeight(props)
	local weight=0
	if (props) then
		local params = ItemProperties.BuildParamsArray( props )			
		for j = 1, #props.PropertiesTids do		
			if (ItemPropertiesInfo.WeightONLYTid[props.PropertiesTids[j]]) then
				token = ItemPropertiesInfo.WeightONLYTid[props.PropertiesTids[j]]
				val = tostring(params[props.PropertiesTids[j]][token])			
				weight = tonumber(val)
				return weight
			end			
		end
	end
	
	return weight
end

function ItemProperties.GetItemWeight(itemId)
	local props = ItemProperties.GetObjectPropertiesArray( itemId, "GetItemWeight" )
	return ItemProperties.GetPropWeight(props)
end


function ItemProperties.GetItemStats(itemId)
	local weight = 0
	local props = ItemProperties.GetObjectPropertiesArray( itemId, "GetItemStats" )

	if (props) then
		local params = ItemProperties.BuildParamsArray( props )			
		--Debug.Print("stated fields:")
		--Debug.Print(params)
		weight = params[1072225][1]
		if (weight == nil) then
			weight = params[1072788][1]
			if (weight == nil) then
				weight = 0
			end 
		end

		--Debug.Print("happy printed all props:")
		for j = 1, #props.PropertiesTids do		
			local x = GetStringFromTid(props.PropertiesTids[j])
			--Debug.Print("tid="..tostring(props.PropertiesTids[j]).." "..tostring(x))
			val = params[props.PropertiesTids[j]]
			if val then
				for k = 1, #val do
					--Debug.Print(val[k])
				end
			end
		end
		--Debug.Print("--------------------")
--		Debug.Print("weight = : "..tostring(weight))
		return tonumber(weight)




--		for j = 1, #props.PropertiesTids do		
--			if (ItemPropertiesInfo.WeightONLYTid[props.PropertiesTids[j]]) then
--				token = ItemPropertiesInfo.WeightONLYTid[props.PropertiesTids[j]]
--				val = tostring(params[props.PropertiesTids[j]][token])			
--				weight = tonumber(val)
--				return weight
--			end			
--		end
	end
	
	return weight
end
--end of added code