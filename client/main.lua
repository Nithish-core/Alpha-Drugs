local QBCore = exports['qb-core']:GetCoreObject()
local currentLab = nil
local isInLab = false
local labBlips = {}
local labMarkers = {}
local labObjects = {}
local labZones = {}
local activeSounds = {}

-- Sound handling functions
local function PlaySound3D(soundData, coords, range, loop)
    if not soundData or not soundData.file then return end
    
    range = range or 10.0
    local soundId = soundData.name or ('sound_%s'):format(math.random(10000, 99999))
    
    -- Use ox_lib's playSound for 3D audio
    if coords then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - coords)
        
        -- Only play if within range
        if distance <= range then
            -- Calculate volume based on distance (exponential falloff)
            local volume = soundData.volume or 0.5
            if distance > 1.0 then
                -- Exponential falloff for more realistic 3D sound
                local falloff = 1.0 - (distance / range) ^ 2
                volume = volume * math.max(0.1, falloff)
            end
            
            -- Play the sound with 3D positioning
            local soundFile = 'sounds/' .. soundData.file
            local sound = {}
            
            -- Use ox_lib's playSound with 3D positioning
            sound.id = lib.playSound(soundFile, {
                volume = volume,
                onPlay = function()
                    -- Update sound position when it starts playing
                    if coords then
                        local soundCoords = GetEntityCoords(PlayerPedId())
                        local distance = #(soundCoords - coords)
                        local direction = (coords - soundCoords) / distance
                        
                        -- Set sound position relative to player
                        local soundId = GetSoundId()
                        PlaySoundFromCoord(
                            soundId,
                            soundFile,
                            direction.x,
                            direction.y,
                            direction.z,
                            0, -- No sound set
                            false, -- Don't play on entity
                            0, -- No range
                            0 -- No reverb
                        )
                        
                        -- Update volume based on distance
                        local volume = soundData.volume or 0.5
                        if distance > 1.0 then
                            local falloff = 1.0 - (distance / range) ^ 2
                            volume = volume * math.max(0.1, falloff)
                        end
                        
                        -- Apply volume and 3D effects
                        SetSoundVolume(soundId, volume * 0.1) -- Adjust multiplier as needed
                        SetSoundReflectionOcclusion(0.0) -- No occlusion for now
                        SetSoundPitch(soundId, 1.0)
                        
                        -- Store sound ID for later updates
                        sound.soundId = soundId
                    end
                end,
                onEnd = function()
                    -- Clean up sound
                    if sound.soundId then
                        StopSound(sound.soundId)
                        ReleaseSoundId(sound.soundId)
                    end
                end
            })
            
            -- Store active sound
            activeSounds[soundId] = {
                coords = coords,
                range = range,
                volume = soundData.volume or 0.5,
                loop = loop or false,
                sound = sound
            }
            
            return soundId
        end
    else
        -- Play as 2D sound (non-positional)
        local soundFile = 'sounds/' .. soundData.file
        local sound = lib.playSound(soundFile, {
            volume = soundData.volume or 0.5,
            loop = loop or false
        })
        
        activeSounds[soundId] = {
            coords = nil,
            loop = loop or false,
            sound = sound
        }
        
        return soundId
    end
end

local function StopSound(soundId)
    if not soundId or not activeSounds[soundId] then return end
    
    local sound = activeSounds[soundId].sound
    if sound and sound.stop then
        sound:stop()
    end
    
    -- Release any sound IDs
    if sound and sound.soundId then
        StopSound(sound.soundId)
        ReleaseSoundId(sound.soundId)
    end
    
    activeSounds[soundId] = nil
end

-- Update 3D sound positions based on player movement
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for soundId, soundData in pairs(activeSounds) do
            if soundData.coords and soundData.sound and soundData.sound.soundId then
                local distance = #(playerCoords - soundData.coords)
                
                -- Stop sounds that are too far away
                if distance > soundData.range * 1.5 then
                    StopSound(soundId)
                else
                    -- Calculate direction vector from player to sound
                    local direction = (soundData.coords - playerCoords) / distance
                    
                    -- Update sound position
                    SetSoundPosition(
                        soundData.sound.soundId,
                        direction.x,
                        direction.y,
                        direction.z,
                        false -- Not relative to entity
                    )
                    
                    -- Update volume based on distance (exponential falloff)
                    local volume = soundData.volume
                    if distance > 1.0 then
                        local falloff = 1.0 - (distance / soundData.range) ^ 2
                        volume = volume * math.max(0.1, falloff)
                    end
                    
                    -- Apply volume
                    SetSoundVolume(soundData.sound.soundId, volume * 0.1) -- Adjust multiplier as needed
                end
            end
        end
        
        Wait(100) -- Update more frequently for smoother 3D audio
    end
end)

-- Initialize the client
CreateThread(function()
    -- Wait for the framework to be ready
    while not (GetResourceState('qb-core') == 'started' or GetResourceState('es_extended') == 'started') do
        Wait(100)
    end
    
    -- Initialize the target system
    if Config.Target == 'ox_target' and GetResourceState('ox_target') == 'started' then
        InitOxTarget()
    end
    
    -- Create blips for existing labs
    CreateLabBlips()
    
    -- Start the main thread
    StartLabSystem()
end)

-- Initialize Ox Target integration
function InitOxTarget()
    -- This will be implemented in a separate file
end

-- Create blips for all labs
function CreateLabBlips()
    -- Clear existing blips
    for _, blip in pairs(labBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    labBlips = {}
    
    -- Add blips for each lab type
    for labType, config in pairs(Config.Labs) do
        local blip = AddBlipForCoord(0, 0, 0) -- Position will be updated when labs are loaded
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, config.blip.scale)
        SetBlipColour(blip, config.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(config.blip.label)
        EndTextCommandSetBlipName(blip)
        
        -- Hide by default, will be shown when labs are loaded
        SetBlipHiddenOnLegend(blip, true)
        
        labBlips[labType] = blip
    end
end

-- Main thread for the lab system
function StartLabSystem()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check if player is in a lab
        if currentLab then
            local lab = currentLab
            local labCoords = vector3(lab.coords.x, lab.coords.y, lab.coords.z)
            local distance = #(playerCoords - labCoords)
            
            -- Check if player has left the lab
            if distance > 50.0 then
                ExitLab()
            end
        end
        
        -- Check for nearby labs
        if not isInLab then
            for labId, lab in pairs(activeLabs) do
                local labCoords = vector3(lab.coords.x, lab.coords.y, lab.coords.z)
                local distance = #(playerCoords - labCoords)
                
                -- Show marker if player is close to a lab
                if distance < 20.0 then
                    DrawMarker(1, labCoords.x, labCoords.y, labCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                    
                    -- Show interaction prompt
                    if distance < 2.0 then
                        Draw3DText(labCoords.x, labCoords.y, labCoords.z + 1.0, '~g~E~w~ - Enter ' .. (Config.Labs[lab.type] and Config.Labs[lab.type].label or 'Lab'))
                        
                        -- Enter lab on key press
                        if IsControlJustReleased(0, 38) then -- E key
                            EnterLab(labId)
                        end
                    end
                end
            end
        end
        
        Wait(0)
    end
end

-- Draw 3D text
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Enter a lab
function EnterLab(labId)
    local lab = activeLabs[labId]
    if not lab then return end
    
    -- Notify server
    TriggerServerEvent('alpha_drugs:enterLab', labId)
    
    -- Store current lab data
    currentLab = lab
    isInLab = true
    
    -- Get interior coords based on lab type
    local interiorCoords = Config.LabInteriors[lab.type] or Config.LabInteriors.default
    
    -- Load interior
    LoadInterior(interiorCoords.interiorId)
    
    -- Fade out screen
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    -- Teleport player to interior
    SetEntityCoords(PlayerPedId(), interiorCoords.inside.x, interiorCoords.inside.y, interiorCoords.inside.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), interiorCoords.inside.w or 0.0)
    
    -- Fade in screen
    DoScreenFadeIn(1000)
    
    -- Initialize lab objects and zones
    InitializeLabEnvironment(lab.type)
    
    -- Notify the server that we've entered the lab
    TriggerServerEvent('alpha_drugs:labEntered', labId)
end

-- Exit the current lab
function ExitLab()
    if not currentLab then return end
    
    -- Notify server
    TriggerServerEvent('alpha_drugs:leaveLab', currentLab.id)
    
    -- Get exit coords
    local exitCoords = vector3(currentLab.coords.x, currentLab.coords.y, currentLab.coords.z + 1.0)
    
    -- Fade out screen
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    -- Teleport player outside
    SetEntityCoords(PlayerPedId(), exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    
    -- Clean up lab objects and zones
    CleanupLabEnvironment()
    
    -- Reset variables
    local oldLabId = currentLab and currentLab.id
    currentLab = nil
    isInLab = false
    
    -- Fade in screen
    DoScreenFadeIn(1000)
    
    -- Notify the server that we've left the lab
    if oldLabId then
        TriggerServerEvent('alpha_drugs:labExited', oldLabId)
    end
end

-- Initialize lab environment (objects, zones, etc.)
function InitializeLabEnvironment(labType)
    -- Clean up any existing objects/zones first
    CleanupLabEnvironment()
    
    -- Get lab configuration
    local labConfig = Config.Labs[labType]
    if not labConfig then return end
    
    -- Create lab objects based on type
    if labType == 'weed' then
        -- Create weed lab objects (grow tables, drying racks, etc.)
        CreateWeedLabObjects()
    elseif labType == 'meth' then
        -- Create meth lab objects (cooking stations, ingredients, etc.)
        CreateMethLabObjects()
    elseif labType == 'cocaine' then
        -- Create cocaine lab objects (processing tables, etc.)
        CreateCocaineLabObjects()
    end
    
    -- Create interaction zones
    CreateLabZones(labType)
end

-- Clean up lab environment
function CleanupLabEnvironment()
    -- Delete objects
    for _, object in pairs(labObjects) do
        if DoesEntityExist(object) then
            DeleteObject(object)
        end
    end
    labObjects = {}
    
    -- Remove zones
    for _, zone in pairs(labZones) do
        if zone.remove then
            zone:remove()
        end
    end
    labZones = {}
end

-- Create weed lab objects
function CreateWeedLabObjects()
    if not currentLab then return end
    
    -- Get interior coords
    local interiorCoords = Config.LabInteriors[currentLab.type] or Config.LabInteriors.default
    local baseCoords = interiorCoords.inside
    
    -- Create grow tables (example positions, adjust as needed)
    for i = 1, 5 do
        local x = baseCoords.x + (i * 1.5)
        local y = baseCoords.y
        local z = baseCoords.z - 1.0
        
        local tableObj = CreateObject(GetHashKey('prop_table_06'), x, y, z, false, false, false)
        SetEntityHeading(tableObj, 0.0)
        FreezeEntityPosition(tableObj, true)
        
        table.insert(labObjects, tableObj)
        
        -- Create plant spots on the table
        for j = 1, 3 do
            local plantX = x + (j * 0.5) - 1.0
            local plantY = y
            local plantZ = z + 0.8
            
            -- Create a small pot or marker for plant placement
            local pot = CreateObject(GetHashKey('prop_plant_pot_01'), plantX, plantY, plantZ, false, false, false)
            SetEntityHeading(pot, 0.0)
            FreezeEntityPosition(pot, true)
            
            table.insert(labObjects, pot)
        end
    end
    
    -- Create drying racks
    for i = 1, 3 do
        local x = baseCoords.x - 2.0
        local y = baseCoords.y + (i * 1.5)
        local z = baseCoords.z - 1.0
        
        local rack = CreateObject(GetHashKey('prop_rack_1'), x, y, z, false, false, false)
        SetEntityHeading(rack, 90.0)
        FreezeEntityPosition(rack, true)
        
        table.insert(labObjects, rack)
    end
end

-- Create meth lab objects
function CreateMethLabObjects()
    if not currentLab then return end
    
    -- Implementation for meth lab objects
    -- This would include cooking stations, ingredients, etc.
end

-- Create cocaine lab objects
function CreateCocaineLabObjects()
    if not currentLab then return end
    
    -- Implementation for cocaine lab objects
    -- This would include processing tables, packaging stations, etc.
end

-- Create interaction zones for the lab
function CreateLabZones(labType)
    if not currentLab then return end
    
    -- Get interior coords
    local interiorCoords = Config.LabInteriors[labType] or Config.LabInteriors.default
    local baseCoords = interiorCoords.inside
    
    -- Create exit zone
    local exitZone = BoxZone:Create(
        vector3(baseCoords.x, baseCoords.y - 1.5, baseCoords.z),
        1.0, 1.0,
        {
            name = 'lab_exit',
            heading = 0.0,
            minZ = baseCoords.z - 1.0,
            maxZ = baseCoords.z + 1.0,
            debugPoly = Config.Debug
        }
    )
    
    exitZone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            -- Show exit prompt
            lib.showTextUI('[E] Exit Lab', {
                position = 'top-center',
                icon = 'door-open',
                style = {
                    borderRadius = 5,
                    backgroundColor = '#1e1e2d',
                    color = 'white'
                }
            })
            
            -- Handle exit key press
            CreateThread(function()
                while exitZone:isPointInside(GetEntityCoords(PlayerPedId())) do
                    if IsControlJustReleased(0, 38) then -- E key
                        ExitLab()
                        break
                    end
                    Wait(0)
                end
                lib.hideTextUI()
            end)
        end
    end)
    
    table.insert(labZones, exitZone)
    
    -- Add lab-specific zones
    if labType == 'weed' then
        CreateWeedLabZones()
    elseif labType == 'meth' then
        CreateMethLabZones()
    elseif labType == 'cocaine' then
        CreateCocaineLabZones()
    end
end

-- Create weed lab interaction zones
function CreateWeedLabZones()
    if not currentLab then return end
    
    -- Implementation for weed lab zones
    -- This would include zones for planting, watering, harvesting, etc.
end

-- Create meth lab interaction zones
function CreateMethLabZones()
    if not currentLab then return end
    
    -- Implementation for meth lab zones
    -- This would include zones for cooking, mixing, collecting, etc.
end

-- Create cocaine lab interaction zones
function CreateCocaineLabZones()
    if not currentLab then return end
    
    -- Implementation for cocaine lab zones
    -- This would include zones for processing, packaging, etc.
end

-- NUI Callbacks
-- This would handle any NUI callbacks for UI interactions

-- Sound Events
RegisterNetEvent('alpha_drugs:playSound')
AddEventHandler('alpha_drugs:playSound', function(soundData)
    if not soundData or not soundData.sound then return end
    
    local soundConfig = nil
    
    -- Find the sound in the config
    for _, soundCategory in pairs(Config.Sounds) do
        if soundCategory[soundData.sound] then
            soundConfig = soundCategory[soundData.sound]
            break
        end
    end
    
    if not soundConfig then return end
    
    -- Play the sound
    local coords = soundData.coords and vector3(soundData.coords.x, soundData.coords.y, soundData.coords.z) or nil
    PlaySound3D(soundConfig, coords, soundData.range, soundConfig.loop)
end)

-- Stop a specific sound
RegisterNetEvent('alpha_drugs:stopSound')
AddEventHandler('alpha_drugs:stopSound', function(soundName)
    StopSound(soundName)
end)

-- Stop all sounds when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Stop all active sounds
    for soundId, _ in pairs(activeSounds) do
        StopSound(soundId)
    end
end)

-- Events
-- Player loaded their labs
RegisterNetEvent('alpha_drugs:playerLabsLoaded')
AddEventHandler('alpha_drugs:playerLabsLoaded', function(labs)
    -- Store player's labs
    playerLabs = labs
    
    -- Update blips
    UpdateLabBlips()
end)

-- Lab data updated
RegisterNetEvent('alpha_drugs:labUpdated')
AddEventHandler('alpha_drugs:labUpdated', function(labData)
    -- Update lab data
    if activeLabs[labData.id] then
        activeLabs[labData.id] = labData
        
        -- If this is the current lab, update the environment
        if currentLab and currentLab.id == labData.id then
            currentLab = labData
            InitializeLabEnvironment(labData.type)
        end
    end
end)

-- Lab was deleted
RegisterNetEvent('alpha_drugs:labDeleted')
AddEventHandler('alpha_drugs:labDeleted', function(labId)
    -- Remove from active labs
    activeLabs[labId] = nil
    
    -- If this was the current lab, exit it
    if currentLab and currentLab.id == labId then
        ExitLab()
    end
    
    -- Update blips
    UpdateLabBlips()
end)

-- Update lab blips on the map
function UpdateLabBlips()
    -- Hide all blips first
    for _, blip in pairs(labBlips) do
        SetBlipHiddenOnLegend(blip, true)
    end
    
    -- Show blips for active labs
    for labId, lab in pairs(activeLabs) do
        local blip = labBlips[lab.type]
        if blip then
            SetBlipCoords(blip, lab.coords.x, lab.coords.y, lab.coords.z)
            SetBlipHiddenOnLegend(blip, false)
        end
    end
end

-- Debug command to spawn a test lab
if Config.Debug then
    RegisterCommand('testlab', function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        -- Create a test lab
        TriggerServerEvent('alpha_drugs:createTestLab', 'weed', {
            x = coords.x,
            y = coords.y,
            z = coords.z - 1.0,
            w = heading
        })
    end, false)
end

-- Export functions
-- Check if player is in a lab
exports('IsInLab', function()
    return isInLab, currentLab
end)

-- Get current lab data
exports('GetCurrentLab', function()
    return currentLab
end)

-- Get all active labs
exports('GetActiveLabs', function()
    return activeLabs
end)

-- Get player's labs
exports('GetPlayerLabs', function()
    return playerLabs
end)
