-- Game Demo with OOP Class System
-- This demonstrates a data-driven architecture with all game logic in Lua

-- Load class system
if not Class then
    require("scripts.class_system")
end

-- Game State (all data in Lua, can be hot-reloaded!)
GameState = GameState or {
    player = nil,
    enemies = {},
    items = {},
    current_wave = 1,
    frame_count = 0,
    is_paused = false,
    
    -- Configuration (can be modified and hot-reloaded!)
    config = {
        spawn_interval = 3,
        damage_multiplier = 1.0,
        exp_multiplier = 1.0,
        difficulty = "normal"
    }
}

-- Initialize game (called once on first load)
function on_init()
    engine:log("========================================")
    engine:log("Game Initialization (OOP Demo)")
    engine:log("========================================")
    
    -- Create player (only if not exists, to preserve state on reload)
    if not GameState.player then
        GameState.player = Player:new("Hero", 100, 50)
        engine:log("Created player: " .. GameState.player:getStatus())
        
        -- Add some skills
        GameState.player.skills = {
            fireball = Skill:new("Fireball", 15, 30, "Launches a fireball"),
            heal = Skill:new("Minor Heal", 10, -20, "Restores health")
        }
    else
        engine:log("Player already exists (preserved from previous session)")
    end
    
    -- Create some items
    if #GameState.items == 0 then
        table.insert(GameState.items, Potion:new("Health Potion", 30))
        table.insert(GameState.items, Potion:new("Mana Potion", 20))
    end
    
    engine:log("Initialization complete!")
end

-- Hot reload callback
function on_reload()
    engine:log("========================================")
    engine:log("HOT RELOAD DETECTED!")
    engine:log("========================================")
    engine:log("Game state preserved:")
    if GameState.player then
        engine:log("  " .. GameState.player:getStatus())
    end
    engine:log("  Enemies: " .. #GameState.enemies)
    engine:log("  Config can be modified in real-time!")
    engine:log("  Try changing GameState.config values!")
end

-- Spawn enemy
function spawnEnemy()
    local enemy_types = {
        { name = "Goblin", health = 30, damage = 8, exp = 15 },
        { name = "Orc", health = 50, damage = 12, exp = 25 },
        { name = "Troll", health = 80, damage = 15, exp = 40 }
    }
    
    -- Choose random enemy type
    local type_index = math.random(1, #enemy_types)
    local enemy_data = enemy_types[type_index]
    
    -- Create enemy
    local enemy = Enemy:new(
        enemy_data.name,
        enemy_data.health,
        enemy_data.damage,
        enemy_data.exp
    )
    
    table.insert(GameState.enemies, enemy)
    engine:log("Spawned: " .. enemy.name)
    
    return enemy
end

-- Spawn boss
function spawnBoss()
    local boss = Boss:new("Dragon Lord", 200, 25, 100)
    table.insert(GameState.enemies, boss)
    
    engine:log("========================================")
    engine:log("BOSS APPEARED: " .. boss.name)
    engine:log("========================================")
    
    return boss
end

-- Combat system
function playerAttack()
    if #GameState.enemies == 0 then
        return
    end
    
    -- Attack first enemy
    local enemy = GameState.enemies[1]
    local damage = math.random(15, 25) * GameState.config.damage_multiplier
    
    engine:log("Player attacks " .. enemy.name .. " for " .. damage .. " damage!")
    local still_alive = enemy:takeDamage(damage)
    
    if not still_alive then
        -- Enemy defeated
        local exp = math.floor(enemy.exp_reward * GameState.config.exp_multiplier)
        GameState.player:gainExp(exp)
        
        -- Remove from enemy list
        table.remove(GameState.enemies, 1)
    end
end

-- Enemy turn
function enemiesTurn()
    for i, enemy in ipairs(GameState.enemies) do
        if enemy.is_alive then
            enemy:attack(GameState.player)
        end
    end
end

-- Use skill
function useSkill(skill_name)
    local skill = GameState.player.skills[skill_name]
    if not skill then
        engine:log_warning("Skill not found: " .. skill_name)
        return
    end
    
    if #GameState.enemies > 0 then
        skill:use(GameState.player, GameState.enemies[1])
    else
        skill:use(GameState.player, nil)
    end
end

-- Update all skills cooldown
function updateSkills()
    for name, skill in pairs(GameState.player.skills) do
        skill:update()
    end
end

-- Main update loop
function on_update()
    GameState.frame_count = GameState.frame_count + 1
    local frame = GameState.frame_count
    
    if GameState.is_paused then
        engine:log("Game paused...")
        return
    end
    
    -- Show player status
    engine:log("----------------------------------------")
    engine:log(GameState.player:getStatus())
    engine:log("Enemies: " .. #GameState.enemies)
    
    -- Spawn enemies periodically
    if frame % GameState.config.spawn_interval == 0 then
        if #GameState.enemies < 3 then
            spawnEnemy()
        end
    end
    
    -- Spawn boss every 10 waves
    if frame == 30 then
        spawnBoss()
    end
    
    -- Combat simulation
    if #GameState.enemies > 0 then
        -- Player turn
        if math.random() > 0.5 then
            playerAttack()
        else
            -- Use skill
            if GameState.player.skills.fireball:canUse(GameState.player) then
                useSkill("fireball")
            else
                playerAttack()
            end
        end
        
        -- Enemy turn
        if GameState.player.health > 0 then
            enemiesTurn()
        end
    else
        engine:log("No enemies to fight...")
        GameState.player:restoreMana(5)
    end
    
    -- Update skills
    updateSkills()
    
    -- Passive mana regen
    if frame % 2 == 0 then
        GameState.player:restoreMana(3)
    end
    
    -- Check game over
    if GameState.player.health <= 0 then
        engine:log_error("GAME OVER!")
        GameState.is_paused = true
    end
end

-- Cleanup
function on_cleanup()
    engine:log("Game cleanup")
    engine:log("Final state:")
    if GameState.player then
        engine:log("  " .. GameState.player:getStatus())
    end
    engine:log("  Waves survived: " .. GameState.current_wave)
end

-- Debug commands (can be called via hot reload console)
function debugGiveExp(amount)
    GameState.player:gainExp(amount or 100)
end

function debugHeal()
    GameState.player:heal(999)
end

function debugSetDifficulty(level)
    if level == "easy" then
        GameState.config.damage_multiplier = 0.5
        GameState.config.exp_multiplier = 1.5
    elseif level == "hard" then
        GameState.config.damage_multiplier = 1.5
        GameState.config.exp_multiplier = 2.0
    else
        GameState.config.damage_multiplier = 1.0
        GameState.config.exp_multiplier = 1.0
    end
    GameState.config.difficulty = level or "normal"
    engine:log("Difficulty set to: " .. GameState.config.difficulty)
end

function debugClearEnemies()
    GameState.enemies = {}
    engine:log("All enemies cleared!")
end

-- Initial call
engine:log("Game script loaded with OOP class system!")
engine:log("Try modifying GameState.config values and reload!")
engine:log("  - GameState.config.damage_multiplier")
engine:log("  - GameState.config.spawn_interval")
engine:log("  - etc.")

