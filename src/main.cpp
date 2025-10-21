#include "game_engine.hpp"
#include <iostream>
#include <thread>
#include <chrono>
#include <conio.h>  // Windows platform for keyboard detection

int main() {
    try {
        std::cout << "==================================" << std::endl;
        std::cout << "Sol2 Demo - Hot Reload Demo" << std::endl;
        std::cout << "==================================" << std::endl;
        
        // Select demo script
        std::cout << "\nSelect demo:" << std::endl;
        std::cout << "  1. Basic demo (simple functions)" << std::endl;
        std::cout << "  2. OOP demo (class-based game)" << std::endl;
        std::cout << "  3. Manager Architecture (recommended)" << std::endl;
        std::cout << "  4. C++ System Services (save/load/network)" << std::endl;
        #ifdef USE_PROTOBUF
        std::cout << "  5. Protobuf Integration (Lua <-> C++ Protobuf)" << std::endl;
        #endif
        std::cout << "\nEnter choice (1-5, default=3): ";
        
        std::string choice;
        std::getline(std::cin, choice);
        
        std::string script_path;
        if (choice == "1") {
            script_path = "scripts/demo.lua";
        } else if (choice == "2") {
            script_path = "scripts/game_with_classes.lua";
        } else if (choice == "4") {
            script_path = "scripts/cpp_services_demo.lua";
        }
        #ifdef USE_PROTOBUF
        else if (choice == "5") {
            script_path = "scripts/protobuf_demo.lua";
        }
        #endif
        else {
            script_path = "scripts/game_with_managers.lua";
        }
        
        std::cout << "\nControls:" << std::endl;
        std::cout << "  - Press 'R' to manually reload script" << std::endl;
        std::cout << "  - Press 'A' to toggle auto-reload" << std::endl;
        std::cout << "  - Press 'Q' to quit" << std::endl;
        std::cout << "\nModify " << script_path << " to see real-time changes!\n" << std::endl;
        
        GameEngine engine;
        bool auto_reload = false;
        
        // Load selected Lua script
        engine.loadScript(script_path);
        
        // Enable auto hot-reload
        engine.enableAutoReload(auto_reload);
        
        // Call Lua initialization function
        engine.callLuaFunction("on_init");
        
        // Game loop
        int frame_count = 0;
        bool running = true;
        
        while (running) {
            // Check keyboard input (non-blocking)
            if (_kbhit()) {
                char key = _getch();
                key = std::toupper(key);
                
                if (key == 'Q') {
                    std::cout << "\nExiting program..." << std::endl;
                    running = false;
                } else if (key == 'R') {
                    std::cout << "\n[Manual Trigger] ";
                    engine.reloadScript();
                } else if (key == 'A') {
                    auto_reload = !auto_reload;
                    engine.enableAutoReload(auto_reload);
                }
            }
            
            // Update game logic
            std::cout << "\n--- Frame " << (++frame_count) << " ---" << std::endl;
            engine.update();
            
            // Frame rate limiter
            std::this_thread::sleep_for(std::chrono::seconds(2));
            
            // Demo mode: auto-exit after 10 frames (comment out to run indefinitely)
            // if (frame_count >= 10) running = false;
        }
        
        // Call Lua cleanup function
        engine.callLuaFunction("on_cleanup");
        
        std::cout << "\nProgram finished!" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}




