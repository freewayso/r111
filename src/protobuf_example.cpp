// C++ Protobuf Save/Load Example
// Shows how to use Protobuf directly in C++ without Lua

#ifdef USE_PROTOBUF

#include "game_engine.hpp"
#include "game_data.pb.h"
#include <iostream>

// Example: Save player data in C++
void exampleSavePlayerInCpp(GameEngine& engine) {
    std::cout << "\n========== C++ Protobuf Save Example ==========" << std::endl;
    
    // Method 1: Use helper function
    bool success = engine.savePlayerDataCpp(
        1001,           // player_id
        "CppHero",      // name
        15,             // level
        120,            // health
        80,             // mana
        2500,           // experience
        1000            // gold
    );
    
    if (success) {
        std::cout << "[C++] Player saved successfully!" << std::endl;
    }
    
    // Method 2: Direct Protobuf manipulation
    game::PlayerData player;
    player.set_id(1002);
    player.set_name("DirectPlayer");
    player.set_level(20);
    player.set_health(150);
    player.set_max_health(150);
    player.set_mana(100);
    player.set_max_mana(100);
    player.set_experience(5000);
    player.set_gold(2000);
    
    // Set position
    auto* position = player.mutable_position();
    position->set_x(100.5f);
    position->set_y(200.0f);
    position->set_z(50.0f);
    
    // Add inventory items
    player.add_inventory("sword_001");
    player.add_inventory("potion_hp");
    player.add_inventory("armor_001");
    
    // Set equipment
    auto* equipment = player.mutable_equipment();
    equipment->set_weapon("legendary_sword");
    equipment->set_armor("dragon_armor");
    
    // Save using generic template
    success = engine.saveProtobufMessage("player_1002.dat", player);
    
    if (success) {
        std::cout << "[C++] Player 1002 saved with full details!" << std::endl;
    }
}

// Example: Load player data in C++
void exampleLoadPlayerInCpp(GameEngine& engine) {
    std::cout << "\n========== C++ Protobuf Load Example ==========" << std::endl;
    
    // Method 1: Use helper function
    std::string name;
    int level, health;
    
    bool success = engine.loadPlayerDataCpp(1001, name, level, health);
    
    if (success) {
        std::cout << "[C++] Loaded player:" << std::endl;
        std::cout << "  Name: " << name << std::endl;
        std::cout << "  Level: " << level << std::endl;
        std::cout << "  Health: " << health << std::endl;
    }
    
    // Method 2: Direct Protobuf loading
    game::PlayerData player;
    success = engine.loadProtobufMessage("player_1002.dat", player);
    
    if (success) {
        std::cout << "[C++] Loaded player 1002:" << std::endl;
        std::cout << "  Name: " << player.name() << std::endl;
        std::cout << "  Level: " << player.level() << std::endl;
        std::cout << "  Gold: " << player.gold() << std::endl;
        
        // Access position
        if (player.has_position()) {
            std::cout << "  Position: (" 
                      << player.position().x() << ", "
                      << player.position().y() << ", "
                      << player.position().z() << ")" << std::endl;
        }
        
        // Access inventory
        std::cout << "  Inventory (" << player.inventory_size() << " items):" << std::endl;
        for (int i = 0; i < player.inventory_size(); ++i) {
            std::cout << "    - " << player.inventory(i) << std::endl;
        }
        
        // Access equipment
        if (player.has_equipment()) {
            std::cout << "  Equipment:" << std::endl;
            std::cout << "    Weapon: " << player.equipment().weapon() << std::endl;
            std::cout << "    Armor: " << player.equipment().armor() << std::endl;
        }
    }
}

// Example: Save mail in C++
void exampleSaveMailInCpp(GameEngine& engine) {
    std::cout << "\n========== C++ Mail Save Example ==========" << std::endl;
    
    // Use helper function
    bool success = engine.saveMailDataCpp(
        1001,               // player_id
        501,                // mail_id
        "System",           // sender
        "Daily Reward",     // title
        "Here is your daily reward!",  // content
        200,                // gold_reward
        100                 // exp_reward
    );
    
    if (success) {
        std::cout << "[C++] Mail saved successfully!" << std::endl;
    }
}

// Example: Save game state
void exampleSaveGameState(GameEngine& engine) {
    std::cout << "\n========== C++ GameState Save Example ==========" << std::endl;
    
    game::GameState game_state;
    game_state.set_version(1);
    game_state.set_timestamp(std::time(nullptr));
    game_state.set_frame_count(1000);
    game_state.set_game_time(500.5f);
    
    // Add multiple players
    for (int i = 1; i <= 3; ++i) {
        auto* player = game_state.add_players();
        player->set_id(i);
        player->set_name("Player" + std::to_string(i));
        player->set_level(i * 5);
        player->set_health(100 + i * 10);
        player->set_gold(i * 100);
    }
    
    // Add enemies
    for (int i = 1; i <= 5; ++i) {
        auto* enemy = game_state.add_enemies();
        enemy->set_id(i);
        enemy->set_name("Enemy" + std::to_string(i));
        enemy->set_health(50);
        enemy->set_damage(10);
        enemy->set_is_alive(true);
    }
    
    // Save entire game state
    bool success = engine.saveProtobufMessage("complete_game_state.dat", game_state);
    
    if (success) {
        std::cout << "[C++] Complete game state saved!" << std::endl;
        std::cout << "  Players: " << game_state.players_size() << std::endl;
        std::cout << "  Enemies: " << game_state.enemies_size() << std::endl;
    }
}

// Example: Load game state
void exampleLoadGameState(GameEngine& engine) {
    std::cout << "\n========== C++ GameState Load Example ==========" << std::endl;
    
    game::GameState game_state;
    
    bool success = engine.loadProtobufMessage("complete_game_state.dat", game_state);
    
    if (success) {
        std::cout << "[C++] Game state loaded!" << std::endl;
        std::cout << "  Version: " << game_state.version() << std::endl;
        std::cout << "  Frame Count: " << game_state.frame_count() << std::endl;
        std::cout << "  Game Time: " << game_state.game_time() << "s" << std::endl;
        
        // List all players
        std::cout << "\n  Players (" << game_state.players_size() << "):" << std::endl;
        for (int i = 0; i < game_state.players_size(); ++i) {
            const auto& player = game_state.players(i);
            std::cout << "    [" << player.id() << "] " 
                      << player.name() << " Lv." << player.level() 
                      << " Gold:" << player.gold() << std::endl;
        }
        
        // List all enemies
        std::cout << "\n  Enemies (" << game_state.enemies_size() << "):" << std::endl;
        for (int i = 0; i < game_state.enemies_size(); ++i) {
            const auto& enemy = game_state.enemies(i);
            std::cout << "    [" << enemy.id() << "] " 
                      << enemy.name() << " HP:" << enemy.health()
                      << " " << (enemy.is_alive() ? "Alive" : "Dead") << std::endl;
        }
    }
}

// Run all examples
void runProtobufExamples(GameEngine& engine) {
    std::cout << "\n\n";
    std::cout << "============================================" << std::endl;
    std::cout << "C++ Protobuf Examples" << std::endl;
    std::cout << "============================================" << std::endl;
    
    // Save examples
    exampleSavePlayerInCpp(engine);
    exampleSaveMailInCpp(engine);
    exampleSaveGameState(engine);
    
    // Load examples
    exampleLoadPlayerInCpp(engine);
    exampleLoadGameState(engine);
    
    std::cout << "\n============================================" << std::endl;
    std::cout << "All C++ Protobuf examples completed!" << std::endl;
    std::cout << "Check saves/ directory for generated files" << std::endl;
    std::cout << "============================================\n" << std::endl;
}

#endif // USE_PROTOBUF

