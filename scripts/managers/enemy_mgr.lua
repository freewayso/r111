-- EnemyMgr - Enemy Manager
-- Manages all enemies, spawning, and AI behavior

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

EnemyMgr = EnemyMgr or Class()

function EnemyMgr:init()
    self.enemies = {}  -- enemy_id -> Enemy instance
    self.next_enemy_id = 1
    
    -- Enemy templates
    self.templates = {}
    
    -- Spawn configuration
    self.spawn_config = {
        enabled = true,
        interval = 3,
        max_enemies = 5,
        current_wave = 1
    }
    
    self.frame_count = 0
    
    -- Initialize templates
    self:initTemplates()
    
    engine:log("EnemyMgr initialized")
end

-- Initialize enemy templates
function EnemyMgr:initTemplates()
    self.templates["goblin"] = {
        class = Enemy,
        params = {"Goblin", 30, 8, 15}
    }
    
    self.templates["orc"] = {
        class = Enemy,
        params = {"Orc", 50, 12, 25}
    }
    
    self.templates["troll"] = {
        class = Enemy,
        params = {"Troll", 80, 15, 40}
    }
    
    self.templates["dragon"] = {
        class = Boss,
        params = {"Dragon Lord", 200, 25, 100}
    }
    
    engine:log("EnemyMgr: Loaded " .. self:getTemplateCount() .. " enemy templates")
end

-- Spawn enemy from template
function EnemyMgr:spawnEnemy(template_name)
    local template = self.templates[template_name]
    if not template then
        engine:log_warning("EnemyMgr: Template not found: " .. template_name)
        return nil
    end
    
    local enemy_id = self.next_enemy_id
    self.next_enemy_id = self.next_enemy_id + 1
    
    local enemy = template.class:new(table.unpack(template.params))
    enemy.id = enemy_id
    enemy.template_name = template_name
    
    self.enemies[enemy_id] = enemy
    
    engine:log("EnemyMgr: Spawned [" .. enemy_id .. "] " .. enemy.name)
    return enemy_id, enemy
end

-- Spawn random enemy
function EnemyMgr:spawnRandomEnemy()
    local templates = {"goblin", "orc", "troll"}
    local template_name = templates[math.random(1, #templates)]
    return self:spawnEnemy(template_name)
end

-- Spawn boss
function EnemyMgr:spawnBoss()
    return self:spawnEnemy("dragon")
end

-- Get enemy by ID
function EnemyMgr:getEnemy(enemy_id)
    return self.enemies[enemy_id]
end

-- Remove enemy
function EnemyMgr:removeEnemy(enemy_id)
    if self.enemies[enemy_id] then
        local name = self.enemies[enemy_id].name
        self.enemies[enemy_id] = nil
        engine:log("EnemyMgr: Removed [" .. enemy_id .. "] " .. name)
        return true
    end
    return false
end

-- Get all alive enemies
function EnemyMgr:getAliveEnemies()
    local alive = {}
    for id, enemy in pairs(self.enemies) do
        if enemy.is_alive then
            table.insert(alive, enemy)
        end
    end
    return alive
end

-- Get enemy count
function EnemyMgr:getEnemyCount()
    return #self:getAliveEnemies()
end

-- Remove dead enemies
function EnemyMgr:removeDeadEnemies()
    local removed_count = 0
    local to_remove = {}
    
    for id, enemy in pairs(self.enemies) do
        if not enemy.is_alive then
            table.insert(to_remove, id)
        end
    end
    
    for _, id in ipairs(to_remove) do
        self:removeEnemy(id)
        removed_count = removed_count + 1
    end
    
    return removed_count
end

-- Update all enemies
function EnemyMgr:update(dt)
    self.frame_count = self.frame_count + 1
    
    -- Auto spawn
    if self.spawn_config.enabled then
        if self.frame_count % self.spawn_config.interval == 0 then
            if self:getEnemyCount() < self.spawn_config.max_enemies then
                self:spawnRandomEnemy()
            end
        end
    end
    
    -- Boss spawn every 20 frames
    if self.frame_count == 20 then
        self:spawnBoss()
        engine:log("========================================")
        engine:log("BOSS WAVE!")
        engine:log("========================================")
    end
    
    -- Remove dead enemies
    self:removeDeadEnemies()
end

-- Enemy AI - Attack target
function EnemyMgr:processAI(target_player)
    local alive_enemies = self:getAliveEnemies()
    
    for _, enemy in ipairs(alive_enemies) do
        if enemy.attack then
            enemy:attack(target_player)
        end
    end
end

-- Set spawn config
function EnemyMgr:setSpawnConfig(config)
    for k, v in pairs(config) do
        if self.spawn_config[k] ~= nil then
            self.spawn_config[k] = v
        end
    end
end

-- Enable/disable spawning
function EnemyMgr:setSpawning(enabled)
    self.spawn_config.enabled = enabled
    engine:log("EnemyMgr: Spawning " .. (enabled and "enabled" or "disabled"))
end

-- Get template count
function EnemyMgr:getTemplateCount()
    local count = 0
    for _ in pairs(self.templates) do
        count = count + 1
    end
    return count
end

-- Cleanup
function EnemyMgr:cleanup()
    engine:log("EnemyMgr: Cleaning up " .. self:getEnemyCount() .. " enemies")
    self.enemies = {}
end

return EnemyMgr

