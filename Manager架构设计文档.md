# Manager 架构设计文档

## 架构概述

本项目采用标准的游戏服务器架构模式，将游戏系统分为：
- **实体层（Entity Layer）** - 游戏对象类（Player, Enemy, Item等）
- **管理层（Manager Layer）** - 实体管理器（PlayerMgr, EnemyMgr等）
- **系统层（System Layer）** - 全局游戏管理器（GameMgr）

```
GameMgr (全局系统)
  ├── PlayerMgr  (玩家管理器)
  │     └── Player实例集合
  ├── ItemMgr    (物品管理器)
  │     └── Item实例集合
  ├── EnemyMgr   (敌人管理器)
  │     └── Enemy实例集合
  └── MailMgr    (邮件管理器)
        └── Mail实例集合
```

## 设计原则

### 1. 职责分离（Separation of Concerns）

**实体类（Entity）：**
- 只负责自身的数据和行为
- 不关心其他实体
- 不处理全局逻辑

```lua
Player = Class()

function Player:init(name, health)
    self.name = name
    self.health = health
end

function Player:damage(amount)
    self.health = self.health - amount
    -- 只处理自己的逻辑
end
```

**管理器类（Manager）：**
- 负责同类实体的创建、删除、查询
- 处理该类实体的集中逻辑
- 提供统一的接口给其他系统

```lua
PlayerMgr = Class()

function PlayerMgr:init()
    self.players = {}  -- 管理所有玩家
end

function PlayerMgr:createPlayer(name)
    local player = Player:new(name)
    self.players[player.id] = player
    return player
end
```

**全局系统（GameMgr）：**
- 统一管理所有管理器
- 协调各个子系统间的交互
- 处理全局游戏逻辑

```lua
GameMgr = Class()

function GameMgr:init()
    self.player_mgr = PlayerMgr:new()
    self.enemy_mgr = EnemyMgr:new()
    -- ...
end

function GameMgr:update()
    -- 协调各系统
    self.player_mgr:update()
    self.enemy_mgr:update()
end
```

### 2. 单一入口（Single Entry Point）

所有游戏逻辑通过 GameMgr 统一入口：

```lua
-- 全局访问
g_GameMgr = GameMgr:new()

-- 获取子系统
local player_mgr = g_GameMgr.player_mgr
local enemy_mgr = g_GameMgr.enemy_mgr
```

### 3. 数据驱动（Data Driven）

使用模板（Template）系统：

```lua
-- ItemMgr 中定义模板
self.templates["health_potion"] = {
    class = Potion,
    params = {"Health Potion", 30}
}

-- 从模板创建实例
local item = item_mgr:createItem("health_potion")
```

## 各Manager详解

### PlayerMgr - 玩家管理器

**职责：**
- 玩家的创建、删除、查询
- 主玩家管理
- 玩家数据的保存/加载
- 玩家的定时更新（被动恢复等）

**核心接口：**
```lua
-- 创建玩家
player_id, player = PlayerMgr:createPlayer(name, health, mana)

-- 获取玩家
player = PlayerMgr:getPlayer(player_id)

-- 设置主玩家
PlayerMgr:setMainPlayer(player_id)

-- 获取主玩家
player = PlayerMgr:getMainPlayer()

-- 更新所有玩家
PlayerMgr:update(dt)

-- 保存/加载
data = PlayerMgr:saveData()
PlayerMgr:loadData(data)
```

**使用示例：**
```lua
-- 创建玩家
local player_id, player = g_GameMgr.player_mgr:createPlayer("Hero", 100, 50)
g_GameMgr.player_mgr:setMainPlayer(player_id)

-- 获取主玩家
local main_player = g_GameMgr.player_mgr:getMainPlayer()
main_player:damage(10)
```

### ItemMgr - 物品管理器

**职责：**
- 物品模板管理
- 物品实例创建
- 物品的赠送、使用
- 掉落系统（可扩展）

**核心接口：**
```lua
-- 从模板创建物品
item_id, item = ItemMgr:createItem(template_name)

-- 给玩家物品
ItemMgr:giveItemToPlayer(player, template_name, count)

-- 注册新模板
ItemMgr:registerTemplate(name, item_class, params)
```

**使用示例：**
```lua
-- 给玩家3个生命药水
g_GameMgr.item_mgr:giveItemToPlayer(player, "health_potion", 3)

-- 注册新物品模板
g_GameMgr.item_mgr:registerTemplate("super_sword", Weapon, {"Excalibur", 100, 999})
```

### EnemyMgr - 敌人管理器

**职责：**
- 敌人模板管理
- 敌人生成（spawning）
- 敌人AI调度
- 波次管理
- 死亡清理

**核心接口：**
```lua
-- 生成敌人
enemy_id, enemy = EnemyMgr:spawnEnemy(template_name)

-- 生成随机敌人
EnemyMgr:spawnRandomEnemy()

-- 生成Boss
EnemyMgr:spawnBoss()

-- 获取存活敌人
enemies = EnemyMgr:getAliveEnemies()

-- AI处理
EnemyMgr:processAI(target_player)

-- 配置生成
EnemyMgr:setSpawnConfig({
    interval = 3,
    max_enemies = 5
})
```

**使用示例：**
```lua
-- 生成3个敌人
for i = 1, 3 do
    g_GameMgr.enemy_mgr:spawnRandomEnemy()
end

-- 让所有敌人攻击玩家
local player = g_GameMgr.player_mgr:getMainPlayer()
g_GameMgr.enemy_mgr:processAI(player)
```

### MailMgr - 邮件管理器

**职责：**
- 邮件的发送、接收
- 邮件奖励管理
- 已读/未读状态
- 过期清理

**核心接口：**
```lua
-- 发送邮件
mail_id = MailMgr:sendMail(player_id, sender, title, content, rewards)

-- 发送给所有人
MailMgr:sendMailToAll(sender, title, content, rewards)

-- 读取邮件
mail = MailMgr:readMail(player_id, mail_id)

-- 领取奖励
success = MailMgr:claimRewards(player_id, mail_id, player)

-- 获取未读数量
count = MailMgr:getUnreadCount(player_id)

-- 清理过期邮件
MailMgr:cleanExpiredMails(player_id)
```

**使用示例：**
```lua
-- 发送欢迎邮件
local player = g_GameMgr.player_mgr:getMainPlayer()
g_GameMgr.mail_mgr:sendMail(
    player.id,
    "System",
    "Welcome!",
    "Thank you for playing!",
    { gold = 100, items = {"health_potion"} }
)

-- 显示未读邮件数量
local unread = g_GameMgr.mail_mgr:getUnreadCount(player.id)
print("You have " .. unread .. " unread mails")
```

## GameMgr - 全局游戏管理器

**职责：**
- 统一管理所有子管理器
- 游戏生命周期管理
- 游戏循环和更新
- 全局事件处理
- 游戏逻辑协调

**核心接口：**
```lua
-- 初始化
GameMgr:init()

-- 开始新游戏
GameMgr:newGame()

-- 主更新
GameMgr:update(dt)

-- 暂停/恢复
GameMgr:pause()
GameMgr:resume()

-- 保存/加载
data = GameMgr:saveData()
GameMgr:loadData(data)

-- 获取子管理器
mgr = GameMgr:getMgr(name)

-- 清理
GameMgr:cleanup()
```

**使用示例：**
```lua
-- 初始化游戏
g_GameMgr = GameMgr:new()
g_GameMgr:newGame()

-- 游戏主循环
while game_running do
    g_GameMgr:update(delta_time)
end

-- 清理
g_GameMgr:cleanup()
```

## 文件组织结构

```
scripts/
├── class_system.lua              # 类系统基础
├── game_with_managers.lua        # 主游戏入口
└── managers/                     # 管理器目录
    ├── game_mgr.lua              # 全局游戏管理器
    ├── player_mgr.lua            # 玩家管理器
    ├── item_mgr.lua              # 物品管理器
    ├── enemy_mgr.lua             # 敌人管理器
    └── mail_mgr.lua              # 邮件管理器
```

## 热更新支持

### 数据保持

使用 `or` 操作符保持管理器实例：

```lua
-- 全局管理器（热更新时保留）
g_GameMgr = g_GameMgr or nil

function on_init()
    if not g_GameMgr then
        g_GameMgr = GameMgr:new()
        g_GameMgr:newGame()
    end
end

function on_reload()
    -- 管理器实例保留，但方法已更新
    -- 可以立即看到逻辑修改的效果
end
```

### 方法更新

热更新会立即更新所有管理器的方法：

```lua
-- 修改前
function PlayerMgr:update(dt)
    -- 旧逻辑
end

-- 保存，按R热更新

-- 修改后的新逻辑立即生效
function PlayerMgr:update(dt)
    -- 新逻辑（热更新后立即使用这个版本）
end
```

## 扩展新Manager

添加新的管理器非常简单：

### 1. 创建Manager类

```lua
-- scripts/managers/skill_mgr.lua
SkillMgr = Class()

function SkillMgr:init()
    self.skills = {}
    engine:log("SkillMgr initialized")
end

function SkillMgr:createSkill(name, data)
    local skill = Skill:new(name, data)
    self.skills[skill.id] = skill
    return skill
end

return SkillMgr
```

### 2. 在GameMgr中注册

```lua
-- game_mgr.lua
require("managers/skill_mgr")

function GameMgr:init()
    -- ... 其他管理器 ...
    self.skill_mgr = self.skill_mgr or SkillMgr:new()
end
```

### 3. 使用新Manager

```lua
local skill = g_GameMgr.skill_mgr:createSkill("Fireball", {damage = 50})
```

## 最佳实践

### 1. 管理器命名规范

- 类名使用 `XxxMgr` 格式
- 文件名使用 `xxx_mgr.lua` 格式
- 实例变量使用 `xxx_mgr` 格式

### 2. ID管理

每个Manager维护自己的ID序列：

```lua
function XxxMgr:init()
    self.objects = {}
    self.next_id = 1  -- 自增ID
end

function XxxMgr:create()
    local id = self.next_id
    self.next_id = self.next_id + 1
    -- ...
end
```

### 3. 生命周期管理

每个Manager都应实现：
- `init()` - 初始化
- `update(dt)` - 更新
- `cleanup()` - 清理

### 4. 数据持久化

支持保存/加载的Manager应实现：
- `saveData()` - 导出数据
- `loadData(data)` - 导入数据

### 5. 错误处理

```lua
function XxxMgr:getObject(id)
    if not self.objects[id] then
        engine:log_warning("Object not found: " .. id)
        return nil
    end
    return self.objects[id]
end
```

## 调试命令

在热更新时可以使用的调试命令：

```lua
-- 显示帮助
help()

-- 玩家相关
debugGiveExp(100)
debugGiveGold(500)

-- 敌人相关
debugSpawnEnemy(3)
debugClearEnemies()

-- 邮件相关
debugSendMail()
debugShowMails()
debugReadMail(1)
debugClaimMail(1)

-- 游戏控制
debugPause()
debugResume()
```

## 运行示例

```bash
# 编译项目
cmake --build build_vs2022 --config Debug

# 运行程序
.\build_vs2022\Debug\sol2_demo.exe

# 选择选项 3: Manager Architecture
# 
# 游戏运行后，可以：
# 1. 修改任何 Manager 的逻辑
# 2. 保存文件
# 3. 按 'R' 热更新
# 4. 立即看到效果（数据保持不变）
```

## 优势总结

✅ **模块化** - 每个Manager职责清晰
✅ **可扩展** - 轻松添加新Manager
✅ **可维护** - 代码组织清晰
✅ **热更新友好** - 数据和逻辑分离
✅ **团队协作** - 不同人可以独立开发不同Manager
✅ **性能优化** - 集中管理便于优化
✅ **数据驱动** - 通过模板系统配置内容

这种架构被广泛应用于：
- MMO游戏服务器
- 大型单机游戏
- 手机游戏后端
- 实时策略游戏

现在您有了一个完整、专业的Manager架构，可以快速开发复杂的游戏系统！🎮

