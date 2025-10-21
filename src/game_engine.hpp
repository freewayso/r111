#pragma once
#include <string>
#include <filesystem>
#include <chrono>
#include "../sol/sol.hpp"

class GameEngine {
private:
    sol::state lua;
    
    // Hot reload support
    std::string current_script_path;
    std::filesystem::file_time_type last_write_time;
    bool auto_reload_enabled = false;
    
public:
    GameEngine();
    ~GameEngine() = default;
    
    void initialize();
    void loadScript(const std::string& filename);
    void callLuaFunction(const std::string& func_name);
    template<typename... Args>
    void callLuaFunction(const std::string& func_name, Args&&... args);
    void update();
    
    // Hot reload functions
    void reloadScript();
    void checkAndReload();
    void enableAutoReload(bool enable = true);
    bool isScriptModified() const;
    
    // Bidirectional save/load interface
    // C++ -> Lua: C++ calls Lua save/load functions
    bool callLuaSaveGame();
    bool callLuaLoadGame();
    bool callLuaSavePlayer(int player_id);
    bool callLuaLoadPlayer(int player_id);
    bool callLuaSaveMail(int player_id);
    
    // Lua -> C++: Already implemented above (save_player_pb, etc.)
    
    // System-level functions exposed to Lua (not game logic)
    void logMessage(const std::string& message);
    void logWarning(const std::string& message);
    void logError(const std::string& message);
    
    // Player data persistence (C++ handles file IO)
    bool savePlayer(int player_id, const std::string& json_data);
    std::string loadPlayer(int player_id);
    bool deletePlayer(int player_id);
    
    // Mail data persistence
    bool saveMail(int player_id, const std::string& json_data);
    std::string loadMail(int player_id);
    bool deleteMail(int player_id);
    
    // Generic data save/load
    bool saveData(const std::string& key, const std::string& data);
    std::string loadData(const std::string& key);
    bool deleteData(const std::string& key);
    
    // Network simulation (for demo purposes)
    void sendPlayer(int player_id, const std::string& message_type, const std::string& content);
    void broadcastToAll(const std::string& message_type, const std::string& content);
    
    #ifdef USE_PROTOBUF
    // Protobuf serialization/deserialization (for Lua)
    std::string serializePlayerToPB(const sol::table& player_data);
    sol::table deserializePlayerFromPB(const std::string& pb_data);
    
    std::string serializeMailToPB(const sol::table& mail_data);
    sol::table deserializeMailFromPB(const std::string& pb_data);
    
    // Save/Load with Protobuf (Lua interface)
    bool savePlayerPB(int player_id, const sol::table& player_data);
    sol::table loadPlayerPB(int player_id);
    
    bool saveMailPB(int player_id, const sol::table& mail_data);
    sol::table loadMailPB(int player_id);
    
    // C++ direct Protobuf operations (no Lua dependency)
    bool savePlayerDataCpp(int player_id, const std::string& name, int level, int health, int mana, int exp, int gold);
    bool loadPlayerDataCpp(int player_id, std::string& out_name, int& out_level, int& out_health);
    
    bool saveMailDataCpp(int player_id, int mail_id, const std::string& sender, const std::string& title, 
                        const std::string& content, int gold_reward, int exp_reward);
    bool loadMailDataCpp(int player_id, std::string& out_sender, std::string& out_title, std::string& out_content);
    
    // Generic Protobuf message save/load
    template<typename MessageType>
    bool saveProtobufMessage(const std::string& filename, const MessageType& message);
    
    template<typename MessageType>
    bool loadProtobufMessage(const std::string& filename, MessageType& message);
    #endif
    
    // Get Lua state for advanced usage
    sol::state& getLuaState() { return lua; }
    
private:
    // Helper: Get save file path
    std::string getSaveFilePath(const std::string& filename);
};

// Template implementation
template<typename... Args>
void GameEngine::callLuaFunction(const std::string& func_name, Args&&... args) {
    try {
        sol::function func = lua[func_name];
        if (func.valid()) {
            func(std::forward<Args>(args)...);
        }
    } catch (const sol::error& e) {
        std::cerr << "Error calling Lua function '" << func_name << "': " << e.what() << std::endl;
    }
}














































