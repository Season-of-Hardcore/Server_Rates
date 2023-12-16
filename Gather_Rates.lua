GatherRatesNamespace = {}

GatherRatesNamespace.enabled = true
GatherRatesNamespace.GMonly = false

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


function GatherRatesNamespace.getPlayerCharacterGUID(player)
    if not player then
        print("Error: Player object is nil in getPlayerCharacterGUID")
        return nil
    end
    return player:GetGUIDLow()
end

function GatherRatesNamespace.GMONLY(player)
    if not player then
        return
    end
    -- player:SendBroadcastMessage("|cffff0000You don't have permission to use this command.|r")
end

function GatherRatesNamespace.OnLogin(event, player)
    if not player then
        return
    end
    local PUID = GatherRatesNamespace.getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT GatherRate FROM custom_gather_rates WHERE CharID=%i", PUID))

    if Q then
        local GatherRate = Q:GetUInt32(0)
        player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Tu tasa de recolección está actualmente configurada en %dx|r", GatherRate)))
    end
end

function GatherRatesNamespace.SetGatherRate(event, player, command)
    if not player then
        return
    end
    local mingmrank = 3
    local PUID = GatherRatesNamespace.getPlayerCharacterGUID(player)

    if command:find("ga") then
        local rate = tonumber(command:sub(4))

        if command == "ga" then
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cff5af304Para establecer su tasa de recolección, escriba '.ga X' donde X es un valor entre 1 y 10.|r"))
            return false
        end

        if rate and rate >= 1 and rate <= 2 then
            if player:HasItem(666, 1) or player:HasItem(666, 1) then
                player:SendBroadcastMessage(escaparCaracteresEspeciales("|cffff0000No puedes usar este comando mientras ciertos modos de desafío estén activos!|r"))
                return false
            end
            if GatherRatesNamespace.GMonly and player:GetGMRank() < mingmrank then
                GatherRatesNamespace.GMONLY(player)
                return false
            else
                CharDBExecute(string.format("REPLACE INTO custom_gather_rates (CharID, GatherRate) VALUES (%i, %d)", PUID, rate))
                player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Cambiaste tu tasa de recolección a %dx|r", rate)))
                return false
            end
        else
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cffff0000Tasa de recogida no válida. Por favor introduzca un valor entre 1 y 2.|r"))
            return false
        end
    end
end

function GatherRatesNamespace.onLootItem(event, player, item, count)
    if not player then
        return
    end
    local itemEntry = item:GetEntry()
    local PUID = GatherRatesNamespace.getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT GatherRate FROM custom_gather_rates WHERE CharID=%i", PUID))
    local GatherRate = 1

    if Q then
        GatherRate = Q:GetUInt32(0)
    end

    if item:GetClass() == 7 then
        local additionalCount = (GatherRate - 1) * count
        
        if additionalCount > 0 then
            player:AddItem(itemEntry, additionalCount)
        end
    end
end

function GatherRatesNamespace.createGatherRatesTable()
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS custom_gather_rates (
            CharID INT PRIMARY KEY,
            GatherRate INT DEFAULT 1
        );
    ]])
end

if GatherRatesNamespace.enabled then
    GatherRatesNamespace.createGatherRatesTable()
    RegisterPlayerEvent(3, GatherRatesNamespace.OnLogin)
    RegisterPlayerEvent(32, GatherRatesNamespace.onLootItem)
    RegisterPlayerEvent(42, GatherRatesNamespace.SetGatherRate)
end
