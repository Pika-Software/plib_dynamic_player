AddCSLuaFile()

ENT.Type = 'anim'
ENT.AutomaticFrameAdvance = true

AccessorFunc( ENT, 'm_Crouching', 'Crouching', FORCE_BOOL )

function ENT:Initialize()
    self:SetNoDraw( true )

    if (CLIENT) then
        self:SetupBones()
    end

    if self:GetCrouching() then
        self:ResetSequence( 'cidle_all' )
    else
        self:ResetSequence( 'idle_all_01' )
    end
end

function ENT:SetCrouching( bool )
    self.m_Crouching = bool
    if (bool) then
        self:ResetSequence( 'cidle_all' )
    else
        self:ResetSequence( 'idle_all_01' )
    end
end

if (SERVER) then
    function ENT:Think()
        self:NextThink( CurTime() )
        return true
    end
end