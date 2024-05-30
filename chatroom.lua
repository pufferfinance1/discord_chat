ActiveUsers = ActiveUsers or {}
ChatRoomName = ChatRoomName or "Anonymous-Chat"
ChatHistory = ChatHistory or {}
MaxReplayDepth = MaxReplayDepth or 5

if (RequireTokens == nil) and (TokenBalances ~= nil) then
    RequireTokens = true
end

function SendMessage(to, from, content, messageType)
    ao.send({
        Target = to,
        Action = "MessageBroadcast",
        Sender = from,
        Username = ActiveUsers[from],
        Content = content,
        MessageType = messageType
    })
end

function RelayMessage(from, content, messageType)
    print("Relaying " .. messageType .. " message from " .. from .. ". Content:\n" .. content)
    local recentUsers = {}
    for i = math.max(#ChatHistory - 100, 1), #ChatHistory do
       recentUsers[ChatHistory[i].Sender] = true
    end
    for user, _ in pairs(recentUsers) do
        SendMessage(user, from, content, messageType)
    end
    table.insert(ChatHistory, { Sender = from, MessageType = messageType, Content = content })
end

Handlers.add(
    "UserRegister",
    Handlers.utils.hasMatchingTag("Action", "Register"),
    function(msg)
        print("Registering user: " .. msg.From .. " with nickname: " .. msg.Nickname)
        ActiveUsers[msg.From] = msg.Nickname
        ao.send({
            Target = msg.From,
            Action = "RegistrationConfirmed"
        })
    end
)

Handlers.add(
    "UserUnregister",
    Handlers.utils.hasMatchingTag("Action", "Unregister"),
    function(msg)
        print("Unregistering user: " .. msg.From)
        ActiveUsers[msg.From] = nil
        ao.send({
            Target = msg.From,
            Action = "UnregistrationConfirmed"
        })
    end
)

Handlers.add(
    "RelayBroadcast",
    Handlers.utils.hasMatchingTag("Action", "Broadcast"),
    function(msg)
        if RequireTokens and TokenBalances[msg.From] < 1 then
            ao.send({
                Action = "LowBalance",
                CurrentBalance = tostring(TokenBalances[msg.From])
            })
            print("User " .. msg.From .. " rejected due to insufficient balance.")
            return
        end
        RelayMessage(msg.From, msg.Content, msg.MessageType or "Standard")
    end
)

Handlers.add(
    "ReplayMessages",
    Handlers.utils.hasMatchingTag("Action", "Replay"),
    function(msg)
        local replayDepth = tonumber(msg.Depth) or MaxReplayDepth

        print("Replaying last " .. replayDepth .. " messages for user " .. msg.From .. "...")

        for i = math.max(#ChatHistory - replayDepth, 1), #ChatHistory do
            print("Replaying message index: " .. i)
            SendMessage(msg.From, ChatHistory[i].Sender, ChatHistory[i].Content, ChatHistory[i].MessageType)
        end
    end
)

function getTotalUsers()
    local userCount = 0
    for _, __ in pairs(ActiveUsers) do
        userCount = userCount + 1
    end
    return userCount
end

Prompt = function()
    return ChatRoomName .. "[Active Users:" .. getTotalUsers() .. "]> "
end
