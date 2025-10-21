# Sol2 Hot Reload - Quick Start Guide

## Compilation Success! ✅

Your sol2 demo with hot reload feature has been successfully compiled!

## How to Run

```bash
# Method 1: Command line
.\build_vs2022\Debug\sol2_demo.exe

# Method 2: Visual Studio
# 1. Open build_vs2022\Sol2Demo.sln
# 2. Right-click 'sol2_demo' -> Set as Startup Project
# 3. Press F5
```

## Interactive Controls

While the program is running:

| Key | Action |
|-----|--------|
| **R** | Manually reload the Lua script |
| **A** | Toggle auto-reload mode ON/OFF |
| **Q** | Quit the program |

## How to Test Hot Reload

### Quick Test (Manual):

1. **Run the program**
   ```bash
   .\build_vs2022\Debug\sol2_demo.exe
   ```

2. **Open the script in an editor**
   - Open `scripts/demo.lua` in your favorite editor

3. **Make a change**
   - For example, find the `on_update()` function
   - Change the log message:
   ```lua
   function on_update()
       game_time = game_time + 1
       engine:log_message("Game Time: " .. game_time .. " seconds")
       engine:log_message("HOT RELOAD WORKS!") -- Add this line
   end
   ```

4. **Save the file**

5. **Press 'R' in the program window**

6. **See your changes immediately!** 🎉

### Automatic Mode:

1. Run the program
2. Press **'A'** to enable auto-reload
3. Edit `scripts/demo.lua` and save
4. Changes are detected and applied automatically!

## Features Implemented

### C++ Side (GameEngine class):

```cpp
// Hot reload functions
void reloadScript();                    // Manually reload the current script
void checkAndReload();                  // Check if modified and reload
void enableAutoReload(bool enable);     // Enable/disable auto-reload
bool isScriptModified() const;          // Check if script file changed
```

### Lua Side:

```lua
-- Called when script is hot-reloaded
function on_reload()
    reload_count = reload_count + 1
    print("Script reloaded " .. reload_count .. " times!")
end

-- Preserve values across reloads
my_value = my_value or 100  -- Will keep value after reload
```

## Example Modifications to Try

### 1. Change Messages

**Original:**
```lua
function on_update()
    game_time = game_time + 1
    engine:log_message("Update #" .. game_time)
end
```

**Modified:**
```lua
function on_update()
    game_time = game_time + 1
    engine:log_message("=== Frame " .. game_time .. " ===")
    engine:log_message("All systems operational!")
end
```

### 2. Add New Logic

```lua
function on_update()
    game_time = game_time + 1
    
    -- New feature: Health check
    local health = engine:get_player_health()
    if health < 50 then
        engine:log_message("WARNING: Low health!")
    end
    
    -- New feature: Time-based events
    if game_time % 5 == 0 then
        engine:log_message("5 second checkpoint!")
    end
end
```

### 3. Dynamic Configuration

```lua
-- Add at the top of demo.lua
CONFIG = CONFIG or {
    show_debug = true,
    update_interval = 1.0
}

function on_update()
    if CONFIG.show_debug then
        engine:log_message("Debug mode ON")
    end
end

-- Modify CONFIG and reload to see changes!
```

## Advanced: Preserving State

Use the `or` operator to preserve values across reloads:

```lua
-- This will reset to 0 on every reload
player_score = 0

-- This will preserve the value
player_score = player_score or 0

-- For tables
game_state = game_state or {
    level = 1,
    score = 0,
    lives = 3
}
```

## Troubleshooting

### Script doesn't reload?
- Make sure the file is actually saved
- Check console for error messages
- Try manual reload (press 'R')

### Syntax error after reload?
- Check the console output for Lua error messages
- The old script version will continue running
- Fix the error and reload again

### Changes not visible?
- Make sure you're modifying the correct file
- Check if the change is in a function that's actually called
- Try adding a print statement in `on_reload()` to confirm reload

## File Structure

```
sol2_demo/
├── build_vs2022/
│   └── Debug/
│       ├── sol2_demo.exe     ← Run this
│       ├── lua54.dll
│       └── scripts/
│           └── demo.lua      ← Or edit this (it's a copy)
├── scripts/
│   └── demo.lua              ← Edit this (original)
└── src/
    ├── main.cpp
    ├── game_engine.cpp
    └── game_engine.hpp
```

**Note:** The program loads from `scripts/demo.lua` by default.

## Performance Notes

- File checking is very fast (< 1ms)
- Script reload typically takes 2-10ms
- Recommended for development, can be disabled for release

## Next Steps

1. **Try it now!** Run the program and press 'R' or 'A'
2. **Experiment** with different Lua code changes
3. **Build your game logic** entirely in Lua
4. **Iterate quickly** without recompiling C++!

## Code Integration

To use hot reload in your own code:

```cpp
GameEngine engine;
engine.loadScript("your_script.lua");

// Enable auto-reload
engine.enableAutoReload(true);

while (gameRunning) {
    engine.update();  // Automatically checks and reloads if enabled
    
    // Or manually check
    if (userPressedReloadKey) {
        engine.reloadScript();
    }
}
```

---

**Enjoy hot reloading with sol2!** 🔥

For more details, see `热更新使用指南.md` (Chinese version with more examples)

