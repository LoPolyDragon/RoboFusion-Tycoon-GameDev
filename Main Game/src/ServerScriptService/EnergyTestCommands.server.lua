--------------------------------------------------------------------
-- EnergyTestCommands.server.lua · 能量系统测试命令
-- 功能：为管理员提供测试能量系统的聊天命令
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ServerModules = script.Parent:WaitForChild("ServerModules")
local EnergyManager = require(ServerModules.EnergyManager)

-- 管理员用户ID列表
local ADMIN_IDS = {5383359631} -- 替换为你的Roblox用户ID

-- 检查是否为管理员
local function isAdmin(player)
    for _, id in ipairs(ADMIN_IDS) do
        if player.UserId == id then
            return true
        end
    end
    return false
end

-- 处理聊天命令
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if not isAdmin(player) then return end
        
        local args = string.split(message, " ")
        local command = args[1]:lower()
        
        if command == "/energyinfo" then
            -- 显示能量系统信息
            local robotStatus = EnergyManager.GetAllRobotStatus()
            local stationStatus = EnergyManager.GetAllStationStatus()
            
            print("=== 能量系统状态 ===")
            print(("机器人数量: %d"):format(#robotStatus))
            
            for _, robot in ipairs(robotStatus) do
                print(("  %s: %d%% (%s, %s)"):format(
                    robot.name, robot.percentage, robot.robotType,
                    robot.isWorking and "工作中" or "待机"
                ))
            end
            
            print(("能量站数量: %d"):format(#stationStatus))
            for _, station in ipairs(stationStatus) do
                print(("  %s: 等级%d (范围%d, 覆盖%d个机器人)"):format(
                    station.name, station.level, station.range, station.robotsInRange
                ))
            end
            
        elseif command == "/scanworkspace" then
            -- 扫描workspace中所有模型
            print("=== Workspace模型扫描 ===")
            local robotCount = 0
            local totalModels = 0
            
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Model") then
                    totalModels = totalModels + 1
                    local hasType = obj:GetAttribute("Type")
                    local hasRobotType = obj:GetAttribute("RobotType") 
                    local hasOwner = obj:GetAttribute("Owner")
                    local nameCheck = obj.Name:lower():find("robot") or obj.Name:lower():find("bot") or obj.Name:lower():find("机器人")
                    
                    -- 显示所有模型的详细信息
                    print(("  模型: %s"):format(obj.Name))
                    print(("    Type属性: %s"):format(tostring(hasType)))
                    print(("    RobotType属性: %s"):format(tostring(hasRobotType)))
                    print(("    Owner属性: %s"):format(tostring(hasOwner)))
                    print(("    名称匹配: %s"):format(tostring(nameCheck)))
                    print(("    有PrimaryPart: %s"):format(tostring(obj.PrimaryPart ~= nil)))
                    
                    -- 显示所有属性
                    local attributes = obj:GetAttributes()
                    if next(attributes) then
                        print("    所有属性:")
                        for key, value in pairs(attributes) do
                            print(("      %s = %s"):format(key, tostring(value)))
                        end
                    else
                        print("    无属性")
                    end
                    print("    ---")
                    
                    if hasType == "Robot" or hasRobotType or hasOwner or nameCheck then
                        robotCount = robotCount + 1
                    end
                end
            end
            
            print(("总计模型: %d, 识别为机器人: %d"):format(totalModels, robotCount))
            
        elseif command == "/chargeall" then
            -- 充满所有机器人能量
            EnergyManager.ChargeAllRobots()
            print("[Admin] 已充满所有机器人能量")
            
        elseif command == "/createrobot" and args[2] then
            -- 创建测试机器人
            local robotType = args[2]:upper()
            local validTypes = {"MN", "TR", "SM", "SC", "BT"}
            
            if not table.find(validTypes, robotType) then
                print("[Admin] 无效的机器人类型，可用类型: MN, TR, SM, SC, BT")
                return
            end
            
            local robot = Instance.new("Model")
            robot.Name = "TestRobot_" .. robotType
            robot:SetAttribute("Type", "Robot")
            robot:SetAttribute("RobotType", robotType)
            robot:SetAttribute("Owner", player.UserId)
            
            local part = Instance.new("Part")
            part.Name = "PrimaryPart"
            part.Size = Vector3.new(4, 4, 4)
            part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(5, 0, 0)
            part.BrickColor = BrickColor.new("Bright blue")
            part.Parent = robot
            
            robot.PrimaryPart = part
            robot.Parent = workspace
            
            print(("[Admin] 创建测试机器人: %s 类型: %s"):format(robot.Name, robotType))
            
        elseif command == "/createstation" and args[2] then
            -- 创建测试能量站
            local level = tonumber(args[2])
            if not level or level < 1 or level > 5 then
                print("[Admin] 无效的能量站等级，范围: 1-5")
                return
            end
            
            -- 尝试从ServerStorage查找EnergyMachine模型
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local energyMachine = machineModel and machineModel:FindFirstChild("EnergyMachine")
            
            local station
            if energyMachine then
                -- 如果找到模型，克隆它
                station = energyMachine:Clone()
                station.Name = "EnergyStation_L" .. level
                station:SetAttribute("Type", "EnergyStation")
                station:SetAttribute("Level", level)
                station.Parent = workspace
                print(("[Admin] 从模型创建能量站: %s 等级: %d"):format(station.Name, level))
            else
                -- 如果没有找到模型，创建简单的测试版本
                station = Instance.new("Model")
                station.Name = "TestEnergyStation_L" .. level
                station:SetAttribute("Type", "EnergyStation")
                station:SetAttribute("Level", level)
                
                local part = Instance.new("Part")
                part.Name = "PrimaryPart"
                part.Size = Vector3.new(8, 8, 8)
                part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(-10, 0, 0)
                part.BrickColor = BrickColor.new("Bright green")
                part.Parent = station
                
                station.PrimaryPart = part
                station.Parent = workspace
                
                print(("[Admin] 创建测试能量站: %s 等级: %d (未找到EnergyMachine模型)"):format(station.Name, level))
            end
            
        elseif command == "/drainrobot" and args[2] then
            -- 消耗指定机器人的能量
            local robotName = args[2]
            local robot = workspace:FindFirstChild(robotName)
            
            if robot and robot:GetAttribute("Type") == "Robot" then
                EnergyManager.ConsumeRobotEnergy(robot, 30) -- 消耗30点能量
                print(("[Admin] 已消耗机器人 %s 的30点能量"):format(robotName))
            else
                print("[Admin] 未找到指定的机器人")
            end
            
        elseif command == "/chargerobot" and args[2] then
            -- 为指定机器人充满电
            local robotName = args[2]
            local robot = workspace:FindFirstChild(robotName)
            
            if robot and robot:GetAttribute("Type") == "Robot" then
                EnergyManager.ChargeRobot(robot, 60) -- 充满电
                print(("[Admin] 已为机器人 %s 充满电"):format(robotName))
            else
                print("[Admin] 未找到指定的机器人")
            end
            
        elseif command == "/activaterobot" and args[2] then
            -- 激活机器人开始工作
            local robotName = args[2]
            local robot = workspace:FindFirstChild(robotName)
            
            if robot and robot:GetAttribute("Type") == "Robot" then
                EnergyManager.SetRobotWorking(robot, true)
                print(("[Admin] 已激活机器人 %s 开始工作"):format(robotName))
            else
                print("[Admin] 未找到指定的机器人")
            end
            
        elseif command == "/monitor" then
            -- 实时监控能量变化
            local duration = tonumber(args[2]) or 30
            print(("[Admin] 开始监控能量变化，持续 %d 秒"):format(duration))
            
            task.spawn(function()
                local startTime = tick()
                while tick() - startTime < duration do
                    local robotStatus = EnergyManager.GetAllRobotStatus()
                    
                    print("--- 能量监控 ---")
                    for _, robot in ipairs(robotStatus) do
                        print(("  %s: %d%% (%.1f/%.1f) %s"):format(
                            robot.name, robot.percentage, robot.energy, robot.maxEnergy,
                            robot.isWorking and "[工作中]" or "[待机]"
                        ))
                    end
                    
                    task.wait(2)
                end
                
                print("[Admin] 能量监控结束")
            end)
            
        elseif command == "/generatestation" and args[2] then
            -- 生成真实的能量站（使用ServerStorage中的模型）
            local level = tonumber(args[2])
            if not level or level < 1 or level > 5 then
                print("[Admin] 无效的能量站等级，范围: 1-5")
                return
            end
            
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local energyMachine = machineModel and machineModel:FindFirstChild("EnergyMachine")
            
            if not energyMachine then
                print("[Admin] 错误：ServerStorage.MachineModel.EnergyMachine 不存在")
                print("[Admin] 请确保你的EnergyMachine模型在正确位置")
                return
            end
            
            -- 克隆模型
            local station = energyMachine:Clone()
            station.Name = "EnergyStation_L" .. level
            station:SetAttribute("Type", "EnergyStation")
            station:SetAttribute("Level", level)
            
            -- 如果有PrimaryPart，设置位置
            if station.PrimaryPart then
                station:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame + Vector3.new(-15, 0, 0))
            end
            
            station.Parent = workspace
            print(("[Admin] 生成能量站: %s 等级: %d"):format(station.Name, level))
            
        elseif command == "/createcrusher" then
            -- 创建Crusher机器
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local crusherModel = machineModel and machineModel:FindFirstChild("Crusher")
            
            local crusher
            if crusherModel then
                -- 如果找到模型，克隆它
                crusher = crusherModel:Clone()
                crusher.Name = "Crusher"
                crusher.Parent = workspace
                print(("[Admin] 从模型创建Crusher: %s"):format(crusher.Name))
            else
                -- 如果没有找到模型，创建简单的测试版本
                crusher = Instance.new("Model")
                crusher.Name = "TestCrusher"
                
                local part = Instance.new("Part")
                part.Name = "PrimaryPart"
                part.Size = Vector3.new(6, 6, 6)
                part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(8, 0, 0)
                part.BrickColor = BrickColor.new("Dark stone grey")
                part.Parent = crusher
                
                crusher.PrimaryPart = part
                crusher.Parent = workspace
                
                print(("[Admin] 创建测试Crusher: %s (未找到Crusher模型)"):format(crusher.Name))
            end
            
        elseif command == "/createshipper" then
            -- 创建Shipper机器
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local shipperModel = machineModel and machineModel:FindFirstChild("Shipper")
            
            local shipper
            if shipperModel then
                -- 如果找到模型，克隆它
                shipper = shipperModel:Clone()
                shipper.Name = "Shipper"
                shipper.Parent = workspace
                print(("[Admin] 从模型创建Shipper: %s"):format(shipper.Name))
            else
                -- 如果没有找到模型，创建简单的测试版本
                shipper = Instance.new("Model")
                shipper.Name = "TestShipper"
                
                local part = Instance.new("Part")
                part.Name = "PrimaryPart"
                part.Size = Vector3.new(6, 6, 6)
                part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(-8, 0, 0)
                part.BrickColor = BrickColor.new("Bright blue")
                part.Parent = shipper
                
                shipper.PrimaryPart = part
                shipper.Parent = workspace
                
                print(("[Admin] 创建测试Shipper: %s (未找到Shipper模型)"):format(shipper.Name))
            end
            
        elseif command == "/creategenerator" then
            -- 创建Generator机器
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local generatorModel = machineModel and machineModel:FindFirstChild("Generator")
            
            local generator
            if generatorModel then
                -- 如果找到模型，克隆它
                generator = generatorModel:Clone()
                generator.Name = "Generator"
                generator.Parent = workspace
                print(("[Admin] 从模型创建Generator: %s"):format(generator.Name))
            else
                -- 如果没有找到模型，创建简单的测试版本
                generator = Instance.new("Model")
                generator.Name = "TestGenerator"
                
                local part = Instance.new("Part")
                part.Name = "PrimaryPart"
                part.Size = Vector3.new(6, 6, 6)
                part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 0, 8)
                part.BrickColor = BrickColor.new("Bright yellow")
                part.Parent = generator
                
                generator.PrimaryPart = part
                generator.Parent = workspace
                
                print(("[Admin] 创建测试Generator: %s (未找到Generator模型)"):format(generator.Name))
            end
            
        elseif command == "/createassembler" then
            -- 创建Assembler机器
            local serverStorage = game:GetService("ServerStorage")
            local machineModel = serverStorage:FindFirstChild("MachineModel")
            local assemblerModel = machineModel and machineModel:FindFirstChild("Assembler")
            
            local assembler
            if assemblerModel then
                -- 如果找到模型，克隆它
                assembler = assemblerModel:Clone()
                assembler.Name = "Assembler"
                assembler.Parent = workspace
                print(("[Admin] 从模型创建Assembler: %s"):format(assembler.Name))
            else
                -- 如果没有找到模型，创建简单的测试版本
                assembler = Instance.new("Model")
                assembler.Name = "TestAssembler"
                
                local part = Instance.new("Part")
                part.Name = "PrimaryPart"
                part.Size = Vector3.new(6, 6, 6)
                part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 0, -8)
                part.BrickColor = BrickColor.new("Bright orange")
                part.Parent = assembler
                
                assembler.PrimaryPart = part
                assembler.Parent = workspace
                
                print(("[Admin] 创建测试Assembler: %s (未找到Assembler模型)"):format(assembler.Name))
            end
            
        elseif command == "/help" then
            -- 显示帮助信息
            print("=== 能量系统管理员命令 ===")
            print("/energyinfo - 查看能量系统信息")
            print("/scanworkspace - 扫描workspace中的所有机器人模型")
            print("/chargeall - 充满所有机器人能量")
            print("/createrobot [类型] - 创建测试机器人 (MN/TR/SM/SC/BT)")
            print("/createstation [等级] - 创建测试能量站 (1-5)")
            print("/generatestation [等级] - 从ServerStorage生成真实能量站 (1-5)")
            print("/createcrusher - 创建Crusher机器")
            print("/createshipper - 创建Shipper机器")
            print("/creategenerator - 创建Generator机器")
            print("/createassembler - 创建Assembler机器")
            print("/drainrobot [名称] - 消耗机器人能量")
            print("/chargerobot [名称] - 为机器人充满电")
            print("/activaterobot [名称] - 激活机器人开始工作")
            print("/monitor [秒数] - 实时监控能量变化 (默认30秒)")
        end
    end)
end)

print("[EnergyTestCommands] 能量系统测试命令已加载")
print("管理员命令: /help 查看所有可用命令")