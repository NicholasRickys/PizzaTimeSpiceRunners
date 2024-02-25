--heres where the values reset when maps load
local function InitMap()
	PTSR.pizzatime = false -- doesn't matter what gamemode it is, just make it false all the time.
    PTSR.spawn_location = {x = 0, y = 0, z = 0}
    PTSR.endsector = nil
	PTSR.laps = 0
	PTSR.quitting = false
	PTSR.pizzatime_tics = 0 
	PTSR.timeleft = 0
	PTSR.timeover = false
	PTSR.showtime = false
	PTSR.deathrings = {}
	PTSR.timeover_tics = 0 -- overtime
	PTSR.intermission_tics = 0
	PTSR.gameover = false
	PTSR.untilend = 0
	
	PTSR.vote_maplist = {
		{votes = 0, mapnum = 1},
		{votes = 0, mapnum = 1},
		{votes = 0, mapnum = 1}
	} 
end

local function InitMap2()
    if gametype ~= GT_PTSPICER then return end
	PTSR.john = nil
    for map in mapthings.iterate do
        if map.type == 1 then
            PTSR.spawn_location.x = map.x
            PTSR.spawn_location.y = map.y
            PTSR.spawn_location.z = map.z
            PTSR.spawn_location.angle = map.angle
        end
		
        if map.type == 501 then
            PTSR.end_location.x = map.x
            PTSR.end_location.y = map.y
            PTSR.end_location.z = map.z
            PTSR.end_location.angle = map.angle
			local john = P_SpawnMobj(
				map.x*FU - cos(map.angle*ANG1)*200, 
				map.y*FU - sin(map.angle*ANG1)*200, 
				map.z*FU,
				MT_PILLARJOHN
			)
			john.angle = map.angle*ANG1
			if map.options & MTF_OBJECTFLIP then
				john.flags2 = $ | MF2_OBJECTFLIP
			end
			PTSR.john = john
        end
    end
	-- dont use the playercount function since it will iterate through all players twice
	-- so make a non functioned playercount
	local playercount = 0
	for player in players.iterate() do
	
		playercount = $ + 1	
		-- INCREMENT OVER --
		PTSR.ResetPlayerVars(player)
	end
	
	if mapheaderinfo[gamemap].ptsr_s_rank_points ~= nil 
	and tonumber(mapheaderinfo[gamemap].ptsr_s_rank_points) then -- custom maxrankpoints
		PTSR.maxrankpoints = tonumber(mapheaderinfo[gamemap].ptsr_s_rank_points)
	else -- default maxrankpoints
		PTSR.maxrankpoints = PTSR.GetRingCount()*150
	end
end

addHook("MapChange", InitMap)
addHook("MapLoad", InitMap)
addHook("MapLoad", InitMap2)