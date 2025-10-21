-- Game Main Script with Manager Architecture
-- Architecture: GameMgr -> {PlayerMgr, ItemMgr, EnemyMgr, MailMgr}

-- Load manager system
if not GameMgr then
    require("scripts.managers.game_mgr")
end

-- Global game manager instance (preserve on hot reload)
g_GameMgr = g_GameMgr or nil

-- Hot reload counter
g_ReloadCount = g_ReloadCount or 0

-- Initialize game
function on_init()
    engine:log("========================================")
    engine:log("Game Initialization - Manager Architecture")
    engine:log("Using Protobuf for Save/Load")
    engine:log("========================================")
    
    -- Create game manager if not exists
    if not g_GameMgr then
        g_GameMgr = GameMgr:new()
        
        -- Try to load existing save
        local loaded = g_GameMgr:loadGame()
        
        if not loaded then
            -- No save found, start new game
            engine:log("")
            engine:log("No save data found, starting new game...")
            g_GameMgr:newGame()
        end
        
        engine:log("")
        engine:log("Architecture Overview:")
        engine:log("  GameMgr (Global System)")
        engine:log("    ├── PlayerMgr  (Player management)")
        engine:log("    ├── ItemMgr    (Item management)")
        engine:log("    ├── EnemyMgr   (Enemy/AI management)")
        engine:log("    └── MailMgr    (Mail/reward management)")
        engine:log("")
        engine:log("Data Persistence:")
        engine:log("  ✓ Save format: Protobuf (binary)")
        engine:log("  ✓ Location: saves/ directory")
        engine:log("  ✓ Auto-save: Every " .. g_GameMgr.config.auto_save_interval .. " frames")
        engine:log("")
    else
        engine:log("GameMgr already exists (preserved from reload)")
    end
    
    engine:log("Initialization complete!")
    engine:log("========================================")
end

-- Hot reload callback
function on_reload()
    g_ReloadCount = g_ReloadCount + 1
    
    engine:log("")
    engine:log("========================================")
    engine:log("HOT RELOAD #" .. g_ReloadCount)
    engine:log("========================================")
    
    if g_GameMgr then
        -- Re-initialize manager (updates methods, keeps data)
        local old_data = {
            player_mgr = g_GameMgr.player_mgr,
            item_mgr = g_GameMgr.item_mgr,
            enemy_mgr = g_GameMgr.enemy_mgr,
            mail_mgr = g_GameMgr.mail_mgr,
            config = g_GameMgr.config,
            frame_count = g_GameMgr.frame_count,
            game_time = g_GameMgr.game_time
        }
        
        -- Preserve managers
        g_GameMgr.player_mgr = old_data.player_mgr
        g_GameMgr.item_mgr = old_data.item_mgr
        g_GameMgr.enemy_mgr = old_data.enemy_mgr
        g_GameMgr.mail_mgr = old_data.mail_mgr
        g_GameMgr.config = old_data.config
        g_GameMgr.frame_count = old_data.frame_count
        g_GameMgr.game_time = old_data.game_time
        
        engine:log("All managers and data preserved!")
        engine:log("  - Players: " .. g_GameMgr.player_mgr:getPlayerCount())
        engine:log("  - Items: " .. g_GameMgr.item_mgr:getItemCount())
        engine:log("  - Enemies: " .. g_GameMgr.enemy_mgr:getEnemyCount())
        engine:log("  - Total Mails: " .. g_GameMgr.mail_mgr:getTotalMailCount())
        
        local main_player = g_GameMgr.player_mgr:getMainPlayer()
        if main_player then
            engine:log("  - " .. main_player:getStatus())
        end
    end
    
    engine:log("")
    engine:log("You can modify any manager's behavior and reload!")
    engine:log("Try changing:")
    engine:log("  - g_GameMgr.config.debug_mode")
    engine:log("  - g_GameMgr.enemy_mgr.spawn_config.interval")
    engine:log("  - Manager methods (will update on next call)")
    engine:log("========================================")
    engine:log("")
end

-- Main update loop
function on_update()
    if not g_GameMgr then
        engine:log_warning("GameMgr not initialized!")
        return
    end
    
    -- Update game through manager
    g_GameMgr:update(1.0)
end

-- Cleanup
function on_cleanup()
    engine:log("")
    engine:log("========================================")
    engine:log("Game Cleanup")
    engine:log("========================================")
    
    if g_GameMgr then
        g_GameMgr:cleanup()
    end
    
    engine:log("Cleanup complete")
    engine:log("========================================")
end

-- Debug commands (can be called during hot reload)
function debugGiveExp(amount)
    if g_GameMgr then
        g_GameMgr:debugGiveExp(amount)
    end
end

function debugGiveGold(amount)
    if g_GameMgr then
        g_GameMgr:debugGiveGold(amount)
    end
end

function debugSpawnEnemy(count)
    if g_GameMgr then
        g_GameMgr:debugSpawnEnemy(count)
    end
end

function debugClearEnemies()
    if g_GameMgr then
        g_GameMgr:debugClearEnemies()
    end
end

function debugSendMail()
    if g_GameMgr then
        g_GameMgr:debugSendMail()
    end
end

function debugPause()
    if g_GameMgr then
        g_GameMgr:pause()
    end
end

function debugResume()
    if g_GameMgr then
        g_GameMgr:resume()
    end
end

function debugShowMails()
    if not g_GameMgr then return end
    
    local player = g_GameMgr.player_mgr:getMainPlayer()
    if not player then return end
    
    local mails = g_GameMgr.mail_mgr:getPlayerMails(player.id)
    
    engine:log("========== Mailbox ==========")
    local count = 0
    for id, mail in pairs(mails) do
        count = count + 1
        local status = ""
        if not mail.is_read then
            status = status .. "[UNREAD] "
        end
        if not mail.is_claimed and next(mail.rewards) ~= nil then
            status = status .. "[HAS REWARDS] "
        end
        
        engine:log(string.format("[%d] %s%s - %s", id, status, mail.sender, mail.title))
    end
    engine:log("Total: " .. count .. " mails")
    engine:log("=============================")
end

function debugReadMail(mail_id)
    if not g_GameMgr then return end
    
    local player = g_GameMgr.player_mgr:getMainPlayer()
    if not player then return end
    
    local mail = g_GameMgr.mail_mgr:readMail(player.id, mail_id)
    if mail then
        engine:log("========== Mail [" .. mail_id .. "] ==========")
        engine:log("From: " .. mail.sender)
        engine:log("Title: " .. mail.title)
        engine:log("Content: " .. mail.content)
        if next(mail.rewards) ~= nil then
            engine:log("Rewards: Gold=" .. (mail.rewards.gold or 0))
        end
        engine:log("========================================")
    else
        engine:log_warning("Mail not found: " .. mail_id)
    end
end

function debugClaimMail(mail_id)
    if not g_GameMgr then return end
    
    local player = g_GameMgr.player_mgr:getMainPlayer()
    if not player then return end
    
    local success, msg = g_GameMgr.mail_mgr:claimRewards(player.id, mail_id, player)
    if success then
        engine:log("Successfully claimed rewards from mail [" .. mail_id .. "]")
    else
        engine:log_warning("Failed to claim: " .. (msg or "unknown error"))
    end
end

-- Save/Load commands
function debugSaveGame()
    if g_GameMgr then
        g_GameMgr:debugSaveGame()
    end
end

function debugLoadGame()
    if g_GameMgr then
        g_GameMgr:debugLoadGame()
    end
end

-- Help command
function help()
    engine:log("========== Available Commands ==========")
    engine:log("debugGiveExp(amount) - Give experience")
    engine:log("debugGiveGold(amount) - Give gold")
    engine:log("debugSpawnEnemy(count) - Spawn enemies")
    engine:log("debugClearEnemies() - Clear all enemies")
    engine:log("debugSendMail() - Send test mail")
    engine:log("debugShowMails() - Show mailbox")
    engine:log("debugReadMail(id) - Read mail")
    engine:log("debugClaimMail(id) - Claim mail rewards")
    engine:log("debugPause() - Pause game")
    engine:log("debugResume() - Resume game")
    engine:log("")
    engine:log("debugSaveGame() - Save game (Protobuf)")
    engine:log("debugLoadGame() - Load game (Protobuf)")
    engine:log("========================================")
end

-- Initial message
engine:log("")
engine:log("Manager Architecture Demo Loaded!")
engine:log("Type help() in Lua console for debug commands")
engine:log("Press 'R' to hot reload and see preserved state!")
engine:log("")

