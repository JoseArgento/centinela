local ADDON, ns = ...
local L = ns.L

-- The gold warning: while the mail or the trade window is open, Centinela reads the amount typed in the
-- money box (the game's own MoneyInputFrame) and, above the limit, asks once before the player sends it.
-- "No" clears the box. It is a question, not a lock: a player who answers yes sends it, and an addon that
-- mails gold without the window (Postal and the like) is only noted in the chat afterwards.
-- Nothing here replaces a game function: the hooks are hooksecurefunc (they run after, and cannot stop it).

local G = {}
ns.Gold = G

local POPUP = ADDON:upper() .. "_GOLD"
local COPPER_PER_GOLD = 10000

function G.LimitCopper()
	local gold = ns.db and ns.db.settings.goldLimit or 0
	return gold > 0 and gold * COPPER_PER_GOLD or nil
end

-- what is typed right now, and for whom: { copper, to } or nil when the window is not there
function G.MailInput()
	local box = _G["SendMailMoney"]
	local frame = _G["MailFrame"]
	if not (box and frame and frame:IsShown() and MoneyInputFrame_GetCopper) then
		return nil
	end
	-- the same box is the C.O.D. amount when that radio is picked: the player receives, not sends
	local sendMoney = _G["SendMailSendMoneyButton"]
	if sendMoney and sendMoney.GetChecked and not sendMoney:GetChecked() then
		return nil
	end
	local name = _G["SendMailNameEditBox"]
	local to = name and name.GetText and name:GetText() or ""
	return { copper = MoneyInputFrame_GetCopper(box) or 0, to = to ~= "" and to or L.GOLD_SOMEONE, kind = "mail" }
end

function G.TradeInput()
	local frame = _G["TradeFrame"]
	if not (frame and frame:IsShown() and GetPlayerTradeMoney) then
		return nil
	end
	local who = _G["TradeFrameRecipientNameText"]
	local to = who and who.GetText and who:GetText()
	if not to or to == "" then
		to = UnitName("NPC") or L.GOLD_SOMEONE
	end
	return { copper = GetPlayerTradeMoney() or 0, to = to, kind = "trade" }
end

local asked = {} -- "kind:copper:to" already asked about, so the popup comes once per amount

-- Clears what was typed, the way the player would.
function G.Clear(kind)
	if kind == "mail" then
		local box = _G["SendMailMoney"]
		if box and MoneyInputFrame_ResetMoney then
			MoneyInputFrame_ResetMoney(box)
		end
	elseif kind == "trade" then
		if C_TradeInfo and C_TradeInfo.SetTradeMoney then
			C_TradeInfo.SetTradeMoney(0)
		end
		local box = _G["TradePlayerInputMoneyFrame"]
		if box and MoneyInputFrame_ResetMoney then
			MoneyInputFrame_ResetMoney(box)
		end
	end
end

-- One look at both windows: asks when an amount above the limit is sitting there and was not asked about.
function G.Look()
	local limit = G.LimitCopper()
	if not limit then
		return
	end
	-- each one on its own: a table { mail, trade } with the mail nil would stop ipairs before the trade
	for _, read in ipairs({ G.MailInput, G.TradeInput }) do
		local input = read()
		if input and input.copper > limit then
			local key = input.kind .. ":" .. input.copper .. ":" .. input.to
			if not asked[key] then
				asked[key] = true
				StaticPopup_Show(POPUP, L.GOLD_POPUP:format(ns.Money(input.copper), input.to), nil, input)
			end
		end
	end
end

function G.Forget()
	asked = {}
end

StaticPopupDialogs[POPUP] = {
	text = "%s", -- the whole sentence comes as the first text argument, in the current language
	button1 = YES,
	button2 = NO,
	OnCancel = function(_, data)
		if data then
			G.Clear(data.kind)
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

-- The ticker runs only while a window is open (MAIL_SHOW / TRADE_SHOW), twice a second.
local ticker
function G.Start()
	if ticker then
		return
	end
	ticker = C_Timer.NewTicker(0.5, G.Look)
end
function G.Stop()
	if ticker then
		if ticker.Cancel then
			ticker:Cancel()
		end
		ticker = nil
	end
	G.Forget()
end

-- After the fact: a money mail that went out above the limit gets one line, whoever sent it.
local pendingMoney = 0
function G.HookSends()
	if type(SetSendMailMoney) == "function" then
		hooksecurefunc("SetSendMailMoney", function(copper)
			pendingMoney = tonumber(copper) or 0
		end)
	end
	if type(SendMail) == "function" then
		hooksecurefunc("SendMail", function(to)
			local limit = G.LimitCopper()
			if limit and pendingMoney > limit then
				ns.Print(L.GOLD_SENT:format(ns.Money(pendingMoney), to or L.GOLD_SOMEONE))
			end
			pendingMoney = 0
		end)
	end
end
