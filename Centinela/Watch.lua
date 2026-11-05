local _, ns = ...
local L = ns.L

-- The check: which of the game's own functions were replaced by an addon, and by which one.
--
-- issecurevariable("name") (or issecurevariable(table, "key")) says whether a variable still holds what the
-- game put there. An addon that assigns over it taints it, and the second value names that addon.
-- hooksecurefunc does NOT taint: an addon that only hooks one of these stays "intact" here, and that is the
-- point: only an outright replacement shows up. Centinela never says why it was replaced; it cannot know.

local W = {}
ns.Watch = W

-- What is watched, by what it does. Every name was checked against the Forever API dump (tools/check_api.py);
-- a name that is not a function in the running game is skipped, not reported.
W.WATCHED = {
	{ "SendMail", "mail" },
	{ "SetSendMailMoney", "mail" },
	{ "SetSendMailCOD", "mail" },
	{ "ClearSendMail", "mail" },
	{ "TakeInboxMoney", "mail" },
	{ "TakeInboxItem", "mail" },
	{ "InitiateTrade", "trade" },
	{ "AcceptTrade", "trade" },
	{ "CancelTrade", "trade" },
	{ "C_TradeInfo.SetTradeMoney", "trade" },
	{ "C_TradeInfo.AddTradeMoney", "trade" },
	{ "PickupMerchantItem", "vendor" },
	{ "BuyMerchantItem", "vendor" },
	{ "SellCursorItem", "vendor" },
	{ "BuybackItem", "vendor" },
	{ "C_MerchantFrame.SellAllJunkItems", "vendor" },
	{ "PickupPlayerMoney", "bags" },
	{ "DropCursorMoney", "bags" },
	{ "DeleteCursorItem", "bags" },
	{ "PutItemInBag", "bags" },
	{ "AutoEquipCursorItem", "bags" },
	{ "C_Container.PickupContainerItem", "bags" },
	{ "C_Container.UseContainerItem", "bags" },
	{ "AcceptQuest", "quests" },
	{ "ConfirmAcceptQuest", "quests" },
	{ "DepositGuildBankMoney", "bank" },
	{ "WithdrawGuildBankMoney", "bank" },
	{ "PickupGuildBankMoney", "bank" },
	{ "C_Bank.DepositMoney", "bank" },
	{ "C_Bank.WithdrawMoney", "bank" },
	{ "C_AuctionHouse.PostItem", "auction" },
	{ "C_AuctionHouse.PostCommodity", "auction" },
	{ "C_AuctionHouse.PlaceBid", "auction" },
	{ "C_AuctionHouse.ConfirmCommoditiesPurchase", "auction" },
	{ "C_ChatInfo.SendChatMessage", "chat" },
	{ "C_CVar.SetCVar", "settings" },
	{ "StaticPopup_Show", "ui" },
	{ "StaticPopup_Hide", "ui" },
}

W.GROUP_LABEL = {
	mail = "G_MAIL",
	trade = "G_TRADE",
	vendor = "G_VENDOR",
	bags = "G_BAGS",
	quests = "G_QUESTS",
	bank = "G_BANK",
	auction = "G_AUCTION",
	chat = "G_CHAT",
	settings = "G_SETTINGS",
	ui = "G_UI",
}

-- "C_Bank.DepositMoney" -> the table C_Bank and the key; "SendMail" -> _G and the key.
local function resolve(name)
	local tbl, key = name:match("^([%w_]+)%.([%w_]+)$")
	if tbl then
		local t = _G[tbl]
		if type(t) ~= "table" then
			return nil
		end
		return t, key
	end
	return _G, name
end

-- One function: { name, group, status = "intact" | "replaced" | "absent", by = addon name or nil }
function W.Inspect(name, group)
	local tbl, key = resolve(name)
	if not tbl or type(tbl[key]) ~= "function" then
		return { name = name, group = group, status = "absent" }
	end
	local secure, by
	if tbl == _G then
		secure, by = issecurevariable(key)
	else
		secure, by = issecurevariable(tbl, key)
	end
	if secure then
		return { name = name, group = group, status = "intact" }
	end
	return { name = name, group = group, status = "replaced", by = (type(by) == "string" and by ~= "" and by) or nil }
end

-- The whole list. Returns { at = time, rows = {...}, watched = n, replaced = m, byName = { [name] = by or "?" } }.
function W.Check()
	local out = { at = time(), rows = {}, watched = 0, replaced = 0, byName = {} }
	for _, e in ipairs(W.WATCHED) do
		local row = W.Inspect(e[1], e[2])
		out.rows[#out.rows + 1] = row
		if row.status ~= "absent" then
			out.watched = out.watched + 1
		end
		if row.status == "replaced" then
			out.replaced = out.replaced + 1
			out.byName[row.name] = row.by or "?"
		end
	end
	W.last = out
	return out
end

-- Replaced functions that the last saved check did not have, or had under another addon's name:
-- { { name, by }, ... } in the watched order.
function W.NewSince(result, lastSeen)
	local fresh = {}
	for _, row in ipairs(result.rows) do
		if row.status == "replaced" then
			local by = row.by or "?"
			if lastSeen[row.name] ~= by then
				fresh[#fresh + 1] = { name = row.name, by = by }
			end
		end
	end
	return fresh
end

-- Check, tell about what is new (a few lines, never the whole list), and remember it for next time.
function W.Run(quiet)
	local result = W.Check()
	local fresh = W.NewSince(result, ns.db.lastSeen)
	if not quiet then
		for i, f in ipairs(fresh) do
			if i > 3 then
				ns.Print(L.NEW_MORE:format(#fresh - 3))
				break
			end
			ns.Print(L.NEW_REPLACED:format(f.name, f.by == "?" and L.REPLACED_BY_UNKNOWN or f.by))
		end
	end
	ns.db.lastSeen = result.byName
	ns.db.lastCheck = result.at
	ns.Fire("checked", result, fresh)
	return result, fresh
end

-- The row's text for the page and the chat, so the tests read what the player reads.
function W.Describe(row)
	if row.status == "absent" then
		return L.ABSENT
	elseif row.status == "intact" then
		return L.INTACT
	elseif row.by then
		return L.REPLACED_BY:format(row.by)
	end
	return L.REPLACED_BY_UNKNOWN
end
