local _, ns = ...

-- English is the fallback; Spanish for esES and esMX (or when /centinela idioma es says so).
-- No emoji anywhere: the game's fonts cannot draw them.
local L = {
	TITLE = "Centinela",
	BINDING_TOGGLE = "Open / close",
	COMPARTMENT = "Click to see which addon replaced the game's money functions.",
	CHECKED_AT = "Checked at %s",
	NEVER_CHECKED = "Not checked yet",
	COUNTS = "%d functions watched",
	REPLACED_COUNT = "%d replaced",
	NONE_REPLACED = "none replaced",
	INTACT = "intact",
	REPLACED_BY = "replaced by %s",
	REPLACED_BY_UNKNOWN = "replaced, by whom is not known",
	ABSENT = "not in this game",
	CHECK_NOW = "Check now",
	ONLY_REPLACED = "Only replaced",
	FOOT = "An addon that replaces one of these can be legitimate: Postal, TSM or Auctionator do it to add features. Centinela only tells you which one did. If you do not recognise the name, disable it and look at its page on CurseForge.",
	GOLD_LINE = "Gold warning: above %d gold (/centinela limit N; 0 turns it off).",
	GOLD_OFF = "Gold warning: off (/centinela limit N turns it on).",
	GOLD_POPUP = "Centinela: you are about to send %s to %s. Sure?",
	GOLD_SOMEONE = "someone",
	GOLD_SENT = "A mail with %s left for %s.",
	NEW_REPLACED = "%s is replaced by %s (new since last time). /centinela shows the list.",
	NEW_MORE = "...and %d more. /centinela shows the list.",
	CHECK_DONE = "Checked: %d watched, %d replaced.",
	LIMIT_SET = "Gold warning above %d gold.",
	LIMIT_OFF = "Gold warning off.",
	LIMIT_USAGE = "/centinela limit N (gold; 0 turns it off).",
	HELP = "/centinela opens the page. /centinela check runs the check now, /centinela limit N sets the gold warning, /centinela idioma es|en|auto picks the language, /centinela errores shows the addon's own errors to copy.",
	ERR_TITLE = "Errors",
	ERR_NOTICE = "had an error. /centinela errores shows it to copy.",
	ERR_EMPTY = "No errors kept.",
	ERR_CLEAR = "Clear",
	ERR_COPY = "Select the text and copy it with Ctrl+C, then paste it in a GitHub issue.",
	LANG_SET = "Language: %s.",
	LANG_NAMES = { auto = "the game's", es = "castellano", en = "English" },
	LANG_USAGE = "/centinela idioma es, en or auto.",
	WHY = "Why these: they move gold and items (mail, trade, vendor, bank, auction), accept quests, write in chat, change settings or draw the game's confirmation popups. A replaced one does the same job, plus whatever the addon added.",
	G_MAIL = "Mail",
	G_TRADE = "Trade",
	G_VENDOR = "Vendor",
	G_BAGS = "Bags and cursor",
	G_QUESTS = "Quests",
	G_BANK = "Bank",
	G_AUCTION = "Auction house",
	G_CHAT = "Chat",
	G_SETTINGS = "Settings",
	G_UI = "Confirmation popups",
	MINIMAP_TIP = "Left click: the page. Right click: check now.",
}

local es = {
	TITLE = "Centinela",
	BINDING_TOGGLE = "Abrir / cerrar",
	COMPARTMENT = "Clic para ver qué addon reemplazó las funciones de oro del juego.",
	CHECKED_AT = "Revisión de las %s",
	NEVER_CHECKED = "Todavía sin revisar",
	COUNTS = "%d funciones vigiladas",
	REPLACED_COUNT = "%d reemplazadas",
	NONE_REPLACED = "ninguna reemplazada",
	INTACT = "intacta",
	REPLACED_BY = "reemplazada por %s",
	REPLACED_BY_UNKNOWN = "reemplazada, no se sabe por quién",
	ABSENT = "no existe en este juego",
	CHECK_NOW = "Revisar ahora",
	ONLY_REPLACED = "Solo reemplazadas",
	FOOT = "Un addon que reemplaza estas funciones puede ser legítimo: Postal, TSM o Auctionator lo hacen para sumar funciones. Centinela solo te dice cuál fue. Si no reconocés el nombre, desactivalo y mirá su página en CurseForge.",
	GOLD_LINE = "Aviso de oro: a partir de %d de oro (/centinela tope N; 0 lo apaga).",
	GOLD_OFF = "Aviso de oro: apagado (/centinela tope N lo prende).",
	GOLD_POPUP = "Centinela: estás por enviar %s a %s. ¿Seguro?",
	GOLD_SOMEONE = "alguien",
	GOLD_SENT = "Salió un correo con %s para %s.",
	NEW_REPLACED = "%s está reemplazada por %s (nuevo desde la última vez). /centinela muestra la lista.",
	NEW_MORE = "...y %d más. /centinela muestra la lista.",
	CHECK_DONE = "Revisado: %d vigiladas, %d reemplazadas.",
	LIMIT_SET = "Aviso de oro a partir de %d de oro.",
	LIMIT_OFF = "Aviso de oro apagado.",
	LIMIT_USAGE = "/centinela tope N (en oro; 0 lo apaga).",
	HELP = "/centinela abre la página. /centinela revisar revisa ahora, /centinela tope N fija el aviso de oro, /centinela idioma es|en|auto elige el idioma, /centinela errores muestra los errores del addon para copiarlos.",
	ERR_TITLE = "Errores",
	ERR_NOTICE = "tuvo un error. /centinela errores lo muestra para copiarlo.",
	ERR_EMPTY = "Sin errores guardados.",
	ERR_CLEAR = "Borrar",
	ERR_COPY = "Seleccioná el texto y copialo con Ctrl+C, después pegalo en un issue de GitHub.",
	LANG_SET = "Idioma: %s.",
	LANG_NAMES = { auto = "el del juego", es = "castellano", en = "inglés" },
	LANG_USAGE = "/centinela idioma es, en o auto.",
	WHY = "Por qué estas: mueven oro y objetos (correo, comercio, vendedor, banco, subasta), aceptan misiones, escriben en el chat, cambian ajustes o dibujan las confirmaciones del juego. Una reemplazada hace lo mismo, más lo que el addon le haya sumado.",
	G_MAIL = "Correo",
	G_TRADE = "Comercio",
	G_VENDOR = "Vendedor",
	G_BAGS = "Bolsas y cursor",
	G_QUESTS = "Misiones",
	G_BANK = "Banco",
	G_AUCTION = "Casa de subastas",
	G_CHAT = "Chat",
	G_SETTINGS = "Ajustes",
	G_UI = "Confirmaciones",
	MINIMAP_TIP = "Clic izquierdo: la página. Clic derecho: revisar ahora.",
}

-- ns.L is a proxy: the files keep `local L = ns.L` and read through it, so the language can change after
-- they loaded (the setting lives in CentinelaDB, which is only there at ADDON_LOADED; /centinela idioma too).
local active = L
ns.L = setmetatable({}, {
	__index = function(_, k)
		return active[k]
	end,
})

-- "auto" follows the game's client; "es" or "en" force one.
function ns.ApplyLanguage(code)
	local locale = GetLocale()
	local spanish = code == "es" or (code ~= "en" and (locale == "esES" or locale == "esMX"))
	if spanish then
		local merged = {}
		for k, v in pairs(L) do
			merged[k] = v
		end
		for k, v in pairs(es) do
			merged[k] = v
		end
		active = merged
	else
		active = L
	end
	ns.language = spanish and "es" or "en"
	if ns.Fire then
		ns.Fire("language")
	end
end
ns.ApplyLanguage("auto")
