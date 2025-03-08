--- @class YouNeedMe
YouNeedMe = YouNeedMe or {}

---@class YouNeedMe
local YNM = YouNeedMe

-- #region Class Definitions

--- @class YouNeedMe.BoneManipulationData
--- @field BoneName string The name of the bone being manipulated
--- @field PositionOffset Vector? The positional offset of the bone, relative to the bone's original position of (0, 0, 0)
--- @field AngleOffset Angle? The angular offset of the bone, relative to the bone's original angle of (0, 0, 0)
--- @field Scale Vector? The scale of the bone, relative to the bone's original scale of (1, 1, 1)

-- #endregion

-- #region Localized Functions

-- Math.*
local math_random = math.random
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad

-- hook.*
local hook_Add = hook.Add
local hook_Remove = hook.Remove

-- Sound.*
local sound_Play = sound.Play

-- table.*
local table_Random  = table.Random
local table_remove  = table.remove
local table_Copy    = table.Copy
local table_insert  = table.insert

-- timer.*
local timer_Create = timer.Create
local timer_Simple = timer.Simple
local timer_Remove = timer.Remove

-- ents.*
local ents_Create = ents.Create

-- Misc
local IsValid = IsValid
local Vector = Vector
local Angle = Angle

--#endregion

-- #region Constants

local DEFAULT_BONE_POSITION_OFFSET  = Vector( 0, 0, 0 )
local DEFAULT_BONE_ANGLE_OFFSET     = Angle ( 0, 0, 0 )
local DEFAULT_BONE_SCALE            = Vector( 1, 1, 1 )

--- @type YouNeedMe.BoneManipulationData[]
YNM.BaseEntityManipulations = {
    { -- Head
        BoneName        = "ValveBiped.Bip01_Head1",
        PositionOffset  = Vector( 10, 5, 0 ),
        AngleOffset     = Angle ( 0, 95, 0 ),
        Scale           = Vector( 1.2, 1.2, 1.2 )
    },
    { -- Neck
        BoneName        = "ValveBiped.Bip01_Neck1",
        PositionOffset  = Vector( 5, 10, 0 ),
        AngleOffset     = Angle ( 0, 25, 0 )
    },
    { -- Waist
        BoneName        = "ValveBiped.Bip01_Spine",
        AngleOffset     = Angle ( 0, 105, 0 )
    },
    { -- Spine 1
        BoneName        = "ValveBiped.Bip01_Spine1",
        PositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Spine 2
        BoneName        = "ValveBiped.Bip01_Spine2",
        PositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Spine 4
        BoneName        = "ValveBiped.Bip01_Spine4",
        AngleOffset     = Angle( 0, -20, 0 ),
        PositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Left Shoulder
        BoneName        = "ValveBiped.Bip01_L_Clavicle",
        AngleOffset     = Angle( 0, 0, -90 )
    },
    { -- Right Shoulder
        BoneName        = "ValveBiped.Bip01_R_Clavicle",
        AngleOffset     = Angle( 0, 0, 90 )
    },
    { -- Right Arm
        BoneName        = "ValveBiped.Bip01_R_UpperArm",
        PositionOffset  = Vector( 10, -10, -5 )
    },
    { -- Right Thigh
        BoneName        = "ValveBiped.Bip01_R_Thigh",
        PositionOffset  = Vector( -15, 0, -20 )
    },
    { -- Left Thigh
        BoneName        = "ValveBiped.Bip01_L_Thigh",
        PositionOffset  = Vector( 15, 0, -20 )
    },
    { -- Right Calf
        BoneName        = "ValveBiped.Bip01_R_Calf",
        PositionOffset  = Vector( 10, 20, 0 )
    },
    { -- Left Calf
        BoneName        = "ValveBiped.Bip01_L_Calf",
        PositionOffset  = Vector( 10, 20, 0 )
    },
}

-- #endregion

--#region Bone Manipulation Functions

--- Sets the position, angle, and scale of a set of bones on an Entity
--- @param ent Entity The Entity whose bones will be manipulated
--- @param boneManipulations YouNeedMe.BoneManipulationData[] The data for the bone manipulations
function YNM.SetBoneManipulations( ent, boneManipulations )
    for _, manipulationData in ipairs( boneManipulations ) do
        local bone = ent:LookupBone( manipulationData.BoneName )

        if bone then
            if manipulationData.PositionOffset then
                ent:ManipulateBonePosition( bone, manipulationData.PositionOffset )
            end

            if manipulationData.AngleOffset then
                ent:ManipulateBoneAngles( bone, manipulationData.AngleOffset )
            end

            if manipulationData.Scale then
                ent:ManipulateBoneScale( bone, manipulationData.Scale )
            end
        end
    end
end

--- Resets the position, angle, and scale of all bones on an Entity
---@param ent Entity The Entity whose bones will be reset
function YNM.ResetBoneManipulations( ent )
    for _, manipulationData in ipairs( YNM.BaseEntityManipulations ) do
        local bone = ent:LookupBone( manipulationData.BoneName )

        if bone then
            ent:ManipulateBonePosition( bone, DEFAULT_BONE_POSITION_OFFSET )
            ent:ManipulateBoneAngles  ( bone, DEFAULT_BONE_ANGLE_OFFSET    )
            ent:ManipulateBoneScale   ( bone, DEFAULT_BONE_SCALE           )
        end
    end
end

--#endregion

do
    local skipChance = 0.75
    local itemSteps = 30
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

    local function playBoneBreakSound( ent )
        local shouldPlay = math_random() < boneBreakSoundChance
        if not shouldPlay then return end

        local soundName = boneBreakSounds[math_random( 1, boneBreakSoundCount )]
        local pitch = math_random( 50, 150 )
        sound_Play( soundName, ent:GetPos(), 75, pitch, 1 )
    end

    local function playPainSound( ent )
        local shouldPlay = math_random() < painSoundChance
        if not shouldPlay then return end

        local soundName = painSounds[math_random( 1, painSoundCount )]
        ent:EmitSound( soundName, 75, 100, 1, CHAN_VOICE )
    end

    local function setupSquence( ent )
        local queue = table_Copy( YNM.BaseEntityManipulations )
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
        -- Man yelling "No!"
        ent:EmitSound( "vo/npc/male01/no02.wav", 100, 100, 1, CHAN_VOICE )

        local queue = setupSquence( ent )

        local timerName = "YouNeedMe_BoneManipulation_" .. ent:EntIndex()
        timer_Create( timerName, 0.02, 0, function()
            local queueCount = #queue

            -- Break if we're done
            if queueCount == 0 then
                timer_Remove( timerName )
                onComplete()
                return
            end

            -- Break if the entity is no longer valid
            if not IsValid( ent ) then
                timer_Remove( timerName )
                return
            end

            -- Chance to skip a step for timing funny
            local shouldSkip = math_random() < skipChance
            if shouldSkip then return end

            -- Pick a random item from the queue
            local queueId, item = table_Random( queue )

            -- Decide what the new value should be
            local steps = item.steps
            local max = math_min( itemSteps, steps + 3 )
            local newSteps = math_random( steps, max )
            local newValue = item.perStep * newSteps

            -- Update current step count
            item.steps = newSteps

            -- Update the bone
            local func = item.func
            func( ent, item.bone, newValue )

            -- Play sounds
            playBoneBreakSound( ent )
            playPainSound( ent )

            -- Remove the item from the queue if we're done with it
            if newSteps == itemSteps then
                table_remove( queue, queueId )
            end
        end )
    end

end

do
    local function makeGman( pos, headPos )
        local gman = ents_Create( "npc_gman" )
        gman:SetPos( pos )
        gman:Spawn()

        gman:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

        local exclude = {
            [5] = true,
            [6] = true,
        }

        -- TODO: We should really do this on client somewhere
        timer_Simple( 0, function()
            local small = Vector( 0.01, 0.01, 0.01 )

            for i = 1, gman:GetBoneCount() do
                if not exclude[i] then
                    gman:ManipulateBoneScale( i, small )
                end
            end
        end )

        -- Long neck
        local timerName = "YouNeedMe_GmanGrowth_" .. SysTime()

        local step = 1
        local steps = 15
        local stepSize = headPos / steps

        timer_Create( timerName, 0.1, 0, function()
            if not IsValid( gman ) then
                timer_Remove( timerName )
                return
            end

            local shouldSkip = math_random() < 0.75
            if shouldSkip then return end

            gman:ManipulateBonePosition( 6, step * stepSize )
            step = step + 1

            if step > steps then
                timer_Remove( timerName )
            end
        end )

        return gman
    end

    local function generateArc( center, radius, startAngle, endAngle, steps )
        local points = {}
        for i = 0, steps do
            local angle = startAngle + ( endAngle - startAngle ) * ( i / steps )
            local x = center.x + radius * math_cos( math_rad( angle ) )
            local y = center.y
            local z = center.z + radius * math_sin( math_rad( angle ) )
            table_insert( points, Vector( x, y, z ) )
        end
        return points
    end

    local center = Vector( 0, 25, 0 )
    local radius = 80
    local startAngle = -45
    local endAngle = 45
    local gmenCount = 6 - 1
    local arcPoints = generateArc( center, radius, startAngle, endAngle, gmenCount )

    local sounds = {
        {
            snd = "vo/citadel/br_youneedme.wav",
            duration = 1.5195918083191,
            pitch = 90,
            level = 100
        },
        {
            snd = "vo/npc/alyx/uggh01.wav",
            duration = 0.52707481384277
        },
        {
            snd = "vo/npc/alyx/hurt05.wav",
            duration = 0.78956913948059
        }
    }

    local function getSound( idx )
        return sounds[( ( idx - 1 ) % #sounds ) + 1]
    end

    local function makeGmen( base )
        local timerPrefix = "YouNeedMe_GmanSound_" .. SysTime()

        local pos = base:GetPos()
        local gmen = {}

        for i, arcPos in ipairs( arcPoints ) do
            local gman = makeGman( pos, arcPos )
            gman:SetPos( pos + Vector( 0, 0, 18 ) )

            gmen[i] = gman

            timer_Simple( i * 0.15, function()
                local snd = getSound( i )
                local path = snd.snd
                local level = snd.level or 75
                local pitch = snd.pitch or 100

                local timerName = timerPrefix .. "_" .. i
                timer_Create( timerName, snd.duration * 1.3, 0, function()
                    if not IsValid( gman ) then
                        timer_Remove( timerName )
                        return
                    end

                    gman:EmitSound( path, level, pitch, 1, CHAN_VOICE )
                end )
            end )
        end

        local hookName = "YouNeedMe_GmanPosition_" .. SysTime()
        hook_Add( "Think", hookName, function()
            if not IsValid( base ) then
                for _, gman in ipairs( gmen ) do
                    if IsValid( gman ) then
                        gman:Remove()
                    end
                end

                hook_Remove( "Think", hookName )
                return
            end

            local basePos = base:GetPos()
            local offset = base:GetForward() * -10

            local baseAng = base:GetAngles()
            baseAng.p = 0

            for _, gman in ipairs( gmen ) do
                if IsValid( gman ) then
                    gman:SetPos( basePos + offset )
                    gman:SetAngles( baseAng )
                end
            end
        end )

    end

    function YNM:EruptGmen( ent )
        makeGmen( ent )
    end
end
