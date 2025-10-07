-- SERVICES
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURATION
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1417753703712297103/b8mWC2L_5jyhGXErl8_gsmV-U8Y8MYrh75dcgWtP3qLOVduaUQNJxWlBZOH7NFNdYlAY"
local GAME_ID = game.PlaceId
local MIN_VALUE = 10000000 -- 10m minimum value

local TARGET_BRAINROTS = {
    "Strawberry Elephant",
    "Ketupat Kepat",
    "Ketchuru and Musturu",
    "La Supreme Combinasion",
    "Tralaledon",
    "TicTac Sahur",
    "67",
    "Los Bros",
    "Spaghetti Tualetti",
    "Esok Sekolah",
    "Los Hotspotsitos",
    "Los Combinasionas",
    "Tacorita Bicicleta",
    "Pot Hotspot",
    "Los Nooo My Hotspotsitos",
    "La Grande Combinasion",
    "Dragon Cannelloni",
    "Chicleteira Bicicleteira",
    "La Extinct Grande",
    "Garama and Madundung",
    "Nuclearo Dinossauro"
}

local TARGET_SET = {}
for _, target in pairs(TARGET_BRAINROTS) do
    TARGET_SET[target] = true
end

for _, v in pairs(getconnections(LocalPlayer.Idled)) do
    v:Disable()
end

-- Keeps the character active
spawn(function()
    while true do
        wait(60)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- FILE STORAGE
local visitedServers = {}
local VISITED_SERVERS_FILE = "visited_servers.txt"

-- Load existing visited servers from file
local function loadVisitedServers()
    local success, data = pcall(function()
        return readfile(VISITED_SERVERS_FILE)
    end)
    
    if success and data then
        for serverId in string.gmatch(data, "([^,]+)") do
            visitedServers[serverId] = true
        end
        print("📁 Loaded " .. #visitedServers .. " visited servers from file")
    else
        print("📁 No visited servers file found, starting fresh")
    end
end

-- Save visited servers to file
local function saveVisitedServers()
    local serverList = {}
    for serverId, _ in pairs(visitedServers) do
        table.insert(serverList, serverId)
    end
    
    local success = pcall(function()
        writefile(VISITED_SERVERS_FILE, table.concat(serverList, ","))
    end)
    
    if success then
        print("💾 Saved " .. #serverList .. " visited servers to file")
    else
        print("❌ Failed to save visited servers")
    end
end

-- Add server to visited list
local function markServerVisited(serverId)
    visitedServers[serverId] = true
    saveVisitedServers()
end

local function isServerVisited(serverId)
    return visitedServers[serverId] == true
end

local function clearAllVisitedServers()
    visitedServers = {}
    saveVisitedServers()
    print("🧹 Cleared ALL visited servers")
end

loadVisitedServers()

markServerVisited(game.JobId)

local function parseValue(genText)
    if not genText or genText == "" then return 0 end
    
    local number, suffix = string.match(genText, "([%d%.]+)([MKmk]?)")
    if not number then return 0 end
    
    number = tonumber(number) or 0
    suffix = string.upper(suffix or "")
    
    if suffix == "M" then
        return number * 1000000
    elseif suffix == "K" then
        return number * 1000
    else
        return number
    end
end

local function findFreshServer()
    local success, result = pcall(function()
        local response = game:HttpGet("https://games.roblox.com/v1/games/" .. GAME_ID .. "/servers/Public?sortOrder=Asc&limit=100")
        return HttpService:JSONDecode(response)
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing and server.playing < 10 and not isServerVisited(server.id) then
                print("🎯 Found fresh server: " .. server.id .. " (" .. server.playing .. " players)")
                return server.id
            end
        end
    end
    return nil
end

local function teleportToServer(serverId)
    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, serverId, LocalPlayer)
    end)
    
    if success then
        print("✅ Successfully teleporting to server:", serverId)
        markServerVisited(serverId)
    else
        print("❌ Failed to teleport:", error)
    end
end

local function serverHop()
    local serverId = findFreshServer()
    if serverId then
        teleportToServer(serverId)
    else
        print("❌ No fresh servers found, clearing visited servers and trying again...")
        -- Clear all visited servers to prevent infinite loop
        clearAllVisitedServers()
        wait(1)
        -- Try to find a server again
        local newServerId = findFreshServer()
        if newServerId then
            teleportToServer(newServerId)
        else
            print("🔄 Still no servers, using random teleport...")
            TeleportService:Teleport(GAME_ID)
        end
    end
end

-- Get plot owner name from PlotSign
local function getPlotOwner(plot)

    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
        if surfaceGui then
            local frame = surfaceGui:FindFirstChild("Frame")
            if frame then
                local textLabel = frame:FindFirstChild("TextLabel")
                if textLabel and textLabel.Text and textLabel.Text ~= "" then
                    -- Remove "'s Base" or "'s" from the player name
                    local playerName = textLabel.Text
                    playerName = string.gsub(playerName, "'s%s*Base$", "")
                    playerName = string.gsub(playerName, "'s$", "")
                    return playerName
                end
            end
        end
    end
    

    local ownerValue = plot:FindFirstChild("Owner")
    if ownerValue then
        if ownerValue.ClassName == "StringValue" and ownerValue.Value ~= "" then
            return ownerValue.Value
        end
        if ownerValue.ClassName == "ObjectValue" and ownerValue.Value then
            local player = ownerValue.Value
            if player and player.Parent == Players then
                return player.DisplayName ~= "" and player.DisplayName or player.Name
            end
        end
    end
    
 
    local ownerName = plot:FindFirstChild("OwnerName")
    if ownerName and ownerName.ClassName == "StringValue" and ownerName.Value ~= "" then
        return ownerName.Value
    end
    
    return "Unknown Player"
end


local function ultraFastScan()
    local plots = game.Workspace.Plots:GetChildren()
    

    for _, plot in pairs(plots) do
        spawn(function()
            local animalPodiums = plot:FindFirstChild("AnimalPodiums")
            if not animalPodiums then return end
            
            for _, podium in pairs(animalPodiums:GetChildren()) do
                local overhead = podium:FindFirstChild("Base") and 
                               podium.Base:FindFirstChild("Spawn") and 
                               podium.Base.Spawn:FindFirstChild("Attachment") and 
                               podium.Base.Spawn.Attachment:FindFirstChild("AnimalOverhead")
                
                if overhead then
                    local displayName = overhead:FindFirstChild("DisplayName")
                    local generation = overhead:FindFirstChild("Generation")
                    
                    if displayName and generation then
                        local name = displayName.Text
                        local genText = generation.Text
                        

                        if TARGET_SET[name] then
                            local value = parseValue(genText)
                            

                            if value >= MIN_VALUE then
                                -- Get the plot owner's name
                                local ownerName = getPlotOwner(plot)
                                

                                spawn(function()
                                    sendWebhook(name, genText, value, ownerName)
                                end)
                                return {name = name, value = genText, numValue = value, owner = ownerName}
                            else
                                print("🚫 " .. name .. " found but value too low: " .. genText .. " (" .. value .. " < " .. MIN_VALUE .. ")")
                            end
                        end
                    end
                end
            end
        end)
    end
    
    return nil
end


function sendWebhook(name, value, numValue, ownerName)
    spawn(function()
        local data = {
            ["embeds"] = { {
                ["title"] = "**𝙎𝙐𝙋𝙍𝙀𝙈𝙀 𝙉𝙊𝙏𝙄𝙁𝙄𝙀𝙍**",
                ["color"] = 16711680,
                ["fields"] = {
                    {["name"] = "Name", ["value"] = "```\n" .. name .. "\n```", ["inline"] = true},
                    {["name"] = "Value", ["value"] = "```\n" .. value .. "\n```", ["inline"] = true},
                    {["name"] = "Job Id", ["value"] = "```\n" .. game.JobId .. "\n```", ["inline"] = false},
                    {["name"] = "Player", ["value"] = "```\n" .. ownerName .. "\n```", ["inline"] = true}
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        local success = pcall(function()
            request({
                Url = DISCORD_WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success then
            print("✅ Webhook sent: " .. name .. " | " .. value .. " | Owner: " .. ownerName)
        else
            print("❌ Webhook failed for: " .. name)
        end
    end)
end

-- Handle teleport failures
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    print("⚠️ Teleport failed, retrying...")
    wait(2)
    serverHop()
end)

-- 🧠 ULTRA FAST MAIN LOOP
print("🚀 Starting ULTRA FAST brainrot hunter...")
print("🎯 Targets: " .. table.concat(TARGET_BRAINROTS, ", "))
print("💰 Minimum value: " .. MIN_VALUE .. " (" .. MIN_VALUE/1000000 .. "M)")
print("📁 Visited servers tracking: ENABLED")

-- Wait minimal time for server to load critical components
wait(0.5)

print("⚡ ULTRA SCANNING...")

-- Instant scan
local found = ultraFastScan()

if found then
    print("🎉 HIGH VALUE TARGET FOUND: " .. found.name .. " | " .. found.value)
    print("📍 Server: " .. game.JobId)
    

    wait(0.1)
else
    print("❌ No high-value targets found")
end

-- Improved server hop
print("🚀 Hopping to next server...")
serverHop()
