local addonName, ns = ...

-- Bouton « retour » posé sous le cadre Blizzard du coffre de guilde (vue native).
-- ns.UI.GuildReturn.Attach(blizzFrame, onClick).

ns.UI.GuildReturn = {}

function ns.UI.GuildReturn.Attach(host, onClick)
    local b = ns.UI.Button(host, 160, 26, ns.L("GUILD_BACK"))
    b:SetPoint("TOPLEFT", host, "BOTTOMLEFT", 0, -2)
    b:SetScript("OnClick", onClick)
    return b
end
