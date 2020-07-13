local addonName, pct = ...;

pct.PROFESSIONS = {
    ALCHEMY = {
        spellId = 11611;
    },
    LEATHERWORKING = {
        spellId = 10662;
    },
    TAILORING = {
        spellId = 12180;
    }
}

pct.TRACKED_SPELLS = {
    TRANSMUTE_ARCANITE = {
        spellId = 17187,
        profession = pct.PROFESSIONS.ALCHEMY
    },
    MOONCLOTH = {
        spellId = 18560,
        profession = pct.PROFESSIONS.TAILORING
    },
    SALT_SHAKER = {
        spellId = 19566,
        profession = pct.PROFESSIONS.LEATHERWORKING
    }
};

pct.COMMANDS = {
    help = function()
        print(" ");
        print("Available commands:");
        print("    /pct help - shows available commands");
        print("    /pct status - shows character cooldowns");
        print(" ");
    end,
    
    status = function()
        print(" ");
        pct:updateCurrentCharacterCooldowns(ProfessionCooldownTrackerDB);
        pct:printStatus(ProfessionCooldownTrackerDB);
        print(" ");
    end
};

local function getTableSize(tbl)
    local count = 0;
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count;
end

local function formatCooldownReadyIn(readyAt)
    local readyInSeconds = readyAt - GetServerTime();
    local minutes = math.floor(readyInSeconds / 60 % 60);
    local hours = math.floor(readyInSeconds / 60 / 60 % 24);
    local days = math.floor(readyInSeconds / 60 / 60 / 24);
    local text = "";
    if (days > 0) then
        text = text .. days .. " Days ";
    end
    if (hours > 0) then
        text = text .. hours .. " Hrs ";
    end
    if (minutes > 0) then
        text = text .. minutes .. " Mins ";
    end
    return "|cffff0000" .. text .. "|r";
end

local function handleCommands(str)
    if (#str == 0) then
        pct.COMMANDS.help();
        return;
    end

    if (str == "status") then
        pct.COMMANDS.status();
        return;
    end

    pct.COMMANDS.help();
end

function pct:initialize()
    if (ProfessionCooldownTrackerDB == nil) then
        ProfessionCooldownTrackerDB = {};
    end

    SLASH_ProfessionCooldownTracker1 = "/pct";
    SlashCmdList.ProfessionCooldownTracker = handleCommands;
end

function pct:updateCurrentCharacterCooldowns(db)
    local character = UnitName("player");
    local cooldowns = db[character];
    if (cooldowns == nil) then
        cooldowns = {};
        db[character] = cooldowns;
    end
    for spell, info in pairs(pct.TRACKED_SPELLS) do
        local start, duration = GetSpellCooldown(info.spellId);
        if (duration ~= 0) then
            local readyInSeconds = start + duration - GetTime();
            cooldowns[spell] = {
                readyAt = GetServerTime() + readyInSeconds,
                ready = false
            };
        elseif (IsSpellKnown(info.profession.spellId)) then
            cooldowns[spell] = { ready = true };
        else
            cooldowns[spell] = nil;
        end
    end
end

function pct:printStatus(db)
    print("Cooldowns:");
    for character, cooldowns in pairs(db) do
        local cooldownCount = getTableSize(cooldowns);
        if (cooldownCount > 0) then
            print("    " .. character);
            for spell, info in pairs(pct.TRACKED_SPELLS) do
                local cooldown = cooldowns[spell];
                if (cooldown ~= nil) then
                    local name = GetSpellInfo(info.spellId);
                    local line = "        - " .. name .. ": ";
                    if (cooldown.ready) then
                        line = line .. "|cff00ff00Ready|r";
                    else
                        line = line .. formatCooldownReadyIn(cooldowns[spell].readyAt);
                    end
                    print(line);
                end
            end
        end
    end
end

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(__, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        pct:initialize();
    elseif event == "PLAYER_LOGIN" then
        pct:updateCurrentCharacterCooldowns(ProfessionCooldownTrackerDB);
        pct:printStatus(ProfessionCooldownTrackerDB);
    elseif event == "PLAYER_LOGOUT" then
        pct:updateCurrentCharacterCooldowns(ProfessionCooldownTrackerDB);
    end
end);
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_LOGIN");