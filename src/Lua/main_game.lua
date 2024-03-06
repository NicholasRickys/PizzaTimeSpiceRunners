rawset(_G, "PTSR_shallowcopy", function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end)

G_AddGametype({
    name = "Spice Runners",
    identifier = "PTSPICER",
    typeoflevel = TOL_PTSR,
    rules = GTR_FRIENDLY|GTR_SPAWNENEMIES|GTR_TIMELIMIT,
    intermissiontype = int_match,
    headercolor = 67,
    description = "Run away from pizzaface, in style!"
})

-- MapVote
addHook("ThinkFrame", do
	local MV = MapVote
	if MV and MV.RegisterGametype then
		local rg = MV.RegisterGametype
		rg(GT_PTSPICER,	"Pizza Time" ,0,0,TOL_RACE)
	end
end)

local loaded_mods = false

rawset(_G, "PTSR", { -- variables
	spawn_location = 
	{x = 0, y = 0, z = 0, angle = 0}, -- where the sign is at the start of the map
	
	end_location = 
	{x = 0, y = 0, z = 0, angle = 0}, -- where the sign originally was in the map placement
	
	pizzatime = false,
	laps = 0,
	quitting = false,
	pizzatime_tics = 0,
	
	maxlaps = 5,

	timeleft = 0,
	
	timeover = false,
	
	endsector = nil,
	
	showtime = false,
	
	hudstuff = {
		anim = 0,
		anim_active = false,
		
		rev = false,
		wait_tics = 0,
		
		stop = false,
	},

	intermission_tics = 0,

	gameover = false,
	
	deathrings = {},
	
	timeover_tics = 0,
	
	maxrankpoints = 0,
	
	vote_maplist = {
		{votes = 0, mapnum = 1},
		{votes = 0, mapnum = 1},
		{votes = 0, mapnum = 1}
	},
	
	nextmapvoted = 0,
	
	dustdeviltimer = 0, -- when this reaches a certain number, every pizza face spawns an alive dust devil
})

PTSR.laphold = 10*TICRATE -- hold fire to lap

addHook("NetVars", function(net)
	local sync_list = {
		"spawn_location",
		"end_location",
		"pizzatime",
		"maxlaps",
		"quitting",
		"pizzatime_tics",
		"timeleft",
		"timeover",
		"showtime",
		"endsector",
		
		"hudstuff",
		
		"maxrankpoints",

		"gamemode",
		
		"maxtime",
		
		"timeover_tics",
		
		"deathrings",
		
		"john",

		"untilend",

		"intermission_tics",

		"gameover",
		
		"vote_maplist",
		
		"nextmapvoted",
		
		"dustdeviltimer",
	}
	
	for i,v in ipairs(sync_list) do
		PTSR[v] = net($)
	end
end)

PTSR.spawn_location_atdefault = (
PTSR.spawn_location.x == 0 and 
PTSR.spawn_location.y == 0 and 
PTSR.spawn_location.z == 0 and 
PTSR.spawn_location.angle == 0
) -- returns true if at the defaults

PTSR.end_location_atdefault = (
PTSR.end_location.x == 0 and 
PTSR.end_location.y == 0 and 
PTSR.end_location.z == 0 and 
PTSR.end_location.angle == 0
) -- returns true if at the defaults

PTSR.gamemode_list = {
	"Elimination Mode",
	"Infection Mode",
}

PTSR.gamemode = 1

rawset(_G, "PTSR_COUNT", do
	local activeCount = 0
	local inactiveCount = 0
	local pizzaCount = 0

	for player in players.iterate
		if player.valid
			if player.pizzaface then
				pizzaCount = $+1
			end
			if player.ptsr_outofgame or player.spectator or player.pizzaface or (player.playerstate == PST_DEAD and PTSR.pizzatime)
				inactiveCount = $+1
			end
		end
		activeCount = $+1
	end

	return {
		inactive = inactiveCount, -- includes pizza faces
		active = activeCount,
		pizzas = pizzacount
	}
end)

local RANKMUS = {
	P = "RNK_P",
	S = "RNK_S",
	A = "RNK_A",
	B = "RNK_CB",
	C = "RNK_CB",
	D = "RNK_D"
}

addHook("ThinkFrame", do
	local count = PTSR_COUNT()

	if PTSR.pizzatime then
		P_StartQuake(FRACUNIT*4, 1)
		PTSR.pizzatime_tics = $ + 1

		if CV_PTSR.timelimit.value then
			if PTSR.timeleft and (count.inactive ~= count.active) then
				PTSR.timeleft = $ - 1
				if PTSR.timeleft == 3*TICRATE then
					S_FadeMusic(0, 3000)
				end
				if not PTSR.timeleft then
					PTSR.timeover = true
					local timeover_text = "\x8F*Overtime!"
					chatprint(timeover_text)
					
					S_StartSound(nil, P_RandomRange(41,43)) -- lightning
					--S_StartSound(nil, sfx_pizzao)
					
					for i,deathring in ipairs(PTSR.deathrings) do
						if deathring and deathring.valid and deathring.rings_kept then
							deathring.rings_kept = $ * 3
						end
					end
					
					if DiscordBot then
						DiscordBot.Data.msgsrb2 = $ .. ":alarm_clock: Overtime!\n"
					end
				end
			end
		end

		-- This is explicitly for turning off an inactive game (everyones dead!!!).
		if not PTSR.gameover then
			if (count.inactive == count.active) and PTSR.untilend < 100 then
				PTSR.untilend = $ + 1
				if PTSR.untilend >= 100 then
					PTSR.gameover = true
					print("GAME OVER!")
					if consoleplayer and consoleplayer.valid then
						S_ChangeMusic(RANKMUS[consoleplayer.ptsr_rank], false, player)
						mapmusname = RANKMUS[consoleplayer.ptsr_rank]
					end
				end
			else
				PTSR.untilend = 0
			end
		else -- intermission thinker
			PTSR.intermission_tics = $ + 1
		end

		if PTSR.timeover then
			PTSR.timeover_tics = $ + 1
		end
	end 
end)

rawset(_G, "GT_PIZZATIMEJISK", GT_PTSPICER)
rawset(_G, "PTJE", PTSR)
rawset(_G, "JISK_COUNT", PTSR_COUNT)