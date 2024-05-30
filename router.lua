RoomRegistry = RoomRegistry or {}

Handlers.add(
    "AddRoom",
    Handlers.utils.hasMatchingTag("Action", "Register"),
    function(message)
        print("Registering room '" .. message.Name .. "'. Requested by: " .. message.From)
        local roomAddress = message.Address or message.From
        table.insert(RoomRegistry, { Address = roomAddress, Name = message.Name, CreatedBy = message.From })
        ao.send({
            Target = message.From,
            Action = "RoomRegistered"
        })
    end
)

Handlers.add(
    "FetchRooms",
    Handlers.utils.hasMatchingTag("Action", "Get-List"),
    function(message)
        print("Providing room list to: " .. message.From)
        local response = { Target = message.From, Action = "RoomList" }
        for i = 1, #RoomRegistry do
            response["Room-" .. RoomRegistry[i].Name] = RoomRegistry[i].Address
        end
        ao.send(response)
    end
)

Handlers.add(
    "RemoveRoom",
    Handlers.utils.hasMatchingTag("Action", "Unregister"),
    function(message)
        local targetRoom = nil
        for i = 1, #RoomRegistry do
            if RoomRegistry[i].Name == message.Name then
                targetRoom = RoomRegistry[i]
                targetRoom.Index = i
            end
        end

        if message.From ~= targetRoom.CreatedBy then
            print("UNAUTHORIZED: Removal attempt by " .. message.From .. " for room '" .. message.Name .. "'!")
            return
        end

        table.remove(RoomRegistry, targetRoom.Index)
    end
)
