-- Protobuf Demo - Using C++ Protobuf from Lua
-- Shows Lua -> C++ Protobuf serialization/deserialization

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

-- Test player data
TestPlayer = {
    id = 1001,
    name = "ProtoHero",
    level = 15,
    health = 85,
    max_health = 150,
    mana = 60,
    max_mana = 100,
    experience = 2500,
    gold = 1000,
    position = {
        x = 100.5,
        y = 200.75,
        z = 50.0
    }
}

-- Test mail data
TestMail = {
    id = 501,
    sender = "GameMaster",
    title = "Daily Reward",
    content = "Thank you for playing! Here's your daily reward.",
    rewards = {
        gold = 200,
        exp = 100
    },
    is_read = false,
    is_claimed = false,
    timestamp = os.time(),
    expire_time = os.time() + (7 * 24 * 3600)  -- 7 days
}

function on_init()
    engine:log("========================================")
    engine:log("Protobuf Integration Demo")
    engine:log("========================================")
    engine:log("")
    engine:log("Architecture:")
    engine:log("  Lua -> C++ (Protobuf serialize)")
    engine:log("  C++ -> File (binary)")
    engine:log("  File -> C++ (binary)")
    engine:log("  C++ -> Lua (Protobuf deserialize)")
    engine:log("")
end

function on_update()
    engine:log("-------- Protobuf Demo --------")
    engine:log("")
    
    -- Test 1: Player serialization/deserialization
    engine:log("Test 1: Player Protobuf")
    engine:log("  Original data:")
    printPlayerData(TestPlayer)
    
    -- Serialize (Lua table -> C++ Protobuf -> binary string)
    local pb_data = engine:serialize_player_pb(TestPlayer)
    engine:log("[Lua] Serialized to " .. #pb_data .. " bytes (binary)")
    
    -- Deserialize (binary string -> C++ Protobuf -> Lua table)
    local restored_player = engine:deserialize_player_pb(pb_data)
    engine:log("[Lua] Deserialized player:")
    printPlayerData(restored_player)
    
    engine:log("")
    
    -- Test 2: Save/Load Player with Protobuf
    engine:log("Test 2: Save/Load Player (Protobuf)")
    
    local save_success = engine:save_player_pb(TestPlayer.id, TestPlayer)
    if save_success then
        engine:log("[Lua] Player saved successfully (Protobuf format)")
    end
    
    local loaded_player = engine:load_player_pb(TestPlayer.id)
    if loaded_player and loaded_player.id then
        engine:log("[Lua] Player loaded successfully:")
        printPlayerData(loaded_player)
    else
        engine:log_error("[Lua] Failed to load player")
    end
    
    engine:log("")
    
    -- Test 3: Mail serialization/deserialization
    engine:log("Test 3: Mail Protobuf")
    engine:log("  Original mail:")
    printMailData(TestMail)
    
    local pb_mail_data = engine:serialize_mail_pb(TestMail)
    engine:log("[Lua] Serialized to " .. #pb_mail_data .. " bytes (binary)")
    
    local restored_mail = engine:deserialize_mail_pb(pb_mail_data)
    engine:log("[Lua] Deserialized mail:")
    printMailData(restored_mail)
    
    engine:log("")
    
    -- Test 4: Save/Load Mail with Protobuf
    engine:log("Test 4: Save/Load Mail (Protobuf)")
    
    save_success = engine:save_mail_pb(TestPlayer.id, TestMail)
    if save_success then
        engine:log("[Lua] Mail saved successfully (Protobuf format)")
    end
    
    local loaded_mail = engine:load_mail_pb(TestPlayer.id)
    if loaded_mail and loaded_mail.id then
        engine:log("[Lua] Mail loaded successfully:")
        printMailData(loaded_mail)
    else
        engine:log_error("[Lua] Failed to load mail")
    end
    
    engine:log("")
    
    -- Test 5: Data size comparison
    engine:log("Test 5: Format Comparison")
    engine:log("  Protobuf binary: " .. #pb_data .. " bytes")
    
    -- Simple JSON-like comparison
    local json_str = tableToString(TestPlayer)
    engine:log("  Text format: ~" .. #json_str .. " bytes")
    engine:log("  Compression ratio: " .. math.floor((1 - #pb_data/#json_str) * 100) .. "%")
    
    engine:log("")
    engine:log("========================================")
    engine:log("Protobuf Demo Complete!")
    engine:log("")
    engine:log("Saved files (binary format):")
    engine:log("  saves/player_1001.dat  (Protobuf)")
    engine:log("  saves/mail_1001.dat    (Protobuf)")
    engine:log("")
    engine:log("Advantages:")
    engine:log("  ✓ Smaller file size")
    engine:log("  ✓ Faster serialization")
    engine:log("  ✓ Type safety")
    engine:log("  ✓ Version compatible")
    engine:log("  ✓ Cross-language support")
    engine:log("========================================")
    
    engine:log("")
    engine:log("Press Q to quit")
end

function on_cleanup()
    engine:log("Cleanup complete")
end

-- Helper functions
function printPlayerData(player)
    if not player or not player.id then
        engine:log("  (empty)")
        return
    end
    
    engine:log(string.format("  ID: %d, Name: %s, Level: %d", 
        player.id or 0, player.name or "N/A", player.level or 0))
    engine:log(string.format("  HP: %d/%d, MP: %d/%d", 
        player.health or 0, player.max_health or 0,
        player.mana or 0, player.max_mana or 0))
    engine:log(string.format("  Gold: %d, EXP: %d", 
        player.gold or 0, player.experience or 0))
    
    if player.position then
        engine:log(string.format("  Position: (%.1f, %.1f, %.1f)", 
            player.position.x or 0, player.position.y or 0, player.position.z or 0))
    end
end

function printMailData(mail)
    if not mail or not mail.id then
        engine:log("  (empty)")
        return
    end
    
    engine:log(string.format("  ID: %d, From: %s", 
        mail.id or 0, mail.sender or "N/A"))
    engine:log(string.format("  Title: %s", mail.title or "N/A"))
    engine:log(string.format("  Content: %s", mail.content or "N/A"))
    
    if mail.rewards then
        engine:log(string.format("  Rewards: Gold=%d, EXP=%d", 
            mail.rewards.gold or 0, mail.rewards.exp or 0))
    end
    
    engine:log(string.format("  Status: Read=%s, Claimed=%s", 
        tostring(mail.is_read or false), tostring(mail.is_claimed or false)))
end

function tableToString(tbl, indent)
    indent = indent or ""
    local str = "{"
    
    for k, v in pairs(tbl) do
        str = str .. "\n" .. indent .. "  " .. tostring(k) .. " = "
        if type(v) == "table" then
            str = str .. tableToString(v, indent .. "  ")
        else
            str = str .. tostring(v)
        end
        str = str .. ","
    end
    
    str = str .. "\n" .. indent .. "}"
    return str
end

engine:log("Protobuf demo script loaded!")

