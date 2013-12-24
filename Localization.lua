local locale, _, A = GetLocale(), ...

A.L = setmetatable({ }, { __index = function(_, key) return key end })

if locale == "frFR" then -- French
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "deDE" then -- German
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "itIT" then -- Italian
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "ptBR" then -- Brazilian Portuguese
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "esMX" then -- Latin American Spanish
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "esES" then -- Spanish
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "ruRU" then -- Russian
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "koKR" then -- Korean
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "zhCN" then -- Simplified Chinese
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

elseif locale == "zhTW" then -- Traditional Chinese
	L["GotS Healing"] = "GotS Healing"
	L["GotS Efficiency"] = "GotS Efficiency"

end