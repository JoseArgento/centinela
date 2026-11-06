local ADDON, ns = ...
local L = ns.L
local W = ns.Watch

-- The page: a single parchment (Pergamino.Book, single). When it was checked and the counts on top, the
-- watched functions as a list (name, what it does, intact or who replaced it), "Check now", the filter
-- "Only replaced", and at the foot what a replacement means and the gold warning's limit.

local UI = {}
ns.UI = UI
local P = Pergamino
-- a dark ink green: the bright one read as a highlighter on parchment
local GREEN, RED = "|cff2f5222", "|cff8f2a1d"
-- one line per function (two lines did not fit in 30 px and the second ran into the next row)
local ROW_H = 26

UI.onlyReplaced = false

-- Everything the page says, as plain data (the tests read it; the page draws it).
function UI.Lines()
	local out = {}
	local last = W.last
	if last then
		out.when = L.CHECKED_AT:format(ns.Clock(last.at))
		local replaced = last.replaced > 0 and (RED .. L.REPLACED_COUNT:format(last.replaced) .. "|r")
			or (GREEN .. L.NONE_REPLACED .. "|r")
		out.counts = L.COUNTS:format(last.watched) .. " · " .. replaced
	else
		out.when = L.NEVER_CHECKED
		out.counts = ""
	end
	out.rows = {}
	for _, row in ipairs(last and last.rows or {}) do
		if row.status ~= "absent" and (not UI.onlyReplaced or row.status == "replaced") then
			out.rows[#out.rows + 1] = {
				name = row.name,
				group = L[W.GROUP_LABEL[row.group]] or row.group,
				status = row.status,
				text = W.Describe(row),
			}
		end
	end
	local gold = ns.db and ns.db.settings.goldLimit or 0
	out.gold = gold > 0 and L.GOLD_LINE:format(gold) or L.GOLD_OFF
	return out
end

local function initRow(row, item)
	if not row.name then
		row.name = P.Label(row, "", "strong")
		row.name:SetPoint("LEFT", 6, 0)
		row.name:SetWidth(220)
		row.name:SetWordWrap(false)
		row.group = P.Label(row, "", "muted")
		row.group:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
		row.group:SetWidth(70)
		row.group:SetWordWrap(false)
		row.status = P.Label(row, "", "small", "RIGHT")
		row.status:SetPoint("RIGHT", -6, 0)
		row.status:SetPoint("LEFT", row.group, "RIGHT", 6, 0)
		row.status:SetWordWrap(false)
	end
	row.name:SetText(item.name)
	row.group:SetText(item.group)
	row.status:SetText((item.status == "replaced" and RED or GREEN) .. item.text .. "|r")
end

UI.InitRow = initRow -- for the tests

local function build()
	local f = P.Book(ADDON .. "Frame", { title = L.TITLE, single = true, width = 520, height = 580 })
	UI.frame = f
	local page = f.left
	local s = ns.db.settings
	if s.point then
		f:ClearAllPoints()
		f:SetPoint(unpack(s.point))
	end
	f.OnMoved = function(...)
		s.point = { ... }
	end

	f.when = P.Label(page, "", "big")
	f.when:SetPoint("TOPLEFT")
	f.when:SetPoint("TOPRIGHT")
	f.when:SetWordWrap(true)
	f.counts = P.Label(page, "", "body")
	f.counts:SetPoint("TOPLEFT", f.when, "BOTTOMLEFT", 0, -4)
	f.counts:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	f.counts:SetWordWrap(true)

	f.check = P.Button(page, L.CHECK_NOW, 130, function()
		UI.CheckNow()
	end)
	f.check:SetPoint("TOPLEFT", f.counts, "BOTTOMLEFT", 0, -10)
	f.only = P.Chip(page, L.ONLY_REPLACED, function()
		UI.onlyReplaced = not UI.onlyReplaced
		UI.Refresh()
	end)
	f.only:SetPoint("LEFT", f.check, "RIGHT", 10, 0)

	local rule = P.Rule(page)
	rule:SetPoint("TOPLEFT", f.check, "BOTTOMLEFT", 0, -10)
	rule:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
	rule:SetPoint("TOP", f.check, "BOTTOM", 0, -10)

	f.gold = P.Label(page, "", "small")
	f.gold:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	f.gold:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	f.gold:SetWordWrap(true)
	f.foot = P.Label(page, L.FOOT, "muted")
	f.foot:SetPoint("BOTTOMLEFT", f.gold, "TOPLEFT", 0, 6)
	f.foot:SetPoint("BOTTOMRIGHT", f.gold, "TOPRIGHT", 0, 6)
	f.foot:SetWordWrap(true)

	local holder = P.Panel(page)
	holder:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -8)
	holder:SetPoint("RIGHT", page, "RIGHT", -14, 0)
	holder:SetPoint("BOTTOM", f.foot, "TOP", 0, 10)
	f.list = P.List(holder, ROW_H, initRow)
	f.list.box:SetPoint("TOPLEFT", 2, -2)
	f.list.box:SetPoint("BOTTOMRIGHT", -2, 2)

	f:SetScript("OnShow", function()
		if not W.last then
			W.Run(true)
		end
		UI.Refresh()
	end)
	return f
end

function UI.CheckNow()
	local result = W.Run(true)
	ns.Print(L.CHECK_DONE:format(result.watched, result.replaced))
	UI.Refresh()
end

-- The static texts, again: the language can change after the page was built.
function UI.ApplyTexts()
	local f = UI.frame
	if not f then
		return
	end
	f:SetTitle(L.TITLE)
	f.check:SetText(L.CHECK_NOW)
	f.only:SetText(L.ONLY_REPLACED)
	if f.only.Fit then
		f.only:Fit()
	end
	f.foot:SetText(L.FOOT)
	UI.Refresh()
end

function UI.Refresh()
	local f = UI.frame
	if not f or not f:IsShown() then
		return
	end
	local lines = UI.Lines()
	f.when:SetText(lines.when)
	f.counts:SetText(lines.counts)
	f.only:SetPressed(UI.onlyReplaced)
	f.list:SetData(lines.rows, true)
	f.gold:SetText(lines.gold)
end

function UI.Toggle()
	local f = UI.frame or build()
	f:SetShown(not f:IsShown())
end

-- The addon's own errors (Pergamino.Guard), on a card to copy them into an issue.
function UI.Errors()
	if not UI.errorsCard then
		local card = P.Card(ADDON .. "ErrorsCard", 460, 360, L.ERR_TITLE)
		card.page = ns.guard.Page(card.body)
		UI.errorsCard = card
	end
	UI.errorsCard.page.Refresh()
	UI.errorsCard:Show()
	return UI.errorsCard
end

-- The minimap button (Pergamino's), kept in the settings: shown or not, and where around the minimap. It is
-- registered in the family's hub (settings.minimapMerged = one button for every addon that shares the lib),
-- and its clicks go through the guard: an error is kept, not thrown.
function UI.Minimap()
	local s = ns.db.settings
	if not UI.minimap then
		UI.minimap = P.MinimapButton(ADDON .. "MinimapButton", {
			icon = "Interface\\AddOns\\" .. ADDON .. "\\Media\\icon",
			angle = s.minimapAngle,
			shown = s.minimap,
			onClick = function()
				UI.Toggle()
			end,
			onRightClick = function()
				UI.CheckNow()
			end,
			onMove = function(angle)
				s.minimapAngle = angle
			end,
			tooltip = function(tip)
				tip:SetText(L.TITLE)
				tip:AddLine(L.MINIMAP_TIP, 1, 1, 1)
			end,
			guard = ns.guard,
			hub = { addon = L.TITLE, label = L.TITLE, order = 6 },
		})
		if s.minimapMerged ~= nil then
			P.MinimapHub.SetMerged(s.minimapMerged)
		end
	end
	UI.minimap:SetShown(s.minimap)
	return UI.minimap
end

-- /centinela minimapa juntar on|off: one button for the whole family (the lib keeps it for every addon)
function UI.SetMinimapMerged(merged)
	ns.db.settings.minimapMerged = merged and true or false
	P.MinimapHub.SetMerged(merged)
	ns.Print(merged and L.MINIMAP_MERGED_ON or L.MINIMAP_MERGED_OFF)
end

ns.On("checked", UI.Refresh)
ns.On("language", UI.ApplyTexts)
