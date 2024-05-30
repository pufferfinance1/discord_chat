ChatSystem = {}

ChatSystem.Colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    reset = "\27[0m",
    gray = "\27[90m"
}

ChatSystem.Router = "xnkv_QpWqICyt8NpVMbfsUQciZ4wlm5DigLrfXRm8fY"
ChatSystem.DefaultRoom = "isImEFj7zii8ALzRirQ2nqUUXecCkdFSh10xB_hbBJ0"
ChatSystem.CurrentRoom = ChatSystem.CurrentRoom or ChatSystem.DefaultRoom

ChatSystem.LastReceived = {
    Room = ChatSystem.DefaultRoom,
    Sender = nil
}

ChatSystem.InitialRooms = { [ChatSystem.DefaultRoom] = "DevChat-Main" }
ChatSystem.Rooms = ChatSystem.Rooms or ChatSystem.InitialRooms

ChatSystem.RequireConfirmations = ChatSystem.RequireConfirmations or true

ChatSystem.findRoomAddress = function(target)
    for address, name in pairs(ChatSystem.Rooms) do
        if target == name then
            return address
        end
    end
end

ChatSystem.registerUser = function(...)
    local args = {...}
    ao.send({
        Target = ChatSystem.Router,
        Action = "Register",
        Name = args[1] or Name,
        Address = args[2] or ao.id
    })
end

GetRoomsList = function()
    ao.send({ Target = ChatSystem.Router, Action = "Get-List" })
    return ChatSystem.Colors.gray .. "Fetching room list from ChatSystem index..." .. ChatSystem.Colors.reset
end

JoinRoom = function(id, ...)
    local args = {...}
    local address = ChatSystem.findRoomAddress(id) or id
    local nickname = args[1] or ao.id
    ao.send({ Target = address, Action = "Register", Nickname = nickname })
    return ChatSystem.Colors.gray .. "Joining room " .. ChatSystem.Colors.blue .. id .. ChatSystem.Colors.gray .. "..." .. ChatSystem.Colors.reset
end

SendMessage = function(text, ...)
    local args = {...}
    local id = args[1]
    if id then
        ChatSystem.CurrentRoom = ChatSystem.findRoomAddress(id) or id
    end
    local roomName = ChatSystem.Rooms[ChatSystem.CurrentRoom] or id
    ao.send({ Target = ChatSystem.CurrentRoom, Action = "Say", Data = text })
    if ChatSystem.RequireConfirmations then
        return ChatSystem.Colors.gray .. "Broadcasting to " .. ChatSystem.Colors.blue .. roomName .. ChatSystem.Colors.gray .. "..." .. ChatSystem.Colors.reset
    else
        return ""
    end
end

SendTip = function(...)
    local args = {...}
    local room = args[2] or ChatSystem.LastReceived.Room
    local roomName = ChatSystem.Rooms[room] or room
    local quantity = tostring(args[3] or 1)
    local recipient = args[1] or ChatSystem.LastReceived.Sender
    ao.send({
        Action = "Transfer",
        Target = room,
        Recipient = recipient,
        Quantity = quantity
    })
    return ChatSystem.Colors.gray .. "Sent tip of " .. ChatSystem.Colors.green .. quantity .. ChatSystem.Colors.gray .. " to " .. ChatSystem.Colors.red .. recipient .. ChatSystem.Colors.gray .. " in room " .. ChatSystem.Colors.blue .. roomName .. ChatSystem.Colors.gray .. "."
end

ReplayMessages = function(...)
    local args = {...}
    local room = args[2] and ChatSystem.findRoomAddress(args[2]) or ChatSystem.LastReceived.Room
    local roomName = ChatSystem.Rooms[room] or room
    local depth = args[1] or 3

    ao.send({
        Target = room,
        Action = "Replay",
        Depth = tostring(depth)
    })
    return ChatSystem.Colors.gray .. "Requested replay of last " .. ChatSystem.Colors.green .. depth .. ChatSystem.Colors.gray .. " messages from " .. ChatSystem.Colors.blue .. roomName .. ChatSystem.Colors.reset .. "."
end

LeaveRoom = function(id)
    local address = ChatSystem.findRoomAddress(id) or id
    ao.send({ Target = address, Action = "Unregister" })
    return ChatSystem.Colors.gray .. "Leaving room " .. ChatSystem.Colors.blue .. id .. ChatSystem.Colors.gray .. "..." .. ChatSystem.Colors.reset
end

Handlers.add(
    "ChatSystem-Broadcasted",
    Handlers.utils.hasMatchingTag("Action", "Broadcasted"),
    function(m)
        local shortRoomName = ChatSystem.Rooms[m.From] or string.sub(m.From, 1, 6)
        if m.Broadcaster == ao.id then
            if ChatSystem.RequireConfirmations == true then
                print(
                    ChatSystem.Colors.gray .. "[Confirmation of your broadcast in "
                    .. ChatSystem.Colors.blue .. shortRoomName .. ChatSystem.Colors.gray .. ".]"
                    .. ChatSystem.Colors.reset)
            end
        else
            local nickname = string.sub(m.Nickname, 1, 10)
            if m.Broadcaster ~= m.Nickname then
                nickname = nickname .. ChatSystem.Colors.gray .. "#" .. string.sub(m.Broadcaster, 1, 3)
            end
            print(
                "[" .. ChatSystem.Colors.red .. nickname .. ChatSystem.Colors.reset
                .. "@" .. ChatSystem.Colors.blue .. shortRoomName .. ChatSystem.Colors.reset
                .. "]> " .. ChatSystem.Colors.green .. m.Data .. ChatSystem.Colors.reset)

            ChatSystem.LastReceived.Room = m.From
            ChatSystem.LastReceived.Sender = m.Broadcaster
        end
    end
)

Handlers.add(
    "ChatSystem-List",
    function(m)
        if m.Action == "Room-List" and m.From == ChatSystem.Router then
            return true
        end
        return false
    end,
    function(m)
        local introText = "The available rooms in ChatSystem are:\n\n"
        local roomList = ""
        ChatSystem.Rooms = ChatSystem.InitialRooms

        for i = 1, #m.TagArray do
            local prefix = "Room-"
            local tagPrefix = string.sub(m.TagArray[i].name, 1, #prefix)
            local roomName = string.sub(m.TagArray[i].name, #prefix + 1, #m.TagArray[i].name)
            local address = m.TagArray[i].value

            if tagPrefix == prefix then
                roomList = roomList .. ChatSystem.Colors.blue .. "        " .. roomName .. ChatSystem.Colors.reset .. "\n"
                ChatSystem.Rooms[address] = roomName
            end
        end

        print(
            introText .. roomList .. "\nTo join a chat, run `JoinRoom(\"roomName\"[, \"yourNickname\"])`. To leave a chat, use `LeaveRoom(\"roomName\")`."
        )
    end
)

Handlers.add(
    "TransferToChatSystem",
    Handlers.utils.hasMatchingTag("Action", "TransferToChatSystem"),
    function(m)
        local messageContent = m.Data or "No message content"
        local sender = m.Event or "Unknown sender"

        print(ChatSystem.Colors.green .. "[" .. sender .. "]: " .. ChatSystem.Colors.reset .. messageContent)
    end
)

if ChatSystemRegistered == nil then
    ChatSystemRegistered = true
    JoinRoom(ChatSystem.DefaultRoom)
end

return(
    ChatSystem.Colors.blue .. "\n\nWelcome to ao ChatSystem v1.0!\n\n" .. ChatSystem.Colors.reset ..
    "ChatSystem is a simple service that helps the ao community communicate as we build our new computer.\n" ..
    "Here are the commands you can use:\n\n" ..
    ChatSystem.Colors.green .. "\t\t`GetRoomsList()`" .. ChatSystem.Colors.reset .. " to view available rooms.\n" ..
    ChatSystem.Colors.green .. "\t\t`JoinRoom(\"RoomName\")`" .. ChatSystem.Colors.reset .. " to join a room.\n" ..
    ChatSystem.Colors.green .. "\t\t`SendMessage(\"Message\"[, \"RoomName\"])`" .. ChatSystem.Colors.reset .. " to send a message to a room (remembers your last choice).\n" ..
    ChatSystem.Colors.green .. "\t\t`ReplayMessages([\"Count\"])`" .. ChatSystem.Colors.reset .. " to replay recent messages from a chat.\n" ..
    ChatSystem.Colors.green .. "\t\t`LeaveRoom(\"RoomName\")`" .. ChatSystem.Colors.reset .. " to leave a chat.\n" ..
    ChatSystem.Colors.green .. "\t\t`SendTip([\"Recipient\"])`" .. ChatSystem.Colors.reset .. " to send a token tip from the chatroom to the sender of the last message.\n\n" ..
    "You are already registered to " .. ChatSystem.Colors.blue .. ChatSystem.Rooms[ChatSystem.DefaultRoom] .. ChatSystem.Colors.reset .. ".\n" ..
    "Enjoy your time, be respectful, and remember: Cypherpunks write code! ??"
)
