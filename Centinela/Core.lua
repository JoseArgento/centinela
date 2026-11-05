local ADDON, ns = ...
local L = ns.L

ns.ADDON = ADDON

-- Saved data (CentinelaDB), the same for every character of the account:
--   settings = { goldLimit = gold (0 = off), lang = "auto" | "es" | "en", minimap = true, minimapAngle = deg,
--                point = where the page was left }
--   lastSeen = { [function name] = addon that replaced it }   what the last check found, to tell what is new
--   lastCheck = time of that check

local listeners = {}
function ns.On(topic, fn)
	listeners[topic] = listeners[topic] or {}
	table.insert(listeners[topic], fn)
end
function ns.Fire(topic, ...)
	for _, fn in ipairs(listeners[topic] or {}) do
		fn(...)
	end
end

ns.DEFAULT_GOLD_LIMIT = 50

function ns.InitDB()
	if type(CentinelaDB) ~= "table" then
		CentinelaDB = {}
	end
	local db = CentinelaDB
	db.version = 1
	db.settings = type(db.settings) == "table" and db.settings or {}
	local s = db.settings
	if type(s.goldLimit) ~= "number" or s.goldLimit < 0 then
		s.goldLimit = ns.DEFAULT_GOLD_LIMIT
	end
	if s.lang ~= "es" and s.lang ~= "en" then
		s.lang = "auto"
	end
	if s.minimap == nil then
		s.minimap = true
	end
	if type(s.minimapAngle) ~= "number" then
		s.minimapAngle = 200
	end
	db.lastSeen = type(db.lastSeen) == "table" and db.lastSeen or {}
	ns.db = db
	ns.ApplyLanguage(s.lang)
end

function ns.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. L.TITLE .. ":|r " .. msg)
end

-- Copper as the game writes it ("12g 30s"), or "N gold" when GetMoneyString is not there.
function ns.Money(copper)
	if GetMoneyString then
		return GetMoneyString(copper)
	end
	return math.floor(copper / 10000) .. "g"
end

function ns.Clock(t)
	return date("%H:%M", t or time())
end
