local addonName, ns = ...

-- Coche "sacs combinés" (CVar Blizzard) une seule fois ; modifiable ensuite.

local CVAR, FLAG = "combinedBags", "combined_applied"

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if ns.Settings.Get(FLAG) or C_CVar.GetCVar(CVAR) == nil then return end
    if not GetCVarBool(CVAR) then SetCVar(CVAR, 1) end
    ns.Settings.Set(FLAG, true)
end)
