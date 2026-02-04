

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local httpRequest = (syn and syn.request) or request or http_request or function() return nil end

local SparkHub = {}
SparkHub.service = nil
SparkHub.provider = nil
SparkHub.base_url = "https://sparkhub-system.vercel.app/api/v1/whitelist"

-- Get HWID (device identifier)
local function getHWID()
    local ok, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and hwid or "unknown_hwid"
end

-- Get Roblox player info
local function getPlayerInfo()
    local player = Players.LocalPlayer
    if player then
        return {
            username = player.Name,
            user_id = player.UserId,
            display_name = player.DisplayName
        }
    end
    return { username = "Unknown", user_id = 0, display_name = "Unknown" }
end


local function getExecutor()
    if syn then return "Synapse X"
    elseif KRNL_LOADED then return "KRNL"
    elseif fluxus then return "Fluxus"
    elseif getexecutorname then return getexecutorname()
    elseif identifyexecutor then return identifyexecutor()
    else return "Unknown"
    end
end


function SparkHub.check_key(key)
    if not SparkHub.service then error("SparkHub.service not set") end
    
    local playerInfo = getPlayerInfo()
    local hwid = getHWID()
    local executor = getExecutor()
    
    local resp = httpRequest({
        Method = "POST",
        Url = SparkHub.base_url .. "/verifyOpen",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            key = tostring(key or ""),
            service = SparkHub.service,
            hwid = hwid,
            username = playerInfo.username,
            user_id = playerInfo.user_id,
            executor = executor
        })
    })
    
    if not resp then
        return {valid = false, error = "ERROR"}
    end
    if resp.StatusCode ~= 200 then
        return {valid = false, error = "http " .. resp.StatusCode}
    end
    
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(resp.Body)
    end)
    
    if ok then
        return decoded
    else
        return {valid = false, error = "DECODE_ERROR"}
    end
end


function SparkHub.get_key_link(provider)
    if not SparkHub.service then error("SparkHub.service not set") end
    if not provider and not SparkHub.provider then error("SparkHub.provider not set") end
    
    local playerInfo = getPlayerInfo()
    local hwid = getHWID()
    
    local linkResp = httpRequest({
        Method = "POST",
        Url = SparkHub.base_url .. "/getKeyOpen",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            service = SparkHub.service,
            provider = tostring(provider or SparkHub.provider),
            hwid = hwid,
            username = playerInfo.username,
            user_id = playerInfo.user_id
        })
    })
    
    if not linkResp then return nil, "ERROR" end
    if linkResp.StatusCode == 429 then return nil, "RATE_LIMITED" end
    if linkResp.StatusCode ~= 200 then return nil, linkResp.Body or "ERROR" end
    return linkResp.Body, nil
end


function SparkHub.load_script(script_id)
    if not script_id then error("script_id not provided") end
    loadstring(game:HttpGet("https://sparkhub-system.vercel.app/api/v1/luascripts/public/" .. tostring(script_id) .. "/download"))()
end

return SparkHub
