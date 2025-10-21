


-- Lua脚本演示Sol2功能 - 支持热更新

-- 全局变量
game_time = 0
enemy_count = 3
reload_count = reload_count or 0  -- 记录重载次数（保留旧值）

-- 初始化函数
function on_init()
    engine:log_message("Lua initialization started!")
    
    -- 调用C++方法
    engine:log_message("Initial player health: " .. engine:get_player_health())
    
    -- 创建Lua表
    enemies = {
        { name = "Goblin", health = 30 },
        { name = "Orc", health = 50 },
        { name = "Dragon", health = 100 }
    }
    
    -- 注册Lua函数给C++调用
    calculate_damage = function(attacker, defender)
        local base_damage = 10
        local multiplier = math.random(5, 15) / 10
        return math.floor(base_damage * multiplier)
    end
    
    engine:log_message("Lua initialization completed!")
end

-- 更新函数（每帧调用）
function on_update()
    game_time = game_time + 1
    
    engine:log_message("Game time: " .. game_time)
    
    -- 模拟游戏逻辑
    if game_time % 2 == 0 then
        local damage = calculate_damage("enemy", "player")
        engine:damage_player(damage)
        engine:log_message("Enemy attacked! Damage: " .. damage)
    end
    
    if game_time % 3 == 0 then
        local heal = 15
        engine:heal_player(heal)
        engine:log_message("Player healed! Amount: " .. heal)
    end
    
    -- 显示敌人信息
    if game_time == 1 then
        engine:log_message("Enemy list:")
        for i, enemy in ipairs(enemies) do
            engine:log_message("  " .. i .. ". " .. enemy.name .. " (HP: " .. enemy.health .. ")")
        end
    end
end

-- 清理函数
function on_cleanup()
    engine:log_message("Lua cleanup started")
    engine:log_message("Final player health: " .. engine:get_player_health())
    engine:log_message("Lua cleanup completed")
end

-- 热更新回调函数
function on_reload()
    reload_count = reload_count + 1
    engine:log_message("========================================")
    engine:log_message("🔥 Script reloaded! (Count: " .. reload_count .. ")")
    engine:log_message("========================================")
    engine:log_message("You can now see your changes in action!")
    
    -- 可以在这里重新初始化需要的数据
    -- 但要注意：全局变量会被保留（除非重新赋值）
end

-- 额外的Lua函数
function custom_lua_function()
    engine:log_message("This is a custom Lua function!")
    
    -- 使用Lua标准库
    local x = math.sin(math.pi / 2)
    local y = string.upper("hello from lua!")
    
    engine:log_message("Math result: " .. x)
    engine:log_message("String result: " .. y)
end

-- 在初始化时调用自定义函数
custom_lua_function()

































































