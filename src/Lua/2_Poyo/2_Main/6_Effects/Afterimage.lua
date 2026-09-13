function PoyoPennynickel.AfterimageEffect(mo)
	local ghost = P_SpawnGhostMobj(mo)

	ghost.colorized = true
	ghost.color = SKINCOLOR_RED
	ghost.frame = $|FF_ADD
	ghost.destscale = FU * 5
	ghost.dispoffset = -1

	if mo and mo.player and mo.player.poyo_secondcolor then
		ghost.color = mo.player.poyo_secondcolor
	end
end