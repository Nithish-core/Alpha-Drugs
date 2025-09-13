local QBCore = exports['qb-core']:GetCoreObject()
local ESX = exports['es_extended']:getSharedObject()
local activeLabs = {}
local playerLabs = {}

-- Initialize the resource
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Load all saved labs from the database
    LoadAllLabs()
    
    -- Set up framework specific events
    SetupFrameworkEvents()
    
    print('^2[Alpha Drugs]^7 Drug system initialized')
end)

-- Load all labs from the database
function LoadAllLabs()
    -- In a real implementation, this would load from a database
    -- For now, we'll use an empty table
    activeLabs = {}
    playerLabs = {}
    
    -- Here you would load labs from your database
    -- Example:
    -- local result = MySQL.query.await('SELECT * FROM alpha_drugs_labs')
    -- for _, labData in ipairs(result) do
    --     local lab = Lab:New(labData)
    --     activeLabs[lab.id] = lab
    --     
    --     -- Track labs by owner
    --     if not playerLabs[lab.owner] then
    --         playerLabs[lab.owner] = {}
    --     end
    --     table.insert(playerLabs[lab.owner], lab.id)
    -- end
    
    print(('^2[Alpha Drugs]^7 Loaded %d labs'):format(#activeLabs))
end

-- Save all labs to the database
function SaveAllLabs()
    local saved = 0
    
    for _, lab in pairs(activeLabs) do
        if lab:Save() then
            saved = saved + 1
        end
    end
    
    print(('^2[Alpha Drugs]^7 Saved %d labs'):format(saved))
    return saved
end

-- Get a lab by ID
function GetLabById(labId)
    return activeLabs[labId]
end

-- Get all labs owned by a player
function GetPlayerLabs(identifier)
    return playerLabs[identifier] or {}
end

-- Create a new lab
function CreateLab(source, labType, position, heading)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return false, 'Invalid player' end
    
    -- Check if player has reached the maximum number of labs
    local playerLabCount = #(playerLabs[identifier] or {})
    if playerLabCount >= Config.LabCreation.maxLabsPerPlayer and not IsPlayerAceAllowed(source, 'command') then
        return false, 'max_labs_reached'
    end
    
    -- Create new lab
    local lab = Lab:New({
        type = labType,
        owner = identifier,
        coords = position,
        heading = heading or 0.0,
        active = true
    })
    
    -- Add to active labs
    activeLabs[lab.id] = lab
    
    -- Track lab by owner
    if not playerLabs[identifier] then
        playerLabs[identifier] = {}
    end
    table.insert(playerLabs[identifier], lab.id)
    
    -- Save lab to database
    lab:Save()
    
    return true, lab.id
end

-- Delete a lab
function DeleteLab(labId, source)
    local lab = activeLabs[labId]
    if not lab then return false, 'Lab not found' end
    
    -- Check permissions
    local identifier = GetPlayerIdentifier(source, 0)
    if lab.owner ~= identifier and not IsPlayerAceAllowed(source, 'command') then
        return false, 'no_permission'
    end
    
    -- Notify players in the lab
    lab:Broadcast('lab_deleted', {reason = 'admin_action'})
    
    -- Remove from active labs
    activeLabs[labId] = nil
    
    -- Remove from player's lab list
    if playerLabs[lab.owner] then
        for i, labId in ipairs(playerLabs[lab.owner]) do
            if labId == labId then
                table.remove(playerLabs[lab.owner], i)
                break
            end
        end
    end
    
    -- Delete from database
    -- MySQL.query('DELETE FROM alpha_drugs_labs WHERE id = ?', {labId})
    
    return true
end

-- Player entered a lab
RegisterNetEvent('alpha_drugs:enterLab')
AddEventHandler('alpha_drugs:enterLab', function(labId)
    local source = source
    local lab = activeLabs[labId]
    
    if not lab then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Lab not found'
        })
        return
    end
    
    -- Add player to lab
    if lab:AddPlayer(source) then
        -- Load lab data for the player
        TriggerClientEvent('alpha_drugs:lab:enter', source, lab:GetClientData())
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Failed to enter lab'
        })
    end
end)

-- Player left a lab
RegisterNetEvent('alpha_drugs:leaveLab')
AddEventHandler('alpha_drugs:leaveLab', function(labId)
    local source = source
    local lab = activeLabs[labId]
    
    if lab then
        lab:RemovePlayer(source)
    end
end)

-- Player planted a seed (Weed Lab)
RegisterNetEvent('alpha_drugs:plantSeed')
AddEventHandler('alpha_drugs:plantSeed', function(labId, seedType)
    local source = source
    local lab = activeLabs[labId]
    
    if not lab then return end
    if lab.type ~= 'weed' then return end
    
    lab:PlantSeed(source, seedType)
end)

-- Player harvested a plant (Weed Lab)
RegisterNetEvent('alpha_drugs:harvestPlant')
AddEventHandler('alpha_drugs:harvestPlant', function(labId, plantId)
    local source = source
    local lab = activeLabs[labId]
    
    if not lab then return end
    if lab.type ~= 'weed' then return end
    
    lab:HarvestPlant(source, plantId)
end)

-- Player started cooking meth (Meth Lab)
RegisterNetEvent('alpha_drugs:startMethCooking')
AddEventHandler('alpha_drugs:startMethCooking', function(labId, recipe)
    local source = source
    local lab = activeLabs[labId]
    
    if not lab then return end
    if lab.type ~= 'meth' then return end
    
    lab:StartMethCooking(source, recipe)
end)

-- Player collected meth (Meth Lab)
RegisterNetEvent('alpha_drugs:collectMeth')
AddEventHandler('alpha_drugs:collectMeth', function(labId, batchId)
    local source = source
    local lab = activeLabs[labId]
    
    if not lab then return end
    if lab.type ~= 'meth' then return end
    
    lab:CollectMethBatch(source, batchId)
end)

-- Admin command to create a lab
RegisterCommand('createlab', function(source, args, rawCommand)
    if source == 0 then
        print('This command cannot be run from the console')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[SYSTEM]', 'Usage: /createlab <type> (weed/meth/cocaine)'}
        })
        return
    end
    
    local labType = args[1]:lower()
    if not Config.Labs[labType] then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[SYSTEM]', 'Invalid lab type. Available types: weed, meth, cocaine'}
        })
        return
    end
    
    -- Get player's position and heading
    TriggerClientEvent('alpha_drugs:getPlayerPosition', source, labType)
end, true)

-- Admin command to delete a lab
RegisterCommand('deletelab', function(source, args, rawCommand)
    if source == 0 then
        print('This command cannot be run from the console')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[SYSTEM]', 'Usage: /deletelab <labId>'}
        })
        return
    end
    
    local labId = args[1]
    local success, message = DeleteLab(labId, source)
    
    if success then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[SYSTEM]', 'Lab deleted successfully'}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[SYSTEM]', 'Failed to delete lab: ' .. (message or 'unknown error')}
        })
    end
end, true)

-- Client requested to create a lab at their position
RegisterNetEvent('alpha_drugs:createLabAtPosition')
AddEventHandler('alpha_drugs:createLabAtPosition', function(labType, position, heading)
    local source = source
    
    -- Check if player has permission to create labs
    if not IsPlayerAceAllowed(source, 'command') then
        -- Check if player has the required item to create a lab
        if not HasItem(source, Config.Labs[labType].item, 1) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'You need a ' .. Config.Labs[labType].label .. ' to create this lab'
            })
            return
        end
        
        -- Remove the lab item
        RemoveItem(source, Config.Labs[labType].item, 1)
    end
    
    -- Create the lab
    local success, result = CreateLab(source, labType, position, heading)
    
    if success then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Lab created successfully! ID: ' .. result
        })
        
        -- Teleport player into the lab
        TriggerClientEvent('alpha_drugs:enterLab', source, result)
    else
        local message = 'Failed to create lab'
        if result == 'max_labs_reached' then
            message = 'You have reached the maximum number of labs'
        end
        
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = message
        })
    end
end)

-- Save all labs periodically
local function saveLabs()
    SaveAllLabs()
    SetTimeout(5 * 60 * 1000, saveLabs) -- Save every 5 minutes
end

-- Start the save timer
SetTimeout(5 * 60 * 1000, saveLabs)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Save all labs before stopping
    SaveAllLabs()
    
    -- Notify all players in labs that the resource is stopping
    for _, lab in pairs(activeLabs) do
        lab:Broadcast('resource_stopping', {reason = 'Resource stopped'})
    end
end)

-- Player dropped
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Remove player from any labs they were in
    for _, lab in pairs(activeLabs) do
        if lab:HasPlayer(source) then
            lab:RemovePlayer(source)
        end
    end
end)

-- Helper function to check if a player has an item
function HasItem(source, item, amount)
    if not source or not item then return false end
    amount = amount or 1
    
    -- Check based on framework
    if GetResourceState('es_extended') == 'started' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local itemData = xPlayer.getInventoryItem(item)
        return itemData and itemData.count >= amount
    elseif GetResourceState('qb-core') == 'started' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= amount
    end
    
    -- Default to true if no framework is detected
    return true
end

-- Helper function to remove an item from a player
function RemoveItem(source, item, amount)
    if not source or not item then return false end
    amount = amount or 1
    
    -- Remove based on framework
    if GetResourceState('es_extended') == 'started' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        return xPlayer.removeInventoryItem(item, amount)
    elseif GetResourceState('qb-core') == 'started' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player.Functions.RemoveItem(item, amount)
    end
    
    -- Default to true if no framework is detected
    return true
end

-- Setup framework specific events
function SetupFrameworkEvents()
    -- ESX
    if GetResourceState('es_extended') == 'started' then
        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
            -- Send any lab data the player might need
            local identifier = xPlayer.identifier
            local labs = GetPlayerLabs(identifier)
            
            if #labs > 0 then
                local labData = {}
                for _, labId in ipairs(labs) do
                    local lab = activeLabs[labId]
                    if lab then
                        table.insert(labData, lab:GetClientData())
                    end
                end
                
                TriggerClientEvent('alpha_drugs:playerLabsLoaded', playerId, labData)
            end
        end)
    
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        RegisterNetEvent('QBCore:Server:OnPlayerLoaded')
        AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
            local src = source
            local Player = QBCore.Functions.GetPlayer(src)
            if not Player then return end
            
            local identifier = Player.PlayerData.citizenid
            local labs = GetPlayerLabs(identifier)
            
            if #labs > 0 then
                local labData = {}
                for _, labId in ipairs(labs) do
                    local lab = activeLabs[labId]
                    if lab then
                        table.insert(labData, lab:GetClientData())
                    end
                end
                
                TriggerClientEvent('alpha_drugs:playerLabsLoaded', src, labData)
            end
        end)
    end
end

-- Exports
-- Get a player's labs
exports('GetPlayerLabs', function(identifier)
    return GetPlayerLabs(identifier)
end)

-- Get a lab by ID
exports('GetLabById', function(labId)
    return GetLabById(labId)
end)

-- Create a new lab
exports('CreateLab', function(source, labType, position, heading)
    return CreateLab(source, labType, position, heading)
end)

-- Delete a lab
exports('DeleteLab', function(labId, source)
    return DeleteLab(labId, source)
end)
