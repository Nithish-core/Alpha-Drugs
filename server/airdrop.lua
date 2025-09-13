local QBCore = exports['qb-core']:GetCoreObject()
local ESX = exports['es_extended']:getSharedObject()
local activeDrops = {}
local nextDropTime = 0
local isDropping = false

-- Get the framework in use
local framework = GetResourceState('qb-core') == 'started' and 'qb' or 'esx'

-- Load config
local Config = require 'config'

-- Server event to start the airdrop system
RegisterNetEvent('alpha_drugs:server:startAirdropSystem', function()
    if not Config.Airdrop.Enabled then return end
    
    -- Schedule the first airdrop
    ScheduleNextAirdrop()
    
    print('^2[Airdrop] ^7Airdrop system started')
end)

-- Function to schedule the next airdrop
function ScheduleNextAirdrop()
    if not Config.Airdrop.Enabled then return end
    
    local minTime = Config.Airdrop.MinInterval * 60000 -- Convert to milliseconds
    local maxTime = Config.Airdrop.MaxInterval * 60000
    local randomTime = math.random(minTime, maxTime)
    
    nextDropTime = GetGameTimer() + randomTime
    
    SetTimeout(randomTime, function()
        if #GetPlayers() >= Config.Airdrop.MinPlayers then
            TriggerEvent('alpha_drugs:server:createAirdrop')
        else
            -- Not enough players, reschedule
            ScheduleNextAirdrop()
        end
    end)
    
    print(string.format('^3[Airdrop] ^7Next airdrop in %d minutes', randomTime / 60000))
end

-- Create an airdrop at a random location
RegisterNetEvent('alpha_drugs:server:createAirdrop', function()
    if isDropping then return end
    isDropping = true
    
    -- Get a random drop location
    local dropLocation = GetRandomDropLocation()
    if not dropLocation then
        isDropping = false
        ScheduleNextAirdrop()
        return
    end
    
    -- Send announcements
    for _, time in ipairs(Config.Airdrop.AnnouncementTimes) do
        SetTimeout((Config.Airdrop.AnnouncementTimes[1] - time) * 60000, function()
            if time > 1 then
                TriggerClientEvent('alpha_drugs:client:notifyAll', -1, {
                    title = 'Airdrop Incoming',
                    description = string.format('A supply drop will arrive in %d minutes!', time),
                    type = 'inform'
                })
            else
                TriggerClientEvent('alpha_drugs:client:notifyAll', -1, {
                    title = 'Airdrop Incoming',
                    description = 'A supply drop will arrive in 1 minute!',
                    type = 'inform'
                })
            end
        end)
    end
    
    -- Final announcement and drop
    SetTimeout(Config.Airdrop.AnnouncementTimes[1] * 60000, function()
        -- Create the airdrop for all players
        TriggerClientEvent('alpha_drugs:client:createAirdrop', -1, dropLocation)
        
        -- Store the airdrop data
        local dropId = #activeDrops + 1
        activeDrops[dropId] = {
            id = dropId,
            coords = dropLocation,
            loot = GenerateLoot(),
            openedBy = {},
            createdAt = os.time()
        }
        
        -- Clean up after a while
        SetTimeout(Config.Airdrop.Blip.time * 60000, function()
            TriggerClientEvent('alpha_drugs:client:removeAirdrop', -1, dropId)
            activeDrops[dropId] = nil
            isDropping = false
            ScheduleNextAirdrop()
        end)
    end)
end)

-- Get a random drop location
function GetRandomDropLocation()
    -- List of possible drop locations (you can add more)
    local locations = {
        vector3(0.0, 0.0, 70.0), -- Example coordinates, replace with actual locations
        vector3(100.0, 100.0, 70.0),
        vector3(-100.0, 100.0, 70.0),
        vector3(100.0, -100.0, 70.0),
        vector3(-100.0, -100.0, 70.0)
    }
    
    -- Find a location that's not in water and has ground
    for _, location in ipairs(locations) do
        local ground, groundZ = GetGroundZFor_3dCoord(location.x, location.y, location.z, true)
        if ground then
            return vector3(location.x, location.y, groundZ + 1.0)
        end
    end
    
    return nil
end

-- Generate random loot for the airdrop
function GenerateLoot()
    local loot = {}
    
    for _, item in ipairs(Config.Airdrop.Loot) do
        if math.random() <= item.chance then
            local count = type(item.count) == 'table' and math.random(item.count[1], item.count[2]) or item.count
            table.insert(loot, {
                name = item.name,
                count = count
            })
        end
    end
    
    return loot
end

-- Event when a player opens the airdrop
RegisterNetEvent('alpha_drugs:server:openAirdrop', function(dropId)
    local src = source
    local drop = activeDrops[dropId]
    
    if not drop then return end
    if drop.openedBy[src] then return end -- Already opened by this player
    
    -- Mark as opened by this player
    drop.openedBy[src] = true
    
    -- Give loot to player
    for _, item in ipairs(drop.loot) do
        if framework == 'qb' then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                Player.Functions.AddItem(item.name, item.count)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'add')
            end
        else -- ESX
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addInventoryItem(item.name, item.count)
            end
        end
    end
    
    -- Notify player
    TriggerClientEvent('alpha_drugs:client:notify', src, {
        title = 'Airdrop Looted',
        description = 'You have received loot from the airdrop!',
        type = 'success'
    })
end)

-- Admin command to force an airdrop
RegisterCommand('forceairdrop', function(source, args, rawCommand)
    if source == 0 then -- Console
        TriggerEvent('alpha_drugs:server:createAirdrop')
        return
    end
    
    -- Check if player has admin permissions (you'll need to implement your own permission check)
    local hasPermission = IsPlayerAceAllowed(tostring(source), 'command') -- Example permission check
    
    if hasPermission then
        TriggerEvent('alpha_drugs:server:createAirdrop')
        TriggerClientEvent('alpha_drugs:client:notify', source, {
            title = 'Airdrop',
            description = 'Airdrop has been forced!',
            type = 'success'
        })
    else
        TriggerClientEvent('alpha_drugs:client:notify', source, {
            title = 'Error',
            description = 'You do not have permission to do that!',
            type = 'error'
        })
    end
end, false)

-- Start the airdrop system when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Wait for framework to be ready
    Citizen.Wait(1000)
    
    -- Start the airdrop system
    TriggerEvent('alpha_drugs:server:startAirdropSystem')
end)
