--[[
distance	6.9817490577698
coords	vec3(2953.688721, 2791.358887, 38.000000)
onExit	function: 000001C0EB8593B0
size	vec3(30.000000, 30.000000, 20.000000)
onEnter	function: 000001C0EB859380
__type	box
remove	function: 000001C0EB83ED40
inside	function: 000001C0EB8663E0
thickness	40.0
polygon	Polygon<4>
id	1
debugColour	table: 000001C0EBAB0180
triangles	table: 000001C0EBAB0200
debug	function: 000001C0EB83BD40
insideZone	true
contains	function: 000001C0EBA70FB0
setDebug	function: 000001C0EB8E0BC0
rotation	quat(0.923880, {0.000000, 0.000000, 0.382683})
entered zone	1
entered zone	box

]]
ESX = exports['es_extended']:getSharedObject()
local inzone, zoneid, zonecoords, zonetype, isDead, cantleavebox, positionSave
local currentRankings = nil
local playerRank = nil
local allowlobbytoleave = false
local joined = false
local gamestarted = false
local currentgun = 1
local gungameclosed = false
local localpoints = {}
-- get from config the points and insert to table and use that shit lol
for _, v in pairs(Config.points) do
    table.insert(localpoints, v)
end

function onEnter(self)
    if gungameclosed then return end
    print('entered zone', self.id)
    print('entered zone', self.__type)
    zoneid = self.id
    zonetype = self.__type
    zonecoords = self.coords
    if not joined then
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoordsNoOffset(PlayerPedId(), -828.5420, -1217.6462, 6.9341, false, false, false)
        NetworkResurrectLocalPlayer(-828.5420, -1217.6462, 6.9341, 0, true, false)
        Wait(500)
        DoScreenFadeIn(500)
        Wait(1000)
        lib.notify({title = "You must join to enter this area.", type = 'warning'})
    end
end

function inside(self)
    if gungameclosed then return end
    if self.__type == "box" then
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)
        DisablePlayerFiring(PlayerId(), true)
    end
    if self.__type == "box" or (self.__type == "poly" and joined) then
        if IsPedSittingInAnyVehicle(cache.ped) then
            ExecuteCommand("dv")
        end
    end
    if not joined then
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoordsNoOffset(PlayerPedId(), -828.5420, -1217.6462, 6.9341, false, false, false)
        NetworkResurrectLocalPlayer(-828.5420, -1217.6462, 6.9341, 0, true, false)
        Wait(500)
        DoScreenFadeIn(500)
        Wait(1000)
        lib.notify({title = "You must join to be here.", type = 'warning'})
    end
end

function onExit(self)
    if gungameclosed then return end
    if joined and not gamestarted then
        if self.__type == "box" or (self.__type == "poly" and gamestarted) then
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoordsNoOffset(PlayerPedId(), zonecoords.x, zonecoords.y, zonecoords.z + 5, false, false, false)
            NetworkResurrectLocalPlayer(zonecoords.x, zonecoords.y, zonecoords.z + 5, 0, true, false)
            Wait(500)
            DoScreenFadeIn(500)
            Wait(1000)
            lib.notify({title = "You cannot leave the zone right now.", type = 'warning'})
        end
    elseif joined and gamestarted and self.__type == "poly" then
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoordsNoOffset(PlayerPedId(), positionSave.x, positionSave.y, positionSave.z, false, false, false)
        NetworkResurrectLocalPlayer(positionSave.x, positionSave.y, positionSave.z, 0, true, false)
        Wait(500)
        DoScreenFadeIn(500)
        Wait(1000)
        lib.notify({title = "You cant run away use /gungame and leave match that way", type = 'warning'})
    end
    print('exited zone', self.id)
    zoneid = nil
end

local box = lib.zones.box({
    coords = vec3(2953.6887, 2791.3589, 38.0),
    size = vec3(60, 60, 40),
    rotation = 45,
    debug = false,
    inside = inside,
    onEnter = onEnter,
    onExit = onExit
})

local poly = lib.zones.poly({
    points = localpoints,
    thickness = 90.0,
    debug = false,
    inside = inside,
    onEnter = onEnter,
    onExit = onExit
})

RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true
    local killer = data.killerServerId
    local victim = GetPlayerServerId(PlayerId())
    local deathCause = data.deathCause

    if gamestarted and joined then
        print(killer)
        print(victim)
        print("Death cause: ", deathCause)
        TriggerServerEvent("one-codes:GunGame:ReportKillToServer", killer, victim, deathCause)
        print("onPlayerDeath killer " .. tostring(killer) .. " victim " .. tostring(victim) .. " deathCause " .. deathCause)
    end
    if isDead and joined and not gamestarted then
        print("1")
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoordsNoOffset(PlayerPedId(), 2953.688721, 2791.358887, 38.000000 + 5, false, false, false)
        NetworkResurrectLocalPlayer(2953.688721, 2791.358887, 38.000000 + 5, 0, true, false)
        TriggerEvent("esx_ambulancejob:revive")
        Wait(500)
        DoScreenFadeIn(500)
        Wait(1000)
    elseif isDead and joined and gamestarted then
        print("2")
        DoScreenFadeOut(500)
        Wait(500)
        lib.callback('one-codes:GunGame:GetNewSpawn', false, function(pos)
            TriggerEvent("esx_ambulancejob:revive")
            Wait(100)
            SetEntityCoordsNoOffset(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false)
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, 0, true, false)
            Wait(500)
            SetEntityCoordsNoOffset(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false)
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, 0, true, false)
        end)
        Wait(500)
        DoScreenFadeIn(500)
        Wait(1000)
    end
end)

-- RegisterNetEvent('one-codes:GunGame:StartingGame')
-- AddEventHandler('one-codes:GunGame:StartingGame', function(message)
--     lib.notify({title = message,type = 'info'})
-- end)

AddEventHandler('esx:onPlayerSpawn', function()
	isDead = false
end)

RegisterNetEvent('one-codes:GunGame:GameStarted')
AddEventHandler('one-codes:GunGame:GameStarted', function(position)
    lib.showTextUI('Next Gun -> combat pistol', {position = "top-center",icon = 'gun',})
    allowlobbytoleave = true
    positionSave = position
    cantleavebox = false
    gamestarted = true
    DoScreenFadeOut(1500)
    Wait(1500)
    if not position or not positionSave then
        print("Something has failed weird?")
        lib.notify({
            title = '[DEV] ERROR',
            description = 'Something has failed inside the script please report it to discord and send screenshot of f8 with the error',
            type = 'warning'
        })
        position = vector3(3480.2896, 3718.3943, 46.2135)
        positionSave = vector3(3480.2896, 3718.3943, 46.2135)
    end
    SetEntityCoordsNoOffset(PlayerPedId(), positionSave.x, positionSave.y, positionSave.z, false, false, false)
    NetworkResurrectLocalPlayer(positionSave.x, positionSave.y, positionSave.z, 0, true, false)
    Wait(1500)
    DoScreenFadeIn(1500)
end)

RegisterNetEvent('one-codes:GunGame:GameEnded')
AddEventHandler('one-codes:GunGame:GameEnded', function()
    currentRankings = nil
    playerRank = nil
    allowlobbytoleave = false
    cantleavebox = true
    gamestarted = false
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoordsNoOffset(PlayerPedId(), 2953.688721, 2791.358887, 38.000000 + 5, false, false, false)
    NetworkResurrectLocalPlayer(2953.688721, 2791.358887, 38.000000 + 5, 0, true, false)
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
    SetEntityCoordsNoOffset(PlayerPedId(), 2953.688721, 2791.358887, 38.000000 + 5, false, false, false)
    NetworkResurrectLocalPlayer(2953.688721, 2791.358887, 38.000000 + 5, 0, true, false)

    local player = source
    local playerPed = GetPlayerPed(player)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vec3(2953.688721, 2791.358887, 38.000000))
    
    Wait(500)
    
    -- if not distance < 20.0 then 
        --lib.notify({title = "FALSE SAFE ACTIVATED", type = 'warning'})
        SetEntityCoordsNoOffset(PlayerPedId(), 2953.688721, 2791.358887, 38.000000 + 5, false, false, false)
        NetworkResurrectLocalPlayer(2953.688721, 2791.358887, 38.000000 + 5, 0, true, false)
    -- end
    
    Wait(500)
    DoScreenFadeIn(500)
    lib.hideTextUI()
end)

RegisterNetEvent('one-codes:GunGame:JoinedGame')
AddEventHandler('one-codes:GunGame:JoinedGame', function()
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoordsNoOffset(PlayerPedId(), 2953.688721, 2791.358887, 38.000000 + 5, false, false, false)
    NetworkResurrectLocalPlayer(2953.688721, 2791.358887, 38.000000 + 5, 0, true, false)
    Wait(500)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('one-codes:GunGame:LobbyInfo')
AddEventHandler('one-codes:GunGame:LobbyInfo', function(msg)
    lib.showTextUI(msg, {position = "top-center",icon = 'gun',})
end)

RegisterNetEvent('one-codes:GunGame:KilledPlayer')
AddEventHandler('one-codes:GunGame:KilledPlayer', function(killCounts, nextgun)
    if gamestarted and joined then
        Wait(300)
        exports.ox_inventory:useSlot(1)
        Wait(300)
        exports.ox_inventory:useSlot(1)
        Wait(300)
        local currentgun = GetSelectedPedWeapon(cache.ped)
        SetPedAmmo(cache.ped, currentgun, 100)
        lib.showTextUI('Next Gun -> '..nextgun..'', {position = "top-center",icon = 'gun',})
    end
end)


RegisterNetEvent('one-codes:GunGame:UpdateRankings')
AddEventHandler('one-codes:GunGame:UpdateRankings', function(topThree, rank)
    print("got data to update leaderboard")
    print("topThree", json.encode(topThree))
    print("playerRank", playerRank)
    currentRankings = topThree
    playerRank = rank
end)

RegisterNetEvent('one-codes:GunGame:AnnounceWinners')
AddEventHandler('one-codes:GunGame:AnnounceWinners', function(winners, playerRank)
    print(json.encode(winners))
    print(playerRank)
end)

RegisterNetEvent('one-codes:GunGame:Admin')
AddEventHandler('one-codes:GunGame:Admin', function(status)
    gungameclosed = status
end)

-- RegisterNetEvent('one-codes:GunGame:AnnounceWinners')
-- AddEventHandler('one-codes:GunGame:AnnounceWinners', function(winners, playerRank)

--     print("announce winners")
--     -- Position for the winners; replace '...' with actual coordinates
--     local podiumPositions = {
--         [1] = {x = 2910.8774, y = 2751.5881, z = 63.2953, heading = 311.5768},
--         [2] = {x = 2912.4333, y = 2750.4731, z = 63.4421, heading = 307.4737},
--         [3] = {x = 2912.6453, y = 2748.2988, z = 63.4249, heading = 309.6521},
--     }

--     -- Camera setup; replace '...' with actual camera coordinates and focus point
--     local camX, camY, camZ = 2924.01, 2757.98, 65.31  -- Example camera coordinates
--     local focusX, focusY, focusZ = 2915.81, 2752.30, 64.57  -- Central point of your podium
--     local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
--     SetCamCoord(cam, camX, camY, camZ)
--     PointCamAtCoord(cam, focusX, focusY, focusZ)
--     RenderScriptCams(true, false, 3000, true, false)

--     local createdPeds = {}  -- Keep track of created peds for later cleanup

--     for index, winner in ipairs(winners) do
--         -- Create and position peds for each winner
--         local model = GetHashKey("mp_m_freemode_01")  -- Example model; replace as necessary
--         RequestModel(model)
--         while not HasModelLoaded(model) do
--             Wait(1)
--         end
--         local ped = CreatePed(4, model, podiumPositions[index].x, podiumPositions[index].y, podiumPositions[index].z, podiumPositions[index].heading, false, true)
--         table.insert(createdPeds, ped)  -- Add to the list for cleanup
--         SetEntityInvincible(ped, true)  -- Optional: Make invincible if desired
--         FreezeEntityPosition(ped, true) -- Optional: Freeze to prevent falling due to physics
--         TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CHEERING", 0, true)

--         -- If this winner is the player, you might want to do something special
--         if winner.playerId == GetPlayerServerId(PlayerId()) then
--             -- Special action for the player
--         end
--     end

--     -- If the player is not in the top three, show their rank
--     if playerRank > 3 then
--         DrawTextOnScreen("Your Rank: " .. playerRank, 0.5, 0.5) -- Adjust placement as needed
--     end

--     -- Cleanup after a delay
--     Citizen.Wait(10000) -- Wait 10 seconds
--     for _, ped in ipairs(createdPeds) do
--         DeletePed(ped) -- Remove created peds
--     end
--     RenderScriptCams(false, false, 0, true, false)
--     DestroyCam(cam, false)
-- end)

RegisterCommand("gungameadmin", function(source, args, rawCommand)
    lib.callback('one-codes:GunGame:GetOverride4', false, function(msg2)
        lib.registerContext({
            id = 'GunGame_ADMIN',
            title = 'Gun Game',
            options = {
                {
                    title = 'Force Start Gun Game',
                    icon = 'circle',
                    onSelect = function()
                        lib.callback('one-codes:GunGame:ForceStart', false, function(msg)
                            lib.notify({title = msg,type = 'info'})
                        end)
                    end,
                },
                {
                    title = 'Print Joined Players in ',
                    icon = 'circle',
                    onSelect = function()
                        lib.callback('one-codes:GunGame:DEBUG:PrintJoinedForceStart', false, function(msg)
                            lib.notify({title = msg,type = 'info'})
                        end)
                    end,
                },
                {
                    title = 'Close GunGame TEMP',
                    description = tostring(msg2),
                    icon = 'circle',
                    onSelect = function()
                        lib.callback('one-codes:GunGame:GetOverride5', false, function(msg)
                            lib.notify({title = msg,type = 'info'})
                        end)
                    end,
                },
            }
        })
    end)
    lib.showContext('GunGame_ADMIN')
end)

RegisterCommand("gungame", function(source, args, rawCommand)
    lib.callback('one-codes:GunGame:GameStarted', false, function(gamestarted)
        if gamestarted == "DEBUG" then
            lib.registerContext({
                id = 'GunGame',
                title = 'Gun Game',
                options = {
                    {
                        title = 'GUN GAME IS IN DEV MODE',
                        icon = 'gun',
                    },
                    {
                        title = 'Join Gun Game',
                        icon = 'gun',
                        disabled = true,
                    },
                    {
                        title = 'Leave Gun Game',
                        icon = 'gun',
                        disabled = true,
                    },
                    {
                        title = 'Leave match',
                        icon = 'gun',
                        disabled = true,
                    },
                }
            })
        else
            lib.registerContext({
                id = 'GunGame',
                title = 'Gun Game',
                options = {
                    {
                        title = 'Join Gun Game',
                        icon = 'gun',
                        disabled = gamestarted or cantleavebox,
                        onSelect = function()
                            joined = true
                            cantleavebox = true
                            Wait(400)
                            lib.callback('one-codes:GunGame:PlayerJoin', source, function(msg, table)
                                print(msg)
                                print(json.encode(table))
                                lib.notify({title = msg, type = 'info'})
                            end)
                        end,
                    },
                    {
                        title = 'Leave Gun Game',
                        icon = 'gun',
                        disabled = gamestarted,
                        onSelect = function()
                            cantleavebox = false        
                            joined = false
                            Wait(400)
                            lib.callback('one-codes:GunGame:PlayerLeft', source, function(msg, table)
                                print(msg)
                                print(json.encode(table))
                                lib.hideTextUI()
                                lib.notify({title = msg, type = 'info'})
                            end)
                        end,
                    },
                    {
                        title = 'Leave match',
                        icon = 'gun',
                        disabled = not gamestarted or not joined,
                        onSelect = function()
                            gamestarted = false
                            cantleavebox = false
                            joined = false
                            lib.hideTextUI()
                            Wait(400)
                            lib.callback('one-codes:GunGame:PlayerLeft', source, function(msg, table)
                                print(msg)
                                print(json.encode(table))
                                lib.notify({title = msg, type = 'info'})
                            end)
                        end,
                    },
                }
            })
        end
        lib.showContext('GunGame')
    end)
end)

Citizen.CreateThread(function()
    local sleep = 500
    while true do
        Wait(sleep) 
        sleep = 500
        if currentRankings and playerRank and gamestarted and joined then
            sleep = 0
            local y = 0.8 
            for index, ranking in ipairs(currentRankings) do
                DrawTextOnScreen("Rank " .. index .. ": " .. "" .. ranking.playerName .. " - Kills: " .. ranking.kills, 0.05, y)
                y = y + 0.035 
            end
            DrawTextOnScreen("Your Rank: " .. playerRank, 0.9, 0.9)
        end
    end
end)

function DrawTextOnScreen(text, x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextRightJustify(true)
    SetTextWrap(0.0, 0.95)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    DoScreenFadeIn(500)
    if joined then
        lib.hideTextUI()
        print("resource stopped player was joined")
        SetEntityCoordsNoOffset(PlayerPedId(), -828.5420, -1217.6462, 6.9341, false, false, false)
        NetworkResurrectLocalPlayer(-828.5420, -1217.6462, 6.9341, 0, true, false)
    end
end)