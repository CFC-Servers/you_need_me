AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_NONE )

    timer.Simple( 0, function()
        self:SetupNPCs()
    end )
end

--- Randomizes the flex values of a given NPC
--- @param npc Entity
local function randomizeFlexes( npc )
    local maxFlexes = 96
    local flexCount = math.min( maxFlexes, npc:GetFlexNum() )

    for i = 1, flexCount - 1 do
        local min, max = npc:GetFlexBounds( i )
        local val = math.Rand( min, max )

        npc:SetFlexWeight( i, val )
    end

    npc:SetFlexScale( math.Rand( 3, 5 ) )
end

local function makeKleiner( pos )
    local kleiner = ents.Create( "npc_kleiner" )

    kleiner:SetPos( pos + Vector( 0, 0, 18 ) )
    kleiner:Spawn()

    kleiner:ManipulateBoneAngles( 6, Angle( 0, 95, 0 ) ) -- head
    kleiner:ManipulateBoneAngles( 5, Angle( 0, 25, 0 ) ) -- neck
    kleiner:ManipulateBoneAngles( 1, Angle( 0, 105, 0 ) ) -- waist

    kleiner:ManipulateBoneScale( 6, Vector( 1.2, 1.2, 1.2 ) ) -- head size
    kleiner:ManipulateBonePosition( 6, Vector( 10, 5, 0 ) ) -- head position
    kleiner:ManipulateBonePosition( 5, Vector( 5, 10, 0 ) ) -- neck position
    kleiner:ManipulateBoneAngles( 4, Angle( 0, -20, 0 ) ) -- top spine angle


    -- long back
    kleiner:ManipulateBonePosition( 2, Vector( 5, 0, 0 ) )
    kleiner:ManipulateBonePosition( 3, Vector( 5, 0, 0 ) )
    kleiner:ManipulateBonePosition( 4, Vector( 5, 0, 0 ) )

    -- left arm
    kleiner:ManipulateBoneAngles( 13, Angle( 0, 0, -90 ) )

    -- right arm
    kleiner:ManipulateBoneAngles( 8, Angle( 0, 0, 90 ) )
    kleiner:ManipulateBonePosition( 9, Vector( 10, -10, -5 ) )

    -- move thighs outward
    kleiner:ManipulateBonePosition( 18, Vector( -15, 0, -20 ) ) -- r
    kleiner:ManipulateBonePosition( 22, Vector( 15, 0, -20 ) ) -- l

    -- calves
    kleiner:ManipulateBonePosition( 19, Vector( 10, 20, 0 ) ) -- r
    kleiner:ManipulateBonePosition( 23, Vector( 10, 20, 0 ) ) -- l

    randomizeFlexes( kleiner )

    local kleinerSound = "ambient/energy/force_field_loop1.wav"
    kleiner:EmitSound( kleinerSound, 75, 60, 1, CHAN_VOICE )

    kleiner:CallOnRemove( "YouNeedMe_KleinerSoundStop", function()
        kleiner:StopSound( kleinerSound )
    end )

    return kleiner
end


local makeGmen
do
    local function generateArc( center, radius, startAngle, endAngle, steps )
        local points = {}
        for i = 0, steps do
            local angle = startAngle + ( endAngle - startAngle ) * ( i / steps )
            local x = center.x + radius * math.cos( math.rad( angle ) )
            local y = center.y
            local z = center.z + radius * math.sin( math.rad( angle ) )
            table.insert( points, Vector( x, y, z ) )
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

    local function makeGman( pos, headPos )
        local gman = ents.Create( "npc_gman" )
        gman:SetPos( pos )
        gman:Spawn()

        local exclude = {
            [5] = true,
            [6] = true,
        }

        -- TODO: We should really do this on client somewhere
        timer.Simple( 0, function()
            for i = 1, gman:GetBoneCount() do
                if not exclude[i] then
                    gman:ManipulateBoneScale( i, vector_origin )
                end
            end
        end )

        -- Long neck
        gman:ManipulateBonePosition( 6, headPos )

        return gman
    end

    makeGmen = function( kleiner )
        local timerPrefix = "YouNeedMe_GmanSound_Entity_" .. SysTime()

        local pos = kleiner:GetPos()

        for i, arcPos in ipairs( arcPoints ) do
            local gman = makeGman( pos, arcPos )
            gman:SetPos( pos + Vector( 0, 0, 18 ) )
            gman:SetParent( kleiner )

            timer.Simple( i * 0.15, function()
                local snd = getSound( i )
                local path = snd.snd
                local level = snd.level or 75
                local pitch = snd.pitch or 100

                local timerName = timerPrefix .. "_" .. i
                timer.Create( timerName, snd.duration * 1.3, 0, function()
                    if not IsValid( gman ) then
                        timer.Remove( timerName )
                        return
                    end

                    gman:EmitSound( path, level, pitch, 1, CHAN_VOICE )
                end )
            end )
        end
    end
end

function ENT:StartKleinerLoop()
    local kleiner = self.Kleiner
    local timerName = "YouNeedMe_KleinerLoop_" .. self:EntIndex()

    timer.Create( timerName, 5, 0, function()
        if not IsValid( kleiner ) then return end

        local pos = kleiner:GetPos()

        local closestPos
        local closestDist = math.huge
        for _, ply in player.Iterator() do
            local plyPos = ply:GetPos()
            local distance = plyPos:Distance( pos )

            if ( not closestPos ) or ( distance < closestDist ) then
                closestPos = plyPos
                closestDist = distance
            end
        end

        kleiner:SetSaveValue( "m_vecLastPosition", closestPos )
        kleiner:SetSchedule( SCHED_FORCED_GO_RUN )
    end )

    kleiner:CallOnRemove( "YouNeedMe_KleinerLoopStop", function()
        timer.Remove( timerName )
    end )
end

function ENT:SetupNPCs()
    local pos = self:GetPos()

    local kleiner = makeKleiner( pos )
    self.Kleiner = kleiner
    self:CallOnRemove( "YouNeedMe_KleinerRemove", function()
        if IsValid( kleiner ) then
            kleiner:Remove()
        end
    end )

    self:SetParent( kleiner )
    self:StartKleinerLoop()

    makeGmen( kleiner )
end
