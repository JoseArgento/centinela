-- What Centinela needs on top of wow_mock.lua: the watched functions, issecurevariable with a list of
-- "replaced by" that a test fills, the mail and trade windows' money boxes, and popups that can be answered.

MOCK.tainted = {} -- ["SendMail"] = "AddonX" or "C_Bank.DepositMoney" = "AddonY"; false = replaced, no name
MOCK.sent = {}    -- SendMail calls
MOCK.cleared = {} -- money boxes reset
MOCK.tradeMoney = 0

local function fn(name)
	return function(...)
		table.insert(MOCK.calls, { name, ... })
	end
end
MOCK.calls = {}

-- the globals Centinela watches (some missing on purpose: absent ones must be skipped)
for _, name in ipairs({
	"SendMail", "SetSendMailMoney", "SetSendMailCOD", "ClearSendMail", "TakeInboxMoney", "TakeInboxItem",
	"InitiateTrade", "AcceptTrade", "CancelTrade", "PickupMerchantItem", "BuyMerchantItem", "SellCursorItem",
	"BuybackItem", "PickupPlayerMoney", "DropCursorMoney", "DeleteCursorItem", "PutItemInBag",
	"AutoEquipCursorItem", "AcceptQuest", "ConfirmAcceptQuest", "DepositGuildBankMoney", "WithdrawGuildBankMoney",
	"PickupGuildBankMoney",
}) do
	_G[name] = fn(name)
end
function SendMail(to, subject, body)
	table.insert(MOCK.sent, { to = to, subject = subject })
end
C_TradeInfo = {
	SetTradeMoney = function(c)
		MOCK.tradeMoney = c
	end,
	AddTradeMoney = fn("AddTradeMoney"),
}
C_MerchantFrame = { SellAllJunkItems = fn("SellAllJunkItems") }
C_Container = { PickupContainerItem = fn("PickupContainerItem"), UseContainerItem = fn("UseContainerItem") }
C_Bank = { DepositMoney = fn("DepositMoney"), WithdrawMoney = fn("WithdrawMoney") }
C_AuctionHouse = {
	PostItem = fn("PostItem"),
	PostCommodity = fn("PostCommodity"),
	PlaceBid = fn("PlaceBid"),
	ConfirmCommoditiesPurchase = fn("ConfirmCommoditiesPurchase"),
}
C_ChatInfo = { SendChatMessage = fn("SendChatMessage") }
C_CVar = { SetCVar = fn("SetCVar") }
function StaticPopup_Hide() end
-- C_Bank.WithdrawMoney missing in this client: Centinela must skip it, not report it
C_Bank.WithdrawMoney = nil

-- issecurevariable([table,] key): true unless the test said this one was replaced
function issecurevariable(a, b)
	local name
	if b == nil then
		name = a
	else
		for tname, t in pairs(_G) do
			if t == a and type(t) == "table" and tname:match("^C_") then
				name = tname .. "." .. b
				break
			end
		end
		name = name or ("?." .. tostring(b))
	end
	local by = MOCK.tainted[name]
	if by == nil then
		return true
	end
	if by == false then
		return false
	end
	return false, by
end

-- the money boxes (MoneyInputFrameTemplate) and the windows
MailFrame = CreateFrame("Frame", "MailFrame")
MailFrame:Hide()
SendMailMoney = CreateFrame("Frame", "SendMailMoney")
SendMailMoney.copper = 0
SendMailNameEditBox = CreateFrame("EditBox", "SendMailNameEditBox")
SendMailSendMoneyButton = CreateFrame("CheckButton", "SendMailSendMoneyButton")
SendMailSendMoneyButton:SetChecked(true)
TradeFrame = CreateFrame("Frame", "TradeFrame")
TradeFrame:Hide()
TradePlayerInputMoneyFrame = CreateFrame("Frame", "TradePlayerInputMoneyFrame")
TradeFrameRecipientNameText = TradeFrame:CreateFontString()
function MoneyInputFrame_GetCopper(box)
	return box.copper or 0
end
function MoneyInputFrame_ResetMoney(box)
	box.copper = 0
	table.insert(MOCK.cleared, rawget(box, "_name"))
end
function GetPlayerTradeMoney()
	return MOCK.tradeMoney
end

-- answer the last popup like the player would
function MOCK.answer(yes)
	local p = table.remove(MOCK.popups)
	assert(p, "no popup to answer")
	local d = StaticPopupDialogs[p.which]
	if yes then
		if d.OnAccept then
			d.OnAccept({}, p.data)
		end
	elseif d.OnCancel then
		d.OnCancel({}, p.data)
	end
	return p
end
