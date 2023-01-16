local table_insert = table.insert
local WorldToLocal = WorldToLocal
local isnumber = isnumber
local ipairs = ipairs
local Vector = Vector
local math = math
local util = util

module( 'dynamic_player' )

function CalcByEntity( ent )
	local mins, maxs = Vector(), Vector()
	local playerPos, playerAng = ent:GetPos(), ent:GetAngles()
	for hboxset = 0, ent:GetHitboxSetCount() - 1 do
		for hitbox = 0, ent:GetHitBoxCount( hboxset ) - 1 do
			local bone = ent:GetHitBoxBone( hitbox, hboxset )
			if isnumber( bone ) and (bone >= 0) then
				local bonePos, boneAng = ent:GetRealBonePosition( bone )
				local boneMins, boneMaxs = ent:GetHitBoxBounds( hitbox, hboxset )
				local localBonePos = WorldToLocal( bonePos, boneAng, playerPos, playerAng )

				boneMins = boneMins + localBonePos
				boneMaxs = boneMaxs + localBonePos

				for i = 1, 3 do
					if (boneMins[i] < mins[i]) then
						mins[i] = boneMins[i]
					end
				end

				for i = 1, 3 do
					if (boneMaxs[i] > maxs[i]) then
						maxs[i] = boneMaxs[i]
					end
				end
			end
		end
	end

	maxs[1] = math.floor( ((maxs[1] - mins[1]) + (maxs[2] - mins[2])) / 6 )
	maxs[3] = math.floor( maxs[3] )
	maxs[2] = maxs[1]

	local floorMins = math.floor( mins[3] )
	mins[3] = math.abs( floorMins ) >= maxs[3] and floorMins or 0
	mins[1] = -maxs[1]
	mins[2] = mins[1]

	return mins, maxs
end

function FastCalcByModel( model )
	local mins, maxs = Vector(), Vector()

	local verticies = {}
	for _, tbl in ipairs( util.GetModelMeshes( model, 0, 0 ) ) do
		for __, point in ipairs( tbl.verticies ) do
			table_insert( verticies, point )
		end
	end

	for num, point in ipairs( verticies ) do
		local pos = point.pos
		for i = 1, 3 do
			if (pos[i] < mins[i]) then
				mins[i] = pos[i]
			end
		end

		for i = 1, 3 do
			if (pos[i] > maxs[i]) then
				maxs[i] = pos[i]
			end
		end
	end

	maxs[1] = math.floor( ((maxs[1] - mins[1]) + (maxs[2] - mins[2])) / 4 )
	maxs[3] = math.floor( maxs[3] )
	maxs[2] = maxs[1]

	local floorMins = math.floor( mins[3] )
	mins[3] = math.abs( floorMins ) >= maxs[3] and floorMins or 0
	mins[1] = -maxs[1]
	mins[2] = mins[1]

	return mins, maxs
end

function CalcByModel( model )

	local mins, maxs = Vector(), Vector()

	local meshInfo, bodyParts = util.GetModelMeshes( model, 0, 0 )
	local modelInfo = util.GetModelInfo( model )

	local verticies = {}
	for _, tbl in ipairs( meshInfo ) do
		for __, point in ipairs( tbl.verticies ) do
			table_insert( verticies, point )
		end
	end

	local bones = {}
	for _, data in ipairs( util.KeyValuesToTablePreserveOrder( modelInfo.KeyValues ) ) do
		if (data.Key == 'solid') then
			local boneData = {}
			for num, bone in ipairs( data.Value ) do
				boneData[ bone.Key ] = bone.Value
			end

			local matrix = nil
			for i = 0, #bodyParts do
				local part = bodyParts[ i ]
				if (part.parent == boneData.index) then
					matrix = part.matrix
					break
				end
			end

			table_insert(bones, {
				['index'] = boneData.index,
				['name'] = boneData.name,
				['matrix'] = matrix
			})
		end
	end

	for num, point in ipairs( verticies ) do
		local pos = point.pos
		for i = 1, 3 do
			if (pos[i] < mins[i]) then
				mins[i] = pos[i]
			end
		end

		for i = 1, 3 do
			if (pos[i] > maxs[i]) then
				maxs[i] = pos[i]
			end
		end
	end

	if (#bones > 1) then
		maxs[1] = math.floor( ((maxs[1] - mins[1]) + (maxs[2] - mins[2])) / 6 )
		maxs[3] = math.floor( maxs[3] * 0.98 )
	else
		maxs[1] = math.floor( ((maxs[1] - mins[1]) + (maxs[2] - mins[2])) / 4 )
		maxs[3] = math.floor( maxs[3] )
	end

	local floorMins = math.floor( mins[3] )
	mins[3] = math.abs( floorMins ) >= maxs[3] and floorMins or 0
	mins[1] = -maxs[1]
	mins[2] = mins[1]
	maxs[2] = maxs[1]

	return mins, maxs
end

function CalcStepSize( mins, maxs )
	return math.min( math.floor( (maxs[3] - mins[3]) / 3.6 ), 4095 )
end

function FixPlayerPosition( ply, mins, maxs )
	if (mins[3] < 0) and not ply:InVehicle() then
		ply:SetPos( ply:GetPos() + Vector( 0, 0, math.abs( mins[3] ) ) )
	end
end