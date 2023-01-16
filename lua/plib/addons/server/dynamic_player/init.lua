plib.Require( 'entity_positioning_kit' )
plib.Require( 'player_extensions' )

include( 'plib/addons/server/dynamic_player/calculating.lua' )

local dynamic_player = dynamic_player
local timer_Simple = timer.Simple
local string_lower = string.lower
local IsValid = IsValid
local Vector = Vector

hook.Add('PlayerModelChanged', 'Dynamic Player', function( ply, model )
	timer_Simple(0, function()
		if IsValid( ply ) and (ply:GetModel() == string_lower( model )) then
			if (model == ply:GetPreviousModel()) then return end
			if (ply:GetBoneCount() > 1) then
				local idleSequence = ply:LookupSequence( 'idle_all_01' )
				if (idleSequence >= 0) then
					ply:ResetSequence( idleSequence )
				end

				local idleMins, idleMaxs = dynamic_player.CalcByEntity( ply )
				ply:SetHullDuck( idleMins, Vector( idleMaxs[1], idleMaxs[2], idleMaxs[3] * 0.7 ) )
				ply:SetHull( idleMins, idleMaxs )

				local height = (idleMaxs[3] - idleMins[3]) * 0.9
				local eyePosition = ply:WorldToLocal( ply:GetEyePosition() )[3]
				if (eyePosition < height) then
					ply:SetViewOffsetDucked( Vector( 0, 0, eyePosition * 0.6 ) )
					ply:SetViewOffset( Vector( 0, 0, eyePosition ) )
				else
					ply:SetViewOffsetDucked( Vector( 0, 0, height * 0.7 ) )
					ply:SetViewOffset( Vector( 0, 0, height ) )
				end

				ply:SetStepSize( dynamic_player.CalcStepSize( idleMins, idleMaxs ) )
				dynamic_player.FixPlayerPosition( ply, idleMins, idleMaxs )
				return
			end

			local mins, maxs = dynamic_player.FastCalcByModel( model )
			ply:SetHullDuck( mins, Vector( maxs[1], maxs[2], maxs[3] * 0.7 ) )
			ply:SetHull( mins, maxs )

			local height = (maxs[3] - mins[3]) * 0.9
			ply:SetViewOffsetDucked( Vector( 0, 0, height * 0.7 ) )
			ply:SetViewOffset( Vector( 0, 0, height ) )

			ply:SetStepSize( dynamic_player.CalcStepSize( mins, maxs ) )
			dynamic_player.FixPlayerPosition( ply, mins, maxs )
		end
	end)
end)
