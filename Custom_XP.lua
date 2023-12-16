CustomXPNamespace = {}

CustomXPNamespace.enabled = true
CustomXPNamespace.GMonly = false

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

function CustomXPNamespace.getPlayerCharacterGUID(player)
    if not player then
        print("Error: Player object is nil in getPlayerCharacterGUID")
        return nil
    end
    return player:GetGUIDLow()
end

function CustomXPNamespace.GMONLY(player)
    if not player then
        return
    end
    -- player:SendBroadcastMessage("|cffff0000You don't have permission to use this command.|r")
end

function CustomXPNamespace.OnLogin(event, player)
if not player then
        return
    end
    local PUID = CustomXPNamespace.getPlayerCharacterGUID(player)
    local Q = WorldDBQuery(string.format("SELECT * FROM custom_xp WHERE CharID=%i", PUID))

    if player:HasItem(666, 1) then
        local specialRate = 2
        if Q then
            WorldDBExecute(string.format("UPDATE custom_xp SET Rate = %.2f WHERE CharID = %i", specialRate, PUID))
        else
            WorldDBExecute(string.format("INSERT INTO custom_xp VALUES (%i, %.2f)", PUID, specialRate))
        end
        player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Su tasa de experiencia está establecida en %.1fx porque eres un jugador Hardcore.|r", specialRate)))
        return
    end

    if Q then
        local CharID, Rate = Q:GetUInt32(0), Q:GetFloat(1)
        player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Su tasa de experiencia está actualmente establecida en %.1f|r", Rate)))
    else
        local defaultRate = 1
        WorldDBExecute(string.format("INSERT INTO custom_xp VALUES (%i, %.2f)", PUID, defaultRate))
        player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Su tasa de experiencia está configurada de forma predeterminada: %.1fx|r", defaultRate)))
    end
end

function CustomXPNamespace.SetRate(event, player, command)
if not player then
        return
    end
    local mingmrank = 3
    local PUID = CustomXPNamespace.getPlayerCharacterGUID(player)
    
    if command:find("xp") or command:find("exp") then
        if player:HasItem(666, 1) then
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cffff0000No tienes acceso a esta función porque eres un jugador Hardcore.|r"))
            return false
        end

        if command:find("q") or command:find("Q") or command:find("?") or command == "xp" or command == "exp" then
            local Q = WorldDBQuery(string.format("SELECT * FROM custom_xp WHERE CharID=%i", PUID))
            if Q then
                local CharID, Rate = Q:GetUInt32(0), Q:GetFloat(1)
                player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Su tasa de experiencia está actualmente configurada en %.1fx|r", Rate)))
            else
                player:SendBroadcastMessage(escaparCaracteresEspeciales("|cff5af304No se encuentra su tasa de experiencia; se aplicará la tasa de experiencia predeterminada.|r"))
            end
            
            player:SendBroadcastMessage(escaparCaracteresEspeciales("|cff5af304Para establecer su tasa de experiencia, escriba '.xp X' o '.exp X' donde X es un valor entre 0,01 y 5.|r"))
            return false
        end

        local rate = tonumber(command:sub(command:find("xp") and 4 or 5))

        if rate and rate >= 0.01 and rate <= 5 then
            if CustomXPNamespace.GMonly and player:GetGMRank() < mingmrank then
                CustomXPNamespace.GMONLY(player)
                return false
            elseif not CustomXPNamespace.GMonly or player:GetGMRank() >= mingmrank then
                WorldDBExecute(string.format("UPDATE custom_xp SET Rate = %.2f WHERE CharID = %i", rate, PUID))
                player:SendBroadcastMessage(escaparCaracteresEspeciales(string.format("|cff5af304Cambiaste tu tasa de experiencia a %.2fx|r", rate)))
                return false
            end
        end
    end
end

function CustomXPNamespace.OnXP(event, player, amount, victim)
if not player then
        return
    end
    local PUID = CustomXPNamespace.getPlayerCharacterGUID(player)
    local Q = WorldDBQuery(string.format("SELECT * FROM custom_xp WHERE CharID=%i", PUID))
    local mingmrank = 3

    if Q then
        local CharID, Rate = Q:GetUInt32(0), Q:GetFloat(1)
        Rate = tonumber(string.format("%.1f", Rate))

        if (CustomXPNamespace.GMonly and player:GetGMRank() < mingmrank) then
            return amount
        end

        if (CustomXPNamespace.GMonly and player:GetGMRank() >= mingmrank) then
            return amount * Rate
        end

        if (not CustomXPNamespace.GMonly) then
            return amount * Rate
        end
    else
        return amount
    end
end

if CustomXPNamespace.enabled then
    RegisterPlayerEvent(3, CustomXPNamespace.OnLogin)
    RegisterPlayerEvent(12, CustomXPNamespace.OnXP)
    RegisterPlayerEvent(42, CustomXPNamespace.SetRate)
end
