local Utils = require 'shared.utils'

local Lab = {}
Lab.__index = Lab

-- Constructor for a new lab
function Lab:New(data)
    local self = setmetatable({}, Lab)
    
    -- Required properties
    self.id = data.id or Utils.GenerateUniqueId()
    self.type = data.type -- weed, meth, cocaine
    self.owner = data.owner -- Player identifier
    self.coords = data.coords -- Vector3
    self.heading = data.heading or 0.0
    self.createdAt = data.createdAt or os.time()
    
    -- State properties
    self.players = data.players or {}
    self.active = data.active or false
    self.lastActive = data.lastActive or 0
    self.metadata = data.metadata or {}
    
    -- Initialize type-specific properties
    if self.type == Config.LabTypes.WEED then
        self.metadata.plants = data.metadata and data.metadata.plants or {}
        self.metadata.plantCount = data.metadata and data.metadata.plantCount or 0
    elseif self.type == Config.LabTypes.METH then
        self.metadata.batches = data.metadata and data.metadata.batches or {}
        self.metadata.activeBatches = data.metadata and data.metadata.activeBatches or 0
    elseif self.type == Config.LabTypes.COCAINE then
        self.metadata.batches = data.metadata and data.metadata.batches or {}
        self.metadata.activeBatches = data.metadata and data.metadata.activeBatches or 0
    end
    
    return self
end

-- Add player to lab
function Lab:AddPlayer(source)
    if not source then return false end
    
    local identifier = Utils.GetPlayerIdentifier(source)
    if not identifier then return false end
    
    -- Check if player is already in the lab
    for _, playerId in ipairs(self.players) do
        if playerId == identifier then
            return true
        end
    end
    
    -- Add player to lab
    table.insert(self.players, identifier)
    self:UpdateLastActive()
    
    -- Notify other players in the lab
    self:Broadcast('player_joined', {playerId = identifier, playerName = GetPlayerName(source)})
    
    return true
end

-- Remove player from lab
function Lab:RemovePlayer(source)
    if not source then return false end
    
    local identifier = Utils.GetPlayerIdentifier(source)
    if not identifier then return false end
    
    -- Find and remove player from lab
    for i, playerId in ipairs(self.players) do
        if playerId == identifier then
            table.remove(self.players, i)
            self:UpdateLastActive()
            
            -- Notify other players in the lab
            self:Broadcast('player_left', {playerId = identifier, playerName = GetPlayerName(source)})
            
            -- If no players left, handle lab cleanup
            if #self.players == 0 then
                self:OnEmpty()
            end
            
            return true
        end
    end
    
    return false
end

-- Update last active timestamp
function Lab:UpdateLastActive()
    self.lastActive = os.time()
end

-- Check if lab is empty
function Lab:IsEmpty()
    return #self.players == 0
end

-- Get number of active players in lab
function Lab:GetPlayerCount()
    return #self.players
end

-- Check if player is in lab
function Lab:HasPlayer(source)
    local identifier = Utils.GetPlayerIdentifier(source)
    if not identifier then return false end
    
    for _, playerId in ipairs(self.players) do
        if playerId == identifier then
            return true
        end
    end
    
    return false
end

-- Broadcast event to all players in the lab
function Lab:Broadcast(event, data)
    for _, playerId in ipairs(self.players) do
        local playerSource = self:GetPlayerSourceByIdentifier(playerId)
        if playerSource then
            TriggerClientEvent('alpha_drugs:lab:' .. event, playerSource, data)
        end
    end
end

-- Get player source from identifier
function Lab:GetPlayerSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        if Utils.GetPlayerIdentifier(playerId) == identifier then
            return playerId
        end
    end
    return nil
end

-- Called when lab becomes empty
function Lab:OnEmpty()
    -- Save lab state to database
    self:Save(function(success)
        if not success then
            print(('^1[ERROR] Failed to save lab %s state^7'):format(self.id))
        end
    end)
    
    -- Mark as inactive if no players
    if #self.players == 0 then
        self.active = false
    end
end

-- Save lab to database
function Lab:Save(cb)
    -- Prepare data for saving
    local data = {
        id = self.id,
        type = self.type,
        owner = self.owner,
        coords = self.coords,
        heading = self.heading,
        createdAt = self.createdAt,
        lastActive = self.lastActive,
        metadata = self.metadata
    }
    
    -- In a real implementation, this would save to a database
    -- For now, we'll just print to console
    Debug('Saving lab:', json.encode(data))
    
    if cb then
        cb(true)
    end
    
    return true
end

-- Get lab data for client
function Lab:GetClientData()
    return {
        id = self.id,
        type = self.type,
        owner = self.owner,
        coords = self.coords,
        heading = self.heading,
        active = self.active,
        playerCount = #self.players,
        metadata = self.metadata
    }
end

-- Weed Lab Specific Methods
function Lab:PlantSeed(source, seedType)
    if self.type ~= Config.LabTypes.WEED then return false end
    
    -- Check if player has required items
    if not Utils.HasItem(source, 'weed_seed', 1) then
        Utils.Notify(source, Utils.GetLocaleString('not_enough_items'), 'error')
        return false
    end
    
    -- Check max plants
    if self.metadata.plantCount >= Config.Labs[self.type].maxPlants then
        Utils.Notify(source, 'Maximum number of plants reached', 'error')
        return false
    end
    
    -- Remove seed from inventory
    if not Utils.RemoveItem(source, 'weed_seed', 1) then
        Utils.Notify(source, 'Failed to plant seed', 'error')
        return false
    end
    
    -- Create new plant
    local plantId = #self.metadata.plants + 1
    local plant = {
        id = plantId,
        type = seedType or 'regular',
        stage = 1,
        health = 100,
        plantedAt = os.time(),
        lastWatered = os.time(),
        lastFertilized = 0,
        position = {
            x = 0.0, -- These would be relative to the lab's position
            y = 0.0,
            z = 0.0,
        }
    }
    
    table.insert(self.metadata.plants, plant)
    self.metadata.plantCount = self.metadata.plantCount + 1
    
    -- Notify all players in the lab
    self:Broadcast('plant_added', {plant = plant})
    
    -- Start growth timer
    self:StartGrowthTimer(plantId)
    
    return true
end

-- Start growth timer for a plant
function Lab:StartGrowthTimer(plantId)
    local plant = self.metadata.plants[plantId]
    if not plant then return end
    
    -- Calculate time until next growth stage (in seconds)
    local growthTime = Config.Labs[self.type].growthTime * 60 -- Convert minutes to seconds
    local stageTime = growthTime / 4 -- 4 growth stages
    
    -- Set timer for next growth stage
    SetTimeout(stageTime * 1000, function()
        self:GrowPlant(plantId)
    end)
end

-- Grow plant to next stage
function Lab:GrowPlant(plantId)
    local plant = self.metadata.plants[plantId]
    if not plant or plant.stage >= 4 then return end
    
    -- Update plant stage
    plant.stage = plant.stage + 1
    
    -- Play growth sound
    local soundData = Config.Sounds.weed.plant_grow
    self:Broadcast('playSound', {
        sound = soundData.name,
        volume = soundData.volume
    })
    
    -- Notify all players in the lab
    self:Broadcast('plant_updated', {plantId = plantId, plant = plant})
    
    -- If not fully grown, set timer for next stage
    if plant.stage < 4 then
        -- Play growing sound effect
        self:StartGrowthTimer(plantId)
    else
        -- Plant is fully grown
        local readySound = Config.Sounds.weed.plant_ready
        self:Broadcast('playSound', {
            sound = readySound.name,
            volume = readySound.volume
        })
        
        -- Notify all players in the lab
        self:Broadcast('plant_ready', {plantId = plantId})
        
        -- Notify all players with a UI sound
        self:Broadcast('playSound', {
            sound = Config.Sounds.ui.notify.name,
            volume = Config.Sounds.ui.notify.volume
        })
    end
end

-- Harvest plant
function Lab:HarvestPlant(source, plantId)
    if self.type ~= Config.LabTypes.WEED then return false end
    
    local plant = self.metadata.plants[plantId]
    if not plant or plant.stage < 4 then
        Utils.Notify(source, 'Plant is not ready to harvest', 'error')
        return false
    end
    
    -- Calculate yield based on plant health and type
    local minYield = Config.Labs[self.type].yield.min
    local maxYield = Config.Labs[self.type].yield.max
    local yieldAmount = math.random(minYield, maxYield)
    
    -- Add weed to player's inventory
    if Utils.AddItem(source, 'weed_bud', yieldAmount) then
        -- Remove plant
        table.remove(self.metadata.plants, plantId)
        self.metadata.plantCount = math.max(0, self.metadata.plantCount - 1)
        
        -- Notify all players in the lab
        self:Broadcast('plant_removed', {plantId = plantId})
        
        Utils.Notify(source, ('Harvested %dx weed buds'):format(yieldAmount), 'success')
        return true
    else
        Utils.Notify(source, 'Not enough inventory space', 'error')
        return false
    end
end

-- Meth Lab Specific Methods
function Lab:StartMethCooking(source, recipe)
    if self.type ~= Config.LabTypes.METH then return false end
    
    -- Check if player has required items
    for _, item in ipairs(Config.Labs[self.type].requiredItems) do
        if not Utils.HasItem(source, item, 1) then
            Utils.Notify(source, Utils.GetLocaleString('not_enough_items'), 'error')
            return false
        end
    end
    
    -- Check max batches
    if self.metadata.activeBatches >= Config.Labs[self.type].maxBatches then
        Utils.Notify(source, 'Maximum number of active batches reached', 'error')
        return false
    end
    
    -- Remove required items
    for _, item in ipairs(Config.Labs[self.type].requiredItems) do
        if not Utils.RemoveItem(source, item, 1) then
            Utils.Notify(source, 'Failed to start cooking', 'error')
            return false
        end
    end
    
    -- Create new batch
    local batchId = #self.metadata.batches + 1
    local batch = {
        id = batchId,
        startedBy = Utils.GetPlayerIdentifier(source),
        startedAt = os.time(),
        progress = 0,
        quality = math.random(70, 100), -- Quality affects yield
        completed = false,
        failed = false
    }
    
    table.insert(self.metadata.batches, batch)
    self.metadata.activeBatches = self.metadata.activeBatches + 1
    
    -- Notify all players in the lab
    self:Broadcast('batch_started', {batchId = batchId, batch = batch})
    
    -- Start cooking process
    self:ProcessMethBatch(batchId)
    
    return true
end

-- Process meth batch
function Lab:ProcessMethBatch(batchId)
    local batch = self.metadata.batches[batchId]
    if not batch or batch.completed or batch.failed then return end
    
    -- Check for explosion chance
    if math.random() <= Config.Labs[self.type].explosionChance then
        batch.failed = true
        self.metadata.activeBatches = math.max(0, self.metadata.activeBatches - 1)
        
        -- Notify all players in the lab
        self:Broadcast('batch_failed', {batchId = batchId, reason = 'explosion'})
        
        -- Trigger explosion effect
        self:Broadcast('explosion', {position = self.coords})
        
        -- Damage players in the lab
        for _, playerId in ipairs(self.players) do
            local playerSource = self:GetPlayerSourceByIdentifier(playerId)
            if playerSource then
                -- Apply damage to player
                TriggerClientEvent('alpha_drugs:damagePlayer', playerSource, 50) -- 50% damage
            end
        end
        
        return
    end
    
    -- Update progress
    batch.progress = math.min(100, batch.progress + 10) -- 10% progress per tick
    
    -- Notify all players in the lab
    self:Broadcast('batch_updated', {batchId = batchId, progress = batch.progress})
    
    -- If not complete, schedule next update
    if batch.progress < 100 then
        -- Process time is divided into 10% increments
        local processTime = (Config.Labs[self.type].processTime * 60 * 1000) / 10
        SetTimeout(processTime, function()
            self:ProcessMethBatch(batchId)
        end)
    else
        -- Batch complete
        batch.completed = true
        self.metadata.activeBatches = math.max(0, self.metadata.activeBatches - 1)
        
        -- Notify all players in the lab
        self:Broadcast('batch_completed', {batchId = batchId, quality = batch.quality})
    end
end

-- Collect meth batch
function Lab:CollectMethBatch(source, batchId)
    if self.type ~= Config.LabTypes.METH then return false end
    
    local batch = self.metadata.batches[batchId]
    if not batch or not batch.completed then
        Utils.Notify(source, 'Batch not ready for collection', 'error')
        return false
    end
    
    -- Calculate yield based on quality
    local yieldAmount = math.floor((batch.quality / 100) * Config.Labs[self.type].batchSize)
    
    -- Add meth to player's inventory
    if Utils.AddItem(source, 'meth', yieldAmount) then
        -- Remove batch
        table.remove(self.metadata.batches, batchId)
        
        -- Notify all players in the lab
        self:Broadcast('batch_collected', {batchId = batchId, amount = yieldAmount})
        
        Utils.Notify(source, ('Collected %dx meth'):format(yieldAmount), 'success')
        return true
    else
        Utils.Notify(source, 'Not enough inventory space', 'error')
        return false
    end
end

-- Cocaine Lab Specific Methods
function Lab:StartCocaineProcessing(source, recipe)
    if self.type ~= Config.LabTypes.COCAINE then return false end
    
    -- Similar implementation to meth lab, but with cocaine-specific logic
    -- This would include checking for coca leaves and processing them into cocaine
    -- Implementation would follow the same pattern as the meth lab methods
end

-- Process Cocaine Batch
function Lab:ProcessCocaineBatch(batchId)
    -- Similar to ProcessMethBatch but with cocaine-specific logic
end

-- Collect Cocaine Batch
function Lab:CollectCocaineBatch(source, batchId)
    -- Similar to CollectMethBatch but with cocaine-specific logic
end

return Lab
