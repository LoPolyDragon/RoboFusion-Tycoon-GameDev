local PLACE_MAIN = 82341741981647 -- 改成你的主城 placeId
local PLACE_MINE = 101306428432235 -- 改成你的 Mine placeId

local pid = game.PlaceId

if pid == PLACE_MINE then
	return require(script.mine) -- ⚠️ 拼写：mine.lua → 实例名 “mine”
else
	return require(script.main) -- main.lua → 实例名 “main”
end
