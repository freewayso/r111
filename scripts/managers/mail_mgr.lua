-- MailMgr - Mail/Message Manager
-- Manages in-game mail system, notifications, and rewards

-- Load class system if not already loaded
if not Class then
    require("scripts.class_system")
end

-- Mail class
Mail = Mail or Class()

function Mail:init(sender, title, content, rewards)
    self.id = 0
    self.sender = sender or "System"
    self.title = title or "Mail"
    self.content = content or ""
    self.rewards = rewards or {}  -- { gold = 100, items = {...} }
    self.is_read = false
    self.is_claimed = false
    self.timestamp = os.time()
    self.expire_time = os.time() + (7 * 24 * 3600)  -- 7 days
end

function Mail:markAsRead()
    self.is_read = true
end

function Mail:claimRewards(player)
    if self.is_claimed then
        return false, "Rewards already claimed"
    end
    
    -- Give gold
    if self.rewards.gold and self.rewards.gold > 0 then
        player.gold = (player.gold or 0) + self.rewards.gold
        engine:log("Received " .. self.rewards.gold .. " gold")
    end
    
    -- Give items
    if self.rewards.items then
        for _, item_template in ipairs(self.rewards.items) do
            -- Would integrate with ItemMgr
            engine:log("Received item: " .. item_template)
        end
    end
    
    self.is_claimed = true
    return true
end

function Mail:isExpired()
    return os.time() > self.expire_time
end

-- MailMgr class
MailMgr = MailMgr or Class()

function MailMgr:init()
    self.mail_boxes = {}  -- player_id -> { mail_id -> Mail }
    self.next_mail_id = 1
    
    engine:log("MailMgr initialized")
end

-- Send mail to player
function MailMgr:sendMail(player_id, sender, title, content, rewards)
    -- Create player mailbox if not exists
    if not self.mail_boxes[player_id] then
        self.mail_boxes[player_id] = {}
    end
    
    local mail_id = self.next_mail_id
    self.next_mail_id = self.next_mail_id + 1
    
    local mail = Mail:new(sender, title, content, rewards)
    mail.id = mail_id
    
    self.mail_boxes[player_id][mail_id] = mail
    
    engine:log("MailMgr: Sent mail [" .. mail_id .. "] to player [" .. player_id .. "]")
    return mail_id
end

-- Send mail to all players
function MailMgr:sendMailToAll(sender, title, content, rewards)
    local sent_count = 0
    for player_id, _ in pairs(self.mail_boxes) do
        self:sendMail(player_id, sender, title, content, rewards)
        sent_count = sent_count + 1
    end
    
    engine:log("MailMgr: Sent mail to " .. sent_count .. " players")
    return sent_count
end

-- Get player mailbox
function MailMgr:getPlayerMails(player_id)
    if not self.mail_boxes[player_id] then
        self.mail_boxes[player_id] = {}
    end
    return self.mail_boxes[player_id]
end

-- Get mail by ID
function MailMgr:getMail(player_id, mail_id)
    local mailbox = self:getPlayerMails(player_id)
    return mailbox[mail_id]
end

-- Read mail
function MailMgr:readMail(player_id, mail_id)
    local mail = self:getMail(player_id, mail_id)
    if mail then
        mail:markAsRead()
        engine:log("MailMgr: Player [" .. player_id .. "] read mail [" .. mail_id .. "]")
        return mail
    end
    return nil
end

-- Claim mail rewards
function MailMgr:claimRewards(player_id, mail_id, player)
    local mail = self:getMail(player_id, mail_id)
    if not mail then
        return false, "Mail not found"
    end
    
    local success, msg = mail:claimRewards(player)
    if success then
        engine:log("MailMgr: Player [" .. player_id .. "] claimed rewards from mail [" .. mail_id .. "]")
    end
    
    return success, msg
end

-- Delete mail
function MailMgr:deleteMail(player_id, mail_id)
    local mailbox = self:getPlayerMails(player_id)
    if mailbox[mail_id] then
        mailbox[mail_id] = nil
        engine:log("MailMgr: Deleted mail [" .. mail_id .. "] from player [" .. player_id .. "]")
        return true
    end
    return false
end

-- Get unread count
function MailMgr:getUnreadCount(player_id)
    local mailbox = self:getPlayerMails(player_id)
    local count = 0
    
    for _, mail in pairs(mailbox) do
        if not mail.is_read then
            count = count + 1
        end
    end
    
    return count
end

-- Get unclaimed count
function MailMgr:getUnclaimedCount(player_id)
    local mailbox = self:getPlayerMails(player_id)
    local count = 0
    
    for _, mail in pairs(mailbox) do
        if not mail.is_claimed and next(mail.rewards) ~= nil then
            count = count + 1
        end
    end
    
    return count
end

-- Clean expired mails
function MailMgr:cleanExpiredMails(player_id)
    local mailbox = self:getPlayerMails(player_id)
    local removed_count = 0
    local to_remove = {}
    
    for mail_id, mail in pairs(mailbox) do
        if mail:isExpired() and mail.is_claimed then
            table.insert(to_remove, mail_id)
        end
    end
    
    for _, mail_id in ipairs(to_remove) do
        self:deleteMail(player_id, mail_id)
        removed_count = removed_count + 1
    end
    
    if removed_count > 0 then
        engine:log("MailMgr: Cleaned " .. removed_count .. " expired mails for player [" .. player_id .. "]")
    end
    
    return removed_count
end

-- Update (called periodically)
function MailMgr:update(dt)
    -- Clean expired mails for all players periodically
    -- (In real game, do this on player login or daily)
end

-- Save single mail using Protobuf
function MailMgr:saveMail(player_id, mail_id)
    local mail = self:getMail(player_id, mail_id)
    if not mail then
        return false
    end
    
    -- Prepare mail data for Protobuf
    local mail_data = {
        id = mail.id,
        sender = mail.sender,
        title = mail.title,
        content = mail.content,
        rewards = mail.rewards or {},
        is_read = mail.is_read,
        is_claimed = mail.is_claimed,
        timestamp = mail.timestamp,
        expire_time = mail.expire_time
    }
    
    -- Call C++ Protobuf save
    -- Use unique key: mail_<playerid>_<mailid>
    local key = "mail_" .. player_id .. "_" .. mail_id
    local success = engine:save_mail_pb(player_id, mail_data)
    
    if success then
        engine:log("MailMgr: Saved mail [" .. mail_id .. "] for player [" .. player_id .. "] using Protobuf")
    end
    
    return success
end

-- Load single mail using Protobuf
function MailMgr:loadMail(player_id, mail_id)
    -- Call C++ Protobuf load
    local key = "mail_" .. player_id .. "_" .. mail_id
    local mail_data = engine:load_mail_pb(player_id)
    
    if not mail_data or not mail_data.id then
        return nil
    end
    
    -- Create Mail instance from loaded data
    local mail = Mail:new(
        mail_data.sender,
        mail_data.title,
        mail_data.content,
        mail_data.rewards
    )
    mail.id = mail_data.id
    mail.is_read = mail_data.is_read
    mail.is_claimed = mail_data.is_claimed
    mail.timestamp = mail_data.timestamp
    mail.expire_time = mail_data.expire_time
    
    return mail
end

-- Save all mails for a player (using Protobuf)
function MailMgr:savePlayerMails(player_id)
    local mailbox = self:getPlayerMails(player_id)
    local count = 0
    
    for mail_id, mail in pairs(mailbox) do
        if self:saveMail(player_id, mail_id) then
            count = count + 1
        end
    end
    
    engine:log("MailMgr: Saved " .. count .. " mails for player [" .. player_id .. "] (Protobuf)")
    return count
end

-- Save all mails for all players
function MailMgr:saveAllMails()
    local total = 0
    for player_id, _ in pairs(self.mail_boxes) do
        total = total + self:savePlayerMails(player_id)
    end
    
    engine:log("MailMgr: Saved total " .. total .. " mails (Protobuf)")
    return total
end

-- Get total mail count
function MailMgr:getTotalMailCount()
    local count = 0
    for _, mailbox in pairs(self.mail_boxes) do
        for _ in pairs(mailbox) do
            count = count + 1
        end
    end
    return count
end

-- Cleanup
function MailMgr:cleanup()
    engine:log("MailMgr: Cleaning up " .. self:getTotalMailCount() .. " mails")
    self.mail_boxes = {}
end

return MailMgr

