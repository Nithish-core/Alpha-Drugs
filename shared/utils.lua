local Utils = {}

-- Get framework object
function Utils.GetFramework()
    if not Config.Framework or Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            return 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            return 'qbcore'
        elseif GetResourceState('qbx_core') == 'started' then
            return 'qbox'
        else
            return 'standalone'
        end
    end
    return Config.Framework
end

-- Get player identifier
function Utils.GetPlayerIdentifier(source)
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    else
        -- For standalone, use server ID as fallback
        return tostring(GetPlayerIdentifierByType(source, 'license'))
    end
end

-- Get player name
function Utils.GetPlayerName(source)
    return GetPlayerName(source) or 'Unknown'
end

-- Check if player has item
function Utils.HasItem(source, item, amount)
    amount = amount or 1
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local itemData = xPlayer.getInventoryItem(item)
        return itemData and itemData.count >= amount
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= amount
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        local itemData = player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= amount
    else
        -- For standalone, you would implement your own inventory check
        return true
    end
end

-- Remove item from player
function Utils.RemoveItem(source, item, amount)
    amount = amount or 1
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        return xPlayer.removeInventoryItem(item, amount)
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, amount)
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveItem(item, amount)
    else
        -- For standalone, implement your own item removal
        return true
    end
end

-- Add item to player
function Utils.AddItem(source, item, amount, metadata)
    amount = amount or 1
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        return xPlayer.addInventoryItem(item, amount, metadata)
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(item, amount, false, metadata or {})
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        return player.Functions.AddItem(item, amount, false, metadata or {})
    else
        -- For standalone, implement your own item addition
        return true
    end
end

-- Get player money
function Utils.GetMoney(source, moneyType)
    moneyType = moneyType or 'money'
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end
        if moneyType == 'money' then
            return xPlayer.getMoney()
        else
            return xPlayer.getAccount(moneyType)?.money or 0
        end
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        if moneyType == 'money' then
            return Player.PlayerData.money.cash
        else
            return Player.PlayerData.money[moneyType] or 0
        end
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return 0 end
        if moneyType == 'money' then
            return player.PlayerData.money.cash
        else
            return player.PlayerData.money[moneyType] or 0
        end
    else
        -- For standalone, implement your own money check
        return 999999
    end
end

-- Remove money from player
function Utils.RemoveMoney(source, moneyType, amount)
    amount = amount or 0
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        if moneyType == 'money' then
            return xPlayer.removeMoney(amount)
        else
            return xPlayer.removeAccountMoney(moneyType, amount)
        end
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveMoney(moneyType, amount)
    elseif framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveMoney(moneyType, amount)
    else
        -- For standalone, implement your own money removal
        return true
    end
end

-- Notification system
function Utils.Notify(source, message, type, length)
    type = type or 'info'
    length = length or 5000
    
    if not source then
        Debug('Notification called without source:', message)
        return
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        description = message,
        type = type,
        position = 'top',
        duration = length
    })
end

-- Check if player has a specific job/permission
function Utils.HasPermission(source, permission)
    local framework = Utils.GetFramework()
    
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        -- Check for admin groups
        if permission == 'admin' then
            for _, group in ipairs(Config.LabCreation.adminGroups) do
                if xPlayer.getGroup() == group then
                    return true
                end
            end
        end
        
        -- Add more permission checks as needed
        return false
        
    elseif framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        if permission == 'admin' then
            return QBCore.Functions.HasPermission(source, Config.LabCreation.adminGroups)
        end
        
        return false
        
    elseif framework == 'qbox' then
        -- QBOX permission check implementation
        return false
        
    else
        -- For standalone, implement your own permission check
        return true
    end
end

-- Generate a unique ID
function Utils.GenerateUniqueId()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Format time (seconds to MM:SS)
function Utils.FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format('%02d:%02d', minutes, remainingSeconds)
end

-- Deep copy a table
function Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Check if table is empty
function Utils.IsTableEmpty(t)
    if not t then return true end
    for _, _ in pairs(t) do
        return false
    end
    return true
end

-- Get localized string
function Utils.GetLocaleString(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    local text = locale[key] or key
    
    if select('#', ...) > 0 then
        return string.format(text, ...)
    end
    
    return text
end

return Utils
