-- Client-side: calcula garagem mais próxima, cria blip/marker, abre garagem
local AssignedHouseGarages = {}
local GarageBlips = {}

local function CreateGarageBlip(garageId)
    local g = HousingGarages[garageId]
    if not g or not g.garage then return end
    local coord = vector3(g.garage.x, g.garage.y, g.garage.z)

    if GarageBlips[garageId] and DoesBlipExist(GarageBlips[garageId]) then
        RemoveBlip(GarageBlips[garageId])
        GarageBlips[garageId] = nil
    end

    local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
    SetBlipSprite(blip, 357)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Garagem da Casa")
    EndTextCommandSetBlipName(blip)

    GarageBlips[garageId] = blip
end

local function ClearAllGarageBlips()
    for k,b in pairs(GarageBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    GarageBlips = {}
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        for houseId, garageId in pairs(AssignedHouseGarages) do
            local g = HousingGarages[garageId]
            if g and g.garage then
                local gcoord = vector3(g.garage.x, g.garage.y, g.garage.z)
                local distance = #(pcoords - gcoord)
                if distance < 50.0 then
                    sleep = 0
                    DrawMarker(1, gcoord.x, gcoord.y, gcoord.z - 1.0, 0,0,0, 0,0,0, 2.0,2.0,0.6, 255,200,0, 100, false, true, 2, nil, nil, false)
                    if distance < 2.0 then
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("Press ~INPUT_CONTEXT~ para abrir garagem")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                        if IsControlJustReleased(0, 38) then
                            exports['renzu_garage']:OpenGarageMenu(garageId)
							--TriggerEvent('renzu_garage:openGarageClient', garageId)
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent('renzu_garage:UpdateHouseAssignments')
AddEventHandler('renzu_garage:UpdateHouseAssignments', function(assignments)
    if not assignments then return end
    AssignedHouseGarages = assignments
    ClearAllGarageBlips()
    for houseId, garageId in pairs(AssignedHouseGarages) do
        CreateGarageBlip(garageId)
    end
end)

RegisterNetEvent('renzu_garage:AssignAutoGarageClient')
AddEventHandler('renzu_garage:AssignAutoGarageClient', function(houseCoords, houseId)
    local coord = vector3(houseCoords.x, houseCoords.y, houseCoords.z)
    local nearest = nil
    local nearestd = -1
    for k,v in pairs(HousingGarages) do
        if v and v.garage then
            local gcoord = vector3(v.garage.x, v.garage.y, v.garage.z)
            local d = #(coord - gcoord)
            if nearestd == -1 or d < nearestd then
                nearestd = d
                nearest = { id = k, coord = v.garage, shell = v.shell, dist = d }
            end
        end
    end
    if nearest and nearest.id then
        TriggerServerEvent('renzu_garage:AssignAutoGarageServer', houseId, nearest.id)
        TriggerEvent('chat:addMessage', { args = { "Garage", ("Garagem atribuída: id=%s shell=%s"):format(nearest.id, nearest.shell) } })
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('renzu_garage:RequestAssignmentsSync')
end)