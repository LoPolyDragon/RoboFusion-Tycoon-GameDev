local Cmd = {}
local Admins = {12345678}   -- 你的 Roblox UserId

local function isAdmin(plr)
	for _,id in ipairs(Admins) do if plr.UserId==id then return true end end
end

game.Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		if not isAdmin(plr) then return end
		if msg == "/log" then
			local ok,log = pcall(function()
				return game:GetService("DataStoreService")
					:GetDataStore("RF_ErrorHub"):GetAsync("Log")
			end)
			if ok and log then
				print("=== Last Logs ==="); for _,l in ipairs(log) do print(l) end
			end
		elseif msg == "/profile" then
			local ProfileStore = require(game.ServerScriptService.ServerModules.ProfileStore)
			print(ProfileStore.Get(plr.UserId))
		end
	end)
end)