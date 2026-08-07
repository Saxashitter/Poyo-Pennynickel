function PoyoPennynickel.AfterimageEffect(mo)
	local ghost = P_SpawnGhostMobj(mo)

	ghost.colorized = true
	ghost.color = SKINCOLOR_RED
	ghost.frame = $|FF_ADD
	ghost.destscale = FU * 5
	ghost.dispoffset = -1
end