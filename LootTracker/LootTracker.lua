local CostDB,browse_rarityhexlink,cost,cost_orig,guildName,lootid,oldplayergp,raidfound,raidid,rarity,sortdirection,
sortfield,timestamp_detail,timestamp_raidid,you,zonename

local LootTrackerOptions_DefaultSettings = {
	enabled = true,
	uncommon = false,
	common = false,
	rare = true,
	epic = true,
	legendary = true,
	timestamp = false,
	cost = false,
}

local LootTrackerBlacklist_DefaultSettings = {
		"Nexus Crystal"
	}


---------------------------------------------------------
--LootTracker Global Functions
---------------------------------------------------------

local function LootTracker_Initialize()
	if not LootTrackerOptions  then
		LootTrackerOptions = {}
	end

	for i in LootTrackerOptions_DefaultSettings do
		if (LootTrackerOptions[i] == nil) then
			LootTrackerOptions[i] = LootTrackerOptions_DefaultSettings[i]
		end
	end
	
	if not LootTrackerBlacklist  then
		LootTrackerBlacklist = {}
	end

	for i in LootTrackerBlacklist_DefaultSettings do
		if (LootTrackerBlacklist[i] == nil) then
			LootTrackerBlacklist[i] = LootTrackerBlacklist_DefaultSettings[i]
		end
	end
  -- if shootyepgp is present and loaded
  if sepgp and sepgp_prices and sepgp_prices.GetPrice and sepgp_progress then
    LootTracker_GetCosts = function(itemID)
    	local itemID = tonumber(itemID)
    	if not (itemID) then return 0,0 end
    	local cost, offspec
    	cost = sepgp_prices:GetPrice(itemID,sepgp_progress) or 0
    	offspec = math.floor(cost*(sepgp_discount or 0.5))
    	return cost, offspec
    end
  end
  if sepgp and sepgp.get_ep_v3 and sepgp.get_gp_v3 then
    LootTracker_GetPlayerEPGP = function(playername) oldplayergp = (sepgp:get_gp_v3(playername) or sepgp.VARS.basegp) end
  end
end
	
function LootTracker_OnLoad()

	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffa335eeLootTracker|r v%s by %s. Type /lt or /loottracker for more info", GetAddOnMetadata("LootTracker", "Version"), GetAddOnMetadata("LootTracker", "Author")));
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("CHAT_MSG_LOOT")
	--CHAT_MSG_LOOT examples:
	--You receive loot: |cffffffff|Hitem:769:0:0:0|h[Chunk of Boar Meat]|h|r.
	--Luise receives loot: |cffffffff|Hitem:769:0:0:0|h[Chunk of Boar Meat]|h|r.
    
	SlashCmdList["LootTracker"] = LootTracker_SlashCommand;
	SLASH_LootTracker1 = "/loottracker";
	SLASH_LootTracker2 = "/lt";
	
	local MSG_PREFIX = "LootTracker"
	
	
	LootTracker_pattern_playername = "^([^%s]+) receive" -- master loot
	LootTracker_pattern_groupwin = "^([^%s]+) won"      -- For group loot
	LootTracker_pattern_itemname = "%[(.+)]"
	LootTracker_pattern_itemid = "item:(%d+)"
	LootTracker_pattern_rarityhex = "(.+)|c(.+)|H"
 	you = "You"
	LootTracker_pattern_epgpextract = "^(%d+)/(%d+)"

	
	LootTracker_color_common = "ffffffff"
	LootTracker_color_uncommon = "ff1eff00"
	LootTracker_color_rare = "ff0070dd"
	LootTracker_color_epic = "ffa335ee"
	LootTracker_color_legendary = "ffff8000"
	
	LootTracker_dbfield_playername = "playername"
	LootTracker_dbfield_itemname = "itemname"
	LootTracker_dbfield_itemid = "itemid"
	LootTracker_dbfield_rarity = "rarity"
	LootTracker_dbfield_timestamp = "timestamp"
	LootTracker_dbfield_zone = "zone"
	LootTracker_dbfield_oldplayergp = "oldplayergp"
	LootTracker_dbfield_cost = "cost"
	LootTracker_dbfield_newplayergp = "newplayergp"
	LootTracker_dbfield_offspec = "offspec"
	LootTracker_dbfield_de = "de"
	LootTracker_dbfield_res3 = "res3"
	LootTracker_dbfield_res4 = "res4"
	LootTracker_dbfield_res5 = "res5"
	
	--Localization
	LootTrackerLoc_Title = "|cffa335eeLootTracker Browser|r" 
	LootTrackerLoc_Version = GetAddOnMetadata("LootTracker", "Version")
end

function LootTracker_OnEvent()
	if event == "VARIABLES_LOADED" then
		this:UnregisterEvent("VARIABLES_LOADED");
		LootTracker_Initialize();
	elseif event == "CHAT_MSG_LOOT" and arg1 and LootTrackerOptions["enabled"] == true then
		
		-- Match standard loot messages
		local _, _, playername = string.find(arg1, LootTracker_pattern_playername)

		-- Match group loot messages if no playername was found
		if not playername then
			_, _, playername = string.find(arg1, LootTracker_pattern_groupwin)
		end

		-- Proceed only if playername is found
		if playername then
			if playername == you then
				playername = UnitName("player")
			end
			
			-- Extract the item name
			local _, _, itemname = string.find(arg1, LootTracker_pattern_itemname)
			
			-- Extract the item ID
			local _, _, itemid = string.find(arg1, LootTracker_pattern_itemid)

			-- Extract rarity
			local _, _, _, rarityhex = string.find(arg1, LootTracker_pattern_rarityhex)
			
			-- Check if the item is on the blacklist
			if not LootTracker_CheckBlacklist(itemname) then

				-- Check rarity and add itemname to the database
				if rarityhex == LootTracker_color_common and LootTrackerOptions["common"] == true then
					rarity = "common"
					LootTracker_AddtoDB(playername, itemname, itemid, rarity)
				elseif rarityhex == LootTracker_color_uncommon and LootTrackerOptions["uncommon"] == true then
					rarity = "uncommon"
					LootTracker_AddtoDB(playername, itemname, itemid, rarity)
				elseif rarityhex == LootTracker_color_rare and LootTrackerOptions["rare"] == true then
					rarity = "rare"
					LootTracker_AddtoDB(playername, itemname, itemid, rarity)
				elseif rarityhex == LootTracker_color_epic and LootTrackerOptions["epic"] == true then
					rarity = "epic"
					LootTracker_AddtoDB(playername, itemname, itemid, rarity)
				elseif rarityhex == LootTracker_color_legendary and LootTrackerOptions["legendary"] == true then
					rarity = "legendary"
					LootTracker_AddtoDB(playername, itemname, tostring(itemid), rarity)
				end
			end
		end
	end
end


function LootTracker_CheckBlacklist(itemname)
	for k,v in ipairs(LootTrackerBlacklist) do
		if itemname == v then
			return true
		end
	end
	return false
end

function LootTracker_SlashCommand(msg)

	if msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("LootTracker usage:")
		DEFAULT_CHAT_FRAME:AddMessage("/lt or /loottracker { help |  enable | disable | toggle | show | options | reset | recalc | uncommon | common | rare | epic | legendary | timestamp | cost}")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9help|r: prints out this help")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9enable|r: enables loot tracking")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9disable|r: disables loot tracking")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9toggle|r: toggles loot tracking")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9show|r: shows the current configuration")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9options|r: shows the option menu")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9reset|r: resets the loot database")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9recalc|r: recalculates GP for loot database")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9uncommon|r: toggles tracking uncommon loot")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9common|r: toggles tracking common loot")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9rare|r: toggles tracking rare loot")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9epic|r: toggles tracking epic loot")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9legendary|r: toggles tracking legendary loot")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9timestamp|r: toggles exporting with timestamps")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9cost|r: toggles exporting with GP price")
	elseif msg == "toggle" then 
		if LootTrackerOptions["enabled"] == true then
			LootTrackerOptions["enabled"] = false
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cffff0000disabled|r")
		elseif LootTrackerOptions["enabled"] == false then
			LootTrackerOptions["enabled"] = true
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cff00ff00enabled|r")
		end
	elseif msg == "enable" then
		LootTrackerOptions["enabled"] = true
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cff00ff00enabled|r")
	elseif msg == "disable" then
		LootTrackerOptions["enabled"] = false
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cffff0000disabled|r")
	elseif msg == "show" then
	
		if LootTrackerOptions["enabled"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cff00ff00enabled|r")
		elseif LootTrackerOptions["enabled"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("LootTracker state: |cffff0000disabled|r")
		end
	
		if LootTrackerOptions["common"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffffffffcommon|r loot: |cff00ff00enabled|r")
		elseif LootTrackerOptions["common"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffffffffcommon|r loot: |cffff0000disabled|r")
		end

		if LootTrackerOptions["uncommon"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff1eff00uncommon|r loot: |cff00ff00enabled|r")
		elseif LootTrackerOptions["uncommon"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff1eff00uncommon|r loot: |cffff0000disabled|r")
		end

		if LootTrackerOptions["rare"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff0070ddrare|r loot: |cff00ff00enabled|r")
		elseif LootTrackerOptions["rare"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff0070ddrare|r loot: |cffff0000disabled|r")
		end

		if LootTrackerOptions["epic"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffa335eeepic|r loot: |cff00ff00enabled|r")
		elseif LootTrackerOptions["epic"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffa335eeepic|r loot: |cffff0000disabled|r")
		end

		if LootTrackerOptions["legendary"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffff8000legendary|r loot: |cff00ff00enabled|r")
		elseif LootTrackerOptions["legendary"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffff8000legendary|r loot: |cffff0000disabled|r")
		end
		
		if LootTrackerOptions["timestamp"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with timestamps: |cff00ff00enabled|r")
		elseif LootTrackerOptions["timestamp"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with timestamps: |cffff0000disabled|r")
		end
		
		if LootTrackerOptions["cost"] == true then
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with GP price: |cff00ff00enabled|r")
		elseif LootTrackerOptions["cost"] == false then
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with GP price: |cffff0000disabled|r")
		end

	elseif msg == "options" then
		if LootTracker_OptionsFrame:IsVisible() then
			LootTracker_OptionsFrame:Hide()
		else
			ShowUIPanel(LootTracker_OptionsFrame, 1)
		end
		
	elseif msg == "reset" then
		LootTracker_ResetDB()
	elseif msg == "recalc" then
		LootTracker_RecalcDB()
	elseif msg == "common" then		
		if LootTrackerOptions["common"] == true then
			LootTrackerOptions["common"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffffffffcommon|r loot: |cffff0000disabled|r")
		elseif LootTrackerOptions["common"] == false then
			LootTrackerOptions["common"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffffffffcommon|r loot: |cff00ff00enabled|r")
		end
	elseif msg == "uncommon" then		
		if LootTrackerOptions["uncommon"] == true then
			LootTrackerOptions["uncommon"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff1eff00uncommon|r loot: |cffff0000disabled|r")
		elseif LootTrackerOptions["uncommon"] == false then
			LootTrackerOptions["uncommon"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff1eff00uncommon|r loot: |cff00ff00enabled|r")
		end
	elseif msg == "rare" then		
		if LootTrackerOptions["rare"] == true then
			LootTrackerOptions["rare"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff0070ddrare|r loot: |cffff0000disabled|r")
		elseif LootTrackerOptions["rare"] == false then
			LootTrackerOptions["rare"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cff0070ddrare|r loot: |cff00ff00enabled|r")
		end
	elseif msg == "epic" then		
		if LootTrackerOptions["epic"] == true then
			LootTrackerOptions["epic"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffa335eeepic|r loot: |cffff0000disabled|r")
		elseif LootTrackerOptions["epic"] == false then
			LootTrackerOptions["epic"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffa335eeepic|r loot: |cff00ff00enabled|r")
		end
	elseif msg == "legendary" then		
		if LootTrackerOptions["legendary"] == true then
			LootTrackerOptions["legendary"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffff8000legendary|r loot: |cffff0000disabled|r")
		elseif LootTrackerOptions["legendary"] == false then
			LootTrackerOptions["legendary"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Tracking |cffff8000legendary|r loot: |cff00ff00enabled|r")
		end
	elseif msg == "timestamp" then		
		if LootTrackerOptions["timestamp"] == true then
			LootTrackerOptions["timestamp"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with timestamps: |cffff0000disabled|r")
		elseif LootTrackerOptions["timestamp"] == false then
			LootTrackerOptions["timestamp"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with timestamps: |cff00ff00enabled|r")

		end
	elseif msg == "cost" then		
		if LootTrackerOptions["cost"] == true then
			LootTrackerOptions["cost"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with GP price: |cffff0000disabled|r")
		elseif LootTrackerOptions["cost"] == false then
			LootTrackerOptions["cost"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Exporting with GP price: |cff00ff00enabled|r")
		end
	else
		if (LootTracker_BrowseFrame:IsVisible() or LootTracker_RaidIDFrame:IsVisible()) then
			LootTracker_BrowseFrame:Hide()
			LootTracker_RaidIDFrame:Hide()
      DEFAULT_CHAT_FRAME:AddMessage("|cffa335eeLootTracker|r: Type \'/lt help\' or \'/loottracker help\' for more options.")
		else
			ShowUIPanel(LootTracker_BrowseFrame, 1)
		end
	end
end

function LootTracker_GetCosts(itemid)

	if guildName == "De Profundis" then
		CostDB = DeProfundis_GP
	elseif guildName == "Discordia" then
		CostDB = Discordia_GP
	else
		CostDB = DeProfundis_GP
	end

	if CostDB and itemid then
		for k, v in pairs(CostDB) do
			if k == "Item"..itemid then
				return v, v/2
			end
		end
	end
	
	return 0, 0
end


---------------------------------------------------------
--LootTracker Database Functions
---------------------------------------------------------
function LootTracker_GetPlayerEPGP(playername)
  --Player GP
  for i = 1, GetNumGuildMembers(true) do
    local guild_name, _, _, _, _, _, _, guild_officernote, _, _ = GetGuildRosterInfo(i)
    local _, _, guild_ep, guild_gp = string.find(guild_officernote, LootTracker_pattern_epgpextract)
      if guild_name == playername then
        oldplayergp = guild_gp
      end
  end
end

function LootTracker_AddtoDB(playername, itemname, itemid, rarity, offspec, de)

	--clear variables
	
	
	--get the metadata
	timestamp_raidid = date("%y-%m-%d")
	timestamp_detail = date("%y-%m-%d %H:%M:%S")
	zonename = GetRealZoneText();
	raidid = timestamp_raidid .. " " .. zonename
	

	--check if db is empty
	if LootTrackerDB == nil then
		LootTrackerDB = {}
	end
	if LootTrackerDB[raidid] == nil then
		LootTrackerDB[raidid] = {}
	end
	
  LootTracker_GetPlayerEPGP(playername)

	--calculate costs
	cost = LootTracker_GetCosts(itemid)
	

	--import the itemname into the db
	if playername and itemname and itemid and rarity and timestamp_detail and zonename then
		if getn(LootTrackerDB[raidid]) == 0 then
			LootTrackerDB[raidid][1] = {}
			LootTrackerDB[raidid][1][LootTracker_dbfield_playername] = playername
			LootTrackerDB[raidid][1][LootTracker_dbfield_itemname] = itemname
			LootTrackerDB[raidid][1][LootTracker_dbfield_itemid] = itemid
			LootTrackerDB[raidid][1][LootTracker_dbfield_rarity] = rarity
			LootTrackerDB[raidid][1][LootTracker_dbfield_timestamp] = timestamp_detail
			LootTrackerDB[raidid][1][LootTracker_dbfield_zone] = zonename
			if oldplayergp then
				LootTrackerDB[raidid][1][LootTracker_dbfield_oldplayergp] = tostring(oldplayergp)
			else
				LootTrackerDB[raidid][1][LootTracker_dbfield_oldplayergp] = "0"
			end
			if cost then 
				LootTrackerDB[raidid][1][LootTracker_dbfield_cost] = tostring(cost)
			else
				LootTrackerDB[raidid][1][LootTracker_dbfield_cost] = "0"
			end
			if oldplayergp and cost then 
				LootTrackerDB[raidid][1][LootTracker_dbfield_newplayergp] = tostring(oldplayergp+cost)
			else
				if oldplayergp then
					LootTrackerDB[raidid][1][LootTracker_dbfield_newplayergp] = tostring(oldplayergp)
				else
					LootTrackerDB[raidid][1][LootTracker_dbfield_newplayergp] = "0"
				end
			end
			
			if offspec == true then
				LootTrackerDB[raidid][1][LootTracker_dbfield_offspec] = true
			else
				LootTrackerDB[raidid][1][LootTracker_dbfield_offspec] = false
			end
			if de == true then
				LootTrackerDB[raidid][1][LootTracker_dbfield_de] = true
			else
				LootTrackerDB[raidid][1][LootTracker_dbfield_de] = false
			end
			LootTrackerDB[raidid][1][LootTracker_dbfield_res3] = nil
			LootTrackerDB[raidid][1][LootTracker_dbfield_res4] = nil
			LootTrackerDB[raidid][1][LootTracker_dbfield_res5] = nil
		else
			lootid = getn(LootTrackerDB[raidid])+1
			LootTrackerDB[raidid][lootid] = {}
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_playername] = playername
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_itemname] = itemname
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_itemid] = itemid
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_rarity] = rarity
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_timestamp] = timestamp_detail
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_zone] = zonename
			if oldplayergp then
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_oldplayergp] = tostring(oldplayergp)
			else
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_oldplayergp] = "0"
			end
			if cost then 
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_cost] = tostring(cost)
			else
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_cost] = "0"
			end
			if oldplayergp and cost then 
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_newplayergp] = tostring(oldplayergp+cost)
			else
				if oldplayergp then
					LootTrackerDB[raidid][lootid][LootTracker_dbfield_newplayergp] = tostring(oldplayergp)
				else
					LootTrackerDB[raidid][lootid][LootTracker_dbfield_newplayergp] = "0"
				end
			end
			
			if offspec == true then
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_offspec] = true
			else
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_offspec] = false
			end
			if de == true then
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_de] = true
			else
				LootTrackerDB[raidid][lootid][LootTracker_dbfield_de] = false
			end
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_res3] = nil
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_res4] = nil
			LootTrackerDB[raidid][lootid][LootTracker_dbfield_res5] = nil
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("LootTracker Debug: Error in LootTracker_AddtoDB")
	end
end

function LootTracker_ResetDB()
	LootTrackerDB = {}
	LootTracker_RaidIDScrollFrame_Update()
	LootTracker_BuildBrowseTable()
	DEFAULT_CHAT_FRAME:AddMessage("LootTracker: Loot Database has been reset")
end

function LootTracker_RecalcDB()
	for raidid,items in pairs(LootTrackerDB) do
		for _,item in ipairs(items) do
			local cost,offspec = LootTracker_GetCosts(item[LootTracker_dbfield_itemid])
			if item[LootTracker_dbfield_de] == true then
				item[LootTracker_dbfield_cost] = "0"
			elseif item[LootTracker_dbfield_offspec] == true then
				item[LootTracker_dbfield_cost] = offspec
			else
				item[LootTracker_dbfield_cost] = cost
			end
		end
	end
	LootTracker_RaidIDScrollFrame_Update()
	LootTracker_BuildBrowseTable()
	DEFAULT_CHAT_FRAME:AddMessage("LootTracker: Loot GP has been recalculated")	
end

function LootTracker_ExportRaid(raidid, timestamp, cost)
  -- Check if the raidid exists in DB
  raidfound = false
  if raidid and (string.len(raidid) >= 1) then
    for k in pairs(LootTrackerDB) do
      if k == raidid then
        raidfound = true
      end
    end
  end
  
  LootTracker_ExportData = nil
  
  if raidfound == true then
    -- Step 1) Build a local itemsToExport table
    local itemsToExport = {}
    for index in LootTrackerDB[raidid] do
      table.insert(itemsToExport, {
        index   = index, 
        item    = LootTrackerDB[raidid][index],
      })
    end
    
    -- Our order: Uncommon -> Common -> Rare -> Epic -> Legendary
    local raritySortOrder = {
      ["uncommon"]  = 1,
      ["common"]    = 2,
      ["rare"]      = 3,
      ["epic"]      = 4,
      ["legendary"] = 5
    }
    
    -- Step 2) Sort items by rarity
    table.sort(itemsToExport, function(a, b)
      local rA = raritySortOrder[a.item[LootTracker_dbfield_rarity]] or 999
      local rB = raritySortOrder[b.item[LootTracker_dbfield_rarity]] or 999
      
      -- If same rarity, you can either break the tie by item name or timestamp
      if rA == rB then
        -- Example: tie‐break by item name
        local nameA = a.item[LootTracker_dbfield_itemname] or ""
        local nameB = b.item[LootTracker_dbfield_itemname] or ""
        return nameA < nameB
      else
        return rA < rB
      end
    end)
    
    -- Step 3) Build the output lines
    local rarityLabels = {
      ["common"]    = "[Common]",
      ["uncommon"]  = "[Uncommon]",
      ["rare"]      = "[Rare]",
      ["epic"]      = "[Epic]",
      ["legendary"] = "[Legendary]"
    }
    
    LootTracker_ExportData = raidid .. "\r\n\r\n"
    
    for _, entry in ipairs(itemsToExport) do
      local itemEntry = entry.item
      
      -- optional timestamp
      if timestamp == true then
        LootTracker_ExportData = LootTracker_ExportData 
                              .. itemEntry[LootTracker_dbfield_timestamp] 
                              .. " - "
      end
      
      -- Add [Rarity] <ItemName>
      local itemRarity = itemEntry[LootTracker_dbfield_rarity]
      local rarityText = rarityLabels[itemRarity] or "[Unknown]"
      LootTracker_ExportData = LootTracker_ExportData 
                            .. rarityText 
                            .. " " 
                            .. itemEntry[LootTracker_dbfield_itemname]
      
      -- Player or Disenchanted
      if itemEntry[LootTracker_dbfield_de] == true then
        LootTracker_ExportData = LootTracker_ExportData .. ": disenchanted"
      else
        LootTracker_ExportData = LootTracker_ExportData 
                              .. ": " 
                              .. itemEntry[LootTracker_dbfield_playername]
      end
      
      -- Offspec
      if itemEntry[LootTracker_dbfield_offspec] == true then
        LootTracker_ExportData = LootTracker_ExportData .. " - offspec"
      end
      
      -- Cost
      if cost and itemEntry[LootTracker_dbfield_de] == false then
        LootTracker_ExportData = LootTracker_ExportData 
                              .. " - " 
                              .. itemEntry[LootTracker_dbfield_cost]
      end
      
      LootTracker_ExportData = LootTracker_ExportData .. "\r\n"
    end
    
    -- Place final text into the export box
    LootTracker_ExportRaidFrameEditBox1:SetText(LootTracker_ExportData)
    ShowUIPanel(LootTracker_ExportRaidFrame, 1)
  end
end


---------------------------------------------------------
--LootTracker ItemBrowse Frame Functions
---------------------------------------------------------
function LootTracker_Main_OnShow()

end

-- this function is called when the frame starts being dragged around
function LootTracker_Main_OnMouseDown(button)
	if (button == "LeftButton") then
		this:StartMoving();
	end
end

-- this function is called when the frame is stopped being dragged around
function LootTracker_Main_OnMouseUp(button)
	if (button == "LeftButton") then
		this:StopMovingOrSizing()

	end
end

function LootTracker_RaidIDButton_OnClick()
	if LootTracker_RaidIDFrame:IsVisible() then
		LootTracker_RaidIDFrame:Hide()
	else
		LootTracker_RaidIDScrollFrame_Update()
		ShowUIPanel(LootTracker_RaidIDFrame, 1)
	end
end

function LootTracker_BuildBrowseTable()
	LootTracker_BrowseTable = {}
	--read ReadSearch editbox
	raidid = getglobal("LootTracker_RaidIDBox"):GetText()
		
	--check if raid exists
	raidfound = false
	if raidid and (string.len(raidid) >= 1) then
		for k in pairs(LootTrackerDB) do
			if k == raidid then
				raidfound = true
			end
		end
	end
	
	if raidfound == true then

		for index in LootTrackerDB[raidid] do
			LootTracker_BrowseTable[index] = {}
			LootTracker_BrowseTable[index].timestamp = LootTrackerDB[raidid][index][LootTracker_dbfield_timestamp]
			LootTracker_BrowseTable[index].playername = LootTrackerDB[raidid][index][LootTracker_dbfield_playername]

			if LootTrackerDB[raidid][index][LootTracker_dbfield_rarity] == "common" then
				browse_rarityhexlink = LootTracker_color_common
			elseif LootTrackerDB[raidid][index][LootTracker_dbfield_rarity] == "uncommon" then
				browse_rarityhexlink = LootTracker_color_uncommon
			elseif LootTrackerDB[raidid][index][LootTracker_dbfield_rarity] == "rare" then
				browse_rarityhexlink = LootTracker_color_rare
			elseif LootTrackerDB[raidid][index][LootTracker_dbfield_rarity] == "epic" then
				browse_rarityhexlink = LootTracker_color_epic
			elseif LootTrackerDB[raidid][index][LootTracker_dbfield_rarity] == "legendary" then
				browse_rarityhexlink = LootTracker_color_legendary
			end
			--building the itemlink
			browse_itemlink = "|c" .. browse_rarityhexlink .. "|Hitem:" .. LootTrackerDB[raidid][index][LootTracker_dbfield_itemid] .. ":0:0:0|h[" .. LootTrackerDB[raidid][index][LootTracker_dbfield_itemname] .. "]|h|r"
			
			LootTracker_BrowseTable[index].itemname = browse_itemlink
			-- for sorting
			LootTracker_BrowseTable[index].itemnamenolink = LootTrackerDB[raidid][index][LootTracker_dbfield_itemname]
			
			--rest
			LootTracker_BrowseTable[index].cost = LootTrackerDB[raidid][index][LootTracker_dbfield_cost]
			LootTracker_BrowseTable[index].offspec = LootTrackerDB[raidid][index][LootTracker_dbfield_offspec]
			LootTracker_BrowseTable[index].de = LootTrackerDB[raidid][index][LootTracker_dbfield_de]
			--for tooltip
			LootTracker_BrowseTable[index].itemid = LootTrackerDB[raidid][index][LootTracker_dbfield_itemid]
			--for itemedit GUI
			LootTracker_BrowseTable[index].oldplayergp = LootTrackerDB[raidid][index][LootTracker_dbfield_oldplayergp]
			LootTracker_BrowseTable[index].newplayergp = LootTrackerDB[raidid][index][LootTracker_dbfield_newplayergp]
			LootTracker_BrowseTable[index].raidid = raidid
			LootTracker_BrowseTable[index].originalindex = index
		end
	
		--sorting
		if sortfield == LootTracker_dbfield_timestamp then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.timestamp < b.timestamp end)
			elseif sortdirection == "descending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.timestamp > b.timestamp end)
			end
		elseif sortfield == LootTracker_dbfield_playername then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.playername < b.playername end)
			elseif sortdirection == "descending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.playername > b.playername end)
			end
		elseif sortfield == LootTracker_dbfield_itemname then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.itemnamenolink < b.itemnamenolink end)
			elseif sortdirection == "descending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return a.itemnamenolink > b.itemnamenolink end)
			end
		elseif sortfield == LootTracker_dbfield_cost then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return tonumber(a.cost) < tonumber(b.cost) end)
			elseif sortdirection == "descending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return tonumber(a.cost) > tonumber(b.cost) end)
			end
		elseif sortfield == LootTracker_dbfield_offspec then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return tostring(a.offspec) < tostring(b.offspec) end)
			elseif sortdirection == "descending" then
			table.sort(LootTracker_BrowseTable, function(a,b) return tostring(a.offspec) > tostring(b.offspec) end)
			end
		elseif sortfield == LootTracker_dbfield_de then
			if sortdirection == "ascending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return tostring(a.de) < tostring(b.de) end)
			elseif sortdirection == "descending" then
				table.sort(LootTracker_BrowseTable, function(a,b) return tostring(a.de) > tostring(b.de) end)
			end
		else
			table.sort(LootTracker_BrowseTable, function(a,b) return a.timestamp < b.timestamp end)
		end
		
	else
		getglobal("LootTracker_TotalLootText"):SetText("no Raid found: " .. raidid)
		getglobal("LootTracker_TotalLootTextValue"):SetText("0 items")
		if (arg1) and (arg1 == "LeftButton") then -- we came here from search button
			if not LootTracker_RaidIDFrame:IsVisible() then
				LootTracker_RaidIDScrollFrame_Update()
				ShowUIPanel(LootTracker_RaidIDFrame, 1)
			end
		end
	end
	--call for GUI Update
	LootTracker_ListScrollFrame_Update()
end

function LootTracker_ListScrollFrame_Update()
	--set GUI Total Loots (per Raid)
	if not LootTracker_BrowseTable then 
		LootTracker_BrowseTable = {}
	end
	
	if not raidid then
		raidid = getglobal("LootTracker_RaidIDBox"):GetText()
	end
	
	local maxlines = getn(LootTracker_BrowseTable)
	getglobal("LootTracker_TotalLootText"):SetText("Raid: " .. raidid .. ":")
	if maxlines == 1 then
		getglobal("LootTracker_TotalLootTextValue"):SetText(maxlines .. " item")
	else
		getglobal("LootTracker_TotalLootTextValue"):SetText(maxlines .. " items")
	end
	
	
	local line; -- 1 through 20 of our window to scroll
	local lineplusoffset; -- an index into our data calculated from the scroll offset
   
	 -- maxlines is max entries, 1 is number of lines, 16 is pixel height of each line
	FauxScrollFrame_Update(LootTracker_ListScrollFrame, maxlines, 1, 16)


	for line=1,20 do
		 lineplusoffset = line + FauxScrollFrame_GetOffset(LootTracker_ListScrollFrame);
		 if lineplusoffset <= maxlines then
			getglobal("LootTracker_List"..line.."TextTimestamp"):SetText(LootTracker_BrowseTable[lineplusoffset].timestamp)
			getglobal("LootTracker_List"..line.."TextPlayername"):SetText(LootTracker_BrowseTable[lineplusoffset].playername)
			getglobal("LootTracker_List"..line.."TextItemName"):SetText(LootTracker_BrowseTable[lineplusoffset].itemname)
			getglobal("LootTracker_List"..line.."TextCost"):SetText(LootTracker_BrowseTable[lineplusoffset].cost)
			
			if LootTracker_BrowseTable[lineplusoffset].offspec == true then
				getglobal("LootTracker_List"..line.."TextOffspec"):SetText("yes")
			else
				getglobal("LootTracker_List"..line.."TextOffspec"):SetText("no")
			end
			
			if LootTracker_BrowseTable[lineplusoffset].de == true then 
				getglobal("LootTracker_List"..line.."TextDE"):SetText("yes")
			else
				getglobal("LootTracker_List"..line.."TextDE"):SetText("no")
			end
			
			getglobal("LootTracker_List"..line):Show()
		 else
			getglobal("LootTracker_List"..line):Hide()
		 end
   end
end

--fires when the headline in the browse frame list is clicked
function LootTracker_SortTimestamp_OnClick(button)
	if sortfield == LootTracker_dbfield_timestamp and sortdirection == "ascending" then
		sortfield = LootTracker_dbfield_timestamp
		sortdirection = "descending"
	else
		sortfield = LootTracker_dbfield_timestamp
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

function LootTracker_SortPlayername_OnClick(button)
	if 	sortfield == LootTracker_dbfield_playername and sortdirection == "ascending" then
		sortfield = LootTracker_dbfield_playername
		sortdirection = "descending"
	else
		sortfield = LootTracker_dbfield_playername
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

function LootTracker_SortItemName_OnClick(button)
	if 	sortfield == LootTracker_dbfield_itemname and sortdirection == "ascending" then
	sortfield = LootTracker_dbfield_itemname
		sortdirection = "descending"
	else
	sortfield = LootTracker_dbfield_itemname
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

function LootTracker_SortCost_OnClick(button)
	if 	sortfield == LootTracker_dbfield_cost and sortdirection == "ascending" then
		sortfield = LootTracker_dbfield_cost
		sortdirection = "descending"
	else
		sortfield = LootTracker_dbfield_cost
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

function LootTracker_SortOffspec_OnClick(button)
	if 	sortfield == LootTracker_dbfield_offspec and sortdirection == "ascending" then
		sortfield = LootTracker_dbfield_offspec
		sortdirection = "descending"
	else
		sortfield = LootTracker_dbfield_offspec
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

function LootTracker_SortDE_OnClick(button)
	if 	sortfield == LootTracker_dbfield_de and sortdirection == "ascending" then
		sortfield = LootTracker_dbfield_de
		sortdirection = "descending"
	else
		sortfield = LootTracker_dbfield_de
		sortdirection = "ascending"
	end
	LootTracker_BuildBrowseTable()
end

--fires when a line in the browse frame list is clicked
function LootTracker_ListButton_OnClick(button, index)
	 if button == "LeftButton" then
		if( IsShiftKeyDown() and ChatFrameEditBox:IsVisible() ) then
			local link = LootTracker_BrowseTable[index].itemname
			ChatFrameEditBox:Insert(link)
		end
		
	 elseif button == "RightButton" then
		LootTracker_ItemEdit(index)
	 end
end

--mouseover a line in the itemlist
function LootTracker_ListButton_OnEnter(index)
	local itemid = LootTracker_BrowseTable[index].itemid
	
	if itemid then
		LootTracker_Tooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
		LootTracker_Tooltip:SetHyperlink("item:" .. itemid .. ":0:0:0")
		LootTracker_Tooltip:Show()
	end
end

function LootTracker_ListButton_OnLeave()
	if LootTracker_Tooltip:IsOwned(this) then
		LootTracker_Tooltip:ClearLines()
		LootTracker_Tooltip:Hide()	
	end
end

function LootTracker_ExportButton_OnClick()
	raidid = getglobal("LootTracker_RaidIDBox"):GetText()
	
	--LootTracker_ExportRaid(raidid, LootTrackerOptions["timestamp"], LootTrackerOptions["cost"])

	if LootTrackerOptions["timestamp"] == false and LootTrackerOptions["cost"] == false then
		LootTracker_ExportRaid(raidid, false, false)
	elseif LootTrackerOptions["timestamp"] == false and LootTrackerOptions["cost"] == true then
		LootTracker_ExportRaid(raidid, false, true)
	elseif LootTrackerOptions["timestamp"] == true and LootTrackerOptions["cost"] == false then
		LootTracker_ExportRaid(raidid, true, false)
	elseif LootTrackerOptions["timestamp"] ==  true and LootTrackerOptions["cost"] == true then
		LootTracker_ExportRaid(raidid, true, true)
	end
end

---------------------------------------------------------
--LootTracker RaidID Browse Frame Functions
---------------------------------------------------------

--fires when a line in the Raid ID browse frame list is clicked
function LootTracker_RaidIDListButton_OnClick(button)
  local raidid_browse = getglobal(this:GetName().."TextRaidID"):GetText();
  if button == "RightButton" and IsControlKeyDown() then
    LootTrackerDB[raidid_browse] = nil
    getglobal("LootTracker_RaidIDBox"):SetText("")
  elseif button == "LeftButton" and IsShiftKeyDown() then
    local _,_,ts_source,zone_source = string.find(raidid_browse,"^(%d+%-%d+%-%d+)%s+(.+)$")
    if not (zone_source) then
      DEFAULT_CHAT_FRAME:AddMessage("LootTracker: Merged raids can\'t be source for merge.")
      return
    end
    local raidid_mergetarget
    for i,id in ipairs(LootTracker_RaidIDBrowseTable) do
      if id == raidid_browse then
        raidid_mergetarget = LootTracker_RaidIDBrowseTable[i+1]
        if raidid_mergetarget ~= nil then
          local _,_,ts_target,zone_target = string.find(raidid_mergetarget,"^(%d+%-%d+%-%d+)%s+(.+)$")
          if not (zone_target) then
            DEFAULT_CHAT_FRAME:AddMessage("LootTracker: Merged raids can\'t be target for merge.")
            return
          end
          if zone_source == zone_target then
            local raidid_merged = string.format("%s(%s)%s",ts_target,ts_source,zone_target)
            if LootTrackerDB[raidid_merged] == nil then LootTrackerDB[raidid_merged] = {} end
            local i, loot = next(LootTrackerDB[raidid_browse],nil)
            while (i) do
              table.insert(LootTrackerDB[raidid_merged],loot)
              i, loot = next(LootTrackerDB[raidid_browse], i)
            end
            LootTrackerDB[raidid_browse] = nil
            i, loot = next(LootTrackerDB[raidid_mergetarget],nil)
            while (i) do
              table.insert(LootTrackerDB[raidid_merged],loot)
              i, loot = next(LootTrackerDB[raidid_mergetarget],i)
            end
            LootTrackerDB[raidid_mergetarget] = nil
            getglobal("LootTracker_RaidIDBox"):SetText(raidid_merged)
            break
          else
            DEFAULT_CHAT_FRAME:AddMessage("LootTracker: You can only merge raids to the same zone.")
            return
          end
        else
          DEFAULT_CHAT_FRAME:AddMessage("LootTracker: Raid below doesn\'t exist or not visible. Scroll?")
          return
        end
      end
    end
  else
		getglobal("LootTracker_RaidIDBox"):SetText(raidid_browse)
  end
	
	HideUIPanel(LootTracker_RaidIDFrame, 1)
	LootTracker_BuildBrowseTable()
	
end

function LootTracker_RaidIDListButton_OnEnter()
	LootTracker_Tooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	LootTracker_Tooltip:SetText("RaidID Browser")
	--LootTracker_Tooltip:AddLine(getglobal("LootTracker_RaidIDList"..(tostring(this:GetID()-1)).."TextRaidID"):GetText())
	--LootTracker_Tooltip:AddLine(getglobal(this:GetName().."TextRaidID"):GetText())
	LootTracker_Tooltip:AddDoubleLine("Click","Load this RaidID in browser",255/255,140/255,0)
	LootTracker_Tooltip:AddDoubleLine("Shift-Click","Merge RaidID into the one below",255/255,140/255,0)
	LootTracker_Tooltip:AddDoubleLine("Ctrl-Right-Click","Remove this RaidID (|cffff0000No Undo|r)",255/255,140/255,0)
	LootTracker_Tooltip:Show()
end

function LootTracker_RaidIDListButton_OnLeave()
	if LootTracker_Tooltip:IsOwned(this) then
		LootTracker_Tooltip:ClearLines()
		LootTracker_Tooltip:Hide()
	end
end

--Raid ID Browser ScrollBar
function LootTracker_RaidIDScrollFrame_Update()

	LootTracker_RaidIDBrowseTable = {}
		
	for k in pairs(LootTrackerDB) do
		table.insert(LootTracker_RaidIDBrowseTable, k)
	end

	local maxlines = getn(LootTracker_RaidIDBrowseTable)
	local line; -- 1 through 10 of our window to scroll
	local lineplusoffset; -- an index into our data calculated from the scroll offset
   
	 -- maxlines is max entries, 1 is number of lines, 16 is pixel height of each line
	FauxScrollFrame_Update(LootTracker_RaidIDScrollFrame, maxlines, 1, 16)

	--sort table
	table.sort(LootTracker_RaidIDBrowseTable, function(a, b) return a > b end)
	--table.sort(LootTracker_RaidIDBrowseTable)

	for line=1,10 do
		 lineplusoffset = line + FauxScrollFrame_GetOffset(LootTracker_RaidIDScrollFrame);
		 if lineplusoffset <= maxlines then
			getglobal("LootTracker_RaidIDList"..line.."TextRaidID"):SetText(LootTracker_RaidIDBrowseTable[lineplusoffset])
			getglobal("LootTracker_RaidIDList"..line):Show()
		 else
			getglobal("LootTracker_RaidIDList"..line):Hide()
		 end
   end
end

---------------------------------------------------------
--LootTracker ItemEdit Frame Functions
---------------------------------------------------------
function LootTracker_ItemEdit(index)
	--fill window then open
	getglobal("LootTracker_ItemEditFrameItemName"):SetText(LootTracker_BrowseTable[index].itemname)
	getglobal("LootTracker_ItemEditFramePlayerName"):SetText(LootTracker_BrowseTable[index].playername)
	getglobal("LootTracker_ItemEditFrameOldPlayerGP"):SetText(LootTracker_BrowseTable[index].oldplayergp)
	getglobal("LootTracker_ItemEditFrameCost"):SetText(LootTracker_BrowseTable[index].cost)
	getglobal("LootTracker_ItemEditFrameNewPlayerGP"):SetText(LootTracker_BrowseTable[index].newplayergp)
	
	if LootTracker_BrowseTable[index].offspec then
		getglobal("LootTracker_ItemEditFrameOption1"):SetChecked(true)
	else
		getglobal("LootTracker_ItemEditFrameOption1"):SetChecked(false)
	end
	
	if LootTracker_BrowseTable[index].de then
		getglobal("LootTracker_ItemEditFrameOption2"):SetChecked(true)
	else
		getglobal("LootTracker_ItemEditFrameOption2"):SetChecked(false)
	end
	
	--fill vars for itemedit
	LootTracker_ItemEditDB = {
	raidid = LootTracker_BrowseTable[index].raidid,
	index = index,
	originalindex = LootTracker_BrowseTable[index].originalindex,
	timestamp = LootTracker_BrowseTable[index].timestamp,
	itemname = LootTracker_BrowseTable[index].itemname,
	itemid = LootTracker_BrowseTable[index].itemid,
	playername = LootTracker_BrowseTable[index].playername,
	oldplayergp = LootTracker_BrowseTable[index].oldplayergp,
	cost = LootTracker_BrowseTable[index].cost,
	newplayergp = LootTracker_BrowseTable[index].newplayergp
	}
	
	
	ShowUIPanel(LootTracker_ItemEditFrame, 1)
end

function LootTracker_ItemEditCheckButton_OnClick(id)
	--offspec
	if id == 1 then
		if LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_offspec] == true then
			local newcost = LootTracker_GetCosts(LootTracker_ItemEditDB.itemid)
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_offspec]	= false
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost] = newcost
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_newplayergp] = LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_oldplayergp] + LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost]

		elseif LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_offspec] == false then
			local _,newcost = LootTracker_GetCosts(LootTracker_ItemEditDB.itemid)
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_offspec]	= true
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost] = newcost
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_newplayergp] = LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_oldplayergp] + LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost]
		end
	--disenchant
	elseif id == 2 then
		if LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_de] == true then
		
			--recalc costs
			cost_orig = LootTracker_GetCosts(LootTracker_ItemEditDB.itemid)
			
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_de]	= false
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost] = cost_orig
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_newplayergp] = LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_oldplayergp] + LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost]
		
		elseif LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_de] == false then
			
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_de]	= true
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost] = "0"
			LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_newplayergp] = LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_oldplayergp] + LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost]
		end
	end
	
	getglobal("LootTracker_ItemEditFrameOldPlayerGP"):SetText(LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_oldplayergp])
	getglobal("LootTracker_ItemEditFrameCost"):SetText(LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_cost])
	getglobal("LootTracker_ItemEditFrameNewPlayerGP"):SetText(LootTrackerDB[LootTracker_ItemEditDB.raidid][LootTracker_ItemEditDB.originalindex][LootTracker_dbfield_newplayergp])
	LootTracker_BuildBrowseTable()
end
		

---------------------------------------------------------
--LootTracker Options Frame Functions
---------------------------------------------------------
function LootTracker_OptionsButton_OnClick()
	if LootTracker_OptionsFrame:IsVisible() then
		LootTracker_OptionsFrame:Hide()
	else
		ShowUIPanel(LootTracker_OptionsFrame, 1)
	end
end

function LootTracker_OptionsFrame_OnShow()
	if LootTrackerOptions["enabled"] == true then
		getglobal("LootTracker_OptionsFrameOption1"):SetChecked(true)
		getglobal("LootTracker_OptionsFrameOption2"):Enable()
		getglobal("LootTracker_OptionsFrameOption3"):Enable()
		getglobal("LootTracker_OptionsFrameOption4"):Enable()
		getglobal("LootTracker_OptionsFrameOption5"):Enable()
		getglobal("LootTracker_OptionsFrameOption6"):Enable()
	else
		getglobal("LootTracker_OptionsFrameOption1"):SetChecked(false)
		getglobal("LootTracker_OptionsFrameOption2"):Disable()
		getglobal("LootTracker_OptionsFrameOption3"):Disable()
		getglobal("LootTracker_OptionsFrameOption4"):Disable()
		getglobal("LootTracker_OptionsFrameOption5"):Disable()
		getglobal("LootTracker_OptionsFrameOption6"):Disable()
	end
	if LootTrackerOptions["common"] == true then
		getglobal("LootTracker_OptionsFrameOption2"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption2"):SetChecked(false)
	end
	if LootTrackerOptions["uncommon"] == true then
		getglobal("LootTracker_OptionsFrameOption3"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption3"):SetChecked(false)
	end
	if LootTrackerOptions["rare"] == true then
		getglobal("LootTracker_OptionsFrameOption4"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption4"):SetChecked(false)
	end
	if LootTrackerOptions["epic"] == true then
		getglobal("LootTracker_OptionsFrameOption5"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption5"):SetChecked(false)
	end
	if LootTrackerOptions["legendary"] == true then
		getglobal("LootTracker_OptionsFrameOption6"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption6"):SetChecked(false)
	end
	if LootTrackerOptions["timestamp"] == true then
		getglobal("LootTracker_OptionsFrameOption7"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption7"):SetChecked(false)
	end
	if LootTrackerOptions["cost"] == true then
		getglobal("LootTracker_OptionsFrameOption8"):SetChecked(true)
	else
		getglobal("LootTracker_OptionsFrameOption8"):SetChecked(false)
	end
end

function LootTracker_OptionCheckButton_OnClick(id)
	if id == 1 then
		if LootTrackerOptions["enabled"] == true then
			LootTrackerOptions["enabled"] = false
			
			--disable checkbuttons
			getglobal("LootTracker_OptionsFrameOption2"):Disable()
			getglobal("LootTracker_OptionsFrameOption3"):Disable()
			getglobal("LootTracker_OptionsFrameOption4"):Disable()
			getglobal("LootTracker_OptionsFrameOption5"):Disable()
			getglobal("LootTracker_OptionsFrameOption6"):Disable()
		else
			LootTrackerOptions["enabled"] = true
			
			--enable checkbuttons
			getglobal("LootTracker_OptionsFrameOption2"):Enable()
			getglobal("LootTracker_OptionsFrameOption3"):Enable()
			getglobal("LootTracker_OptionsFrameOption4"):Enable()
			getglobal("LootTracker_OptionsFrameOption5"):Enable()
			getglobal("LootTracker_OptionsFrameOption6"):Enable()
		end
	elseif id == 2 then
		if LootTrackerOptions["common"] == true then
			LootTrackerOptions["common"] = false
		else
			LootTrackerOptions["common"] = true
		end
	elseif id == 3 then
		if LootTrackerOptions["uncommon"] == true then
			LootTrackerOptions["uncommon"] = false
		else
			LootTrackerOptions["uncommon"] = true
		end
	elseif id == 4 then
		if LootTrackerOptions["rare"] == true then
			LootTrackerOptions["rare"] = false
		else
			LootTrackerOptions["rare"] = true
		end
	elseif id == 5 then
		if LootTrackerOptions["epic"] == true then
			LootTrackerOptions["epic"] = false
		else
			LootTrackerOptions["epic"] = true
		end
	elseif id == 6 then
		if LootTrackerOptions["legendary"] == true then
			LootTrackerOptions["legendary"] = false
		else
			LootTrackerOptions["legendary"] = true
		end
	elseif id == 7 then
		if LootTrackerOptions["timestamp"] == true then
			LootTrackerOptions["timestamp"] = false
		else
			LootTrackerOptions["timestamp"] = true
		end
	elseif id == 8 then
		if LootTrackerOptions["cost"] == true then
			LootTrackerOptions["cost"] = false
		else
			LootTrackerOptions["cost"] = true
		end
	end
end

function LootTracker_OptionsReset_OnClick() 
	LootTracker_ResetDB()
end

function LootTracker_OptionsReset_OnEnter()
  LootTracker_Tooltip:SetOwner(this, "ANCHOR_TOPLEFT")
  LootTracker_Tooltip:SetText("Reset DB")
  LootTracker_Tooltip:AddLine("Deletes whole Raid DB (|cffff0000No Undo|r)",1,1,1,1)
  LootTracker_Tooltip:Show()  
end

function LootTracker_OptionsReset_OnLeave()
  if LootTracker_Tooltip:IsOwned(this) then
    LootTracker_Tooltip:ClearLines()
    LootTracker_Tooltip:Hide()  
  end  
end

function LootTracker_OptionsRecalc_OnClick()
	LootTracker_RecalcDB()
end

function LootTracker_OptionsRecalc_OnEnter()
  LootTracker_Tooltip:SetOwner(this, "ANCHOR_TOPLEFT")
  LootTracker_Tooltip:SetText("Recalculate DB")
  LootTracker_Tooltip:AddLine("Updates GP costs for all Raids to current price list",1,1,1,1)
  LootTracker_Tooltip:Show() 
end

function LootTracker_OptionsRecalc_OnLeave()
  if LootTracker_Tooltip:IsOwned(this) then
    LootTracker_Tooltip:ClearLines()
    LootTracker_Tooltip:Hide()  
  end  
end
