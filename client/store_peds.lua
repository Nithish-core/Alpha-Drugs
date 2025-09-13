local createdPeds = {}

-- Function to create a store ped
local function createStorePed(storeData, storeType)
    RequestModel(storeData.model)
    while not HasModelLoaded(storeData.model) do
        Wait(0)
    end

    local ped = CreatePed(4, storeData.model, storeData.coords.x, storeData.coords.y, storeData.coords.z - 1.0, storeData.heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    
    -- Add blip if enabled
    if storeData.blip and storeData.blip.enabled then
        local blip = AddBlipForCoord(storeData.coords.x, storeData.coords.y, storeData.coords.z)
        SetBlipSprite(blip, storeData.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, storeData.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(storeData.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Add target options
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'drugstore_purchase',
            icon = 'fas fa-shopping-cart',
            label = 'Browse Items',
            distance = 2.5,
            onSelect = function()
                local options = {}
                for _, item in ipairs(storeData.items) do
                    table.insert(options, {
                        title = item.label,
                        description = ('$%s'):format(item.price),
                        onSelect = function()
                            local input = lib.inputDialog(('Purchase %s'):format(item.label), {
                                {type = 'number', label = 'Amount', default = 1, min = 1, max = 100}
                            })
                            
                            if not input then return end
                            local amount = input[1]
                            
                            TriggerServerEvent('alpha_drugs:purchaseItem', storeType, item.name, amount)
                        end
                    })
                end
                
                lib.registerContext({
                    id = 'drugstore_menu',
                    title = storeData.blip and storeData.blip.label or 'Supplier',
                    options = options
                })
                
                lib.showContext('drugstore_menu')
            end
        }
    })

    table.insert(createdPeds, ped)
end

-- Create all store peds when resource starts
CreateThread(function()
    -- Wait for resource to be fully loaded
    Wait(1000)
    
    -- Create peds for each store type
    for storeType, storeData in pairs(Config.StorePeds) do
        createStorePed(storeData, storeType)
    end
end)

-- Cleanup peds when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, ped in ipairs(createdPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)
