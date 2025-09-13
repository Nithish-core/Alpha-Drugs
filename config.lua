Config = {}

-- Framework Settings
Config.Framework = 'auto' -- 'auto', 'esx', 'qbcore', 'qbox', 'standalone'

-- General Settings
Config.Debug = false
Config.Target = 'ox_target' -- 'ox_target' or 'qb-target' or 'qtarget'

-- Lab Types
Config.LabTypes = {
    WEED = 'weed',
    METH = 'meth',
    COCAINE = 'cocaine'
}

-- Lab Settings
Config.Labs = {
    [Config.LabTypes.WEED] = {
        label = 'Weed Lab',
        item = 'weed_lab',
        requiredItems = {
            'fertilizer',
            'water',
            'plant_pot',
            'weed_seed'
        },
        processTime = 30, -- in minutes
        maxPlants = 10,
        growthTime = 60, -- in minutes
        yield = {
            min = 1,
            max = 3
        },
        interior = 'weed_lab',
        blip = {
            sprite = 496,
            color = 2,
            scale = 0.9,
            label = 'Weed Lab'
        }
    },
    [Config.LabTypes.METH] = {
        label = 'Meth Lab',
        item = 'meth_lab',
        requiredItems = {
            'pseudoephedrine',
            'acetone',
            'lithium',
            'phosphorus',
            'hydrochloric_acid'
        },
        processTime = 45, -- in minutes
        maxBatches = 5,
        batchSize = 5,
        explosionChance = 0.1, -- 10% chance of explosion if failed
        interior = 'meth_lab',
        blip = {
            sprite = 499,
            color = 5,
            scale = 0.9,
            label = 'Meth Lab'
        }
    },
    [Config.LabTypes.COCAINE] = {
        label = 'Cocaine Lab',
        item = 'cocaine_lab',
        requiredItems = {
            'coca_leaves',
            'gasoline',
            'lime',
            'sulfuric_acid',
            'acetone'
        },
        processTime = 60, -- in minutes
        maxBatches = 3,
        batchSize = 3,
        purity = {
            min = 60, -- 60% purity
            max = 95  -- 95% purity
        },
        interior = 'cocaine_lab',
        blip = {
            sprite = 501,
            color = 3,
            scale = 0.9,
            label = 'Cocaine Lab'
        }
    }
}

-- Lab Creation Settings
Config.LabCreation = {
    distance = 2.0,
    price = 50000, -- Price to create a lab
    maxLabsPerPlayer = 2,
    adminGroups = {'admin', 'mod'} -- Groups that can create labs anywhere
}

-- Notification Settings
Config.Notifications = {
    success = 'success',
    error = 'error',
    info = 'inform'
}

-- Framework Item Names (will be used for inventory checks)
Config.Items = {
    -- Weed Lab
    weed_lab = 'weed_lab',
    fertilizer = 'fertilizer',
    water = 'water',
    plant_pot = 'plant_pot',
    weed_seed = 'weed_seed',
    weed_bud = 'weed_bud',
    
    -- Meth Lab
    meth_lab = 'meth_lab',
    pseudoephedrine = 'pseudoephedrine',
    acetone = 'acetone',
    lithium = 'lithium',
    phosphorus = 'phosphorus',
    hydrochloric_acid = 'hydrochloric_acid',
    meth = 'meth',
    
    -- Cocaine Lab
    cocaine_lab = 'cocaine_lab',
    coca_leaves = 'coca_leaves',
    gasoline = 'gasoline',
    lime = 'lime',
    sulfuric_acid = 'sulfuric_acid',
    cocaine = 'cocaine',
    
    -- Tools
    money = 'money',
    black_money = 'black_money'
}

-- Airdrop Configuration
Config.Airdrop = {
    Enabled = true, -- Enable/disable airdrop system
    MinInterval = 30, -- Minimum minutes between airdrops
    MaxInterval = 60, -- Maximum minutes between airdrops
    AnnouncementTimes = {10, 2}, -- Announcement times in minutes before drop (10min and 2min)
    DropHeight = 300.0, -- Height from which the airdrop will be dropped
    ParachuteModel = 'p_parachute_s', -- Model for the parachute
    CrateModel = 'prop_drop_armscrate_01b', -- Model for the airdrop crate
    SmokeEffect = 'scr_ba_drug_heist', -- Particle effect for smoke
    SmokeColor = {r = 255, g = 100, b = 0}, -- Orange smoke
    MinPlayers = 1, -- Minimum players online for airdrops to occur
    Loot = {
        {name = 'weed_brick', count = {1, 3}, chance = 0.7},
        {name = 'meth_bag', count = {1, 5}, chance = 0.6},
        {name = 'coke_bag', count = {1, 5}, chance = 0.6},
        {name = 'weapon_pistol', count = 1, chance = 0.3},
        {name = 'money', count = {5000, 15000}, chance = 0.8}
    },
    Minigame = {
        type = 'circle', -- Type of minigame (circle, sequence, etc.)
        difficulty = 'easy', -- Difficulty level
        time = 10, -- Time to complete in seconds
        circles = 3, -- Number of circles to complete
        areaSize = 2.0, -- Size of the target area
        speed = 1.0 -- Speed of the minigame
    },
    Blip = {
        sprite = 501,
        color = 1,
        scale = 1.0,
        label = 'Airdrop',
        time = 30 -- Minutes before blip disappears
    }
}

-- Localization
-- Store PED Configurations
Config.StorePeds = {
    [Config.LabTypes.WEED] = {
        model = 'a_m_m_hillbilly_01',
        coords = vector4(380.0, -823.0, 29.3, 90.0), -- Example coordinates, adjust as needed
        heading = 90.0,
        blip = {
            enabled = true,
            sprite = 140,
            color = 2,
            label = 'Weed Supplier'
        },
        items = {
            {name = 'weed_seed', price = 100, label = 'Weed Seed'},
            {name = 'fertilizer', price = 50, label = 'Fertilizer'},
            {name = 'plant_pot', price = 30, label = 'Plant Pot'},
            {name = 'water', price = 10, label = 'Water'}
        }
    },
    [Config.LabTypes.METH] = {
        model = 'a_m_m_og_boss_01',
        coords = vector4(1000.0, -3200.0, -38.5, 0.0), -- Example coordinates, adjust as needed
        heading = 0.0,
        blip = {
            enabled = true,
            sprite = 499,
            color = 5,
            label = 'Meth Supplier'
        },
        items = {
            {name = 'pseudoephedrine', price = 200, label = 'Pseudoephedrine'},
            {name = 'acetone', price = 100, label = 'Acetone'},
            {name = 'lithium', price = 150, label = 'Lithium'},
            {name = 'phosphorus', price = 120, label = 'Phosphorus'},
            {name = 'hydrochloric_acid', price = 80, label = 'Hydrochloric Acid'}
        }
    },
    [Config.LabTypes.COCAINE] = {
        model = 'a_m_m_salton_03',
        coords = vector4(1090.0, -3190.0, -38.5, 180.0), -- Example coordinates, adjust as needed
        heading = 180.0,
        blip = {
            enabled = true,
            sprite = 501,
            color = 3,
            label = 'Cocaine Supplier'
        },
        items = {
            {name = 'coca_leaves', price = 300, label = 'Coca Leaves'},
            {name = 'gasoline', price = 80, label = 'Gasoline'},
            {name = 'lime', price = 60, label = 'Lime'},
            {name = 'sulfuric_acid', price = 120, label = 'Sulfuric Acid'},
            {name = 'acetone', price = 100, label = 'Acetone'}
        }
    }
}

Config.Locale = 'en'
Config.Locales = {
    ['en'] = {
        -- General
        ['no_permission'] = 'You do not have permission to do this.',
        ['not_enough_money'] = 'You do not have enough money.',
        ['invalid_target'] = 'Invalid target.',
        
        -- Lab Creation
        ['lab_created'] = 'Lab created successfully!',
        ['lab_creation_failed'] = 'Failed to create lab.',
        ['max_labs_reached'] = 'You have reached the maximum number of labs.',
        
        -- Lab Interaction
        ['lab_in_use'] = 'This lab is already in use.',
        ['lab_not_found'] = 'Lab not found.',
        ['not_enough_items'] = 'You do not have the required items.',
        
        -- Weed Lab
        ['weed_planted'] = 'Weed plant has been planted.',
        ['weed_harvested'] = 'You harvested some weed.',
        ['weed_fully_grown'] = 'Weed is fully grown and ready to harvest!',
        
        -- Meth Lab
        ['meth_cooking'] = 'Started cooking meth...',
        ['meth_cooked'] = 'Successfully cooked meth!',
        ['meth_exploded'] = 'The meth lab exploded!',
        
        -- Cocaine Lab
        ['cocaine_processing'] = 'Processing cocaine...',
        ['cocaine_processed'] = 'Successfully processed cocaine!',
        
        -- Admin
        ['lab_deleted'] = 'Lab has been deleted.',
        ['lab_reset'] = 'All labs have been reset.'
    }
}

-- Debug function
function Debug(...)
    if Config.Debug then
        local args = {...}
        local str = '^3[DEBUG]^7 '
        
        for i = 1, #args do
            str = str .. tostring(args[i])
            if i < #args then
                str = str .. ' | '
            end
        end
        
        print(str)
    end
end
