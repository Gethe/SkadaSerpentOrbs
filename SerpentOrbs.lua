local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local NAME, SerpentOrbs = ...
local Skada = Skada

local modGotSHeal = Skada:NewModule(SerpentOrbs.L["GotS Healing"])
local orbBreakdown = Skada:NewModule(SerpentOrbs.L["Orb Healing"])
local modGotSWaste = Skada:NewModule(SerpentOrbs.L["GotS Efficiency"])

local function log_heal(set, heal)
	-- Get the player from set.
	local player = Skada:get_player(set, heal.playerid, heal.playername)
	if player then
		-- Subtract overhealing
		local amount = math.max(0, heal.orbamount - heal.orboverhealing)
		-- Add absorbed
		amount = amount + heal.orbabsorbed

		-- Add to player total.
		player.orbhealing = player.orbhealing + amount
		player.orboverhealing = player.orboverhealing + heal.orboverhealing
		player.orbhealingabsorbed = player.orbhealingabsorbed + heal.orbabsorbed
		player.orbhits = player.orbhits + 1

		-- Also add to set total damage.
		set.orbhealing = set.orbhealing + amount
		set.orboverhealing = set.orboverhealing + heal.orboverhealing
		set.orbhealingabsorbed = set.orbhealingabsorbed + heal.orbabsorbed
		set.orbhits = set.orbhits + 1

		-- Add to recipient healing.
		do
			if heal.dstName then
				local orbhealed = player.orbhealed[heal.dstName]

				-- Create recipient if it does not exist.
				if not orbhealed then
					local _, className = UnitClass(heal.dstName)
					orbhealed = {class = className, amount = 0}
					player.orbhealed[heal.dstName] = orbhealed
				end

				orbhealed.amount = orbhealed.amount + amount
			end
		end

		-- Add to spell healing
		do
			if heal.spellid == 124041 then --orb pickup
				heal.spellname = "Gift of the Serpent (Pickup)"
			elseif heal.spellid == 135920 then --orb explosion
				heal.spellname = "Gift of the Serpent (Burst)"
			end

			local spell = player.orbhealingspells[heal.spellname]

			-- Create spell if it does not exist.
			if not spell then
				spell = {id = heal.spellid, name = heal.spellname, orbhits = 0, orbhealing = 0, orboverhealing = 0, orbabsorbed = 0, orbcritical = 0, orbmin = nil, orbmax = 0}
				player.orbhealingspells[heal.spellname] = spell
			end

			spell.orbhealing = spell.orbhealing + amount
			if heal.orbcritical then
				spell.orbcritical = spell.orbcritical + 1
			end
			spell.orboverhealing = spell.orboverhealing + heal.orboverhealing
			spell.orbabsorbed = spell.orbabsorbed + heal.orbabsorbed

			spell.orbhits = (spell.orbhits or 0) + 1

			if not spell.orbmin or amount < spell.orbmin then
				spell.orbmin = amount
			end
			if not spell.orbmax or amount > spell.orbmax then
				spell.orbmax = amount
			end
		end
	end
end

local function log_cast(set, cast)
	-- Get the player from set.
	local player = Skada:get_player(set, cast.playerid, cast.playername)
	if player then
		-- Add to player orb casts.
		if cast.spellId == 135920 then -- Orb Explosion
			player.orbburst = player.orbburst + 1
			set.orbburst = set.orbburst + 1
		end
	end
end

local heal = {}
local cast = {}

local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Healing
	local spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical = ...

	if (spellId == 124041) or (spellId == 135920) then  -- orb pickup or explosion
		heal.playername = dstName
		heal.playerid = dstGUID
		heal.srcName = srcName
		heal.spellid = spellId
		heal.spellname = spellName
		heal.orbamount = samount
		heal.orboverhealing = soverhealing
		heal.orbcritical = scritical
		heal.orbabsorbed = absorbed

		Skada:FixPets(heal)
		log_heal(Skada.current, heal)
		log_heal(Skada.total, heal)
	end
end

local function SpellCast(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Healing
	local spellId, spellName, spellSchool = ...

	-- Warlords: GotS summon spellId = 119031

	if (spellId == 124041) or (spellId == 135920) then  -- orb pickup or explosion
		cast.dstName = dstName
		cast.playerid = srcGUID
		cast.playername = srcName
		cast.spellid = spellId
		cast.spellname = spellName

		Skada:FixPets(cast)
		log_cast(Skada.current, cast)
		log_cast(Skada.total, cast)
	end
end



local function getHPS(set, player)
	local totaltime = Skada:PlayerActiveTime(set, player)

	return player.orbhealing / math.max(1,totaltime)
end

local function getHPSByValue(set, player, healing)
	local totaltime = Skada:PlayerActiveTime(set, player)

	return healing / math.max(1,totaltime)
end

local function getRaidHPS(set)
	if set.time > 0 then
		return set.orbhealing / math.max(1, set.time)
	else
		local endtime = set.endtime or time()
		return set.orbhealing / math.max(1, endtime - set.starttime)
	end
end

local function spell_tooltip(win, id, label, tooltip)
	local player = Skada:find_player(win:get_selected_set(), orbBreakdown.playerid)
	if player then
		local spell = player.orbhealingspells[label]
		if spell then
			tooltip:AddLine(player.name.." - "..label)
			if spell.orbmax and spell.orbmin then
				tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(spell.orbmin), 255,255,255,255,255,255)
				tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(spell.orbmax), 255,255,255,255,255,255)
			end
			tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(spell.orbhealing / spell.orbhits), 255,255,255,255,255,255)
			if spell.orbhits then
				tooltip:AddDoubleLine(L["Critical"]..":", ("%02.1f%%"):format(spell.orbcritical / spell.orbhits * 100), 255,255,255,255,255,255)
			end
			if spell.orbhits then
				tooltip:AddDoubleLine(L["Overhealing"]..":", ("%02.1f%%"):format(spell.orboverhealing / (spell.orboverhealing + spell.orbhealing) * 100), 255,255,255,255,255,255)
			end
			if spell.orbhits and spell.orbabsorbed then
				tooltip:AddDoubleLine(L["Absorbed"]..":", ("%02.1f%%"):format(spell.orbabsorbed / (spell.orboverhealing + spell.orbhealing) * 100), 255,255,255,255,255,255)
			end
		end
	end
end
-- Number of full orbs vs explosions
function orbBreakdown:Enter(win, id, label)
	orbBreakdown.playerid = id
	orbBreakdown.title = SerpentOrbs.L["Orb Healing for"].." "..label
end


function orbBreakdown:Update(win, set)
	-- View spells for this player.

	local player = Skada:find_player(set, self.playerid)
	local nr = 1
	local max = 0

	if player then
		for spellname, spell in pairs(player.orbhealingspells) do
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d

			d.id = spell.id
			d.label = spell.name
			d.value = spell.orbhealing
			d.valuetext = Skada:FormatValueText(
											Skada:FormatNumber(spell.orbhealing), self.metadata.columns.Healing,
											string.format("%d", spell.orbhits), self.metadata.columns.Percent
										)
			local _, _, icon = GetSpellInfo(spell.id)
			d.icon = icon
			d.spellid = spell.id

			if spell.orbhealing > max then
				max = spell.orbhealing
			end

			nr = nr + 1
		end
	end

	win.metadata.hasicon = true
	win.metadata.maxvalue = max
end

function modGotSHeal:Update(win, set)
	local nr = 1
	local max = 0

	for i, player in ipairs(set.players) do
		if player.orbhealing > 0 then

			local d = win.dataset[nr] or {}
			win.dataset[nr] = d

			d.id = player.id
			d.label = player.name
			d.value = player.orbhealing

			d.valuetext = Skada:FormatValueText(
											Skada:FormatNumber(player.orbhealing), self.metadata.columns.Healing,
											string.format("%d", player.orbhits), self.metadata.columns.Percent
										)
			d.class = player.class

			if player.orbhealing > max then
				max = player.orbhealing
			end

			nr = nr + 1
		end
	end

	win.metadata.maxvalue = max
end

function modGotSHeal:OnEnable()
	modGotSHeal.metadata		= {showspots = true, click1 = orbBreakdown, columns = {Healing = true, Percent = true}}
	orbBreakdown.metadata	= {tooltip = spell_tooltip, columns = {Healing = true, Percent = true}}
	modGotSWaste.metadata	= {tooltip = spell_tooltip, columns = {Healing = true, HPS = true, Percent = true}}

	-- handlers for Healing spells
	Skada:RegisterForCL(SpellHeal, 'SPELL_HEAL', {dst_is_interesting = true})
	Skada:RegisterForCL(SpellCast, 'SPELL_CAST_SUCCESS', {src_is_interesting = true})

	Skada:AddMode(self)
end

function modGotSHeal:OnDisable()
	Skada:RemoveMode(self)
end

function modGotSHeal:AddToTooltip(set, tooltip)
	local endtime = set.endtime
	if not endtime then
		endtime = time()
	end
	local raidhps = set.orbhealing / (endtime - set.starttime + 1)
 	GameTooltip:AddDoubleLine(L["HPS"], ("%02.1f"):format(raidhps), 1,1,1)
end

function modGotSHeal:GetSetSummary(set)
	return Skada:FormatValueText(
		Skada:FormatNumber(set.orbhealing), self.metadata.columns.Healing,
		string.format("%d", set.orbhits), self.metadata.columns.Percent
	)
end

-- Called by Skada when a new player is added to a set.
function modGotSHeal:AddPlayerAttributes(player)
	player.orbhealed = player.orbhealed or {}						-- Stored healing per recipient
	player.orbhealing = player.orbhealing or 0					-- Total healing
	player.orbhealingspells = player.orbhealingspells or {}		-- Healing spells
	player.orboverhealing = player.orboverhealing or 0			-- Overheal total
	player.orbhealingabsorbed = player.orbhealingabsorbed or 0	-- Absorbed total
	player.orbhits = player.orbhits or 0 						-- Total Hits

	-- update any pre-existing orbhealingspells for new properties
	local _, orbheal, orbhealed
	for _, orbheal in pairs(player.orbhealingspells) do
		heal.orbabsorbed = heal.orbabsorbed or 0 		-- Amount of healing that was absorbed
	end
end

-- Called by Skada when a new set is created.
function modGotSHeal:AddSetAttributes(set)
	set.orbhealing = set.orbhealing or 0
	set.orboverhealing = set.orboverhealing or 0
	set.orbhealingabsorbed = set.orbhealingabsorbed or 0
	set.orbhits = set.orbhits or 0
end


-- Spell view of a player.
function modGotSWaste:Update(win, set)
	local max = 0
	local nr = 1

	for i, player in ipairs(set.players) do
		if player.orbburst > 0 then

			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			d.value = player.orbburst
			d.label = player.name
			d.class = player.class
			d.id = player.id
			d.valuetext = Skada:FormatValueText(
								string.format("%d", player.orbburst), self.metadata.columns.Healing,
								string.format("%d", player.orbhealingspells["Gift of the Serpent (Burst)"].orbhits), self.metadata.columns.HPS,
								string.format("%02.1f%%", player.orbhealingspells["Gift of the Serpent (Burst)"].orbhits / player.orbburst * 100), self.metadata.columns.Percent
							)
			if player.orbburst > max then
				max = player.orbburst
			end
			nr = nr + 1
		end
	end

	win.metadata.maxvalue = max
end

function modGotSWaste:OnEnable()
	Skada:AddMode(self)
end

function modGotSWaste:OnDisable()
	Skada:RemoveMode(self)
end

function modGotSWaste:AddPlayerAttributes(player)
	player.orbburst = player.orbburst or 0
end

-- Called by Skada when a new set is created.
function modGotSWaste:AddSetAttributes(set)
	set.orbburst = set.orbburst or 0
end

function modGotSWaste:GetSetSummary(set)
	return set.orbburst
end
