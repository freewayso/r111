# Lua 面向对象编程 - 类系统完整指南

## 为什么 Lua 需要类？

虽然 Lua 本身是一种轻量级的脚本语言，没有内置的类系统，但通过 **metatable** 机制，我们可以实现完整的面向对象编程。

### 优势

1. **代码组织** - 将相关数据和行为封装在一起
2. **重用性** - 通过继承减少代码重复
3. **可维护性** - 清晰的结构便于理解和修改
4. **数据驱动** - 所有游戏数据和逻辑都在 Lua 中，支持热更新

## 类系统实现原理

### 基础实现

```lua
-- 定义类工厂函数
function Class(base)
    local class = {}
    local class_mt = { __index = class }
    
    -- 构造函数
    function class:new(...)
        local instance = setmetatable({}, class_mt)
        if instance.init then
            instance:init(...)
        end
        return instance
    end
    
    -- 支持继承
    if base then
        setmetatable(class, { __index = base })
    end
    
    return class
end
```

### 工作原理

1. **类定义** - `Class()` 返回一个表作为类
2. **实例化** - `Class:new()` 创建新实例
3. **方法查找** - 通过 metatable 的 `__index` 实现
4. **继承** - 子类的 metatable 指向父类

## 基础使用示例

### 1. 定义一个简单的类

```lua
-- 定义 Player 类
Player = Class()

-- 构造函数（初始化器）
function Player:init(name, health)
    self.name = name or "Unknown"
    self.health = health or 100
    self.level = 1
end

-- 定义方法
function Player:takeDamage(amount)
    self.health = self.health - amount
    print(self.name .. " took " .. amount .. " damage")
end

function Player:heal(amount)
    self.health = self.health + amount
    print(self.name .. " healed " .. amount .. " HP")
end

-- 创建实例
local player1 = Player:new("Alice", 150)
local player2 = Player:new("Bob")

-- 调用方法
player1:takeDamage(20)  -- Alice took 20 damage
player2:heal(10)         -- Bob healed 10 HP
```

### 2. 继承

```lua
-- 定义基类 Enemy
Enemy = Class()

function Enemy:init(name, health)
    self.name = name
    self.health = health
end

function Enemy:attack(target)
    local damage = 10
    target:takeDamage(damage)
end

-- 定义子类 Boss（继承自 Enemy）
Boss = Class(Enemy)  -- 注意这里传入父类

function Boss:init(name, health, special_ability)
    -- 调用父类构造函数
    Enemy.init(self, name, health)
    
    -- 添加新属性
    self.special_ability = special_ability
    self.phase = 1
end

-- 重写（override）父类方法
function Boss:attack(target)
    local damage = 25  -- Boss 伤害更高
    print(self.name .. " uses special attack!")
    target:takeDamage(damage)
end

-- 添加新方法
function Boss:useSpecialAbility()
    print(self.name .. " uses " .. self.special_ability .. "!")
end

-- 使用
local boss = Boss:new("Dragon", 500, "Fire Breath")
boss:attack(player1)           -- 调用重写的方法
boss:useSpecialAbility()       -- 调用新方法
```

## 完整示例：RPG 游戏系统

### Player 类（完整版）

```lua
Player = Class()

function Player:init(name, health, mana)
    -- 基础属性
    self.name = name or "Hero"
    self.health = health or 100
    self.max_health = health or 100
    self.mana = mana or 50
    self.max_mana = mana or 50
    
    -- 进阶属性
    self.level = 1
    self.experience = 0
    self.gold = 0
    
    -- 复杂数据结构
    self.inventory = {}
    self.skills = {}
    self.equipment = {
        weapon = nil,
        armor = nil,
        accessory = nil
    }
    
    -- 状态
    self.status_effects = {}
    self.position = { x = 0, y = 0 }
end

function Player:damage(amount)
    self.health = math.max(0, self.health - amount)
    
    engine:log(self.name .. " took " .. amount .. " damage")
    
    if self.health == 0 then
        self:onDeath()
    end
end

function Player:heal(amount)
    local old_health = self.health
    self.health = math.min(self.health + amount, self.max_health)
    local actual = self.health - old_health
    
    engine:log(self.name .. " healed " .. actual .. " HP")
end

function Player:useMana(amount)
    if self.mana >= amount then
        self.mana = self.mana - amount
        return true
    end
    return false
end

function Player:gainExp(amount)
    self.experience = self.experience + amount
    
    -- 检查升级
    local exp_needed = self.level * 100
    if self.experience >= exp_needed then
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    self.max_health = self.max_health + 20
    self.max_mana = self.max_mana + 10
    self.health = self.max_health
    self.mana = self.max_mana
    
    engine:log("LEVEL UP! Now level " .. self.level)
end

function Player:addItem(item)
    table.insert(self.inventory, item)
end

function Player:useItem(index)
    if self.inventory[index] then
        local item = self.inventory[index]
        item:use(self)
        table.remove(self.inventory, index)
    end
end

function Player:learnSkill(skill)
    self.skills[skill.name] = skill
    engine:log("Learned new skill: " .. skill.name)
end

function Player:useSkill(skill_name, target)
    local skill = self.skills[skill_name]
    if skill and skill:canUse(self) then
        return skill:use(self, target)
    end
    return false
end

function Player:getStatus()
    return string.format(
        "%s [Lv.%d] HP:%d/%d MP:%d/%d EXP:%d Gold:%d",
        self.name, self.level,
        self.health, self.max_health,
        self.mana, self.max_mana,
        self.experience, self.gold
    )
end

function Player:onDeath()
    engine:log_error(self.name .. " has died!")
end
```

### Item 类系统

```lua
-- 基类：Item
Item = Class()

function Item:init(name, type, value, description)
    self.name = name or "Item"
    self.type = type or "misc"
    self.value = value or 0
    self.description = description or "An item"
end

function Item:use(target)
    engine:log("Using " .. self.name)
    return true
end

-- 子类：Potion
Potion = Class(Item)

function Potion:init(name, heal_amount)
    Item.init(self, name, "consumable", heal_amount)
    self.heal_amount = heal_amount or 20
end

function Potion:use(target)
    engine:log("Drinking " .. self.name)
    target:heal(self.heal_amount)
    return true
end

-- 子类：Weapon
Weapon = Class(Item)

function Weapon:init(name, damage, durability)
    Item.init(self, name, "weapon", damage * 10)
    self.damage = damage or 10
    self.durability = durability or 100
    self.max_durability = durability or 100
end

function Weapon:use(target)
    if self.durability > 0 then
        target:damage(self.damage)
        self.durability = self.durability - 1
        return true
    else
        engine:log_warning(self.name .. " is broken!")
        return false
    end
end

function Weapon:repair(amount)
    self.durability = math.min(self.durability + amount, self.max_durability)
end
```

### Skill 类

```lua
Skill = Class()

function Skill:init(name, mana_cost, effect, cooldown)
    self.name = name
    self.mana_cost = mana_cost or 10
    self.effect = effect or function() end
    self.cooldown_max = cooldown or 0
    self.cooldown_current = 0
    self.description = ""
end

function Skill:canUse(caster)
    return caster.mana >= self.mana_cost and self.cooldown_current == 0
end

function Skill:use(caster, target)
    if not self:canUse(caster) then
        return false
    end
    
    caster:useMana(self.mana_cost)
    self.cooldown_current = self.cooldown_max
    
    -- 执行技能效果
    self.effect(caster, target)
    
    return true
end

function Skill:update()
    if self.cooldown_current > 0 then
        self.cooldown_current = self.cooldown_current - 1
    end
end

-- 创建具体技能
function createFireballSkill()
    return Skill:new("Fireball", 15, function(caster, target)
        local damage = 30
        engine:log(caster.name .. " casts Fireball!")
        target:damage(damage)
    end, 3)
end

function createHealSkill()
    return Skill:new("Heal", 10, function(caster, target)
        local amount = 25
        engine:log(caster.name .. " casts Heal!")
        (target or caster):heal(amount)
    end, 2)
end
```

## 高级特性

### 1. 静态方法（类方法）

```lua
Player = Class()

-- 静态变量
Player.total_players = 0

-- 静态方法（不使用 self）
function Player.getPlayerCount()
    return Player.total_players
end

function Player:init(name)
    self.name = name
    Player.total_players = Player.total_players + 1
end

-- 使用
local p1 = Player:new("Alice")
local p2 = Player:new("Bob")
print(Player.getPlayerCount())  -- 输出: 2
```

### 2. 属性访问器（Getter/Setter）

```lua
Player = Class()

function Player:init(name)
    self._health = 100  -- 私有变量（约定用下划线）
end

-- Getter
function Player:getHealth()
    return self._health
end

-- Setter（带验证）
function Player:setHealth(value)
    if value < 0 then
        self._health = 0
    elseif value > 100 then
        self._health = 100
    else
        self._health = value
    end
end

-- 使用
local player = Player:new("Alice")
player:setHealth(150)  -- 会被限制为 100
print(player:getHealth())  -- 100
```

### 3. 操作符重载

```lua
Vector2D = Class()

function Vector2D:init(x, y)
    self.x = x or 0
    self.y = y or 0
end

-- 重载加法操作符
function Vector2D:__add(other)
    return Vector2D:new(self.x + other.x, self.y + other.y)
end

-- 重载字符串转换
function Vector2D:__tostring()
    return "Vector2D(" .. self.x .. ", " .. self.y .. ")"
end

-- 使用
local v1 = Vector2D:new(1, 2)
local v2 = Vector2D:new(3, 4)
local v3 = v1 + v2  -- 需要设置 metatable
print(v3)  -- Vector2D(4, 6)
```

## 与 C++ 的对比

### C++ 版本
```cpp
class Player {
private:
    int health;
    int mana;
    
public:
    Player(int h, int m) : health(h), mana(m) {}
    
    void damage(int amount) {
        health -= amount;
    }
    
    int getHealth() const {
        return health;
    }
};

// 使用
Player player(100, 50);
player.damage(20);
```

### Lua 版本
```lua
Player = Class()

function Player:init(health, mana)
    self.health = health
    self.mana = mana
end

function Player:damage(amount)
    self.health = self.health - amount
end

function Player:getHealth()
    return self.health
end

-- 使用
local player = Player:new(100, 50)
player:damage(20)
```

## 热更新与类系统

### 状态保持

```lua
-- 使用 or 操作符保持状态
GameState = GameState or {}
GameState.player = GameState.player or Player:new("Hero", 100)

-- 重载时更新类定义，但保持实例
function on_reload()
    -- 类定义已更新，但现有实例仍然有效
    engine:log("Player state preserved: " .. GameState.player:getStatus())
    
    -- 可以给现有实例添加新方法
    if not GameState.player.newMethod then
        GameState.player.newMethod = function(self)
            engine:log("New method added during reload!")
        end
    end
end
```

## 最佳实践

### 1. 命名约定
```lua
ClassName = Class()          -- 类名用 PascalCase
local instanceName = Class:new()  -- 实例用 camelCase
local _privateVar = 0        -- 私有变量用下划线前缀
```

### 2. 模块化
```lua
-- player.lua
local Player = Class()
-- ... Player 定义 ...
return Player

-- main.lua
local Player = require("player")
local player = Player:new("Hero")
```

### 3. 错误处理
```lua
function Player:damage(amount)
    assert(type(amount) == "number", "Damage must be a number")
    assert(amount >= 0, "Damage cannot be negative")
    
    self.health = self.health - amount
end
```

## 完整项目结构示例

```
scripts/
├── class_system.lua         # 类系统实现
├── classes/
│   ├── player.lua          # Player 类
│   ├── enemy.lua           # Enemy 类
│   ├── item.lua            # Item 类
│   └── skill.lua           # Skill 类
├── game_state.lua          # 游戏状态管理
└── main.lua                # 主游戏逻辑
```

## 运行示例

要运行带类系统的演示：

```bash
# 编译项目
cmake --build build_vs2022 --config Debug

# 修改 main.cpp 加载新脚本
engine.loadScript("scripts/game_with_classes.lua");

# 运行
.\build_vs2022\Debug\sol2_demo.exe
```

## 总结

Lua 的类系统虽然需要手动实现，但提供了极大的灵活性：

✅ **完整的 OOP 支持** - 封装、继承、多态
✅ **动态性强** - 运行时修改类和实例
✅ **热更新友好** - 数据和代码可以独立更新
✅ **轻量高效** - 基于 metatable 的实现非常快速

现在您的游戏数据和逻辑都在 Lua 中，可以充分利用热更新的优势进行快速迭代开发！

