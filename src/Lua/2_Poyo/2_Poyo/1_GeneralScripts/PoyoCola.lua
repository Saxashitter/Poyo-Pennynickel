/*
	If eligible, replace all rings with colas.
	In multiplayer, this happens if the Poyo Cola cvar is enabled.
	If the cvar is disabled, colas remain rings.
*/

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local poyo_cola = CV_RegisterVar{name = "poyo_cola", defaultvalue = 1, PossibleValue = CV_YesNo}

local SPR_POYO_COLA = freeslot("SPR_POYO_COLA")
local S_POYO_COLA = freeslot("S_POYO_COLA")
local S_POYO_COLA_COLLECTION = freeslot("S_POYO_COLA_COLLECTION")
local MT_POYO_COLA = freeslot("MT_POYO_COLA")
local MT_POYO_FLINGCOLA = freeslot("MT_POYO_FLINGCOLA")
local sfx_py_cla = freeslot("sfx_py_cla")

sfxinfo[sfx_py_cla].caption = "Cola"

local UPWARDS_TICS = 20
local COLLECTION_TICS = 9
local DURATION = UPWARDS_TICS
local UPWARDS_SPEED = 60 * FU

mobjinfo[MT_POYO_COLA] = {
	radius = 16 * FU,
	height = 32 * FU,
	speed = 38*FRACUNIT,
	flags = MF_SLIDEME|MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
	spawnstate = S_POYO_COLA,
	deathstate = S_POYO_COLA_COLLECTION,
	deathsound = sfx_py_cla
}

mobjinfo[MT_POYO_FLINGCOLA] = {
	radius = 16 * FU,
	height = 32 * FU,
	speed = 38*FRACUNIT,
	flags = MF_SLIDEME|MF_SPECIAL,
	spawnstate = S_POYO_COLA,
	deathstate = S_POYO_COLA_COLLECTION,
	deathsound = sfx_py_cla
}

states[S_POYO_COLA] = {
	sprite = SPR_POYO_COLA,
	frame = A,
	tics = 1,
	action = A_AttractChase,
	nextstate = S_POYO_COLA
}

states[S_POYO_COLA_COLLECTION] = {
	sprite = SPR_POYO_COLA,
	frame = A,
	tics = DURATION,
	nextstate = S_NULL
}

local function _startRingAnimation(mobj, tracer)
	S_StartSound(tracer, sfx_ring, tracer.player)
	S_StartSound(mobj, sfx_ring)
end

local function canSpawnColas()
	if poyo_cola.value > 0 and not multiplayer and consoleplayer and consoleplayer.mo and consoleplayer.mo.valid and consoleplayer.mo.skin == "poyo" then
		return true
	end

	return false
end

addHook("MapLoad", function()
	if not canSpawnColas() then return end

	for mobj in mobjs.iterate() do
		if not mobj.valid then continue end

		if mobj.type == MT_RING then
			local new = P_SpawnMobjFromMobj(mobj, 0,0,0, MT_POYO_COLA)
			new.flags = mobj.flags
			P_RemoveMobj(mobj)
		end
	end
end)

local function animationStarter(mobj, _, source)
	if not source then return end
	if not source.valid then return end
	if not mobj.valid then return end
	mobj.killer = source
	mobj.ox = mobj.x
	mobj.oy = mobj.y
	mobj.oz = mobj.z

	if source.player then
		P_GivePlayerRings(source.player, 1)
	end
end

local function bounceEase(t, start, upwards, finish)
	if t < FU / 2 then
		return ease.outcubic(t * 2, start, upwards)
	end

	return ease.incubic((t * 2) - FU, upwards, finish or start)
end

local function getT(tics, maxtics, delay)
	return FixedDiv(min(maxtics, max(0, tics - (delay or 0))), maxtics)
end

local function animationThinker(mobj)
	if not mobj.valid then return end
	if mobj.state ~= S_POYO_COLA_COLLECTION then return end

	if not mobj.killer or not mobj.killer.valid then
		P_RemoveMobj(mobj)
		return
	end

	local elapsed = (DURATION - mobj.tics) + 1

	local upwardsT = getT(elapsed, UPWARDS_TICS)
	local tracerT = getT(elapsed, COLLECTION_TICS, DURATION - COLLECTION_TICS)

	-- get momentum values....
	local x = ease.inquad(tracerT, mobj.ox, mobj.killer.x)
	local y = ease.inquad(tracerT, mobj.oy, mobj.killer.y)
	local z = ease.inquad(tracerT, bounceEase(upwardsT, mobj.oz, mobj.oz + UPWARDS_SPEED, mobj.oz), mobj.killer.z)

	P_MoveOrigin(mobj, x,y,z)

	-- TODO: properly attached to mobjremoved, lazy rn
	if mobj.tics == 1 then
		S_StartSoundAtVolume(mobj.killer, sfx_s3k81, 128)
	end
end

addHook("MobjDeath", animationStarter, MT_POYO_COLA)
addHook("MobjThinker", animationThinker, MT_POYO_COLA)

addHook("MobjDeath", animationStarter, MT_POYO_FLINGCOLA)
addHook("MobjThinker", animationThinker, MT_POYO_FLINGCOLA)