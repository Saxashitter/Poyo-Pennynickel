PoyoPennynickel.FNF.RapBattles = {}
PoyoPennynickel.FNF.Songs = {}
PoyoPennynickel.FNF.Chart = nil -- CLIENT-SIDE
PoyoPennynickel.FNF.KeyBinds = {
	left = {"a", "left arrow"},
	down = {"s", "down arrow"},
	up = {"w", "k", "up arrow"},
	right = {"d", "l", "right arrow"}
}

local function get_input(keyevent)
	for name, binds in pairs(PoyoPennynickel.FNF.KeyBinds)
		for _, bind in ipairs(binds) do
			if keyevent.name == bind then
				return name
			end
		end
	end
end

local function validity_check(player)
	return player and player.valid and player.mo and player.mo.valid and player.mo.health and PoyoPennynickel.FNF.active(player)
end

local function clone_chart(group)
	local notes = {}
	for lane_id, lane in ipairs(group) do
		notes[lane_id] = {}

		for i, note in ipairs(lane) do
			notes[lane_id][i] = note
		end
	end
	return notes
end

function PoyoPennynickel.FNF:PlayerIsInRapBattle(player, match)
	if not player then return end
	if not player.valid then return end

	if match ~= nil then
		if match.players[1] == player or match.players[2] == player then
			return true, match, match.players[1] == player and 1 or 2
		end
	else
		for k,v in ipairs(self.RapBattles) do
			if v.players[1] == player or v.players[2] == player then
				return true, v, v.players[1] == player and 1 or 2
			end
		end
	end

	return false
end

function PoyoPennynickel.FNF:StartRapBattle(player1, player2, song)
	-- no player 2 means your by yourself... shame

	local song = self.Songs[1]
	local match = {
		players = {player1, player2},
		song = 1, -- dadbattle index
		tics = 0,
		notes = {}
	}

	-- setup notes for both charts... BUT. if we are the consoleplayer, store a personal chart just for us

	local initalize_client_side = 0
	for side, group in ipairs(song.notes) do
		if match.players[side] == consoleplayer then
			initalize_client_side = side
			self.Chart = clone_chart(group)
		end

		match.notes[side] = clone_chart(group)
	end

	if initalize_client_side then
		print("you are player "..initalize_client_side)
		S_ChangeMusic(song.song, false)
	end

	self.RapBattles[#self.RapBattles+1] = match
end

function PoyoPennynickel.FNF:UpdateRapBattle(match)
	local song = self.Songs[match.song]

	if not validity_check(match.players[1])
	and not validity_check(match.players[2]) then
		print("both players died")
		return true
	end

	match.tics = $ + 1
	if match.tics >= song.length then
		print("match is over")
		return true
	end

	if self:PlayerIsInRapBattle(consoleplayer, match) then
		local milliseconds = match.tics * MUSICRATE / TICRATE

		if S_MusicName() ~= song.song then
			S_ChangeMusic(song.song, nil)
			S_SetMusicPosition(milliseconds)
		elseif abs(milliseconds - S_GetMusicPosition()) >= 500 then
			S_SetMusicPosition(milliseconds)
		end
	end
end

function PoyoPennynickel.FNF:EndRapBattle(match)
	if self:PlayerIsInRapBattle(consoleplayer, match) then
		self:ResetClientRapBattle()
	end
end

function PoyoPennynickel.FNF:ResetClientRapBattle()
	self.Chart = nil
	S_ChangeMusic(mapmusname, true)
	print("reset")
end

-- TODO: maybe make this its own lua
addHook("KeyDown", function(keyevent)
	if isdedicatedserver then return end
	if keyevent.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	if chatactive then return end

	local result, match = PoyoPennynickel.FNF:PlayerIsInRapBattle(consoleplayer)
	if not result then return end

	local bind = get_input(keyevent)
	local i

	if bind == "left" then i = 1 end
	if bind == "down" then i = 2 end
	if bind == "up" then i = 3 end
	if bind == "right" then i = 4 end

	if i == nil then
		return
	end

	local self = PoyoPennynickel.FNF
	local note = self.Chart[i][1]

	if not note then
		return true
	end

	local timing = note.timing - match.tics

	if timing <= 12 then
		table.remove(self.Chart[i], 1)
	end

	return true
end)

addHook("MapChange", function()
	PoyoPennynickel.FNF.Chart = nil
	PoyoPennynickel.FNF.RapBattles = {}
end)

addHook("ThinkFrame", function()
	local self = PoyoPennynickel.FNF

	for i = #self.RapBattles, 1, -1 do
		local match = self.RapBattles[i]

		if self:UpdateRapBattle(match) then
			self:EndRapBattle(match)
			table.remove(self.RapBattles, i)
		end
	end
end)