plib.Require( 'entity_positioning_kit' )
plib.Require( 'player_extensions' )

include( 'plib/addons/server/dynamic_player/calculating.lua' )

local dynamic_player = dynamic_player
local timer_Simple = timer.Simple
local string_lower = string.lower
local IsValid = IsValid
local Vector = Vector
local select = select
local math = math

local modelCache = {}

hook.Add('PlayerModelChanged', 'Dynamic Player', function( ply, model )
	timer_Simple(0, function()
		if IsValid( ply ) and (ply:GetModel() == string_lower( model )) then
			local mins, maxs, duckHeight, eyeHeight, eyeHeightDuck

			-- Loading from cache
			local cache = modelCache[ model ]
			if (cache) then
				mins, maxs, duckHeight, eyeHeight, eyeHeightDuck = cache[1][1], cache[1][2], cache[2], cache[3][1], cache[3][2]
			end

			if (ply:GetBoneCount() > 1) then
				if (cache == nil) then
					-- Hull Dummy
					local dummy = dynamic_player.CreateDummy( model, false )
					if not IsValid( dummy ) then return end

					-- Hull Calc
					mins, maxs = dynamic_player.CalcByEntity( dummy )

					-- Eyes Height Calc
					eyeHeight = math.Round( dummy:WorldToLocal( dummy:GetEyePosition() )[3] )

					-- Duck Hull Dummy
					local crouchingDummy = dynamic_player.CreateDummy( model, true )
					if not IsValid( crouchingDummy ) then return end

					-- Duck Height Calc
					duckHeight = select( -1, dynamic_player.CalcByEntity( crouchingDummy ) )[3]
					if (duckHeight < 5) then
						duckHeight = maxs[3] / 2
					end

					-- Duck Eyes Height Calc
					eyeHeightDuck = math.Round( crouchingDummy:WorldToLocal( crouchingDummy:GetEyePosition() )[3] ) + 1

					-- Eye position correction
					local height = (maxs[3] - mins[3]) * 0.9
					eyeHeight = math.floor( math.Clamp( eyeHeight, 5, height ) )
					eyeHeightDuck = math.floor( math.max( 5, eyeHeightDuck, height * 0.7 ) )

					-- Height correction
					duckHeight = math.floor( math.max( duckHeight, eyeHeightDuck + 5 ) )
					maxs[3] = math.floor( math.max( maxs[3], eyeHeight + 5 ) )

					-- Saving results in cache
					modelCache[ model ] = { { mins, maxs }, duckHeight, { eyeHeight, eyeHeightDuck } }
				end

				-- Selecting Eyes Level
				ply:SetViewOffset( Vector( 0, 0, eyeHeight ) )
				ply:SetViewOffsetDucked( Vector( 0, 0, eyeHeightDuck ) )
			else
				if (cache == nil) then
					-- Hulls Calc
					mins, maxs = dynamic_player.FastCalcByModel( model )
					duckHeight = maxs[3] * 0.7

					-- Eyes Calc
					eyeHeight = math.Round( (maxs[3] - mins[3]) * 0.9 )
					eyeHeightDuck = math.Round( eyeHeight * 0.7 )

					-- Saving results in cache
					modelCache[ model ] = { { mins, maxs }, duckHeight, { eyeHeight, eyeHeightDuck } }
				end

				-- Selecting Eyes Level
				ply:SetViewOffsetDucked( Vector( 0, 0, eyeHeightDuck ) )
				ply:SetViewOffset( Vector( 0, 0, eyeHeight ) )
			end

			-- Setuping Hulls
			ply:SetHullDuck( mins, Vector( maxs[1], maxs[2], duckHeight ) )
			ply:SetHull( mins, maxs )

			-- Setuping Step Size & Pos Fix
			ply:SetStepSize( dynamic_player.CalcStepSize( mins, maxs ) )
			dynamic_player.FixPlayerPosition( ply, mins, maxs )
		end
	end)
end)
