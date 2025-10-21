
#include "game_engine.hpp"
#include <iostream>
#include <fstream>
#include <sstream>

#ifdef USE_PROTOBUF
#include "game_data.pb.h"
#endif

GameEngine::GameEngine() {
    initialize();
}

void GameEngine::initialize() {
    // Open Lua standard libraries
    lua.open_libraries(
        sol::lib::base, 
                      sol::lib::package, 
                      sol::lib::string, 
                      sol::lib::math,
        sol::lib::table,
        sol::lib::io,
        sol::lib::os
    );
    
    // Register C++ engine functions to Lua (system-level only)
    lua.new_usertype<GameEngine>("GameEngine",
        // Logging
        "log", &GameEngine::logMessage,
        "log_message", &GameEngine::logMessage,
        "log_warning", &GameEngine::logWarning,
        "log_error", &GameEngine::logError,
        
        // Player data persistence
        "save_player", &GameEngine::savePlayer,
        "load_player", &GameEngine::loadPlayer,
        "delete_player", &GameEngine::deletePlayer,
        
        // Mail data persistence
        "save_mail", &GameEngine::saveMail,
        "load_mail", &GameEngine::loadMail,
        "delete_mail", &GameEngine::deleteMail,
        
        // Generic data save/load
        "save_data", &GameEngine::saveData,
        "load_data", &GameEngine::loadData,
        "delete_data", &GameEngine::deleteData,
        
        // Network simulation
        "send_player", &GameEngine::sendPlayer,
        "broadcast_to_all", &GameEngine::broadcastToAll
        
        #ifdef USE_PROTOBUF
        ,
        // Protobuf serialization
        "serialize_player_pb", &GameEngine::serializePlayerToPB,
        "deserialize_player_pb", &GameEngine::deserializePlayerFromPB,
        "serialize_mail_pb", &GameEngine::serializeMailToPB,
        "deserialize_mail_pb", &GameEngine::deserializeMailFromPB,
        
        // Protobuf save/load
        "save_player_pb", &GameEngine::savePlayerPB,
        "load_player_pb", &GameEngine::loadPlayerPB,
        "save_mail_pb", &GameEngine::saveMailPB,
        "load_mail_pb", &GameEngine::loadMailPB
        #endif
    );
    
    // Set global engine instance for Lua access
    lua["engine"] = this;
    
    // Configure Lua module search paths
    std::string package_path = lua["package"]["path"];
    package_path += ";./?.lua";
    package_path += ";./scripts/?.lua";
    package_path += ";./scripts/?/init.lua";
    package_path += ";./?/init.lua";
    lua["package"]["path"] = package_path;
    
    std::cout << "GameEngine initialized (Data-Driven Architecture)" << std::endl;
    std::cout << "  - C++: System layer (logging, etc.)" << std::endl;
    std::cout << "  - Lua: Game logic & data layer" << std::endl;
}

void GameEngine::loadScript(const std::string& filename) {
    try {
        // Load and execute Lua script
        auto result = lua.load_file(filename);
        if (!result.valid()) {
            sol::error err = result;
            throw std::runtime_error(err.what());
        }
        
        // Execute script
        result();
        std::cout << "Loaded script: " << filename << std::endl;
        
        // Save script path and modification time for hot reload
        current_script_path = filename;
        if (std::filesystem::exists(filename)) {
            last_write_time = std::filesystem::last_write_time(filename);
        }
        
    } catch (const std::exception& e) {
        std::cerr << "Error loading script: " << e.what() << std::endl;
    }
}

void GameEngine::callLuaFunction(const std::string& func_name) {
    try {
        sol::function func = lua[func_name];
        if (func.valid()) {
            func();
        } else {
            std::cout << "Lua function '" << func_name << "' not found" << std::endl;
        }
    } catch (const sol::error& e) {
        std::cerr << "Error calling Lua function: " << e.what() << std::endl;
    }
}

void GameEngine::update() {
    // Check and reload if auto-reload is enabled
    if (auto_reload_enabled) {
        checkAndReload();
    }
    
    // Call Lua update function if it exists
    callLuaFunction("on_update");
}

// Bidirectional save/load - C++ calls Lua functions

bool GameEngine::callLuaSaveGame() {
    std::cout << "[C++ -> Lua] Calling Lua save game function..." << std::endl;
    
    try {
        // Try to call g_GameMgr:saveGame()
        sol::optional<sol::table> game_mgr_opt = lua["g_GameMgr"];
        
        if (game_mgr_opt) {
            sol::table game_mgr = *game_mgr_opt;
            sol::function save_func = game_mgr["saveGame"];
            
            if (save_func.valid()) {
                bool result = save_func(game_mgr);
                std::cout << "[C++ -> Lua] Lua save completed: " << (result ? "success" : "failed") << std::endl;
                return result;
            }
        }
        
        // Fallback: try global function
        sol::function save_func = lua["debugSaveGame"];
        if (save_func.valid()) {
            save_func();
            std::cout << "[C++ -> Lua] Lua save completed via debugSaveGame" << std::endl;
            return true;
        }
        
        std::cout << "[C++ -> Lua] No Lua save function found" << std::endl;
        return false;
        
    } catch (const sol::error& e) {
        std::cerr << "[C++ -> Lua] Error calling Lua save: " << e.what() << std::endl;
        return false;
    }
}

bool GameEngine::callLuaLoadGame() {
    std::cout << "[C++ -> Lua] Calling Lua load game function..." << std::endl;
    
    try {
        sol::optional<sol::table> game_mgr_opt = lua["g_GameMgr"];
        
        if (game_mgr_opt) {
            sol::table game_mgr = *game_mgr_opt;
            sol::function load_func = game_mgr["loadGame"];
            
            if (load_func.valid()) {
                bool result = load_func(game_mgr);
                std::cout << "[C++ -> Lua] Lua load completed: " << (result ? "success" : "failed") << std::endl;
                return result;
            }
        }
        
        sol::function load_func = lua["debugLoadGame"];
        if (load_func.valid()) {
            load_func();
            std::cout << "[C++ -> Lua] Lua load completed via debugLoadGame" << std::endl;
            return true;
        }
        
        std::cout << "[C++ -> Lua] No Lua load function found" << std::endl;
        return false;
        
    } catch (const sol::error& e) {
        std::cerr << "[C++ -> Lua] Error calling Lua load: " << e.what() << std::endl;
        return false;
    }
}

bool GameEngine::callLuaSavePlayer(int player_id) {
    std::cout << "[C++ -> Lua] Calling Lua save player [" << player_id << "]..." << std::endl;
    
    try {
        sol::optional<sol::table> game_mgr_opt = lua["g_GameMgr"];
        
        if (game_mgr_opt) {
            sol::table game_mgr = *game_mgr_opt;
            sol::table player_mgr = game_mgr["player_mgr"];
            sol::function save_func = player_mgr["savePlayer"];
            
            if (save_func.valid()) {
                bool result = save_func(player_mgr, player_id);
                std::cout << "[C++ -> Lua] Player save completed: " << (result ? "success" : "failed") << std::endl;
                return result;
            }
        }
        
        std::cout << "[C++ -> Lua] PlayerMgr not found" << std::endl;
        return false;
        
    } catch (const sol::error& e) {
        std::cerr << "[C++ -> Lua] Error: " << e.what() << std::endl;
        return false;
    }
}

bool GameEngine::callLuaLoadPlayer(int player_id) {
    std::cout << "[C++ -> Lua] Calling Lua load player [" << player_id << "]..." << std::endl;
    
    try {
        sol::optional<sol::table> game_mgr_opt = lua["g_GameMgr"];
        
        if (game_mgr_opt) {
            sol::table game_mgr = *game_mgr_opt;
            sol::table player_mgr = game_mgr["player_mgr"];
            sol::function load_func = player_mgr["loadPlayer"];
            
            if (load_func.valid()) {
                sol::object result = load_func(player_mgr, player_id);
                bool success = result.valid();
                std::cout << "[C++ -> Lua] Player load completed: " << (success ? "success" : "failed") << std::endl;
                return success;
            }
        }
        
        return false;
        
    } catch (const sol::error& e) {
        std::cerr << "[C++ -> Lua] Error: " << e.what() << std::endl;
        return false;
    }
}

bool GameEngine::callLuaSaveMail(int player_id) {
    std::cout << "[C++ -> Lua] Calling Lua save mails for player [" << player_id << "]..." << std::endl;
    
    try {
        sol::optional<sol::table> game_mgr_opt = lua["g_GameMgr"];
        
        if (game_mgr_opt) {
            sol::table game_mgr = *game_mgr_opt;
            sol::table mail_mgr = game_mgr["mail_mgr"];
            sol::function save_func = mail_mgr["savePlayerMails"];
            
            if (save_func.valid()) {
                int count = save_func(mail_mgr, player_id);
                std::cout << "[C++ -> Lua] Saved " << count << " mails" << std::endl;
                return count > 0;
            }
        }
        
        return false;
        
    } catch (const sol::error& e) {
        std::cerr << "[C++ -> Lua] Error: " << e.what() << std::endl;
        return false;
    }
}

// Hot reload implementation

void GameEngine::reloadScript() {
    if (current_script_path.empty()) {
        std::cout << "No script loaded yet" << std::endl;
        return;
    }
    
    std::cout << "\n[Hot Reload] Reloading script: " << current_script_path << std::endl;
    
    try {
        // Reload script
        auto result = lua.load_file(current_script_path);
        if (!result.valid()) {
            sol::error err = result;
            throw std::runtime_error(err.what());
        }
        
        // Execute script
        result();
        
        // Update modification time
        if (std::filesystem::exists(current_script_path)) {
            last_write_time = std::filesystem::last_write_time(current_script_path);
        }
        
        std::cout << "[Hot Reload] Script reloaded successfully!" << std::endl;
        
        // Call reload callback if it exists
        sol::function on_reload = lua["on_reload"];
        if (on_reload.valid()) {
            on_reload();
        }
        
    } catch (const std::exception& e) {
        std::cerr << "[Hot Reload] Error reloading script: " << e.what() << std::endl;
    }
}

void GameEngine::checkAndReload() {
    if (isScriptModified()) {
        reloadScript();
    }
}

void GameEngine::enableAutoReload(bool enable) {
    auto_reload_enabled = enable;
    if (enable) {
        std::cout << "[Hot Reload] Auto-reload enabled" << std::endl;
    } else {
        std::cout << "[Hot Reload] Auto-reload disabled" << std::endl;
    }
}

bool GameEngine::isScriptModified() const {
    if (current_script_path.empty() || !std::filesystem::exists(current_script_path)) {
        return false;
    }
    
    auto current_time = std::filesystem::last_write_time(current_script_path);
    return current_time != last_write_time;
}

// System-level logging functions
void GameEngine::logMessage(const std::string& message) {
    std::cout << "[LUA] " << message << std::endl;
}

void GameEngine::logWarning(const std::string& message) {
    std::cout << "[WARNING] " << message << std::endl;
}

void GameEngine::logError(const std::string& message) {
    std::cerr << "[ERROR] " << message << std::endl;
}

// Helper: Get save file path
std::string GameEngine::getSaveFilePath(const std::string& filename) {
    return "saves/" + filename;
}

// Player data persistence
bool GameEngine::savePlayer(int player_id, const std::string& json_data) {
    try {
        std::string filename = getSaveFilePath("player_" + std::to_string(player_id) + ".dat");
        
        // Create saves directory if not exists
        std::filesystem::create_directories("saves");
        
        std::ofstream file(filename);
        if (!file.is_open()) {
            std::cerr << "[C++] Failed to open file for writing: " << filename << std::endl;
            return false;
        }
        
        file << json_data;
        file.close();
        
        std::cout << "[C++] Saved player [" << player_id << "] to " << filename << std::endl;
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error saving player: " << e.what() << std::endl;
        return false;
    }
}

std::string GameEngine::loadPlayer(int player_id) {
    try {
        std::string filename = getSaveFilePath("player_" + std::to_string(player_id) + ".dat");
        
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cout << "[C++] Player file not found: " << filename << std::endl;
            return "";
        }
        
        std::stringstream buffer;
        buffer << file.rdbuf();
        file.close();
        
        std::cout << "[C++] Loaded player [" << player_id << "] from " << filename << std::endl;
        return buffer.str();
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error loading player: " << e.what() << std::endl;
        return "";
    }
}

bool GameEngine::deletePlayer(int player_id) {
    try {
        std::string filename = getSaveFilePath("player_" + std::to_string(player_id) + ".dat");
        
        if (std::filesystem::exists(filename)) {
            std::filesystem::remove(filename);
            std::cout << "[C++] Deleted player file: " << filename << std::endl;
            return true;
        }
        
        return false;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error deleting player: " << e.what() << std::endl;
        return false;
    }
}

// Mail data persistence
bool GameEngine::saveMail(int player_id, const std::string& json_data) {
    try {
        std::string filename = getSaveFilePath("mail_" + std::to_string(player_id) + ".dat");
        
        std::filesystem::create_directories("saves");
        
        std::ofstream file(filename);
        if (!file.is_open()) {
            std::cerr << "[C++] Failed to open file for writing: " << filename << std::endl;
            return false;
        }
        
        file << json_data;
        file.close();
        
        std::cout << "[C++] Saved mail for player [" << player_id << "] to " << filename << std::endl;
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error saving mail: " << e.what() << std::endl;
        return false;
    }
}

std::string GameEngine::loadMail(int player_id) {
    try {
        std::string filename = getSaveFilePath("mail_" + std::to_string(player_id) + ".dat");
        
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cout << "[C++] Mail file not found: " << filename << std::endl;
            return "";
        }
        
        std::stringstream buffer;
        buffer << file.rdbuf();
        file.close();
        
        std::cout << "[C++] Loaded mail for player [" << player_id << "] from " << filename << std::endl;
        return buffer.str();
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error loading mail: " << e.what() << std::endl;
        return "";
    }
}

bool GameEngine::deleteMail(int player_id) {
    try {
        std::string filename = getSaveFilePath("mail_" + std::to_string(player_id) + ".dat");
        
        if (std::filesystem::exists(filename)) {
            std::filesystem::remove(filename);
            std::cout << "[C++] Deleted mail file: " << filename << std::endl;
            return true;
        }
        
        return false;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error deleting mail: " << e.what() << std::endl;
        return false;
    }
}

// Generic data save/load
bool GameEngine::saveData(const std::string& key, const std::string& data) {
    try {
        std::string filename = getSaveFilePath(key + ".dat");
        
        std::filesystem::create_directories("saves");
        
        std::ofstream file(filename);
        if (!file.is_open()) {
            std::cerr << "[C++] Failed to open file for writing: " << filename << std::endl;
            return false;
        }
        
        file << data;
        file.close();
        
        std::cout << "[C++] Saved data [" << key << "] to " << filename << std::endl;
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error saving data: " << e.what() << std::endl;
        return false;
    }
}

std::string GameEngine::loadData(const std::string& key) {
    try {
        std::string filename = getSaveFilePath(key + ".dat");
        
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cout << "[C++] Data file not found: " << filename << std::endl;
            return "";
        }
        
        std::stringstream buffer;
        buffer << file.rdbuf();
        file.close();
        
        std::cout << "[C++] Loaded data [" << key << "] from " << filename << std::endl;
        return buffer.str();
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error loading data: " << e.what() << std::endl;
        return "";
    }
}

bool GameEngine::deleteData(const std::string& key) {
    try {
        std::string filename = getSaveFilePath(key + ".dat");
        
        if (std::filesystem::exists(filename)) {
            std::filesystem::remove(filename);
            std::cout << "[C++] Deleted data file: " << filename << std::endl;
            return true;
        }
        
        return false;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++] Error deleting data: " << e.what() << std::endl;
        return false;
    }
}

// Network simulation (for demo purposes)
void GameEngine::sendPlayer(int player_id, const std::string& message_type, const std::string& content) {
    std::cout << "[C++/NETWORK] Send to player [" << player_id << "]" << std::endl;
    std::cout << "  Type: " << message_type << std::endl;
    std::cout << "  Content: " << content << std::endl;
    
    // In real game, this would:
    // 1. Serialize the message
    // 2. Send via network socket
    // 3. Handle acknowledgment
}

void GameEngine::broadcastToAll(const std::string& message_type, const std::string& content) {
    std::cout << "[C++/NETWORK] Broadcast to all players" << std::endl;
    std::cout << "  Type: " << message_type << std::endl;
    std::cout << "  Content: " << content << std::endl;
    
    // In real game, this would:
    // 1. Get all online players
    // 2. Serialize the message
    // 3. Send to each player's connection
}

#ifdef USE_PROTOBUF
// Protobuf serialization/deserialization implementations

std::string GameEngine::serializePlayerToPB(const sol::table& player_data) {
    game::PlayerData pb_player;
    
    // Basic fields
    pb_player.set_id(player_data["id"].get_or(0));
    pb_player.set_name(player_data["name"].get_or(std::string("Unknown")));
    pb_player.set_level(player_data["level"].get_or(1));
    pb_player.set_health(player_data["health"].get_or(100));
    pb_player.set_max_health(player_data["max_health"].get_or(100));
    pb_player.set_mana(player_data["mana"].get_or(50));
    pb_player.set_max_mana(player_data["max_mana"].get_or(50));
    pb_player.set_experience(player_data["experience"].get_or(0));
    pb_player.set_gold(player_data["gold"].get_or(0));
    
    // Position
    sol::optional<sol::table> pos_opt = player_data["position"];
    if (pos_opt) {
        sol::table pos = *pos_opt;
        auto* pb_pos = pb_player.mutable_position();
        pb_pos->set_x(pos["x"].get_or(0.0f));
        pb_pos->set_y(pos["y"].get_or(0.0f));
        pb_pos->set_z(pos["z"].get_or(0.0f));
    }
    
    // Timestamp
    pb_player.set_save_time(std::time(nullptr));
    
    // Serialize to string
    std::string output;
    pb_player.SerializeToString(&output);
    
    std::cout << "[C++/PROTOBUF] Serialized player to " << output.size() << " bytes" << std::endl;
    return output;
}

sol::table GameEngine::deserializePlayerFromPB(const std::string& pb_data) {
    game::PlayerData pb_player;
    
    if (!pb_player.ParseFromString(pb_data)) {
        std::cerr << "[C++/PROTOBUF] Failed to parse player data" << std::endl;
        return lua.create_table();
    }
    
    sol::table player = lua.create_table();
    player["id"] = pb_player.id();
    player["name"] = pb_player.name();
    player["level"] = pb_player.level();
    player["health"] = pb_player.health();
    player["max_health"] = pb_player.max_health();
    player["mana"] = pb_player.mana();
    player["max_mana"] = pb_player.max_mana();
    player["experience"] = pb_player.experience();
    player["gold"] = pb_player.gold();
    
    // Position
    if (pb_player.has_position()) {
        sol::table pos = lua.create_table();
        pos["x"] = pb_player.position().x();
        pos["y"] = pb_player.position().y();
        pos["z"] = pb_player.position().z();
        player["position"] = pos;
    }
    
    std::cout << "[C++/PROTOBUF] Deserialized player from " << pb_data.size() << " bytes" << std::endl;
    return player;
}

std::string GameEngine::serializeMailToPB(const sol::table& mail_data) {
    game::MailData pb_mail;
    
    pb_mail.set_id(mail_data["id"].get_or(0));
    pb_mail.set_sender(mail_data["sender"].get_or(std::string("System")));
    pb_mail.set_title(mail_data["title"].get_or(std::string("")));
    pb_mail.set_content(mail_data["content"].get_or(std::string("")));
    pb_mail.set_is_read(mail_data["is_read"].get_or(false));
    pb_mail.set_is_claimed(mail_data["is_claimed"].get_or(false));
    pb_mail.set_timestamp(mail_data["timestamp"].get_or(0L));
    pb_mail.set_expire_time(mail_data["expire_time"].get_or(0L));
    
    // Rewards
    sol::optional<sol::table> rewards_opt = mail_data["rewards"];
    if (rewards_opt) {
        sol::table rewards = *rewards_opt;
        auto* pb_rewards = pb_mail.mutable_rewards();
        pb_rewards->set_gold(rewards["gold"].get_or(0));
        pb_rewards->set_exp(rewards["exp"].get_or(0));
    }
    
    std::string output;
    pb_mail.SerializeToString(&output);
    
    std::cout << "[C++/PROTOBUF] Serialized mail to " << output.size() << " bytes" << std::endl;
    return output;
}

sol::table GameEngine::deserializeMailFromPB(const std::string& pb_data) {
    game::MailData pb_mail;
    
    if (!pb_mail.ParseFromString(pb_data)) {
        std::cerr << "[C++/PROTOBUF] Failed to parse mail data" << std::endl;
        return lua.create_table();
    }
    
    sol::table mail = lua.create_table();
    mail["id"] = pb_mail.id();
    mail["sender"] = pb_mail.sender();
    mail["title"] = pb_mail.title();
    mail["content"] = pb_mail.content();
    mail["is_read"] = pb_mail.is_read();
    mail["is_claimed"] = pb_mail.is_claimed();
    mail["timestamp"] = pb_mail.timestamp();
    mail["expire_time"] = pb_mail.expire_time();
    
    // Rewards
    if (pb_mail.has_rewards()) {
        sol::table rewards = lua.create_table();
        rewards["gold"] = pb_mail.rewards().gold();
        rewards["exp"] = pb_mail.rewards().exp();
        mail["rewards"] = rewards;
    }
    
    std::cout << "[C++/PROTOBUF] Deserialized mail from " << pb_data.size() << " bytes" << std::endl;
    return mail;
}

bool GameEngine::savePlayerPB(int player_id, const sol::table& player_data) {
    std::string pb_data = serializePlayerToPB(player_data);
    return savePlayer(player_id, pb_data);
}

sol::table GameEngine::loadPlayerPB(int player_id) {
    std::string pb_data = loadPlayer(player_id);
    if (pb_data.empty()) {
        return lua.create_table();
    }
    return deserializePlayerFromPB(pb_data);
}

bool GameEngine::saveMailPB(int player_id, const sol::table& mail_data) {
    std::string pb_data = serializeMailToPB(mail_data);
    return saveMail(player_id, pb_data);
}

sol::table GameEngine::loadMailPB(int player_id) {
    std::string pb_data = loadMail(player_id);
    if (pb_data.empty()) {
        return lua.create_table();
    }
    return deserializeMailFromPB(pb_data);
}

// C++ direct Protobuf operations (no Lua dependency)

bool GameEngine::savePlayerDataCpp(int player_id, const std::string& name, int level, 
                                   int health, int mana, int exp, int gold) {
    game::PlayerData pb_player;
    
    // Set all fields directly in C++
    pb_player.set_id(player_id);
    pb_player.set_name(name);
    pb_player.set_level(level);
    pb_player.set_health(health);
    pb_player.set_max_health(health);  // Can be extended
    pb_player.set_mana(mana);
    pb_player.set_max_mana(mana);
    pb_player.set_experience(exp);
    pb_player.set_gold(gold);
    pb_player.set_save_time(std::time(nullptr));
    
    // Serialize and save
    return saveProtobufMessage("player_" + std::to_string(player_id) + ".dat", pb_player);
}

bool GameEngine::loadPlayerDataCpp(int player_id, std::string& out_name, 
                                   int& out_level, int& out_health) {
    game::PlayerData pb_player;
    
    // Load from file
    if (!loadProtobufMessage("player_" + std::to_string(player_id) + ".dat", pb_player)) {
        return false;
    }
    
    // Extract data
    out_name = pb_player.name();
    out_level = pb_player.level();
    out_health = pb_player.health();
    
    std::cout << "[C++] Loaded player [" << player_id << "] " << out_name 
              << " Level " << out_level << std::endl;
    
    return true;
}

bool GameEngine::saveMailDataCpp(int player_id, int mail_id, const std::string& sender, 
                                 const std::string& title, const std::string& content,
                                 int gold_reward, int exp_reward) {
    game::MailData pb_mail;
    
    // Set fields
    pb_mail.set_id(mail_id);
    pb_mail.set_sender(sender);
    pb_mail.set_title(title);
    pb_mail.set_content(content);
    pb_mail.set_is_read(false);
    pb_mail.set_is_claimed(false);
    pb_mail.set_timestamp(std::time(nullptr));
    pb_mail.set_expire_time(std::time(nullptr) + (7 * 24 * 3600));  // 7 days
    
    // Set rewards
    auto* rewards = pb_mail.mutable_rewards();
    rewards->set_gold(gold_reward);
    rewards->set_exp(exp_reward);
    
    // Save
    std::string filename = "mail_" + std::to_string(player_id) + "_" + std::to_string(mail_id) + ".dat";
    return saveProtobufMessage(filename, pb_mail);
}

bool GameEngine::loadMailDataCpp(int player_id, std::string& out_sender, 
                                 std::string& out_title, std::string& out_content) {
    game::MailData pb_mail;
    
    // Note: This loads mail_<player_id>.dat, would need mail_id for specific mail
    std::string filename = "mail_" + std::to_string(player_id) + ".dat";
    
    if (!loadProtobufMessage(filename, pb_mail)) {
        return false;
    }
    
    out_sender = pb_mail.sender();
    out_title = pb_mail.title();
    out_content = pb_mail.content();
    
    std::cout << "[C++] Loaded mail for player [" << player_id << "] from " << pb_mail.sender() << std::endl;
    
    return true;
}

// Generic template implementations
template<typename MessageType>
bool GameEngine::saveProtobufMessage(const std::string& filename, const MessageType& message) {
    try {
        std::string fullpath = getSaveFilePath(filename);
        
        // Create directory if not exists
        std::filesystem::create_directories("saves");
        
        // Serialize to binary
        std::string binary_data;
        if (!message.SerializeToString(&binary_data)) {
            std::cerr << "[C++/PROTOBUF] Failed to serialize message" << std::endl;
            return false;
        }
        
        // Write to file
        std::ofstream file(fullpath, std::ios::binary);
        if (!file.is_open()) {
            std::cerr << "[C++/PROTOBUF] Failed to open file for writing: " << fullpath << std::endl;
            return false;
        }
        
        file.write(binary_data.data(), binary_data.size());
        file.close();
        
        std::cout << "[C++/PROTOBUF] Saved " << binary_data.size() 
                  << " bytes to " << fullpath << std::endl;
        
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++/PROTOBUF] Error saving: " << e.what() << std::endl;
        return false;
    }
}

template<typename MessageType>
bool GameEngine::loadProtobufMessage(const std::string& filename, MessageType& message) {
    try {
        std::string fullpath = getSaveFilePath(filename);
        
        // Check if file exists
        if (!std::filesystem::exists(fullpath)) {
            std::cout << "[C++/PROTOBUF] File not found: " << fullpath << std::endl;
            return false;
        }
        
        // Read binary data
        std::ifstream file(fullpath, std::ios::binary);
        if (!file.is_open()) {
            std::cerr << "[C++/PROTOBUF] Failed to open file for reading: " << fullpath << std::endl;
            return false;
        }
        
        std::string binary_data((std::istreambuf_iterator<char>(file)), 
                                std::istreambuf_iterator<char>());
        file.close();
        
        // Parse protobuf
        if (!message.ParseFromString(binary_data)) {
            std::cerr << "[C++/PROTOBUF] Failed to parse message from " << fullpath << std::endl;
            return false;
        }
        
        std::cout << "[C++/PROTOBUF] Loaded " << binary_data.size() 
                  << " bytes from " << fullpath << std::endl;
        
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "[C++/PROTOBUF] Error loading: " << e.what() << std::endl;
        return false;
    }
}

#endif // USE_PROTOBUF












































































