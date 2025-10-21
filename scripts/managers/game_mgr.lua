-- GameMgr - Global Game Manager
-- Central system that manages all sub-managers
-- Architecture: GameMgr -> {PlayerMgr, ItemMgr, EnemyMgr, MailMgr, ...}

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

-- Load sub-managers
if not PlayerMgr then
    require("scripts.managers.player_mgr")
end
if not ItemMgr then
    require("scripts.managers.item_mgr")
end
if not EnemyMgr then
    require("scripts.managers.enemy_mgr")
end
if not MailMgr then
    require("scripts.managers.mail_mgr")
end

GameMgr = GameMgr or Class()

function GameMgr:init()
    engine:log("========================================")
    engine:log("GameMgr: Initializing Global System")
    engine:log("========================================")
    
    -- Sub-managers (only create if not already exists for hot-reload)
    self.player_mgr = self.player_mgr or PlayerMgr:new()
    self.item_mgr = self.item_mgr or ItemMgr:new()
    self.enemy_mgr = self.enemy_mgr or EnemyMgr:new()
    self.mail_mgr = self.mail_mgr or MailMgr:new()
    
    -- Game state
    self.is_running = true
    self.is_paused = false
    self.frame_count = 0
    self.game_time = 0
    
    -- Configuration
    self.config = self.config or {
        update_interval = 1.0,  -- seconds
        auto_save_interval = 60,  -- frames
        debug_mode = true
    }
    
    engine:log("GameMgr: All managers initialized")
    engine:log("========================================")
end

-- Initialize new game
function GameMgr:newGame()
    engine:log("GameMgr: Starting new game")
    
    -- Create main player
    local player_id, player = self.player_mgr:createPlayer("Hero", 100, 50)
    self.player_mgr:setMainPlayer(player_id)
    
    -- Give starting items
    self.item_mgr:giveItemToPlayer(player, "health_potion", 3)
    self.item_mgr:giveItemToPlayer(player, "mana_potion", 2)
    
    -- Create player mailbox and send welcome mail
    self.mail_mgr:sendMail(
        player_id,
        "System",
        "Welcome to the Game!",
        "Thank you for playing! Here are some starter rewards.",
        { gold = 100, items = {"health_potion"} }
    )
    
    engine:log("GameMgr: New game started")
end

-- Main update loop
function GameMgr:update(dt)
    if not self.is_running or self.is_paused then
        return
    end
    
    self.frame_count = self.frame_count + 1
    self.game_time = self.game_time + (dt or 1.0)
    
    -- Update all managers
    self.player_mgr:update(dt)
    self.enemy_mgr:update(dt)
    self.mail_mgr:update(dt)
    
    -- Game logic
    self:processGameLogic()
    
    -- Auto save (using Protobuf)
    if self.config.auto_save_interval > 0 and self.frame_count % self.config.auto_save_interval == 0 then
        self:autoSave()
    end
    
    -- Show status
    if self.config.debug_mode then
        self:showStatus()
    end
end

-- Process game logic (combat, events, etc.)
function GameMgr:processGameLogic()
    local main_player = self.player_mgr:getMainPlayer()
    if not main_player then
        return
    end
    
    -- Check game over
    if main_player.health <= 0 then
        self:onGameOver()
        return
    end
    
    -- Combat system
    local enemy_count = self.enemy_mgr:getEnemyCount()
    
    if enemy_count > 0 then
        -- Player attacks
        local alive_enemies = self.enemy_mgr:getAliveEnemies()
        if #alive_enemies > 0 then
            local target = alive_enemies[1]
            local damage = math.random(15, 25)
            
            engine:log(main_player.name .. " attacks " .. target.name .. " for " .. damage .. " damage")
            local still_alive = target:takeDamage(damage)
            
            if not still_alive then
                -- Gain exp and rewards
                main_player:gainExp(target.exp_reward)
                main_player.gold = (main_player.gold or 0) + target.exp_reward
                
                -- Chance to drop item
                if math.random() > 0.7 then
                    self.item_mgr:giveItemToPlayer(main_player, "health_potion", 1)
                end
            end
        end
        
        -- Enemies attack
        self.enemy_mgr:processAI(main_player)
        
    else
        -- No enemies, peaceful time
        if self.frame_count % 3 == 0 then
            main_player:restoreMana(5)
        end
    end
end

-- Show current status
function GameMgr:showStatus()
    local main_player = self.player_mgr:getMainPlayer()
    if not main_player then
        return
    end
    
    engine:log("========================================")
    engine:log("Game Time: " .. math.floor(self.game_time) .. "s  Frame: " .. self.frame_count)
    engine:log(main_player:getStatus())
    engine:log("Enemies: " .. self.enemy_mgr:getEnemyCount())
    engine:log("Inventory: " .. #main_player.inventory .. " items")
    
    local player_id = main_player.id
    local unread_mails = self.mail_mgr:getUnreadCount(player_id)
    local unclaimed_rewards = self.mail_mgr:getUnclaimedCount(player_id)
    engine:log("Mails: " .. unread_mails .. " unread, " .. unclaimed_rewards .. " unclaimed")
    engine:log("========================================")
end

-- Game over
function GameMgr:onGameOver()
    if self.is_running then
        engine:log_error("========================================")
        engine:log_error("GAME OVER!")
        engine:log_error("========================================")
        
        self.is_running = false
        self.is_paused = true
        
        -- Show final stats
        local main_player = self.player_mgr:getMainPlayer()
        if main_player then
            engine:log("Final Level: " .. main_player.level)
            engine:log("Final Gold: " .. (main_player.gold or 0))
            engine:log("Survival Time: " .. math.floor(self.game_time) .. " seconds")
        end
    end
end

-- Pause/Resume
function GameMgr:pause()
    self.is_paused = true
    engine:log("GameMgr: Game paused")
end

function GameMgr:resume()
    self.is_paused = false
    engine:log("GameMgr: Game resumed")
end

-- Auto save (using Protobuf)
function GameMgr:autoSave()
    if self.config.debug_mode then
        engine:log("========================================")
        engine:log("GameMgr: Auto-saving (Protobuf)...")
    end
    
    local success = self:saveGame()
    
    if self.config.debug_mode then
        if success then
            engine:log("GameMgr: Auto-save completed successfully")
        else
            engine:log_warning("GameMgr: Auto-save failed")
        end
        engine:log("========================================")
    end
    
    return success
end

-- Save entire game state (using Protobuf for all data)
function GameMgr:saveGame()
    local success = true
    
    -- Save all players (each player as separate Protobuf file)
    local player_count = self.player_mgr:saveAllPlayers()
    
    -- Save player metadata
    self.player_mgr:saveMetadata()
    
    -- Save all mails (each mail as separate Protobuf file)
    local mail_count = self.mail_mgr:saveAllMails()
    
    -- Save game state metadata
    local game_state = string.format(
        "version=1.0\ntimestamp=%d\nframe_count=%d\ngame_time=%.2f",
        os.time(),
        self.frame_count,
        self.game_time
    )
    engine:save_data("game_state", game_state)
    
    engine:log("GameMgr: Saved complete game state (Protobuf)")
    engine:log("  - Players: " .. player_count)
    engine:log("  - Mails: " .. mail_count)
    
    return success
end

-- Load entire game state (using Protobuf)
function GameMgr:loadGame()
    engine:log("========================================")
    engine:log("GameMgr: Loading game (Protobuf mode)...")
    engine:log("========================================")
    
    -- Load game state metadata
    local game_state_str = engine:load_data("game_state")
    if game_state_str and game_state_str ~= "" then
        for line in game_state_str:gmatch("[^\n]+") do
            local key, value = line:match("(%w+)=(.*)")
            if key == "frame_count" then
                self.frame_count = tonumber(value) or 0
            elseif key == "game_time" then
                self.game_time = tonumber(value) or 0
            end
        end
    end
    
    -- Load player metadata and all players
    local loaded = self.player_mgr:loadMetadata()
    
    if loaded then
        engine:log("GameMgr: Game loaded successfully")
        engine:log("  - Players: " .. self.player_mgr:getPlayerCount())
        engine:log("  - Frame: " .. self.frame_count)
        return true
    else
        engine:log("GameMgr: No save data found")
        return false
    end
end

-- Get manager by name
function GameMgr:getMgr(name)
    local mgr_map = {
        player = self.player_mgr,
        item = self.item_mgr,
        enemy = self.enemy_mgr,
        mail = self.mail_mgr
    }
    return mgr_map[name]
end

-- Debug commands
function GameMgr:debugGiveExp(amount)
    local player = self.player_mgr:getMainPlayer()
    if player then
        player:gainExp(amount or 100)
    end
end

function GameMgr:debugGiveGold(amount)
    local player = self.player_mgr:getMainPlayer()
    if player then
        player.gold = (player.gold or 0) + (amount or 100)
        engine:log("Gave " .. amount .. " gold")
    end
end

function GameMgr:debugSpawnEnemy(count)
    count = count or 1
    for i = 1, count do
        self.enemy_mgr:spawnRandomEnemy()
    end
end

function GameMgr:debugClearEnemies()
    self.enemy_mgr.enemies = {}
    engine:log("All enemies cleared")
end

function GameMgr:debugSendMail()
    local player = self.player_mgr:getMainPlayer()
    if player then
        self.mail_mgr:sendMail(
            player.id,
            "Debug System",
            "Test Mail",
            "This is a test mail sent from debug command",
            { gold = 50, items = {"health_potion"} }
        )
    end
end

function GameMgr:debugSaveGame()
    engine:log("========================================")
    engine:log("Manual Save (Protobuf)")
    engine:log("========================================")
    self:saveGame()
end

function GameMgr:debugLoadGame()
    engine:log("========================================")
    engine:log("Manual Load (Protobuf)")
    engine:log("========================================")
    self:loadGame()
end

-- Cleanup all managers
function GameMgr:cleanup()
    engine:log("GameMgr: Shutting down all managers")
    
    if self.player_mgr then
        self.player_mgr:cleanup()
    end
    
    if self.item_mgr then
        self.item_mgr:cleanup()
    end
    
    if self.enemy_mgr then
        self.enemy_mgr:cleanup()
    end
    
    if self.mail_mgr then
        self.mail_mgr:cleanup()
    end
    
    engine:log("GameMgr: Cleanup complete")
end

return GameMgr

