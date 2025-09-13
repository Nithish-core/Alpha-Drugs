-- Server-side handler for store purchases
RegisterNetEvent('alpha_drugs:purchaseItem', function(storeType, itemName, amount)
    local src = source
    local player = QBCore.Functions.GetPlayer(src) -- For QBCore
    
    -- If using ESX, uncomment the following line and comment the QBCore line above
    -- local player = ESX.GetPlayerFromId(src)
    
    if not player then return end
    
    local storeData = Config.StorePeds[storeType]
    if not storeData then return end
    
    local itemData
    for _, item in ipairs(storeData.items) do
        if item.name == itemName then
            itemData = item
            break
        end
    end
    
    if not itemData then return end
    
    local totalPrice = itemData.price * amount
    
    -- Check if player has enough money
    if player.Functions.GetMoney('cash') >= totalPrice then -- QBCore
    -- if player.getMoney() >= totalPrice then -- ESX
        -- Remove money
        player.Functions.RemoveMoney('cash', totalPrice, 'drugstore-purchase') -- QBCore
        -- player.removeMoney(totalPrice) -- ESX
        
        -- Add item to inventory
        player.Functions.AddItem(itemName, amount) -- QBCore
        -- player.addInventoryItem(itemName, amount) -- ESX
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Purchase Successful',
            description = ('You bought %sx %s for $%s'):format(amount, itemData.label, totalPrice),
            type = 'success'
        })
    else
        -- Not enough money
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Purchase Failed',
            description = 'You don\'t have enough money!',
            type = 'error'
        })
    end
end)
