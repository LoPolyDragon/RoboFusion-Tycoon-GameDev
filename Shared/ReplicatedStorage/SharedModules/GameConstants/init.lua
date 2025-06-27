local PlaceIds = {
	MAIN = 82341741981647, -- 请替换成主城 PlaceId
	MINE = 101306428432235, -- 替换成矿场 PlaceId
}

if game.PlaceId == PlaceIds.MAIN then
	return require(script.Parent.main)
elseif game.PlaceId == PlaceIds.MINE then
	return require(script.Parent.mine)
else
	warn("[GameConstants] Unknown place, default to main")
	return require(script.Parent.main)
end
