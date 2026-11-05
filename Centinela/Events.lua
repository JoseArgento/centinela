local ADDON, ns = ...
local L = ns.L

local W, G = ns.Watch, ns.Gold

-- Login: the check runs a few seconds in (addons that load late get counted), then every ten minutes.
local CHECK_DELAY, CHECK_EVERY = 5, 600

local handlers = {
	MAIL_SHOW = G.Start,
	MAIL_CLOSED = G.Stop,
	TRADE_SHOW = G.Start,
	TRADE_CLOSED = G.Stop,
}

local onSlash -- the /centinela handler, defined below; guarded once the saved variables are in
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON then
			ns.InitDB()
			frame:UnregisterEvent("ADDON_LOADED")
			-- from here on a Lua error in a handler is kept, not thrown (see /centinela errores)
			SlashCmdList.CENTINELA = ns.guard.Install(frame, onSlash)
		end
	elseif event == "PLAYER_LOGIN" then
		G.HookSends()
		ns.UI.Minimap()
		C_Timer.After(CHECK_DELAY, function()
			W.Run()
		end)
		C_Timer.NewTicker(CHECK_EVERY, function()
			W.Run()
		end)
		for e in pairs(handlers) do
			frame:RegisterEvent(e)
		end
	elseif handlers[event] then
		handlers[event](...)
	end
end)

SLASH_CENTINELA1 = "/centinela"
onSlash = function(msg)
	msg = strtrim((msg or ""):lower())
	if msg == "revisar" or msg == "check" then
		ns.UI.CheckNow()
	elseif msg:match("^tope") or msg:match("^limit") then
		local n = tonumber(msg:match("(%d+)%s*$"))
		if n then
			ns.db.settings.goldLimit = n
			G.Forget()
			ns.Print(n > 0 and L.LIMIT_SET:format(n) or L.LIMIT_OFF)
			ns.UI.Refresh()
		else
			ns.Print(L.LIMIT_USAGE)
		end
	elseif msg:match("^minimapa") or msg:match("^minimap") then
		local on = msg:match("%s+(%a+)$")
		if on == "on" or on == "si" or on == "sí" then
			ns.db.settings.minimap = true
		elseif on == "off" or on == "no" then
			ns.db.settings.minimap = false
		else
			ns.db.settings.minimap = not ns.db.settings.minimap
		end
		ns.UI.Minimap()
	elseif msg:match("^idioma") or msg:match("^language") or msg:match("^lang") then
		local code = msg:match("%s+(%a+)$")
		if code == "es" or code == "en" or code == "auto" then
			ns.db.settings.lang = code
			ns.ApplyLanguage(code)
			ns.Print(L.LANG_SET:format(L.LANG_NAMES[code]))
		else
			ns.Print(L.LANG_USAGE)
		end
	elseif msg == "errores" or msg == "errors" then
		ns.UI.Errors()
	elseif msg == "help" or msg == "ayuda" then
		ns.Print(L.HELP)
	else
		ns.UI.Toggle()
	end
end
SlashCmdList.CENTINELA = onSlash

function Centinela_OnAddonCompartmentClick()
	ns.UI.Toggle()
end
function Centinela_OnAddonCompartmentEnter(_, button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(L.TITLE)
	GameTooltip:AddLine(L.COMPARTMENT, 1, 1, 1)
	GameTooltip:Show()
end
function Centinela_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

-- Key binding (Bindings.xml, loaded by the game on its own: it is not listed in the TOC) and its names.
_G["Centinela_Toggle"] = function()
	ns.UI.Toggle()
end
_G["BINDING_HEADER_CENTINELA"] = "Centinela"
_G["BINDING_NAME_CENTINELA_TOGGLE"] = L.BINDING_TOGGLE
