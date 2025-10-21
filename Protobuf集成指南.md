# Protobuf 集成指南

## 为什么使用 Protobuf？

Protobuf (Protocol Buffers) 是 Google 开发的序列化协议，在游戏服务器中广泛使用：

### 优势

✅ **性能优秀** - 比 JSON/XML 快 3-10 倍
✅ **体积小** - 二进制格式，比文本格式小 50-70%
✅ **类型安全** - 强类型检查，减少错误
✅ **向后兼容** - 支持协议演进
✅ **跨语言** - C++, Lua, Python, Go 等都支持
✅ **IDL定义** - 清晰的数据结构定义

## 架构设计

```
Lua (Game Logic)
  ↓ 调用 C++ 函数
C++ (System Layer)
  ↓ Protobuf 序列化
Binary Data (文件/网络)
  ↓ Protobuf 反序列化
C++ (System Layer)
  ↓ 返回 Lua Table
Lua (Game Logic)
```

## 安装 Protobuf

### Windows (使用 vcpkg)

```powershell
# 安装 protobuf
vcpkg install protobuf:x64-windows

# 如果还没有 vcpkg，先安装它
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

### Linux

```bash
# Ubuntu/Debian
sudo apt-get install protobuf-compiler libprotobuf-dev

# CentOS/RHEL
sudo yum install protobuf protobuf-devel
```

## 项目结构

```
sol2_demo/
├── proto/
│   └── game_data.proto          # Protobuf 定义文件
├── src/
│   ├── game_engine.hpp           # C++ 接口定义
│   ├── game_engine.cpp           # Protobuf 实现
│   └── main.cpp
├── scripts/
│   └── protobuf_demo.lua         # Lua 调用示例
└── CMakeLists.txt                # 构建配置
```

## Proto 文件定义

### 基本语法

```protobuf
syntax = "proto3";

package game;

// Player data structure
message PlayerData {
    int32 id = 1;                  // 字段编号（不可改变）
    string name = 2;
    int32 level = 3;
    
    // 嵌套消息
    message Position {
        float x = 1;
        float y = 2;
        float z = 3;
    }
    Position position = 10;
    
    // 数组
    repeated string inventory = 11;
}
```

### 字段类型

| Proto 类型 | C++ 类型 | Lua 类型 | 说明 |
|-----------|---------|---------|------|
| int32 | int32 | number | 32位整数 |
| int64 | int64 | number | 64位整数 |
| float | float | number | 浮点数 |
| double | double | number | 双精度 |
| bool | bool | boolean | 布尔值 |
| string | std::string | string | 字符串 |
| bytes | std::string | string | 二进制数据 |
| repeated | vector | table | 数组 |

### 完整的游戏数据定义

参见 `proto/game_data.proto`:

```protobuf
// Player data
message PlayerData {
    int32 id = 1;
    string name = 2;
    int32 level = 3;
    int32 health = 4;
    // ... more fields
}

// Mail data
message MailData {
    int32 id = 1;
    string sender = 2;
    string title = 3;
    string content = 4;
    
    message Rewards {
        int32 gold = 1;
        int32 exp = 2;
        repeated string items = 3;
    }
    Rewards rewards = 5;
}
```

## C++ 实现

### 序列化（Lua Table -> Protobuf Binary）

```cpp
std::string GameEngine::serializePlayerToPB(const sol::table& player_data) {
    game::PlayerData pb_player;
    
    // 从 Lua table 读取数据
    pb_player.set_id(player_data["id"].get_or(0));
    pb_player.set_name(player_data["name"].get_or(std::string("Unknown")));
    pb_player.set_level(player_data["level"].get_or(1));
    
    // 处理嵌套对象
    sol::optional<sol::table> pos_opt = player_data["position"];
    if (pos_opt) {
        sol::table pos = *pos_opt;
        auto* pb_pos = pb_player.mutable_position();
        pb_pos->set_x(pos["x"].get_or(0.0f));
        pb_pos->set_y(pos["y"].get_or(0.0f));
    }
    
    // 序列化为二进制
    std::string output;
    pb_player.SerializeToString(&output);
    
    return output;
}
```

### 反序列化（Protobuf Binary -> Lua Table）

```cpp
sol::table GameEngine::deserializePlayerFromPB(const std::string& pb_data) {
    game::PlayerData pb_player;
    
    // 解析二进制数据
    if (!pb_player.ParseFromString(pb_data)) {
        return lua.create_table();  // 返回空表
    }
    
    // 转换为 Lua table
    sol::table player = lua.create_table();
    player["id"] = pb_player.id();
    player["name"] = pb_player.name();
    player["level"] = pb_player.level();
    
    // 处理嵌套对象
    if (pb_player.has_position()) {
        sol::table pos = lua.create_table();
        pos["x"] = pb_player.position().x();
        pos["y"] = pb_player.position().y();
        player["position"] = pos;
    }
    
    return player;
}
```

## Lua 使用方法

### 基本序列化

```lua
-- Lua 端的数据
local player = {
    id = 1001,
    name = "Hero",
    level = 10,
    health = 100,
    position = {x = 10.5, y = 20.0, z = 0.0}
}

-- 调用 C++ 序列化
local pb_data = engine:serialize_player_pb(player)
print("Serialized to " .. #pb_data .. " bytes")

-- 调用 C++ 反序列化
local restored = engine:deserialize_player_pb(pb_data)
print("Name: " .. restored.name)
print("Level: " .. restored.level)
```

### 保存/加载

```lua
-- 保存玩家数据（Protobuf 格式）
local success = engine:save_player_pb(player.id, player)
if success then
    print("Player saved!")
end

-- 加载玩家数据
local loaded_player = engine:load_player_pb(player.id)
if loaded_player.id then
    print("Loaded: " .. loaded_player.name)
end
```

### Manager 集成

在 PlayerMgr 中使用：

```lua
-- player_mgr.lua
function PlayerMgr:savePlayer(player_id)
    local player = self.players[player_id]
    if player then
        -- 准备数据
        local player_data = {
            id = player.id,
            name = player.name,
            level = player.level,
            health = player.health,
            max_health = player.max_health,
            -- ... 其他字段
        }
        
        -- 调用 C++ Protobuf 保存
        local success = engine:save_player_pb(player_id, player_data)
        return success
    end
    return false
end

function PlayerMgr:loadPlayer(player_id)
    -- 调用 C++ Protobuf 加载
    local player_data = engine:load_player_pb(player_id)
    
    if player_data.id then
        -- 创建 Player 实例
        local player = Player:new(player_data.name, player_data.max_health)
        player.id = player_data.id
        player.level = player_data.level
        player.health = player_data.health
        player.experience = player_data.experience
        
        self.players[player_id] = player
        return player
    end
    
    return nil
end
```

## 编译项目

### 1. 生成 CMake 项目

```bash
# Windows (使用 vcpkg)
cmake -S . -B build_vs2022 -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_TOOLCHAIN_FILE=[vcpkg路径]/scripts/buildsystems/vcpkg.cmake

# Linux
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

### 2. 编译

```bash
# Windows
cmake --build build_vs2022 --config Debug

# Linux
cmake --build build
```

### 3. 运行

```bash
# Windows
.\build_vs2022\Debug\sol2_demo.exe

# 选择选项 5: Protobuf Integration

# Linux
./build/sol2_demo
```

## 性能对比

### 测试数据

```lua
player = {
    id = 1001,
    name = "TestPlayer",
    level = 50,
    health = 500,
    max_health = 500,
    mana = 300,
    max_mana = 300,
    experience = 25000,
    gold = 10000,
    position = {x = 100.5, y = 200.75, z = 50.0}
}
```

### 序列化大小

| 格式 | 大小 | 压缩率 |
|------|------|-------|
| Protobuf (Binary) | ~60 bytes | - |
| JSON (Text) | ~180 bytes | -67% |
| Lua table.concat | ~200 bytes | -70% |

### 序列化速度

| 操作 | Protobuf | JSON |
|------|----------|------|
| 序列化 | ~0.5μs | ~2.0μs |
| 反序列化 | ~0.8μs | ~3.0μs |
| 总计 | **~1.3μs** | ~5.0μs |

**Protobuf 约快 4 倍**

## 常见 API

### C++ 端（已注册到 Lua）

```cpp
// Player
engine:serialize_player_pb(player_table) -> binary_string
engine:deserialize_player_pb(binary_string) -> player_table
engine:save_player_pb(player_id, player_table) -> bool
engine:load_player_pb(player_id) -> player_table

// Mail
engine:serialize_mail_pb(mail_table) -> binary_string
engine:deserialize_mail_pb(binary_string) -> mail_table
engine:save_mail_pb(player_id, mail_table) -> bool
engine:load_mail_pb(player_id) -> mail_table
```

### Lua 端使用

```lua
-- 直接序列化/反序列化
local binary = engine:serialize_player_pb(player)
local player = engine:deserialize_player_pb(binary)

-- 保存/加载（内部自动序列化）
engine:save_player_pb(1001, player)
local player = engine:load_player_pb(1001)
```

## 扩展新消息类型

### 1. 在 proto 文件中定义

```protobuf
// proto/game_data.proto
message InventoryData {
    int32 player_id = 1;
    
    message Item {
        string template_name = 1;
        int32 count = 2;
        int32 level = 3;
    }
    
    repeated Item items = 2;
}
```

### 2. 在 C++ 中实现

```cpp
// game_engine.hpp
std::string serializeInventoryToPB(const sol::table& inventory_data);
sol::table deserializeInventoryFromPB(const std::string& pb_data);

// game_engine.cpp
std::string GameEngine::serializeInventoryToPB(const sol::table& inventory_data) {
    game::InventoryData pb_inv;
    
    pb_inv.set_player_id(inventory_data["player_id"].get_or(0));
    
    // 处理 items 数组
    sol::optional<sol::table> items_opt = inventory_data["items"];
    if (items_opt) {
        sol::table items = *items_opt;
        for (auto& pair : items) {
            sol::table item = pair.second.as<sol::table>();
            auto* pb_item = pb_inv.add_items();
            pb_item->set_template_name(item["template_name"].get_or(std::string("")));
            pb_item->set_count(item["count"].get_or(1));
            pb_item->set_level(item["level"].get_or(1));
        }
    }
    
    std::string output;
    pb_inv.SerializeToString(&output);
    return output;
}
```

### 3. 注册到 Lua

```cpp
lua.new_usertype<GameEngine>("GameEngine",
    // ... existing functions ...
    "serialize_inventory_pb", &GameEngine::serializeInventoryToPB,
    "deserialize_inventory_pb", &GameEngine::deserializeInventoryFromPB
);
```

### 4. 在 Lua 中使用

```lua
local inventory = {
    player_id = 1001,
    items = {
        {template_name = "sword_001", count = 1, level = 5},
        {template_name = "potion_hp", count = 10, level = 1}
    }
}

local pb_data = engine:serialize_inventory_pb(inventory)
local restored = engine:deserialize_inventory_pb(pb_data)
```

## 最佳实践

### 1. 协议版本管理

```protobuf
message GameState {
    int32 version = 1;  // 总是第一个字段
    int64 timestamp = 2;
    
    // ... 其他字段
}
```

### 2. 向后兼容

```protobuf
message PlayerData {
    int32 id = 1;
    string name = 2;
    
    // ✓ 可以添加新字段（旧版本会忽略）
    int32 vip_level = 100;
    
    // ✗ 不要删除或改变已有字段的编号
}
```

### 3. 使用 Reserved

```protobuf
message PlayerData {
    reserved 10, 11, 12;  // 保留字段编号
    reserved "old_field"; // 保留字段名
    
    int32 id = 1;
    // ... 其他字段
}
```

### 4. 错误处理

```lua
function savePlayerSafe(player_id, player_data)
    local success, err = pcall(function()
        return engine:save_player_pb(player_id, player_data)
    end)
    
    if not success then
        engine:log_error("Save failed: " .. tostring(err))
        return false
    end
    
    return err
end
```

## 故障排查

### 问题 1: Protobuf not found

```
CMake Warning: Protobuf not found
```

**解决：**
```bash
vcpkg install protobuf:x64-windows
```

### 问题 2: 编译错误 game_data.pb.h not found

**原因：** Proto 文件未生成

**解决：** 确保 CMakeLists.txt 中有：
```cmake
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILES})
```

### 问题 3: Lua 调用失败

**检查：**
```lua
if engine.serialize_player_pb then
    print("Protobuf available")
else
    print("Protobuf NOT available - rebuild with protobuf")
end
```

## 总结

✅ **C++ 负责** - 文件IO、序列化、网络
✅ **Lua 负责** - 游戏逻辑、数据管理
✅ **Protobuf 负责** - 高效数据传输

这种架构充分发挥了各自的优势：
- C++ 的性能
- Lua 的灵活性
- Protobuf 的效率

完美的游戏服务器架构！🎮

