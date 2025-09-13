Config.LabInteriors = {
    -- Default interior (fallback)
    default = {
        interiorId = 0,
        inside = vector4(0.0, 0.0, 0.0, 0.0),
        outside = vector4(0.0, 0.0, 0.0, 0.0),
        ipl = nil,
        objects = {}
    },
    
    -- Weed Lab Interior (using one of the apartment interiors as an example)
    weed = {
        interiorId = 0, -- Will be set when loading the IPL
        inside = vector4(346.58, -1012.85, -99.2, 0.0),
        outside = vector4(0.0, 0.0, 0.0, 0.0), -- Will be set when creating the lab
        ipl = 'apa_v_mp_h_01_a',
        objects = {
            -- Add object hashes for the interior
            'apa_mp_h_acc_rugwoolm_04',
            'apa_mp_h_acc_rugwooll_04',
            -- Add more objects as needed
        },
        -- Additional properties for weed lab
        plantSpots = {
            vector4(345.5, -1012.0, -99.2, 0.0),
            vector4(346.5, -1012.0, -99.2, 0.0),
            vector4(347.5, -1012.0, -99.2, 0.0),
            vector4(348.5, -1012.0, -99.2, 0.0),
            vector4(349.5, -1012.0, -99.2, 0.0)
        },
        dryingRacks = {
            vector4(343.0, -1010.0, -99.2, 90.0),
            vector4(343.0, -1008.0, -99.2, 90.0),
            vector4(343.0, -1006.0, -99.2, 90.0)
        },
        storage = vector4(350.0, -1010.0, -99.2, 270.0)
    },
    
    -- Meth Lab Interior (using a different apartment interior)
    meth = {
        interiorId = 0,
        inside = vector4(266.05, -1007.6, -101.01, 0.0),
        outside = vector4(0.0, 0.0, 0.0, 0.0),
        ipl = 'bkr_biker_interior_placement_interior_2_biker_dlc_int_ware01_milo',
        objects = {
            -- Add object hashes for the meth lab
            'bkr_prop_meth_ammonia',
            'bkr_prop_meth_sacid',
            'bkr_prop_meth_smashedtray_01',
            -- Add more objects as needed
        },
        -- Additional properties for meth lab
        cookSpots = {
            vector4(265.0, -1008.0, -101.0, 0.0),
            vector4(267.0, -1008.0, -101.0, 0.0)
        },
        ingredientStorage = vector4(264.0, -1010.0, -101.0, 90.0),
        productStorage = vector4(268.0, -1010.0, -101.0, 270.0)
    },
    
    -- Cocaine Lab Interior (using another interior)
    cocaine = {
        interiorId = 0,
        inside = vector4(1088.65, -3187.66, -38.99, 0.0),
        outside = vector4(0.0, 0.0, 0.0, 0.0),
        ipl = 'bkr_biker_interior_placement_interior_3_biker_dlc_int_ware02_milo',
        objects = {
            -- Add object hashes for the cocaine lab
            'bkr_prop_coke_tablepowder_01',
            'bkr_prop_coke_doll',
            'bkr_prop_coke_scale_03',
            -- Add more objects as needed
        },
        -- Additional properties for cocaine lab
        processSpots = {
            vector4(1087.0, -3188.0, -38.99, 0.0),
            vector4(1089.0, -3188.0, -38.99, 0.0)
        },
        packagingSpot = vector4(1088.0, -3185.0, -38.99, 180.0),
        storage = vector4(1090.0, -3185.0, -38.99, 270.0)
    }
}

-- Interior loading functions
function LoadInterior(interiorConfig)
    if not interiorConfig then return end
    
    -- Request the IPL
    if interiorConfig.ipl and not IsIplActive(interiorConfig.ipl) then
        RequestIpl(interiorConfig.ipl)
        while not IsIplActive(interiorConfig.ipl) do
            Wait(10)
        end
    end
    
    -- Load interior entities
    if interiorConfig.objects then
        for _, objectHash in ipairs(interiorConfig.objects) do
            if type(objectHash) == 'string' then
                objectHash = GetHashKey(objectHash)
            end
            
            if not HasModelLoaded(objectHash) then
                RequestModel(objectHash)
                while not HasModelLoaded(objectHash) do
                    Wait(10)
                end
            end
        end
    end
    
    -- Get the interior ID if not set
    if interiorConfig.interiorId == 0 then
        interiorConfig.interiorId = GetInteriorAtCoords(interiorConfig.inside.x, interiorConfig.inside.y, interiorConfig.inside.z)
    end
    
    -- Activate the interior
    if interiorConfig.interiorId ~= 0 then
        PinInteriorInMemory(interiorConfig.interiorId)
        SetInteriorActive(interiorConfig.interiorId, true)
        RefreshInterior(interiorConfig.interiorId)
    end
end

function UnloadInterior(interiorConfig)
    if not interiorConfig then return end
    
    -- Unload interior entities
    if interiorConfig.objects then
        for _, objectHash in ipairs(interiorConfig.objects) do
            if type(objectHash) == 'string' then
                objectHash = GetHashKey(objectHash)
            end
            
            if HasModelLoaded(objectHash) then
                SetModelAsNoLongerNeeded(objectHash)
            end
        end
    end
    
    -- Deactivate the interior
    if interiorConfig.interiorId ~= 0 then
        SetInteriorActive(interiorConfig.interiorId, false)
        UnpinInterior(interiorConfig.interiorId)
    end
    
    -- Unload the IPL (be careful with this as it might affect other scripts)
    -- if interiorConfig.ipl and IsIplActive(interiorConfig.ipl) then
    --     RemoveIpl(interiorConfig.ipl)
    -- end
end
