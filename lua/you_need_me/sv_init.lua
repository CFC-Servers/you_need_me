--- @class YouNeedMe
YouNeedMe = YouNeedMe or {}

--- @class YouNeedMe
--- @field ActiveTransformations table<Entity, YouNeedMe.TransformationData> A table of active transformations, indexed by the Entity being transformed
local YNM = YouNeedMe
YNM.ActiveTransformations = {}

-- #region Localized Functions

-- Math.*
local math_random = math.random
local math_floor = math.floor
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

-- #endregion

-- #region Classes

--- @class YouNeedMe.BoneManipulationData
--- @field BoneName string The name of the bone being manipulated
--- @field StartPositionOffset Vector? The starting positional offset of the bone, relative to the bone's original position of (0, 0, 0)
--- @field EndPositionOffset Vector? The final positional offset of the bone, relative to the bone's original position of (0, 0, 0)
--- @field StartAngleOffset Angle? The starting angular offset of the bone, relative to the bone's original angle of (0, 0, 0)
--- @field EndAngleOffset Angle? The final angular offset of the bone, relative to the bone's original angle of (0, 0, 0)
--- @field StartScale Vector? The starting scale of the bone, relative to the bone's original scale of (1, 1, 1)
--- @field EndScale Vector? The final scale of the bone, relative to the bone's original scale of (1, 1, 1)

--- Represents a transformation in-progress
--- A sequential table of YouNeedMe.BoneManipulationData with some additional properties
--- @class YouNeedMe.TransformationData : table
--- @field StartTime number The time at which the transformation began, in seconds, relative to CurTime
--- @field EndTime number The time at which the transformation will end, in seconds, relative to CurTime
--- @field Duration number The duration of the transformation, in seconds
--- @field BoneManipulations YouNeedMe.BoneManipulationData[] The goal state of the Entity's bones

--- Creates a new TransformationData object
--- @param boneManipulations YouNeedMe.BoneManipulationData[] The data for the bone manipulations, which will be copied rather than referenced directly
--- @param duration number The duration of the transformation, in seconds
--- @return YouNeedMe.TransformationData
function YNM.NewTransformationData( boneManipulations, duration )
    local time = CurTime()

    --- @type YouNeedMe.TransformationData
    return {
        StartTime = time,
        EndTime   = time + duration,
        Duration = duration,
        BoneManipulations = table_Copy( boneManipulations )
    }
end

--- Information about a bone breaking sound
--- @class YouNeedMe.BoneBreakSoundData
--- @field SoundName string The name of the sound that was played
--- @field PlayTime number The time at which the sound was played, in seconds, relative to CurTime

-- #endregion

-- #region Constants

local DEFAULT_BONE_POSITION_OFFSET  = Vector( 0, 0, 0 )
local DEFAULT_BONE_ANGLE_OFFSET     = Angle ( 0, 0, 0 )
local DEFAULT_BONE_SCALE            = Vector( 1, 1, 1 )

---@class YouNeedMe
--- The bone manipulations to turn a Player into the host body for a YouNeedMe
--- @type YouNeedMe.BoneManipulationData[]
YNM.HostBodyManipulations = {
    { -- Head
        BoneName        = "ValveBiped.Bip01_Head1",
        EndPositionOffset  = Vector( 10, 5, 0 ),
        EndAngleOffset     = Angle ( 0, 95, 0 ),
        EndScale           = Vector( 1.2, 1.2, 1.2 )
    },
    { -- Neck
        BoneName        = "ValveBiped.Bip01_Neck1",
        EndPositionOffset  = Vector( 5, 10, 0 ),
        EndAngleOffset     = Angle ( 0, 25, 0 )
    },
    { -- Waist
        BoneName        = "ValveBiped.Bip01_Spine",
        EndAngleOffset     = Angle ( 0, 105, 0 )
    },
    { -- Spine 1
        BoneName        = "ValveBiped.Bip01_Spine1",
        EndPositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Spine 2
        BoneName        = "ValveBiped.Bip01_Spine2",
        EndPositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Spine 4
        BoneName        = "ValveBiped.Bip01_Spine4",
        EndAngleOffset     = Angle( 0, -20, 0 ),
        EndPositionOffset  = Vector( 5, 0, 0 )
    },
    { -- Left Shoulder
        BoneName        = "ValveBiped.Bip01_L_Clavicle",
        EndAngleOffset     = Angle( 0, 0, -90 )
    },
    { -- Right Shoulder
        BoneName        = "ValveBiped.Bip01_R_Clavicle",
        EndAngleOffset     = Angle( 0, 0, 90 )
    },
    { -- Right Arm
        BoneName        = "ValveBiped.Bip01_R_UpperArm",
        EndPositionOffset  = Vector( 10, -10, -5 )
    },
    { -- Right Thigh
        BoneName        = "ValveBiped.Bip01_R_Thigh",
        EndPositionOffset  = Vector( -15, 0, -20 )
    },
    { -- Left Thigh
        BoneName        = "ValveBiped.Bip01_L_Thigh",
        EndPositionOffset  = Vector( 15, 0, -20 )
    },
    { -- Right Calf
        BoneName        = "ValveBiped.Bip01_R_Calf",
        EndPositionOffset  = Vector( 10, 20, 0 )
    },
    { -- Left Calf
        BoneName        = "ValveBiped.Bip01_L_Calf",
        EndPositionOffset  = Vector( 10, 20, 0 )
    },
}

YNM.BoneBreakSounds = {
    "physics/body/body_medium_break2.wav",
    "physics/body/body_medium_break3.wav",
    "physics/body/body_medium_break4.wav",
    "physics/flesh/flesh_squishy_impact_hard1.wav",
    "physics/flesh/flesh_squishy_impact_hard2.wav",
    "physics/flesh/flesh_squishy_impact_hard3.wav",
    "physics/flesh/flesh_squishy_impact_hard4.wav",
}

-- #endregion

-- #region Bone Manipulation Functions

--- Sets the position, angle, and scale of a set of bones on an Entity
--- @param ent Entity The Entity whose bones will be manipulated
--- @param boneManipulations YouNeedMe.BoneManipulationData[] The data for the bone manipulations
function YNM.SetBoneManipulations( ent, boneManipulations )
    for _, manipulationData in ipairs( boneManipulations ) do
        local bone = ent:LookupBone( manipulationData.BoneName )

        if bone then
            if manipulationData.EndPositionOffset then
                ent:ManipulateBonePosition( bone, manipulationData.EndPositionOffset )
            end

            if manipulationData.EndAngleOffset then
                ent:ManipulateBoneAngles( bone, manipulationData.EndAngleOffset )
            end

            if manipulationData.EndScale then
                ent:ManipulateBoneScale( bone, manipulationData.EndScale )
            end
        end
    end
end

--- Sets the position of a bone on an Entity and plays an appropriate sound
--- @param ent Entity The Entity whose bone will be manipulated
--- @param boneId integer The ID of the bone to manipulate
--- @param positionOffset Vector The new position offset of the bone
function YNM.SetBonePositionOffset( ent, boneId, positionOffset )
    local oldOffset = ent:GetManipulateBonePosition( boneId )

    local distance = oldOffset:Distance( positionOffset )

    local threshold = 1

    -- Play a sound if the bone is being moved significantly
    if distance > threshold then
        YNM.PlayBoneMoveSound( ent )
    end

    ent:ManipulateBonePosition( boneId, positionOffset )
end

--- Sets the angle of a bone on an Entity and plays an appropriate sound
--- @param ent Entity
--- @param boneId integer
--- @param angleOffset Angle
function YNM.SetBoneAngleOffset( ent, boneId, angleOffset )
    local oldOffset = ent:GetManipulateBoneAngles( boneId )

    local distance = 0
    distance = distance + math.abs( oldOffset.p - angleOffset.p )
    distance = distance + math.abs( oldOffset.y - angleOffset.y )
    distance = distance + math.abs( oldOffset.r - angleOffset.r )

    local threshold = 20

    -- Play a sound if the bone is being moved significantly
    if distance > threshold then
        print( distance )
        YNM.PlayBoneMoveSound( ent, boneId )
    end

    ent:ManipulateBoneAngles( boneId, angleOffset )
end

--- Resets the position, angle, and scale of all bones on an Entity
--- @param ent Entity The Entity whose bones will be reset
function YNM.ResetBoneManipulations( ent )
    for _, manipulationData in ipairs( YNM.HostBodyManipulations ) do
        local bone = ent:LookupBone( manipulationData.BoneName )

        if bone then
            ent:ManipulateBonePosition( bone, DEFAULT_BONE_POSITION_OFFSET )
            ent:ManipulateBoneAngles  ( bone, DEFAULT_BONE_ANGLE_OFFSET    )
            ent:ManipulateBoneScale   ( bone, DEFAULT_BONE_SCALE           )
        end
    end
end

-- #endregion

-- #region Transformation

--- Begins the transformation of an Entity's bones
--- @param ent Entity The Entity whose bones will be transformed
--- @param boneManipulationData YouNeedMe.TransformationData The end goal of the transformation
--- @param duration number The duration of the transformation, in seconds
function YNM.StartTransformation( ent, boneManipulationData, duration )
    local transformation = YNM.NewTransformationData( boneManipulationData, duration )
    YNM.ActiveTransformations[ent] = transformation

    -- Store starting values as needed
    for _, boneManipulation in ipairs( transformation.BoneManipulations ) do
        --- @cast boneManipulation YouNeedMe.BoneManipulationData

        local boneId = ent:LookupBone( boneManipulation.BoneName )

        if boneManipulation.EndPositionOffset then
            boneManipulation.StartPositionOffset = ent:GetManipulateBonePosition( boneId )
        end

        if boneManipulation.EndAngleOffset then
            boneManipulation.StartAngleOffset = ent:GetManipulateBoneAngles( boneId )
        end

        if boneManipulation.EndScale then
            boneManipulation.StartScale = ent:GetManipulateBoneScale( boneId )
        end
    end
end

--- Bone breaking sounds will have at least this many seconds between them
YNM.BoneBreakMinSoundInterval = 0.5

--- Bone breaking sounds will happen at least once per this many seconds
YNM.BoneBreakMaxSoundInterval = 1.5

-- Update all transformations
hook.Add( "Think", "Phatso_YouNeedMe_UpdateTransformations", function()
    local time = CurTime()

    -- Update each active transformation
    for ent, transformation in pairs( YNM.ActiveTransformations ) do
        --- @cast transformation YouNeedMe.TransformationData
        --- @cast ent Entity

        local progress = math_min( ( time - transformation.StartTime ) / transformation.Duration, 1 )

        -- Manipulate each bone
        for _, boneManipulation in ipairs( transformation.BoneManipulations ) do
            --- @cast boneManipulation YouNeedMe.BoneManipulationData

            local boneId = ent:LookupBone( boneManipulation.BoneName )

            if boneManipulation.EndPositionOffset then
                local startPos = boneManipulation.StartPositionOffset --- @type Vector
                local endPos = boneManipulation.EndPositionOffset --- @type Vector

                local stepFrequency = 1 + boneId
                local lerpInput = math_floor( progress * stepFrequency ) / stepFrequency
                --lerpInput = math.ease.InElastic( lerpInput )

                local pos = LerpVector( lerpInput, startPos, endPos )
                YNM.SetBonePositionOffset( ent, boneId, pos )
            end

            if boneManipulation.EndAngleOffset then
                local startAng = boneManipulation.StartAngleOffset --- @type Angle
                local endAng = boneManipulation.EndAngleOffset --- @type Angle

                local stepFrequency = 2 + boneId
                local lerpInput = math_floor( progress * stepFrequency ) / stepFrequency
                --lerpInput = math.ease.InOutBounce( lerpInput )

                local ang = LerpAngle( lerpInput, startAng, endAng )
                YNM.SetBoneAngleOffset( ent, boneId, ang )
            end

            if boneManipulation.EndScale then
                local startScale = boneManipulation.StartScale --- @type Vector
                local endScale = boneManipulation.EndScale --- @type Vector

                local stepFrequency = 3 + boneId
                local lerpInput = math_floor( progress * stepFrequency ) / stepFrequency
                --lerpInput = math.ease.InCubic( lerpInput )

                local scale = LerpVector( lerpInput, startScale, endScale )
                ent:ManipulateBoneScale( boneId, scale )
            end
        end

        -- Stop the transformation if it's done
        if time >= transformation.EndTime then
            YNM.ActiveTransformations[ent] = nil
        end
    end
end )


-- #endregion

-- #region Sounds

--- @type table<Entity, YouNeedMe.BoneBreakSoundData>
YNM.RecentSounds = {}

--- Plays a sound to indicate that a bone has been moved
--- @param ent Entity The Entity whose bone was moved
--- @param boneid integer The ID of the bone that was moved
function YNM.PlayBoneBreakSound( ent, boneid )

    local length = ent:BoneLength( boneid )

    -- 55 is the approximate length of the longest bone in the Kleiner player model
    local lengthPercent = math_min( length / 55, 1 )

    local pitch = 100 - ( lengthPercent * 50 )

    local soundName = YNM.BoneBreakSounds[math_random( 1, #YNM.BoneBreakSounds )]
    sound_Play( soundName, ent:GetPos(), 75, pitch, 1 )
end

-- #endregion

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
        "physics/plastic/plastic_barrel_impact_bullet1.wav",
        "physics/plastic/plastic_box_break2.wav",
        "physics/body/body_medium_break2.wav",
        "physics/body/body_medium_break3.wav",
        "physics/body/body_medium_break4.wav",
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

    --- 
    --- @param ent Entity
    --- @param boneManipulations YouNeedMe.BoneManipulationData[]
    --- @return table
    local function setupSquence( ent, boneManipulations )
        local queue = table_Copy( YNM.HostBodyManipulations )

        -- Precompute some values that make our timer faster probably
        local boneCache = {}
        local function lookupBone( id )
            local cached = boneCache[id]
            if cached then return cached end

            cached = ent:LookupBone( id )
            boneCache[id] = cached

            return cached
        end

        for _, item in ipairs( queue ) do
            item.steps = 0
            item.stepSize = item.value / itemSteps

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

        local queue = setupSquence( ent, YNM.HostBodyManipulations )

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
