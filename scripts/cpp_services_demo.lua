-- C++ System Services Demo
-- Shows how Lua calls C++ layer for system operations

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

-- Simple JSON serialization (for demo purposes)
function serializeToJSON(data)
    local json = "{"
    local first = true
    
    for k, v in pairs(data) do
        if not first then
            json = json .. ","
        end
        first = false
        
        local key = '"' .. tostring(k) .. '"'
        local value
        
        if type(v) == "string" then
            value = '"' .. v .. '"'
        elseif type(v) == "number" then
            value = tostring(v)
        elseif type(v) == "boolean" then
            value = tostring(v)
        elseif type(v) == "table" then
            value = serializeToJSON(v)  -- Recursive
        else
            value = "null"
        end
        
        json = json .. key .. ":" .. value
    end
    
    json = json .. "}"
    return json
end

-- Simple JSON deserialization (very basic, for demo only)
function deserializeJSON(json_str)
    if not json_str or json_str == "" then
        return nil
    end
    
    -- This is a very simplified parser
    -- In real game, use a proper JSON library
    local data = {}
    
    -- Remove braces
    json_str = json_str:gsub("^{", ""):gsub("}$", "")
    
    -- Split by comma (simple split, doesn't handle nested objects)
    for pair in json_str:gmatch('[^,]+') do
        local key, value = pair:match('"([^"]+)"%s*:%s*([^,]+)')
        if key and value then
            -- Try to parse value
            if value:match('^".*"$') then
                -- String
                data[key] = value:gsub('"', '')
            elseif tonumber(value) then
                -- Number
                data[key] = tonumber(value)
            elseif value == "true" then
                data[key] = true
            elseif value == "false" then
                data[key] = false
            end
        end
    end
    
    return data
end

-- Test player data
TestPlayer = {
    id = 1001,
    name = "TestHero",
    level = 10,
    health = 100,
    gold = 500,
    experience = 1250
}

function on_init()
    engine:log("========================================")
    engine:log("C++ System Services Demo")
    engine:log("========================================")
    engine:log("")
    engine:log("This demo shows:")
    engine:log("  - Lua calling C++ for file IO")
    engine:log("  - Lua calling C++ for network simulation")
    engine:log("  - Data persistence (save/load)")
    engine:log("")
end

function on_update()
    -- Test 1: Save player data
    engine:log("-------- Test 1: Save Player --------")
    local player_json = serializeToJSON(TestPlayer)
    engine:log("[Lua] Serialized player data: " .. player_json)
    
    local success = engine:save_player(TestPlayer.id, player_json)
    if success then
        engine:log("[Lua] Player save successful!")
    else
        engine:log_error("[Lua] Player save failed!")
    end
    
    -- Test 2: Load player data
    engine:log("")
    engine:log("-------- Test 2: Load Player --------")
    local loaded_json = engine:load_player(TestPlayer.id)
    
    if loaded_json and loaded_json ~= "" then
        engine:log("[Lua] Loaded JSON: " .. loaded_json)
        local loaded_player = deserializeJSON(loaded_json)
        
        if loaded_player then
            engine:log("[Lua] Deserialized player:")
            engine:log("  Name: " .. (loaded_player.name or "N/A"))
            engine:log("  Level: " .. (loaded_player.level or 0))
            engine:log("  Gold: " .. (loaded_player.gold or 0))
        end
    else
        engine:log("[Lua] No saved player data found")
    end
    
    -- Test 3: Save mail data
    engine:log("")
    engine:log("-------- Test 3: Save Mail --------")
    local mail_data = {
        sender = "System",
        title = "Welcome Mail",
        content = "Thank you for playing!",
        gold = 100,
        has_attachment = true
    }
    
    local mail_json = serializeToJSON(mail_data)
    engine:log("[Lua] Saving mail data...")
    
    success = engine:save_mail(TestPlayer.id, mail_json)
    if success then
        engine:log("[Lua] Mail save successful!")
    end
    
    -- Test 4: Load mail data
    engine:log("")
    engine:log("-------- Test 4: Load Mail --------")
    local loaded_mail_json = engine:load_mail(TestPlayer.id)
    
    if loaded_mail_json and loaded_mail_json ~= "" then
        engine:log("[Lua] Loaded mail JSON: " .. loaded_mail_json)
        local loaded_mail = deserializeJSON(loaded_mail_json)
        
        if loaded_mail then
            engine:log("[Lua] Mail content:")
            engine:log("  From: " .. (loaded_mail.sender or "N/A"))
            engine:log("  Title: " .. (loaded_mail.title or "N/A"))
            engine:log("  Gold: " .. (loaded_mail.gold or 0))
        end
    end
    
    -- Test 5: Generic data save/load
    engine:log("")
    engine:log("-------- Test 5: Generic Data --------")
    local config_data = serializeToJSON({
        game_version = "1.0.0",
        max_players = 100,
        server_name = "TestServer"
    })
    
    engine:save_data("server_config", config_data)
    local loaded_config = engine:load_data("server_config")
    
    if loaded_config and loaded_config ~= "" then
        engine:log("[Lua] Loaded config: " .. loaded_config)
    end
    
    -- Test 6: Network simulation
    engine:log("")
    engine:log("-------- Test 6: Network Messages --------")
    
    -- Send message to specific player
    engine:send_player(1001, "LEVEL_UP", "Congratulations! You reached level 10!")
    
    -- Broadcast to all players
    engine:broadcast_to_all("SERVER_ANNOUNCEMENT", "Server maintenance in 10 minutes!")
    
    engine:log("")
    engine:log("========================================")
    engine:log("All tests completed!")
    engine:log("")
    engine:log("Check the 'saves/' directory for saved files:")
    engine:log("  - saves/player_1001.dat")
    engine:log("  - saves/mail_1001.dat")
    engine:log("  - saves/server_config.dat")
    engine:log("========================================")
    
    -- Note: In real game loop, you would call this periodically
    -- Here we only run once
    engine:log("")
    engine:log("Press Q to quit")
end

function on_cleanup()
    engine:log("Cleanup complete")
end

