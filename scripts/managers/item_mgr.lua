-- ItemMgr - Item Manager
-- Manages all items, loot drops, and item templates

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

ItemMgr = ItemMgr or Class()

function ItemMgr:init()
    self.items = {}  -- item_id -> Item instance
    self.next_item_id = 1
    
    -- Item templates (for creating new items)
    self.templates = {}
    
    -- Initialize item templates
    self:initTemplates()
    
    engine:log("ItemMgr initialized")
end

-- Initialize item templates
function ItemMgr:initTemplates()
    -- Potions
    self.templates["health_potion"] = {
        class = Potion,
        params = {"Health Potion", 30}
    }
    
    self.templates["mana_potion"] = {
        class = Potion,
        params = {"Mana Potion", 20}
    }
    
    self.templates["super_potion"] = {
        class = Potion,
        params = {"Super Potion", 100}
    }
    
    engine:log("ItemMgr: Loaded " .. self:getTemplateCount() .. " item templates")
end

-- Create item from template
function ItemMgr:createItem(template_name)
    local template = self.templates[template_name]
    if not template then
        engine:log_warning("ItemMgr: Template not found: " .. template_name)
        return nil
    end
    
    local item_id = self.next_item_id
    self.next_item_id = self.next_item_id + 1
    
    -- Create item instance using template
    local item = template.class:new(table.unpack(template.params))
    item.id = item_id
    item.template_name = template_name
    
    self.items[item_id] = item
    
    return item_id, item
end

-- Get item by ID
function ItemMgr:getItem(item_id)
    return self.items[item_id]
end

-- Remove item
function ItemMgr:removeItem(item_id)
    if self.items[item_id] then
        self.items[item_id] = nil
        return true
    end
    return false
end

-- Give item to player
function ItemMgr:giveItemToPlayer(player, template_name, count)
    count = count or 1
    
    for i = 1, count do
        local item_id, item = self:createItem(template_name)
        if item then
            player:addItem(item)
            engine:log("ItemMgr: Gave " .. item.name .. " to " .. player.name)
        end
    end
end

-- Get template count
function ItemMgr:getTemplateCount()
    local count = 0
    for _ in pairs(self.templates) do
        count = count + 1
    end
    return count
end

-- Get item count
function ItemMgr:getItemCount()
    local count = 0
    for _ in pairs(self.items) do
        count = count + 1
    end
    return count
end

-- Register custom template
function ItemMgr:registerTemplate(name, item_class, params)
    self.templates[name] = {
        class = item_class,
        params = params
    }
    engine:log("ItemMgr: Registered template: " .. name)
end

-- Cleanup
function ItemMgr:cleanup()
    engine:log("ItemMgr: Cleaning up " .. self:getItemCount() .. " items")
    self.items = {}
end

return ItemMgr

