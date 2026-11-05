"""Centinela running in Lua 5.1 (the Lua of WoW) on a small stand-in for the client.

issecurevariable is driven by MOCK.tainted: a test says which function an addon replaced, and Centinela
must report exactly that, with the addon's name, and never more.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

lupa = pytest.importorskip("lupa.lua51")

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "Centinela"
TESTS = Path(__file__).resolve().parent


def toc_lines():
    return [ln.strip() for ln in (ADDON / "Centinela.toc").read_text(encoding="utf-8").splitlines()]


def toc_files():
    return [ln.replace("\\", "/") for ln in toc_lines() if ln and not ln.startswith("#") and ln.endswith(".lua")]


class Client:
    def __init__(self, locale="enUS", saved=None, setup=None):
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((TESTS / "wow_mock.lua").read_text(encoding="utf-8"))
        self.lua.execute((TESTS / "centinela_mock.lua").read_text(encoding="utf-8"))
        self.m = self.lua.globals().MOCK
        self.m.locale = locale
        if saved is not None:
            self.lua.execute(saved)
        if setup:
            self.lua.execute(setup)
        self.ns = self.lua.table()
        loader = self.lua.eval("function(src, name) return assert(loadstring(src, '@' .. name)) end")
        for rel in toc_files():
            loader((ADDON / rel).read_text(encoding="utf-8"), f"Centinela/{rel}")("Centinela", self.ns)

    def login(self):
        self.fire("ADDON_LOADED", "Centinela")
        self.fire("PLAYER_LOGIN")
        self.m.runTimers()  # the check, 5 s after login
        return self

    def run(self, code):
        return self.lua.eval("function(ns, MOCK) " + code + " end")(self.ns, self.m)

    def fire(self, event, *args):
        self.m.fire(event, *args)

    def slash(self, msg):
        self.lua.globals().SlashCmdList.CENTINELA(msg)

    def taint(self, name, by):
        self.run(f"MOCK.tainted[{name!r}] = {by!r}" if by is not False else f"MOCK.tainted[{name!r}] = false")

    def chat(self):
        return [self.m.chat[i] for i in range(1, len(self.m.chat) + 1)]

    def popups(self):
        return [self.m.popups[i] for i in range(1, len(self.m.popups) + 1)]

    def saved(self):
        return self.m.savedVariables("CentinelaDB")

    def check(self):
        return self.ns.Watch.Check()

    def rows(self, result):
        return {r.name: r for r in (result.rows[i] for i in range(1, len(result.rows) + 1))}


def lua_list(t):
    return [t[i] for i in range(1, len(t) + 1)]


# --- packaging -------------------------------------------------------------------------------------------


def test_bindings_xml_is_not_listed_in_the_toc():
    # The game loads Bindings.xml on its own; listed in the TOC it is parsed as UI XML and warns
    assert (ADDON / "Bindings.xml").exists()
    assert not any(ln.lower().endswith(".xml") for ln in toc_lines() if not ln.startswith("#"))


def test_toc_is_for_forever_and_has_its_icon():
    lines = toc_lines()
    assert "## Interface: 16001" in lines
    assert "## SavedVariables: CentinelaDB" in lines
    assert (ADDON / "Media" / "icon.tga").exists()
    assert toc_files()[0] == "Libs/Pergamino/Pergamino.lua"


def test_no_emoji_in_the_addon_strings():
    # the game's fonts cannot draw them (it showed an empty box in Listos)
    for f in ADDON.glob("*.lua"):
        text = f.read_text(encoding="utf-8")
        assert not re.search("[\U0001f000-\U0001ffff⌀-⏿☀-➿]", text), f.name


# --- the check -------------------------------------------------------------------------------------------


def test_nothing_replaced_means_every_present_function_is_intact():
    c = Client().login()
    r = c.ns.Watch.last
    assert r.replaced == 0
    assert r.watched > 30
    statuses = {row.status for row in c.rows(r).values()}
    assert statuses <= {"intact", "absent"}


def test_a_replaced_global_is_reported_with_the_addon_that_did_it():
    c = Client().login()
    c.taint("SendMail", "ShadyMail")
    rows = c.rows(c.check())
    assert rows["SendMail"].status == "replaced"
    assert rows["SendMail"].by == "ShadyMail"
    assert c.ns.Watch.Describe(rows["SendMail"]) == "replaced by ShadyMail"
    assert rows["SetSendMailMoney"].status == "intact"


def test_a_replaced_function_inside_a_table_is_checked_with_the_table_form():
    c = Client().login()
    c.taint("C_AuctionHouse.PostItem", "Auctionator")
    rows = c.rows(c.check())
    assert rows["C_AuctionHouse.PostItem"].status == "replaced"
    assert rows["C_AuctionHouse.PostItem"].by == "Auctionator"
    assert rows["C_AuctionHouse.PlaceBid"].status == "intact"


def test_replaced_without_a_name_says_so_and_does_not_invent_one():
    c = Client().login()
    c.taint("AcceptTrade", False)
    row = c.rows(c.check())["AcceptTrade"]
    assert row.status == "replaced"
    assert row.by is None
    assert c.ns.Watch.Describe(row) == "replaced, by whom is not known"


def test_a_function_missing_in_this_client_is_skipped_not_reported():
    c = Client().login()
    c.taint("C_Bank.WithdrawMoney", "Whatever")
    r = c.check()
    row = c.rows(r)["C_Bank.WithdrawMoney"]
    assert row.status == "absent"
    assert r.replaced == 0


def test_a_missing_namespace_is_skipped():
    c = Client(setup="C_MerchantFrame = nil").login()
    assert c.rows(c.check())["C_MerchantFrame.SellAllJunkItems"].status == "absent"


def test_a_hook_is_not_a_replacement():
    # hooksecurefunc keeps the function secure in the game; the mock's issecurevariable only reports tainted
    c = Client().login()
    c.run("hooksecurefunc('SendMail', function() end)")
    assert c.rows(c.check())["SendMail"].status == "intact"


def test_the_check_runs_after_login_and_on_a_ticker():
    c = Client()
    c.fire("ADDON_LOADED", "Centinela")
    c.fire("PLAYER_LOGIN")
    assert c.ns.Watch.last is None
    c.m.runTimers()
    assert c.ns.Watch.last is not None
    c.taint("BuyMerchantItem", "Vendorer")
    c.m.tick()
    assert c.ns.Watch.last.replaced == 1


def test_every_watched_name_is_unique():
    c = Client()
    names = [c.ns.Watch.WATCHED[i][1] for i in range(1, len(c.ns.Watch.WATCHED) + 1)]
    assert len(names) == len(set(names))


# --- the chat line, only for what is new -----------------------------------------------------------------


def test_the_chat_tells_once_about_a_new_replacement():
    c = Client(setup="MOCK.tainted['SendMail'] = 'ShadyMail'").login()
    lines = [ln for ln in c.chat() if "SendMail" in ln]
    assert len(lines) == 1
    assert "replaced by ShadyMail" in lines[0]
    assert "new since last time" in lines[0]
    c.m.tick()
    assert len([ln for ln in c.chat() if "SendMail" in ln]) == 1


def test_the_chat_says_nothing_when_nothing_changed_since_the_last_session():
    first = Client(setup="MOCK.tainted['SendMail'] = 'Postal'").login()
    saved = first.saved()
    again = Client(saved=saved, setup="MOCK.tainted['SendMail'] = 'Postal'").login()
    assert not [ln for ln in again.chat() if "SendMail" in ln]


def test_the_chat_speaks_again_when_another_addon_takes_it_over():
    first = Client(setup="MOCK.tainted['SendMail'] = 'Postal'").login()
    again = Client(saved=first.saved(), setup="MOCK.tainted['SendMail'] = 'Mailman'").login()
    lines = [ln for ln in again.chat() if "SendMail" in ln]
    assert len(lines) == 1 and "Mailman" in lines[0]


def test_many_new_ones_are_three_lines_and_a_count():
    setup = "\n".join(
        f"MOCK.tainted[{n!r}] = 'Bulk'" for n in ["SendMail", "AcceptTrade", "BuyMerchantItem", "SellCursorItem", "PutItemInBag"]
    )
    c = Client(setup=setup).login()
    ours = [ln for ln in c.chat() if "Centinela" in ln]
    assert len(ours) == 4
    assert "and 2 more" in ours[-1]


def test_nothing_in_the_chat_never_accuses():
    c = Client(setup="MOCK.tainted['SendMail'] = 'ShadyMail'").login()
    for ln in c.chat():
        low = ln.lower()
        assert "fraud" not in low and "scam" not in low and "malicious" not in low


# --- the gold warning ------------------------------------------------------------------------------------


def open_mail(c, copper, to="Ana"):
    c.run(f"MailFrame:Show(); SendMailMoney.copper = {copper}; SendMailNameEditBox:SetText({to!r})")
    c.fire("MAIL_SHOW")
    c.m.tick()


def test_mail_above_the_limit_asks_once():
    c = Client().login()
    open_mail(c, 120 * 10000)
    ps = c.popups()
    assert len(ps) == 1
    assert "Ana" in ps[0].text and "120g" in ps[0].text
    c.m.tick()
    assert len(c.popups()) == 1


def test_mail_below_the_limit_does_not_ask():
    c = Client().login()
    open_mail(c, 20 * 10000)
    assert c.popups() == []


def test_answering_no_clears_the_mail_money():
    c = Client().login()
    open_mail(c, 300 * 10000)
    c.m.answer(False)
    assert lua_list(c.m.cleared) == ["SendMailMoney"]
    assert c.lua.globals().SendMailMoney.copper == 0


def test_answering_yes_leaves_it_alone():
    c = Client().login()
    open_mail(c, 300 * 10000)
    c.m.answer(True)
    assert lua_list(c.m.cleared) == []


def test_a_cod_amount_is_not_gold_leaving():
    c = Client().login()
    c.run("SendMailSendMoneyButton:SetChecked(false)")
    open_mail(c, 500 * 10000)
    assert c.popups() == []


def test_trade_above_the_limit_asks_and_no_sets_it_back_to_zero():
    c = Client().login()
    c.run("TradeFrame:Show(); TradeFrameRecipientNameText:SetText('Beto'); MOCK.tradeMoney = 90 * 10000")
    c.fire("TRADE_SHOW")
    c.m.tick()
    ps = c.popups()
    assert len(ps) == 1 and "Beto" in ps[0].text
    c.m.answer(False)
    assert c.m.tradeMoney == 0


def test_limit_zero_turns_the_warning_off():
    c = Client().login()
    c.slash("limit 0")
    open_mail(c, 999 * 10000)
    assert c.popups() == []
    assert "Gold warning off." in c.chat()[-1]


def test_slash_limit_sets_it_and_it_is_saved():
    c = Client().login()
    c.slash("tope 200")
    assert c.ns.db.settings.goldLimit == 200
    again = Client(saved=c.saved()).login()
    assert again.ns.db.settings.goldLimit == 200


def test_a_money_mail_above_the_limit_sent_without_the_window_is_noted():
    c = Client().login()
    c.run("SetSendMailMoney(100 * 10000); SendMail('Ana', 'x', '')")
    assert "A mail with 100g left for Ana." in c.chat()[-1]


def test_the_hooks_do_not_replace_the_game_functions():
    # the hooks wrap in the mock; in the game hooksecurefunc keeps them secure. What matters here: the
    # original still runs
    c = Client().login()
    c.run("SendMail('Ana', 'hola', '')")
    assert lua_list(c.m.sent)[0].to == "Ana"


# --- the page, slash, language, minimap ------------------------------------------------------------------


def test_the_page_builds_and_lists_the_replaced_ones():
    c = Client(setup="MOCK.tainted['SendMail'] = 'ShadyMail'").login()
    c.slash("")
    assert c.ns.UI.frame.IsShown(c.ns.UI.frame)
    lines = c.ns.UI.Lines()
    assert lines.when.startswith("Checked at ")
    assert "1 replaced" in lines.counts
    texts = {r.name: r.text for r in lua_list(lines.rows)}
    assert texts["SendMail"] == "replaced by ShadyMail"
    assert texts["AcceptTrade"] == "intact"
    assert "C_Bank.WithdrawMoney" not in texts


def test_only_replaced_filters_the_list():
    c = Client(setup="MOCK.tainted['SendMail'] = 'ShadyMail'").login()
    c.slash("")
    c.run("ns.UI.onlyReplaced = true")
    rows = lua_list(c.ns.UI.Lines().rows)
    assert [r.name for r in rows] == ["SendMail"]


def test_check_now_from_the_slash_reports_the_counts():
    c = Client().login()
    c.taint("PickupPlayerMoney", "Banker")
    c.slash("revisar")
    assert re.search(r"Checked: \d+ watched, 1 replaced\.", c.chat()[-1])


def test_language_switch_to_spanish_and_back():
    c = Client().login()
    c.taint("SendMail", "ShadyMail")
    c.check()
    c.slash("idioma es")
    assert c.chat()[-1].endswith("Idioma: castellano.")
    row = c.rows(c.ns.Watch.last)["SendMail"]
    assert c.ns.Watch.Describe(row) == "reemplazada por ShadyMail"
    c.slash("idioma en")
    assert c.ns.Watch.Describe(row) == "replaced by ShadyMail"
    assert c.ns.db.settings.lang == "en"


def test_spanish_client_is_spanish_by_default():
    c = Client(locale="esMX").login()
    c.slash("revisar")
    assert "Revisado:" in c.chat()[-1]


def test_minimap_button_toggles_and_remembers_its_angle():
    c = Client().login()
    b = c.ns.UI.minimap
    assert b.IsShown(b)
    c.slash("minimapa off")
    assert not b.IsShown(b)
    c.slash("minimap on")
    assert b.IsShown(b)
    c.run("ns.UI.minimap:GetScript('OnDragStop')(ns.UI.minimap)")
    assert c.ns.db.settings.minimapAngle == b.angle


def test_minimap_right_click_checks_left_click_opens():
    c = Client().login()
    b = c.ns.UI.minimap
    c.run("ns.UI.minimap:GetScript('OnClick')(ns.UI.minimap, 'RightButton')")
    assert "Checked:" in c.chat()[-1]
    c.run("ns.UI.minimap:GetScript('OnClick')(ns.UI.minimap, 'LeftButton')")
    assert c.ns.UI.frame.IsShown(c.ns.UI.frame)
    assert b is not None


def test_help_and_compartment():
    c = Client().login()
    c.slash("ayuda")
    assert "/centinela limit N" in c.chat()[-1]
    c.lua.globals().Centinela_OnAddonCompartmentClick()
    assert c.ns.UI.frame.IsShown(c.ns.UI.frame)
    c.lua.globals().Centinela_Toggle()
    assert not c.ns.UI.frame.IsShown(c.ns.UI.frame)


def test_rows_are_one_line_and_the_green_is_dark_ink():
    # in the game the two-line rows ran into each other ("Mail" over the next name)
    g = Client().login()
    got = g.run(
        "local row = CreateFrame('Button'); ns.UI.InitRow(row, { name = 'SendMail', group = 'Mail', status = 'intact', text = 'intact' });"
        " local n, gr, st = row.name._points[1], row.group._points[1], row.status._points[2];"
        " return n[1] .. '|' .. gr[1] .. ':' .. tostring(gr[2] == row.name) .. ':' .. gr[3] .. '|' .. tostring(st[2] == row.group) .. '|' .. row.status._text"
    )
    assert got == "LEFT|LEFT:true:RIGHT|true||cff2f5222intact|r"
    g.slash("")
    assert g.run("return ns.UI.frame.list.rowHeight") == 26
