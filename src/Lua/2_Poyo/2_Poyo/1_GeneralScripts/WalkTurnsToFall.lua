PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	if P_IsObjectOnGround(player.mo) then return end
	if player.powers[pw_carry] then return end
	if MM and MM:isMM() then return end

	if player.mo.state == S_PLAY_STND or player.mo.state == S_PLAY_WALK or player.mo.state == S_PLAY_RUN then
		player.mo.state = S_PLAY_FALL
	end
end)