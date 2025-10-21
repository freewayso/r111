-- Lua Class System Implementation
-- Provides OOP-like functionality in Lua

-- Base Class Factory
function Class(base)
    local class = {}
    local class_mt = { __index = class }
    
    -- Constructor
    function class:new(...)
        local instance = setmetatable({}, class_mt)
        if instance.init then
            instance:init(...)
        end
        return instance
    end
    
    -- Inheritance
    if base then
        setmetatable(class, { __index = base })
    end
    
    return class
end

-- Example: Player Class
Player = Class()

function Player:init(name, health, mana)
    self.name = name or "Unknown"
    self.health = health or 100
    self.max_health = health or 100
    self.mana = mana or 50
    self.max_mana = mana or 50
    self.level = 1
    self.experience = 0
    self.position = { x = 0, y = 0 }
    self.inventory = {}
    self.skills = {}
end

function Player:damage(amount)
    self.health = self.health - amount
    if self.health < 0 then
        self.health = 0
    end
    
    engine:log("Player took " .. amount .. " damage. Health: " .. self.health .. "/" .. self.max_health)
    
    if self.health <= 0 then
        self:onDeath()
    end
end

function Player:heal(amount)
    local old_health = self.health
    self.health = math.min(self.health + amount, self.max_health)
    local actual_heal = self.health - old_health
    
    engine:log("Player healed " .. actual_heal .. ". Health: " .. self.health .. "/" .. self.max_health)
end

function Player:useMana(amount)
    if self.mana >= amount then
        self.mana = self.mana - amount
        return true
    else
        engine:log_warning("Not enough mana!")
        return false
    end
end

function Player:restoreMana(amount)
    self.mana = math.min(self.mana + amount, self.max_mana)
end

function Player:gainExp(amount)
    self.experience = self.experience + amount
    engine:log("Gained " .. amount .. " EXP. Total: " .. self.experience)
    
    -- Level up check
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
    
    engine:log("========================================")
    engine:log("LEVEL UP! Now level " .. self.level)
    engine:log("========================================")
end

function Player:onDeath()
    engine:log_error("Player has died!")
end

function Player:getStatus()
    return string.format(
        "%s [Lv.%d] HP:%d/%d MP:%d/%d EXP:%d",
        self.name, self.level, 
        self.health, self.max_health,
        self.mana, self.max_mana,
        self.experience
    )
end

function Player:addItem(item)
    table.insert(self.inventory, item)
    engine:log("Added item: " .. item.name)
end

-- Example: Enemy Class
Enemy = Class()

function Enemy:init(name, health, damage, exp_reward)
    self.name = name or "Enemy"
    self.health = health or 30
    self.max_health = health or 30
    self.damage = damage or 5
    self.exp_reward = exp_reward or 10
    self.is_alive = true
end

function Enemy:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.is_alive = false
        self:onDeath()
    end
    return self.is_alive
end

function Enemy:attack(target)
    if self.is_alive then
        local damage = self.damage + math.random(-2, 2)
        engine:log(self.name .. " attacks for " .. damage .. " damage!")
        target:damage(damage)
    end
end

function Enemy:onDeath()
    engine:log(self.name .. " defeated!")
end

-- Example: Boss Enemy (Inheritance)
Boss = Class(Enemy)

function Boss:init(name, health, damage, exp_reward)
    Enemy.init(self, name, health, damage, exp_reward)
    self.phase = 1
    self.special_abilities = {}
end

function Boss:takeDamage(amount)
    local alive = Enemy.takeDamage(self, amount)
    
    -- Phase transition
    local health_percent = self.health / self.max_health
    if health_percent < 0.5 and self.phase == 1 then
        self.phase = 2
        engine:log("========================================")
        engine:log(self.name .. " enters PHASE 2!")
        engine:log("========================================")
        self.damage = self.damage * 1.5
    end
    
    return alive
end

-- Example: Item Class
Item = Class()

function Item:init(name, type, value)
    self.name = name or "Item"
    self.type = type or "misc"
    self.value = value or 0
end

function Item:use(target)
    engine:log("Using " .. self.name)
    return true
end

-- Potion (Inheritance from Item)
Potion = Class(Item)

function Potion:init(name, heal_amount)
    Item.init(self, name, "potion", heal_amount)
    self.heal_amount = heal_amount or 20
end

function Potion:use(target)
    engine:log("Using " .. self.name .. "!")
    target:heal(self.heal_amount)
    return true
end

-- Skill Class
Skill = Class()

function Skill:init(name, mana_cost, damage, description)
    self.name = name or "Skill"
    self.mana_cost = mana_cost or 10
    self.damage = damage or 20
    self.description = description or "A skill"
    self.cooldown = 0
end

function Skill:canUse(caster)
    return caster.mana >= self.mana_cost and self.cooldown == 0
end

function Skill:use(caster, target)
    if not self:canUse(caster) then
        engine:log_warning("Cannot use " .. self.name)
        return false
    end
    
    caster:useMana(self.mana_cost)
    engine:log(caster.name .. " uses " .. self.name .. "!")
    
    if target then
        target:takeDamage(self.damage)
    end
    
    self.cooldown = 3
    return true
end

function Skill:update()
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - 1
    end
end

return {
    Class = Class,
    Player = Player,
    Enemy = Enemy,
    Boss = Boss,
    Item = Item,
    Potion = Potion,
    Skill = Skill
}

