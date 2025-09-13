local activeDrops = {}
local activeBlips = {}
local isOpening = false

-- Load config
local Config = require 'config'

-- Create an airdrop at the specified location
RegisterNetEvent('alpha_drugs:client:createAirdrop', function(dropId, coords)
    -- Remove any existing drop with the same ID
    if activeDrops[dropId] then
        RemoveAirdrop(dropId)
    end
    
    -- Create the airdrop
    local drop = {
        id = dropId,
        coords = coords,
        objects = {},
        blip = nil
    }
    
    -- Load models
    RequestModel(Config.Airdrop.CrateModel)
    RequestModel(Config.Airdrop.ParachuteModel)
    
    while not HasModelLoaded(Config.Airdrop.CrateModel) or not HasModelLoaded(Config.Airdrop.ParachuteModel) do
        Wait(0)
    end
    
    -- Create parachute
    local parachute = CreateObject(
        GetHashKey(Config.Airdrop.ParachuteModel),
        coords.x, coords.y, coords.z + Config.Airdrop.DropHeight,
        false, true, true
    )
    SetEntityLodDist(parachute, 1000)
    SetEntityInvincible(parachute, true)
    
    -- Create crate
    local crate = CreateObject(
        GetHashKey(Config.Airdrop.CrateModel),
        coords.x, coords.y, coords.z + Config.Airdrop.DropHeight - 2.0,
        false, true, true
    )
    SetEntityLodDist(crate, 1000)
    SetEntityInvincible(crate, true)
    
    -- Attach crate to parachute
    AttachEntityToEntity(
        crate, parachute,
        0, 0.0, 0.0, 2.0,
        0.0, 0.0, 0.0,
        false, false, false, false, 2, true
    )
    
    -- Store objects
    drop.objects = {
        parachute = parachute,
        crate = crate
    }
    
    -- Add blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Airdrop.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Airdrop.Blip.scale)
    SetBlipColour(blip, Config.Airdrop.Blip.color)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Airdrop.Blip.label)
    EndTextCommandSetBlipName(blip)
    
    drop.blip = blip
    activeBlips[dropId] = blip
    
    -- Start drop animation
    StartDropAnimation(drop)
    
    -- Store the drop
    activeDrops[dropId] = drop
    
    -- Create target zone for interaction
    exports.ox_target:addSphereZone({
        coords = vec3(coords.x, coords.y, coords.z + 1.0),
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'airdrop_open',
                icon = 'fas fa-box-open',
                label = 'Open Airdrop',
                onSelect = function()
                    OpenAirdrop(dropId)
                end,
                distance = 2.0
            }
        }
    })
    
    -- Add smoke effect when landed
    CreateThread(function()
        while not HasEntityCollidedWithAnything(crate) do
            Wait(100)
        end
        
        -- Remove parachute
        DeleteEntity(parachute)
        
        -- Add smoke effect
        UseParticleFxAssetNextCall('core')
        local particle = StartParticleFxLoopedAtCoord(
            Config.Airdrop.SmokeEffect,
            coords.x, coords.y, coords.z + 1.0,
            0.0, 0.0, 0.0,
            1.0,
            false, false, false, false
        )
        
        -- Store particle effect
        activeDrops[dropId].particle = particle
    end)
end)

-- Animation for the airdrop falling
function StartDropAnimation(drop)
    CreateThread(function()
        local crate = drop.objects.crate
        local parachute = drop.objects.parachute
        local startTime = GetGameTimer()
        local dropTime = 10000 -- 10 seconds to drop
        
        while GetGameTimer() - startTime < dropTime do
            local progress = (GetGameTimer() - startTime) / dropTime
            local height = Config.Airdrop.DropHeight * (1 - progress)
            
            local currentCoords = GetEntityCoords(crate)
            local targetCoords = vector3(
                drop.coords.x,
                drop.coords.y,
                drop.coords.z + height
            )
            
            SetEntityCoords(crate, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
            
            -- Rotate the crate for visual effect
            local rot = GetEntityRotation(crate)
            SetEntityRotation(crate, rot.x + 1.0, rot.y, rot.z + 1.0, 2, true)
            
            Wait(0)
        end
        
        -- Make sure it's at the correct position
        SetEntityCoords(crate, drop.coords.x, drop.coords.y, drop.coords.z, false, false, false, true)
    end)
end

-- Remove an airdrop
RegisterNetEvent('alpha_drugs:client:removeAirdrop', function(dropId)
    RemoveAirdrop(dropId)
end)

function RemoveAirdrop(dropId)
    local drop = activeDrops[dropId]
    if not drop then return end
    
    -- Remove objects
    if DoesEntityExist(drop.objects.parachute) then
        DeleteEntity(drop.objects.parachute)
    end
    
    if DoesEntityExist(drop.objects.crate) then
        DeleteEntity(drop.objects.crate)
    end
    
    -- Remove particle effect
    if drop.particle then
        StopParticleFxLooped(drop.particle, false)
    end
    
    -- Remove blip
    if activeBlips[dropId] then
        RemoveBlip(activeBlips[dropId])
        activeBlips[dropId] = nil
    end
    
    -- Remove target zone
    exports.ox_target:removeZone('airdrop_' .. dropId)
    
    -- Remove from active drops
    activeDrops[dropId] = nil
end

-- Open the airdrop
function OpenAirdrop(dropId)
    if isOpening then return end
    isOpening = true
    
    -- Play animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
    
    -- Start minigame
    local success = StartMinigame()
    
    -- Stop animation
    ClearPedTasks(playerPed)
    
    if success then
        -- Notify server that player opened the airdrop
        TriggerServerEvent('alpha_drugs:server:openAirdrop', dropId)
    else
        -- Notify player they failed
        lib.notify({
            title = 'Airdrop',
            description = 'You failed to open the airdrop!',
            type = 'error'
        })
    end
    
    isOpening = false
end

-- Minigame to open the airdrop
function StartMinigame()
    local difficulty = Config.Airdrop.Minigame.difficulty
    local time = Config.Airdrop.Minigame.time
    local circles = Config.Airdrop.Minigame.circles
    local areaSize = Config.Airdrop.Minigame.areaSize
    
    -- Use ox_lib's minigame system
    local success = lib.skillCheck({
        difficulty = {difficulty},
        inputs = {'E'},
        areaSize = areaSize,
        speedMultiplier = Config.Airdrop.Minigame.speed
    }, {
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
    })
    
    return success
end

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Remove all airdrops
    for dropId in pairs(activeDrops) do
        RemoveAirdrop(dropId)
    end
end)
