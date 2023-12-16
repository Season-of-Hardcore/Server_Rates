CraftingRatesNamespace = {}

CraftingRatesNamespace.enabled = true
CraftingRatesNamespace.GMonly = false

local function escaparCaracteresEspeciales(texto)
    local reemplazos = {
        ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
        ["Á"] = "A", ["É"] = "E", ["Í"] = "I", ["Ó"] = "O", ["Ú"] = "U",
        ["ü"] = "u", ["Ü"] = "U", ["ñ"] = "n", ["Ñ"] = "N",
        ["à"] = "a", ["è"] = "e", ["ì"] = "i", ["ò"] = "o", ["ù"] = "u",
        ["À"] = "A", ["È"] = "E", ["Ì"] = "I", ["Ò"] = "O", ["Ù"] = "U",
        ["ä"] = "a", ["ë"] = "e", ["ï"] = "i", ["ö"] = "o", ["ü"] = "u",
        ["Ä"] = "A", ["Ë"] = "E", ["Ï"] = "I", ["Ö"] = "O", ["Ü"] = "U",
        ["â"] = "a", ["ê"] = "e", ["î"] = "i", ["ô"] = "o", ["û"] = "u",
        ["Â"] = "A", ["Ê"] = "E", ["Î"] = "I", ["Ô"] = "O", ["Û"] = "U",
        ["ã"] = "a", ["õ"] = "o",
        ["Ã"] = "A", ["Õ"] = "O",
        ["ç"] = "c", ["Ç"] = "C",
        -- Agrega más reemplazos según sea necesario
    }

    return texto:gsub('[áéíóúÁÉÍÓÚ\']', reemplazos)
end


function CraftingRatesNamespace.getPlayerCharacterGUID(player)
    if not player then
        print("Error: Player object is nil in getPlayerCharacterGUID")
        return nil
    end
    return player:GetGUIDLow()
end

function CraftingRatesNamespace.GMONLY(player)
    if not player then
        return
    end
    -- player:SendBroadcastMessage("|cffff0000You don't have permission to use this command.|r")
end

function CraftingRatesNamespace.OnLogin(event, player)
    if not player then
        return
    end
    local PUID = CraftingRatesNamespace.getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT CraftRate FROM custom_craft_rates WHERE CharID=%i", PUID))

    if Q then
        local CraftRate = Q:GetUInt32(0)
        player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Tu tasa de creación está actualmente configurada en %dx|r", CraftRate)))
    end
end

function CraftingRatesNamespace.SetCraftRate(event, player, command)
    if not player then
        return false
    end
    local mingmrank = 3
    local PUID = CraftingRatesNamespace.getPlayerCharacterGUID(player)

    if command:find("craft") then
        local rate = tonumber(command:sub(7))

        if command == "craft" then
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cff5af304Para establecer su tasa de creación, escriba '.craft X' donde X es un valor entre 1 y 2.|r"))
            return false
        end

        if rate and rate >= 1 and rate <= 2 then
            if player:HasItem(666, 1) or player:HasItem(666, 1) then
                player:SendBroadcastMessage(escaparCaracteresEspeciales("|cffff0000No puedes usar este comando mientras ciertos modos de desafío estén activos!|r"))
                return false
            end
            if CraftingRatesNamespace.GMonly and player:GetGMRank() < mingmrank then
                CraftingRatesNamespace.GMONLY(player)
                return false
            else
                CharDBExecute(string.format("REPLACE INTO custom_craft_rates (CharID, CraftRate) VALUES (%i, %d)", PUID, rate))
                player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Cambiaste tu tasa de creación a %dx|r", rate)))
                return false
            end
        else
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cffff0000Tarifa de embarcación no válida. Por favor introduzca un valor entre 1 y 2.|r"))
            return false
        end
    end
end

function CraftingRatesNamespace.onCreateItem(event, player, item, count)
    if not player then
        return
    end

    local itemEntry = item:GetEntry()
    local PUID = CraftingRatesNamespace.getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT CraftRate FROM custom_craft_rates WHERE CharID=%i", PUID))
    local CraftRate = 1

    if Q then
        CraftRate = Q:GetUInt32(0)
    end

    local additionalCount = (CraftRate - 1) * count

    if additionalCount > 0 then
        player:AddItem(itemEntry, additionalCount)
    end
end

function CraftingRatesNamespace.createCraftRatesTable()
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS custom_craft_rates (
            CharID INT PRIMARY KEY,
            CraftRate INT DEFAULT 1
        );
    ]])
end

if CraftingRatesNamespace.enabled then
    CraftingRatesNamespace.createCraftRatesTable()
    RegisterPlayerEvent(3, CraftingRatesNamespace.OnLogin)
    RegisterPlayerEvent(52, CraftingRatesNamespace.onCreateItem)
    RegisterPlayerEvent(42, CraftingRatesNamespace.SetCraftRate)
end

