-- PlayerMgr - Player Manager
-- Manages all player instances in the game

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

PlayerMgr = PlayerMgr or Class()

function PlayerMgr:init()
    self.players = {}  -- player_id -> Player instance
    self.next_player_id = 1
    self.main_player_id = nil
    
    engine:log("PlayerMgr initialized")
end

-- Create new player
function PlayerMgr:createPlayer(name, health, mana)
    local player_id = self.next_player_id
    self.next_player_id = self.next_player_id + 1
    
    local player = Player:new(name, health, mana)
    player.id = player_id
    
    self.players[player_id] = player
    
    engine:log("PlayerMgr: Created player [" .. player_id .. "] " .. name)
    return player_id, player
end

-- Get player by ID
function PlayerMgr:getPlayer(player_id)
    return self.players[player_id]
end

-- Remove player
function PlayerMgr:removePlayer(player_id)
    if self.players[player_id] then
        local name = self.players[player_id].name
        self.players[player_id] = nil
        engine:log("PlayerMgr: Removed player [" .. player_id .. "] " .. name)
        return true
    end
    return false
end

-- Set main player
function PlayerMgr:setMainPlayer(player_id)
    if self.players[player_id] then
        self.main_player_id = player_id
        engine:log("PlayerMgr: Set main player to [" .. player_id .. "]")
        return true
    end
    return false
end

-- Get main player
function PlayerMgr:getMainPlayer()
    return self.players[self.main_player_id]
end

-- Get all players
function PlayerMgr:getAllPlayers()
    return self.players
end

-- Update all players
function PlayerMgr:update(dt)
    for id, player in pairs(self.players) do
        -- Passive mana regeneration
        if player.mana < player.max_mana then
            player:restoreMana(2)
        end
        
        -- Update skills cooldown
        if player.skills then
            for _, skill in pairs(player.skills) do
                if skill.update then
                    skill:update()
                end
            end
        end
    end
end

-- Get player count
function PlayerMgr:getPlayerCount()
    local count = 0
    for _ in pairs(self.players) do
        count = count + 1
    end
    return count
end

-- Save player using Protobuf (C++ layer)
function PlayerMgr:savePlayer(player_id)
    local player = self.players[player_id]
    if not player then
        return false
    end
    
    -- Prepare player data for Protobuf
    local player_data = {
        id = player.id,
        name = player.name,
        level = player.level,
        health = player.health,
        max_health = player.max_health,
        mana = player.mana,
        max_mana = player.max_mana,
        experience = player.experience,
        gold = player.gold or 0,
        position = player.position or {x = 0, y = 0, z = 0}
    }
    
    -- Call C++ Protobuf save
    local success = engine:save_player_pb(player_id, player_data)
    
    if success then
        engine:log("PlayerMgr: Saved player [" .. player_id .. "] using Protobuf")
    else
        engine:log_error("PlayerMgr: Failed to save player [" .. player_id .. "]")
    end
    
    return success
end

-- Load player using Protobuf (C++ layer)
function PlayerMgr:loadPlayer(player_id)
    -- Call C++ Protobuf load
    local player_data = engine:load_player_pb(player_id)
    
    if not player_data or not player_data.id then
        engine:log("PlayerMgr: No saved data for player [" .. player_id .. "]")
        return nil
    end
    
    -- Create Player instance from loaded data
    local player = Player:new(player_data.name, player_data.max_health, player_data.max_mana)
    player.id = player_data.id
    player.level = player_data.level
    player.health = player_data.health
    player.experience = player_data.experience
    player.gold = player_data.gold or 0
    player.position = player_data.position or {x = 0, y = 0, z = 0}
    
    self.players[player_id] = player
    
    engine:log("PlayerMgr: Loaded player [" .. player_id .. "] " .. player.name .. " using Protobuf")
    return player
end

-- Save all players (using Protobuf)
function PlayerMgr:saveAllPlayers()
    local count = 0
    for id, player in pairs(self.players) do
        if self:savePlayer(id) then
            count = count + 1
        end
    end
    
    engine:log("PlayerMgr: Saved " .. count .. " players (Protobuf)")
    return count
end

-- Save metadata (player list, next_id, etc.)
function PlayerMgr:saveMetadata()
    local metadata = {
        next_player_id = self.next_player_id,
        main_player_id = self.main_player_id,
        player_ids = {}
    }
    
    -- Collect all player IDs
    for id, _ in pairs(self.players) do
        table.insert(metadata.player_ids, id)
    end
    
    -- Simple text format for metadata
    local data_str = string.format(
        "next_id=%d\nmain_id=%d\nplayer_ids=%s",
        metadata.next_player_id,
        metadata.main_player_id or 0,
        table.concat(metadata.player_ids, ",")
    )
    
    return engine:save_data("player_metadata", data_str)
end

-- Load metadata
function PlayerMgr:loadMetadata()
    local data_str = engine:load_data("player_metadata")
    if not data_str or data_str == "" then
        return false
    end
    
    -- Parse metadata
    for line in data_str:gmatch("[^\n]+") do
        local key, value = line:match("(%w+)=(.*)")
        if key == "next_id" then
            self.next_player_id = tonumber(value) or 1
        elseif key == "main_id" then
            local main_id = tonumber(value)
            if main_id and main_id > 0 then
                self.main_player_id = main_id
            end
        elseif key == "player_ids" then
            -- Load each player
            for id_str in value:gmatch("[^,]+") do
                local id = tonumber(id_str)
                if id then
                    self:loadPlayer(id)
                end
            end
        end
    end
    
    engine:log("PlayerMgr: Loaded metadata (Protobuf mode)")
    return true
end

-- Cleanup
function PlayerMgr:cleanup()
    engine:log("PlayerMgr: Cleaning up " .. self:getPlayerCount() .. " players")
    self.players = {}
end

return PlayerMgr

