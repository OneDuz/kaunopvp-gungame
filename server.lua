local ox_inventory = exports.ox_inventory
local joinedplayers = {}
local killCounts = {}
local weaponNames = {}
local playercount = 0
local positionIndex = 1
local totalGunsAdded = 0
local totalGunsFailed = 0
local forceendgame = false
local gamestarted = false
local gameisstarting = false
local gamewiningshow = false
local overrideadmin = false
local forcestartadmin = false
local gungameclosed = false
local playerwonvialastkill = false
local DEBUG = false

ESX = exports['es_extended']:getSharedObject()

-- does lib.print. even fucking work? the fuck is it used for lol
if Config.DEV then
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game [DEBUG]:', 'Dev mode is active currently' }
    })
end

function LoadWeaponNames()
    local startTime = os.clock()
    -- lib.print.debug("Loading ox_inventory/data/weapons.lua...")
    -- print("Loading ox_inventory/data/weapons.lua...")
    local weaponsFilePath = "data/weapons.lua"
    local weaponsFile = LoadResourceFile("ox_inventory", weaponsFilePath)
    if weaponsFile then
        local chunk = load(weaponsFile)
        if chunk then
            local success, weaponsData = pcall(chunk)
            if success and weaponsData and weaponsData.Weapons then
                for spawnCode, weaponData in pairs(weaponsData.Weapons) do
                    local displayName = weaponData.label
                    weaponNames[GetHashKey(spawnCode)] = displayName
                    totalGunsAdded = totalGunsAdded + 1
                end
                -- lib.print.debug("Loaded " .. totalGunsAdded .. " guns from weapons.lua.")
                -- print("Loaded " .. totalGunsAdded .. " guns from weapons.lua.")
            else
                -- lib.print.error("Error: Invalid weapons.lua format or missing 'Weapons' table.")
                -- print("Error: Invalid weapons.lua format or missing 'Weapons' table.")
                totalGunsFailed = totalGunsFailed + 1
            end
        else
            -- lib.print.error("Error: Failed to load weapons.lua.")
            -- print("Error: Failed to load weapons.lua.")
            totalGunsFailed = totalGunsFailed + 1
        end
    else
        -- lib.print.error("Error: Failed to read weapons.lua.")
        -- print("Error: Failed to read weapons.lua.")
        totalGunsFailed = totalGunsFailed + 1
    end
    -- lib.print.debug("Total guns added: " .. totalGunsAdded)
    -- lib.print.debug("Total guns failed to load: " .. totalGunsFailed)
    -- print("Total guns added: " .. totalGunsAdded)
    -- print("Total guns failed to load: " .. totalGunsFailed)
    local endTime = os.clock()
    local runtime = endTime - startTime
    -- lib.print.verbose("LoadWeaponNames function runtime: " .. runtime .. " seconds")
    -- print("LoadWeaponNames function runtime: " .. runtime .. " seconds")
end

function GetWeaponName(hash)
    return weaponNames[hash] or "Unknown Weapon"
end

lib.callback.register('one-codes:GunGame:GetOverride', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        return overrideadmin
    else
        return overrideadmin
    end
end)

lib.callback.register('one-codes:GunGame:GetOverride5', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        gungameclosed = not gungameclosed
        TriggerClientEvent("one-codes:GunGame:Admin", -1, gungameclosed)
    end
end)

lib.callback.register('one-codes:GunGame:GetOverride4', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        return gungameclosed
    else
        return gungameclosed
    end
end)

lib.callback.register('one-codes:GunGame:Override', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        startCountdown()
        return "Force start executed"
    else
        return "Force start denied due to insufficient perms"
    end
end)

lib.callback.register('one-codes:GunGame:ForceStart', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        forcestartadmin = true
        startCountdown()
        return "Force start executed"
    else
        return "Force start denied due to insufficient perms"
    end
end)

lib.callback.register('one-codes:GunGame:ForceEnd', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        forceendgame = true
        return "Force end executed"
    else
        return "Force end denied due to insufficient perms"
    end
end)

lib.callback.register('one-codes:GunGame:DEBUG:PrintJoined', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        DEBUG = not DEBUG
        CheckPlayers(DEBUG)
        return "[DEBUG] Print Joined Players executed"
    else
        return "[DEBUG] Print Joined Players denied due to insufficient perms"
    end
end)


lib.callback.register('one-codes:GunGame:GameStarted', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if gungameclosed then return true end
    if Config.DEV then
        if xPlayer.getGroup() == "user" then
            return "DEBUG"
        end
    else
        if not tonumber(playercount) < 14 then
            print(playercount)
            TriggerClientEvent('ox_lib:notify', source, { title = "The game is already full", type = 'info' })
            return true
        end
        return gamestarted
    end
end)

lib.callback.register('one-codes:GunGame:PlayerJoin', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    playercount = playercount + 1
    exports.ox_inventory:ConfiscateInventory(source)
    table.insert(joinedplayers, {playerid = source, playername = GetPlayerName(source)})
    TriggerClientEvent('one-codes:GunGame:JoinedGame', source)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game:', 'Player joined current player count:'..playercount..'/15' }
    })
    if not tonumber(playercount) < 14 then
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
            args = { 'Gun Game:', 'Game is full!' }
        })
    end
    --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Player joined current player count:'..playercount..'/'..Config.MinPlayers + 1)
    return "Player Joined", joinedplayers
end)

lib.callback.register('one-codes:GunGame:PlayerLeft', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    exports.ox_inventory:ReturnInventory(source)
    for i, player in ipairs(joinedplayers) do
        if player.playerid == source then
            table.remove(joinedplayers, i)
            break
        end
    end
    playercount = playercount - 1
    return "Player Left", joinedplayers
end)

lib.callback.register('one-codes:GunGame:GetNewSpawn', function(source)
    local totalPositions = #Config.SpawnPositions
    local positionIndex = math.random(1, totalPositions)
    local spawnPos = Config.SpawnPositions[positionIndex]
    return spawnPos
end)


-- CheckPlayers = function(state)
--     Citizen.CreateThread(function()
--         while state do
--             Citizen.Wait(5000)
--             print("joined player")
--             print(json.encode(joinedplayers))
--         end
--     end)
-- end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if gamewiningshow or overrideadmin or gamestarted then
            return
        end
        for _, player in ipairs(joinedplayers) do
            if player.playerid then
                print(playercount)
                if playercount <= Config.MinPlayers then
                    TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game will start when theres more then "..Config.MinPlayers.." players")
                else
                    Wait(3000)
                    if not gamestarted or not gameisstarting then
                        if not overrideadmin then
                            Startinggame()
                            TriggerClientEvent('chat:addMessage', -1, {
                                template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
                                args = { 'Gun Game:', 'Preparing to start with '..playercount..' players' }
                            })
                            --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game is preparing to start with '..playercount..' players')
                        end
                    end
                end
               -- TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "")
            end
        end
    end
end)

function Startinggame()
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game:', 'Preparing zones, spawns, guns...' }
    })
    
    --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Preparing zones, spawns, guns...')
    for _, player in ipairs(joinedplayers) do
        if player.playerid then
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 10 seconds")
            Wait(5000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 5 seconds")
            Wait(1000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 4 seconds")
            Wait(1000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 3 seconds")
            Wait(1000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 2 seconds")
            Wait(1000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Game is preparing to start in 1 seconds")
            Wait(1000)
            TriggerClientEvent('one-codes:GunGame:LobbyInfo', player.playerid, "Trying to start the game...")
            --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Trying to start the game...')
            TriggerClientEvent('chat:addMessage', -1, {
                template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
                args = { 'Gun Game:', 'Trying to start the game...' }
            })
            if not gamestarted or not gameisstarting then
                if not overrideadmin then
                    startCountdown()
                end
            end
        end
    end
end

startCountdown = function()
    local currentCountdown = Config.StartTimer
    while currentCountdown > 0 do
        -- print("Time remaining: " .. currentCountdown .. " seconds")
        for _, player in ipairs(joinedplayers) do
            if player.playerid then
                --TriggerClientEvent('one-codes:GunGame:GetTimer', player.playerid, "Time remaining: " .. currentCountdown .. " seconds")
                TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game starting in: " .. currentCountdown .. " seconds",type = 'info'})
            end
        end
        currentCountdown = currentCountdown - 1
        gameisstarting = true
        Citizen.Wait(1000)
    end

    -- print("Time's up!")
    gamestarted = false
    for _, player in ipairs(joinedplayers) do
        -- print(player.playerid)
        if player.playerid then
            
            if Config.MinPlayers >= playercount and not forcestartadmin then
                gamestarted = false
                TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game is canceled due to low player count",type = 'warning'})
                --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Game is canceled due to low player count')
                TriggerClientEvent('chat:addMessage', -1, {
                    template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
                    args = { 'Gun Game:', 'Game is canceled due to low player count' }
                })
                return
            end

            
            local spawnPos = Config.SpawnPositions[positionIndex]
            TriggerClientEvent('one-codes:GunGame:GameStarted', player.playerid, spawnPos)
            exports.ox_inventory:AddItem(player.playerid, "weapon_pistol", 1)
            exports.ox_inventory:AddItem(player.playerid, "ammo-9", 500)
            positionIndex = positionIndex + 1
            gamestarted = true
            forcestartadmin = false
            TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game is starting...",type = 'info'})
            --TriggerClientEvent('one-codes:GunGame:GetTimer', player.playerid, "Game is starting...")
        end
    end
    --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Game is started have fun')
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game:', 'Game is started have fun' }
    })
    startThreeMinuteCountdown()
end

startThreeMinuteCountdown = function()
    local currentCountdown = Config.GameTime

    while currentCountdown > 0 do
        if currentCountdown % 60 == 0 then
            local minutesLeft = currentCountdown / 60
            for _, player in ipairs(joinedplayers) do
                if player.playerid then
                    TriggerClientEvent('ox_lib:notify', player.playerid, {title = minutesLeft .. " minute(s) remaining", type = 'info'})
                end
            end
        end

        if currentCountdown == 30 or currentCountdown == 15 then
            for _, player in ipairs(joinedplayers) do
                if player.playerid then
                    TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Time remaining: " .. currentCountdown .. " seconds", type = 'info'})
                end
            end
        end

        if currentCountdown <= 15 then
            for _, player in ipairs(joinedplayers) do
                if player.playerid then
                    TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Time remaining: " .. currentCountdown .. " seconds", type = 'info'})
                end
            end
        end

        if forceendgame then
            TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Admin forced ended game", type = 'info'})
            currentCountdown = 5
            forceendgame = false
        end

        if playerwonvialastkill then
            currentCountdown = 0
        end

        currentCountdown = currentCountdown - 1
        Citizen.Wait(1000)
    end

    -- print("Time's up!")
    gamestarted = false
    positionIndex = 1
    --TriggerClientEvent('chat:addMessage', -1, '', { 255, 255, 255 }, '^2Gun Game: Game ended')
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game:', 'Game ended' }
    })
    WonGameLol()
    for _, player in ipairs(joinedplayers) do
        if player.playerid then
            exports.ox_inventory:ClearInventory(player.playerid)
            TriggerClientEvent('one-codes:GunGame:GameEnded', player.playerid)
            TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game is ending...", type = 'info'})
            --AnnounceWinners()
        end
    end
end

function WonGameLol()
    local sortedPlayers = {}
    for playerId, kills in pairs(killCounts) do
        table.insert(sortedPlayers, { playerId = playerId, kills = kills })
    end

    -- print("Sorted Players before sorting: ", json.encode(sortedPlayers)) -- Debug print

    table.sort(sortedPlayers, function(a, b) return a.kills > b.kills end)

    -- print("Sorted Players after sorting: ", json.encode(sortedPlayers)) -- Debug print

    local winners = { table.unpack(sortedPlayers, 1, 3) }

    -- print("Winners: ", json.encode(winners)) -- Debug print

    -- Prepare the chat message
    local message = '^2Gun Game winners are '
    for i, winner in ipairs(winners) do
        local playerName = GetPlayerName(winner.playerId)
        -- print("Winner " .. i .. ": ", playerName, winner.kills) -- Debug print

        local suffix = 'th' -- Default suffix
        if i == 1 then
            suffix = 'st'
        elseif i == 2 then
            suffix = 'nd'
        elseif i == 3 then
            suffix = 'rd'
        end

        if playerName then
            message = message .. tostring(i) .. suffix .. ": [" .. playerName .. "] KillCount: [" .. winner.kills .. "]"
            if i < #winners then
                message = message .. ", "
            else
                message = message .. "."  -- End with a period for the last entry
            end
        end
    end

    -- print("Final Message: ", message) -- Debug print
    --TriggerClientEvent('chat:addMessage', -1, '', {255, 255, 255}, message)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
        args = { 'Gun Game:', message }
    })
    killCounts = {}
end

function UpdateAndSendRankings()
    local sortedPlayers = {}
    for playerId, kills in pairs(killCounts) do
        -- Insert the player's Steam name alongside their kills
        table.insert(sortedPlayers, {playerId = playerId, playerName = GetPlayerName(playerId), kills = kills})
    end
    table.sort(sortedPlayers, function(a, b) return a.kills > b.kills end)
    
    for _, playerInfo in ipairs(joinedplayers) do
        local topThree = {}
        -- Prepare the top three with their Steam names for sending
        for i = 1, math.min(3, #sortedPlayers) do
            local pInfo = sortedPlayers[i]
            table.insert(topThree, {playerName = pInfo.playerName, kills = pInfo.kills})
        end

        local playerRank = nil
        local playerName = nil

        for rank, pInfo in ipairs(sortedPlayers) do
            if pInfo.playerId == playerInfo.playerid then
                playerRank = rank
                playerName = pInfo.playerName
                break
            end
        end

        TriggerClientEvent('one-codes:GunGame:UpdateRankings', playerInfo.playerid, topThree, playerRank, playerName)
    end
end

-- function AnnounceWinners()
--     local sortedPlayers = {}
--     for playerId, kills in pairs(killCounts) do
--         table.insert(sortedPlayers, { playerId = playerId, kills = kills })
--     end
--     table.sort(sortedPlayers, function(a, b) return a.kills > b.kills end)

--     local winners = { table.unpack(sortedPlayers, 1, 3) }

--     for _, joinedPlayer in ipairs(joinedplayers) do
--         local playerRank
--         for rank, pInfo in ipairs(sortedPlayers) do
--             if pInfo.playerId == joinedPlayer.playerid then
--                 playerRank = rank
--                 break
--             end
--         end
--         gamewiningshow = true
--         TriggerClientEvent('one-codes:GunGame:AnnounceWinners', joinedPlayer.playerid, winners, playerRank)
--         Wait(10000)
--         gamewiningshow = false
--     end
-- end

RegisterServerEvent('one-codes:GunGame:ReportKillToServer')
AddEventHandler('one-codes:GunGame:ReportKillToServer', function(killer, victim, weapon)
    -- print(killer)
    -- print(victim)
    -- print(GetWeaponName(weapon))
    if killer and victim then
        killCounts[killer] = (killCounts[killer] or 0) + 1
        local weaponRewards = {
            "weapon_compactrifle",
            "weapon_advancedrifle",
            "weapon_assaultsmg",
            "weapon_bullpuprifle",
            "weapon_combatshotgun",
            "weapon_m70",
            "weapon_m4",
            "weapon_precisionrifle",
            "weapon_specialcarbine",
            "weapon_carbinerifle",
            "weapon_assaultrifle",
            "weapon_ak47",
            "weapon_ar15",
            "weapon_dbshotgun",
            "weapon_appistol",
            "weapon_glock22",
            "weapon_pistolxm3",
            "weapon_heavypistol",
            "weapon_combatpistol",
            "none", -- Make sure this is the last weapon
        }
        local ammoAmount = 500
        local currentKillCount = killCounts[killer]
        local weaponIndex = currentKillCount <= #weaponRewards and currentKillCount or #weaponRewards
        exports.ox_inventory:ClearInventory(killer)

        if GetWeaponName(weapon) == "Combat Pistol" then
            local playerName = GetPlayerName(killer)
            -- print(playerName .. " has won the Gun Game!")

            TriggerClientEvent('chat:addMessage', -1, {
                template =
                '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 215, 0, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(255, 165, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-trophy"></i> <b>{0}</b> {1}</div>',
                args = { 'Gun Game:', playerName .. ' has won the game!' }
            })

            playerwonvialastkill = true
            local xPlayer = ESX.GetPlayerFromId(killer)
            if xPlayer then
                xPlayer.addAccountMoney('bank', 100000)
            end

            Wait(2000)
            playerwonvialastkill = false
            return
        end

        local nextWeapon = weaponRewards[weaponIndex]
        local nextWeaponNoti = weaponRewards[weaponIndex + 1]
        exports.ox_inventory:AddItem(killer, nextWeapon, 1)
        exports.ox_inventory:AddItem(killer, "ammo-9", ammoAmount)
        local displayWeaponName = nextWeaponNoti and string.gsub(nextWeaponNoti, "weapon_", "") or "none"
        TriggerClientEvent('one-codes:GunGame:KilledPlayer', killer, currentKillCount, displayWeaponName)
        -- print(string.format("%s has killed %s. Total kills: %s. Next weapon: %s", GetPlayerName(killer),GetPlayerName(victim), currentKillCount, displayWeaponName))
        UpdateAndSendRankings()
    end
end)


RegisterNetEvent('esx:playerDropped', function(playerId)
    killCounts[playerId] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    for _, player in ipairs(joinedplayers) do
        if player.playerid then
            exports.ox_inventory:ClearInventory(player.playerid)
            exports.ox_inventory:ReturnInventory(player.playerid)
            TriggerClientEvent('one-codes:GunGame:GameEnded', player.playerid)
            TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game is ending...", type = 'info'})
            --AnnounceWinners()
        end
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadWeaponNames()
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(45000)
            -- print("15 seconds before restart... saving all players!")
            for _, player in ipairs(joinedplayers) do
                if player.playerid then
                    exports.ox_inventory:ClearInventory(player.playerid)
                    exports.ox_inventory:ReturnInventory(player.playerid)
                    TriggerClientEvent('one-codes:GunGame:GameEnded', player.playerid)
                    TriggerClientEvent('ox_lib:notify', player.playerid, {title = "Game is ending...", type = 'info'})
                    --AnnounceWinners()
                    TriggerClientEvent('chat:addMessage', -1, {
                        template =
                        '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 123, 255, 0.6); color: white; border-radius: 5px; border-left: 4px solid rgba(0, 255, 0, 0.8); box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);"><i class="fas fa-gamepad"></i> <b>{0}</b> {1}</div>',
                        args = { 'Gun Game:', 'Game ended due to server restarting in 15 seconds' }
                    })
                end
            end
        end)
    end
end)

RegisterNetEvent('esx:playerDropped', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    exports.ox_inventory:ReturnInventory(playerId)
    for i, player in ipairs(joinedplayers) do
        if player.playerid == playerId then
            table.remove(joinedplayers, i)
            playercount = playercount - 1
            break
        end
    end
end)