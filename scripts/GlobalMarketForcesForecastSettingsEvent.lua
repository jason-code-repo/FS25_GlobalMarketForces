-- Keeps the per-save Forecast Accuracy setting authoritative in multiplayer.
GlobalMarketForcesForecastSettingsEvent = {}
local GlobalMarketForcesForecastSettingsEvent_mt = Class(GlobalMarketForcesForecastSettingsEvent, Event)

GlobalMarketForcesForecastSettingsEvent.SETTINGS = { "Disabled", "Low", "Normal", "High", "Perfect" }
GlobalMarketForcesForecastSettingsEvent.NUM_BITS_SETTING = 3

InitEventClass(GlobalMarketForcesForecastSettingsEvent, "GlobalMarketForcesForecastSettingsEvent")

function GlobalMarketForcesForecastSettingsEvent.emptyNew()
    return Event.new(GlobalMarketForcesForecastSettingsEvent_mt)
end

function GlobalMarketForcesForecastSettingsEvent.new(setting, isRequest)
    local self = GlobalMarketForcesForecastSettingsEvent.emptyNew()
    self.setting = setting or "Normal"
    self.isRequest = isRequest == true
    return self
end

function GlobalMarketForcesForecastSettingsEvent.getSettingIndex(setting)
    for index, value in ipairs(GlobalMarketForcesForecastSettingsEvent.SETTINGS) do
        if value == setting then return index end
    end
    return 3
end

function GlobalMarketForcesForecastSettingsEvent.readStream(self, streamId, connection)
    local index = streamReadUIntN(streamId, GlobalMarketForcesForecastSettingsEvent.NUM_BITS_SETTING)
    self.isRequest = index == 0
    self.setting = GlobalMarketForcesForecastSettingsEvent.SETTINGS[index] or "Normal"
    self:run(connection)
end

function GlobalMarketForcesForecastSettingsEvent.writeStream(self, streamId, connection)
    local index = self.isRequest and 0 or GlobalMarketForcesForecastSettingsEvent.getSettingIndex(self.setting)
    streamWriteUIntN(streamId, index, GlobalMarketForcesForecastSettingsEvent.NUM_BITS_SETTING)
end

function GlobalMarketForcesForecastSettingsEvent.run(self, connection)
    if GlobalMarketForces == nil then return end

    -- Clients request the host's setting after joining. The response is
    -- broadcast through the same event, keeping every player's report aligned.
    if self.isRequest then
        if g_server ~= nil then
            local setting = GlobalMarketForces:getSavegameSettings().forecastAccuracy
            g_server:broadcastEvent(GlobalMarketForcesForecastSettingsEvent.new(setting))
        end
        return
    end

    GlobalMarketForces:setForecastAccuracy(self.setting)

    -- A client request is applied by the server, then distributed to every
    -- connected player so each Market Report displays the same forecast model.
    if g_server ~= nil and connection ~= nil and not connection:getIsServer() then
        g_server:broadcastEvent(GlobalMarketForcesForecastSettingsEvent.new(self.setting))
    end
end

if FSBaseMission ~= nil then
    FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, function()
        if g_server == nil and g_client ~= nil and g_client:getServerConnection() ~= nil then
            g_client:getServerConnection():sendEvent(GlobalMarketForcesForecastSettingsEvent.new(nil, true))
        end
    end)
end

function GlobalMarketForcesForecastSettingsEvent.sendEvent(setting)
    if g_server ~= nil then
        GlobalMarketForces:setForecastAccuracy(setting)
        g_server:broadcastEvent(GlobalMarketForcesForecastSettingsEvent.new(setting))
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(GlobalMarketForcesForecastSettingsEvent.new(setting))
    end
end
