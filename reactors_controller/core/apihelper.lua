-- API Helper Module
-- Handles HTTP communication with reactor APIs

local http = require("http")
local json = require("json")

local ApiHelper = {}
ApiHelper.__index = ApiHelper

function ApiHelper.new(base_url)
    local self = setmetatable({}, ApiHelper)
    self.base_url = base_url or "http://localhost:8080"
    self.timeout = 5000 -- ms
    return self
end

function ApiHelper:request(endpoint, method, data)
    local url = self.base_url .. endpoint
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    
    local body = data and json.encode(data) or nil
    
    local response, err = http.request({
        url = url,
        method = method or "GET",
        headers = headers,
        body = body,
        timeout = self.timeout
    })
    
    if err then
        return nil, err
    end
    
    if response.status >= 200 and response.status < 300 then
        return json.decode(response.body)
    else
        return nil, "HTTP " .. response.status .. ": " .. (response.body or "Unknown error")
    end
end

function ApiHelper:fetch_status(reactor_address)
    return self:request("/api/reactors/" .. reactor_address .. "/status", "GET")
end

function ApiHelper:send_command(reactor_address, command, params)
    return self:request("/api/reactors/" .. reactor_address .. "/command", "POST", {
        command = command,
        params = params
    })
end

function ApiHelper:fetch_config(reactor_address)
    return self:request("/api/reactors/" .. reactor_address .. "/config", "GET")
end

function ApiHelper:update_config(reactor_address, config)
    return self:request("/api/reactors/" .. reactor_address .. "/config", "PUT", config)
end

return ApiHelper
