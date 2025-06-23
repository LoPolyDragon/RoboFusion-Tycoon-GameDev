-- ServerModules/ErrorHub.lua
local ServerStorage = game:GetService("ServerStorage")
local HttpService   = game:GetService("HttpService")

local folder = ServerStorage:FindFirstChild("ErrorLogs") or Instance.new("Folder")
folder.Name  = "ErrorLogs"; folder.Parent = ServerStorage

local ErrorHub = {}

function ErrorHub:Log(level, msg)
	local stamp = os.date("[%Y-%m-%d %H:%M:%S] ")
	warn(stamp..level..": "..msg)      -- 控制台

	-- 追加到当天 txt
	local fileName = os.date("%Y%m%d")..".txt"
	local file     = folder:FindFirstChild(fileName) or Instance.new("StringValue")
	file.Name, file.Parent = fileName, folder
	file.Value = file.Value..stamp..level..": "..msg.."\n"
end

function ErrorHub:Warn(msg)  self:Log("Warn", msg)  end
function ErrorHub:Crit(msg)  self:Log("Critical", msg) end

return ErrorHub