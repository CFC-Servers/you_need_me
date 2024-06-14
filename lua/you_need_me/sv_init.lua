
--- @class YouNeedMe
YouNeedMe = {}

--- @class YouNeedMe
local YNM = YouNeedMe

--- @class Entity
local EntMeta = FindMetaTable( "Entity" )
local ManipulateBoneScale = EntMeta.ManipulateBoneScale
local ManipulateBoneAngles = EntMeta.ManipulateBoneAngles
local ManipulateBonePosition = EntMeta.ManipulateBonePosition

--- @class YNM_BoneManipulation
--- @field func function
--- @field bone string
--- @field value any

--- @type table<YNM_BoneManipulation>
YNM.BaseEntityManipulations = {
    {
        -- Head facing
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_Head1",
        value = Angle( 0, 95, 0 ),
        default = Angle( 0, 0, 0 )
    },
    {
        -- Neck cricking
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_Neck1",
        value = Angle( 0, 25, 0 ),
        default = Angle( 0, 0, 0 )
    },
    {
        -- Waist bneding
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_Spine",
        value = Angle( 0, 105, 0 ),
        default = Angle( 0, 0, 0 )
    },

    {
        -- Head Size
        func = ManipulateBoneScale,
        bone = "ValveBiped.Bip01_Head1",
        value = Vector( 1.2, 1.2, 1.2 ),
        default = Vector( 1, 1, 1 )
    },
    {
        -- Head Position
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_Head1",
        value = Vector( 10, 5, 0 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Neck Position
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_Neck1",
        value = Vector( 5, 10, 0 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Top spine angle
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_Spine4",
        value = Angle( 0, -20, 0 ),
        default = Angle( 0, 0, 0 )
    },

    {
        -- Long back
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_Spine1",
        value = Vector( 5, 0, 0 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Long back
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_Spine2",
        value = Vector( 5, 0, 0 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Long back
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_Spine4",
        value = Vector( 5, 0, 0 ),
        default = Vector( 0, 0, 0 )
    },

    {
        -- Left arm
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_L_Clavicle",
        value = Angle( 0, 0, -90 ),
        default = Angle( 0, 0, 0 )
    },

    {
        -- Right arm
        func = ManipulateBoneAngles,
        bone = "ValveBiped.Bip01_R_Clavicle",
        value = Angle( 0, 0, 90 ),
        default = Angle( 0, 0, 0 )
    },
    {
        -- Right arm
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_R_UpperArm",
        value = Vector( 10, -10, -5 ),
        default = Vector( 0, 0, 0 )
    },

    {
        -- Right thigh outwards
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_R_Thigh",
        value = Vector( -15, 0, -20 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Left thigh outwards
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_L_Thigh",
        value = Vector( 15, 0, -20 ),
        default = Vector( 0, 0, 0 )
    },

    {
        -- Right calf
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_R_Calf",
        value = Vector( 10, 20, 0 ),
        default = Vector( 0, 0, 0 )
    },
    {
        -- Left calf
        func = ManipulateBonePosition,
        bone = "ValveBiped.Bip01_L_Calf",
        value = Vector( 10, 20, 0 ),
        default = Vector( 0, 0, 0 )
    },
}

--- Manipulates the given Entity's bones to form the base of a YouNeedMe
--- @param ent Player|NPC
function YNM:ManipulateBaseEntity( ent )
    for _, v in ipairs( self.BaseEntityManipulations ) do
        local bone = ent:LookupBone( v.bone )

        if bone then
            v.func( ent, bone, v.value )
        end
    end
end

do
    local IsValid = IsValid
    local math_random = math.random

    local skipChance = 0.6
    local itemSteps = 20
    local boneBreakSoundChance = 0.35
    local painSoundChance = 0.1

    local painSounds = {
        "vo/npc/male01/moan01.wav",
        "vo/npc/male01/moan02.wav",
        "vo/npc/male01/moan03.wav",
        "vo/npc/male01/moan04.wav",
        "vo/npc/male01/moan05.wav",
        "vo/npc/male01/pain01.wav",
        "vo/npc/male01/pain02.wav",
        "vo/npc/male01/pain03.wav",
        "vo/npc/male01/pain04.wav",
        "vo/npc/male01/pain05.wav",
        "vo/npc/male01/pain06.wav",
        "vo/npc/male01/pain07.wav",
        "vo/npc/male01/pain08.wav",
        "vo/npc/male01/pain09.wav",
        "vo/npc/male01/help01.wav",
        "vo/npc/male01/ow01.wav",
        "vo/npc/male01/ow02.wav",
    }
    local painSoundCount = #painSounds

    local boneBreakSounds = {
        "physics/body/body_medium_break2.wav",
        "physics/body/body_medium_break3.wav",
        "physics/body/body_medium_break4.wav",
        "physics/flesh/flesh_squishy_impact_hard1.wav",
        "physics/flesh/flesh_squishy_impact_hard2.wav",
        "physics/flesh/flesh_squishy_impact_hard3.wav",
        "physics/flesh/flesh_squishy_impact_hard4.wav",
    }
    local boneBreakSoundCount = #boneBreakSounds

    local function boneBreakSound( ent )
        local shouldPlay = math_random() < boneBreakSoundChance
        if not shouldPlay then return end

        local soundName = boneBreakSounds[math_random( 1, boneBreakSoundCount )]
        local pitch = math_random( 50, 150 )
        sound.Play( soundName, ent:GetPos(), 75, pitch, 1 )
    end

    local function painSound( ent )
        local shouldPlay = math_random() < painSoundChance
        if not shouldPlay then return end

        local soundName = painSounds[math_random( 1, painSoundCount )]
        ent:EmitSound( soundName, 75, 100, 1, CHAN_VOICE )
    end

    local function setupSquence( ent )
        local queue = table.Copy( YNM.BaseEntityManipulations )
        local queueCount = #queue

        -- Precompute some values that make our timer faster probably
        local boneCache = {}
        local function lookupBone( id )
            local cached = boneCache[id]
            if cached then return cached end

            cached = ent:LookupBone( id )
            boneCache[id] = cached

            return cached
        end

        for i = 1, queueCount do
            local item = queue[i]

            item.steps = 0
            item.perStep = item.value / itemSteps

            local boneName = item.bone
            item.bone = lookupBone( boneName )
        end

        return queue
    end

    --- In a randomized sequence, manipulates the given Entity's bones to form the base of a YouNeedMe
    --- Warning: This is a brutal, savage process and may cause the Entity to scream in agony
    --- @param ent Player|NPC
    --- @param onComplete function The function to call when the sequence is complete
    function YNM:ManipulateBaseEntitySequenced( ent, onComplete )
        -- NO!
        ent:EmitSound( "vo/npc/male01/no02.wav", 100, 100, 1, CHAN_VOICE )

        local queue = setupSquence( ent )

        local timerName = "youneedme_bonemanipulation_" .. ent:EntIndex()
        timer.Create( timerName, 0.03, 0, function()
            local queueCount = #queue

            -- Break if we're done
            if queueCount == 0 then
                timer.Remove( timerName )
                onComplete()
                return
            end

            -- Break if the entity is no longer valid
            if not IsValid( ent ) then
                timer.Remove( timerName )
                return
            end

            -- Chance to skip a step for timing funny
            local shouldSkip = math_random() < skipChance
            if shouldSkip then return end

            -- Pick a random item from the queue
            local queueIdx = math_random( 1, queueCount )
            local queueItem = queue[queueIdx]

            -- Decide what the new value should be
            local steps = queueItem.steps
            local max = math.min( itemSteps, steps + 3 )
            local newSteps = math_random( steps, max )
            local newValue = queueItem.perStep * newSteps

            -- Update current step count
            queueItem.steps = newSteps

            -- Update the bone
            local func = queueItem.func
            func( ent, queueItem.bone, newValue )

            -- Play sounds
            boneBreakSound( ent )
            painSound( ent )

            -- Remove the item from the queue if we're done with it
            if newSteps == itemSteps then
                table.remove( queue, queueIdx )
            end
        end )
    end
end
