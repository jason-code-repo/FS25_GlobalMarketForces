-- Sends the authoritative GMF timeline from the host to connected clients.
-- Prices are delivered separately by GlobalMarketForcesStationPriceEvent;
-- this event keeps the Market Report's conditions and forecasts in sync.
GlobalMarketForcesMarketStateEvent = {}
local GlobalMarketForcesMarketStateEvent_mt = Class(GlobalMarketForcesMarketStateEvent, Event)

GlobalMarketForcesMarketStateEvent.NUM_BITS_COUNT = 16
GlobalMarketForcesMarketStateEvent.NUM_BITS_SETTING = 3
GlobalMarketForcesMarketStateEvent.SETTINGS = { "Disabled", "Low", "Normal", "High", "Perfect" }

InitEventClass(GlobalMarketForcesMarketStateEvent, "GlobalMarketForcesMarketStateEvent")

function GlobalMarketForcesMarketStateEvent.emptyNew()
    return Event.new(GlobalMarketForcesMarketStateEvent_mt)
end

function GlobalMarketForcesMarketStateEvent.new(isRequest)
    local self = GlobalMarketForcesMarketStateEvent.emptyNew()
    self.isRequest = isRequest == true
    return self
end

function GlobalMarketForcesMarketStateEvent.getSettingIndex(setting)
    for index, value in ipairs(GlobalMarketForcesMarketStateEvent.SETTINGS) do
        if value == setting then return index end
    end
    return 3
end

function GlobalMarketForcesMarketStateEvent.writeCount(streamId, value)
    streamWriteUIntN(streamId, math.min(value or 0, 65535), GlobalMarketForcesMarketStateEvent.NUM_BITS_COUNT)
end

function GlobalMarketForcesMarketStateEvent.readCount(streamId)
    return streamReadUIntN(streamId, GlobalMarketForcesMarketStateEvent.NUM_BITS_COUNT)
end

function GlobalMarketForcesMarketStateEvent.flattenCropTrends(cropTrends)
    local entries = {}
    for cropName, channels in pairs(cropTrends or {}) do
        for _, channelName in ipairs({ "demand", "supply", "policy" }) do
            for _, trend in ipairs(channels[channelName] or {}) do
                table.insert(entries, { cropName = cropName, channel = channelName, trend = trend })
            end
        end
    end
    return entries
end

function GlobalMarketForcesMarketStateEvent.writeTrend(streamId, trend)
    streamWriteString(streamId, trend.channel or "")
    streamWriteString(streamId, trend.trendType or "")
    streamWriteInt32(streamId, trend.startMonth or 1)
    streamWriteInt32(streamId, trend.durationMonths or 1)
    streamWriteFloat32(streamId, trend.severity or 1)
end

function GlobalMarketForcesMarketStateEvent.readTrend(streamId)
    return {
        channel = streamReadString(streamId),
        trendType = streamReadString(streamId),
        startMonth = streamReadInt32(streamId),
        durationMonths = streamReadInt32(streamId),
        severity = streamReadFloat32(streamId)
    }
end

function GlobalMarketForcesMarketStateEvent.writeStream(self, streamId, connection)
    streamWriteBool(streamId, self.isRequest)
    if self.isRequest then return end

    local market = GlobalMarketForces.market or {}
    local settings = GlobalMarketForces:getSavegameSettings()
    streamWriteInt32(streamId, market.currentMonthIndex or 1)
    streamWriteInt32(streamId, market.maxMonths or 60)
    streamWriteBool(streamId, market.basePricesCaptured == true)
    streamWriteBool(streamId, market.generated == true)
    streamWriteInt32(streamId, market.randomSeed or 1)
    streamWriteInt32(streamId, market.randomState or 1)
    streamWriteInt32(streamId, market.eventsGeneratedThroughYear or 0)
    streamWriteUIntN(streamId, GlobalMarketForcesMarketStateEvent.getSettingIndex(settings.forecastAccuracy), GlobalMarketForcesMarketStateEvent.NUM_BITS_SETTING)

    local globalTrends = GlobalMarketForces.globalTrends or {}
    GlobalMarketForcesMarketStateEvent.writeCount(streamId, #globalTrends)
    for _, trend in ipairs(globalTrends) do GlobalMarketForcesMarketStateEvent.writeTrend(streamId, trend) end

    local events = GlobalMarketForces.generatedEvents or {}
    GlobalMarketForcesMarketStateEvent.writeCount(streamId, #events)
    for _, event in ipairs(events) do
        GlobalMarketForcesMarketStateEvent.writeTrend(streamId, {
            channel = "event",
            trendType = event.eventType,
            startMonth = event.startMonth,
            durationMonths = event.durationMonths,
            severity = event.severity
        })
    end

    local cropTrends = GlobalMarketForcesMarketStateEvent.flattenCropTrends(GlobalMarketForces.cropTrends)
    GlobalMarketForcesMarketStateEvent.writeCount(streamId, #cropTrends)
    for _, entry in ipairs(cropTrends) do
        streamWriteString(streamId, entry.cropName)
        GlobalMarketForcesMarketStateEvent.writeTrend(streamId, entry.trend)
    end

    local basePrices = {}
    for cropName, price in pairs(GlobalMarketForces.basePrices or {}) do table.insert(basePrices, { cropName = cropName, price = price }) end
    GlobalMarketForcesMarketStateEvent.writeCount(streamId, #basePrices)
    for _, entry in ipairs(basePrices) do
        streamWriteString(streamId, entry.cropName)
        streamWriteFloat32(streamId, entry.price or 1)
    end
end

function GlobalMarketForcesMarketStateEvent.readStream(self, streamId, connection)
    self.isRequest = streamReadBool(streamId)
    if self.isRequest then
        self:run(connection)
        return
    end

    local currentMonthIndex = streamReadInt32(streamId)
    local maxMonths = streamReadInt32(streamId)
    local basePricesCaptured = streamReadBool(streamId)
    local generated = streamReadBool(streamId)
    local randomSeed = streamReadInt32(streamId)
    local randomState = streamReadInt32(streamId)
    local eventsGeneratedThroughYear = streamReadInt32(streamId)
    local settingIndex = streamReadUIntN(streamId, GlobalMarketForcesMarketStateEvent.NUM_BITS_SETTING)
    local state = {
        market = {
            currentMonthIndex = currentMonthIndex,
            maxMonths = maxMonths,
            basePricesCaptured = basePricesCaptured,
            generated = generated,
            randomSeed = randomSeed,
            randomState = randomState,
            eventsGeneratedThroughYear = eventsGeneratedThroughYear,
            settings = { forecastAccuracy = GlobalMarketForcesMarketStateEvent.SETTINGS[settingIndex] or "Normal" }
        },
        globalTrends = {},
        generatedEvents = {},
        cropTrends = {},
        basePrices = {}
    }

    local globalCount = GlobalMarketForcesMarketStateEvent.readCount(streamId)
    for _ = 1, globalCount do table.insert(state.globalTrends, GlobalMarketForcesMarketStateEvent.readTrend(streamId)) end

    local eventCount = GlobalMarketForcesMarketStateEvent.readCount(streamId)
    for _ = 1, eventCount do
        local event = GlobalMarketForcesMarketStateEvent.readTrend(streamId)
        event.eventType = event.trendType
        event.trendType = nil
        table.insert(state.generatedEvents, event)
    end

    local cropTrendCount = GlobalMarketForcesMarketStateEvent.readCount(streamId)
    for _ = 1, cropTrendCount do
        local cropName = streamReadString(streamId)
        local trend = GlobalMarketForcesMarketStateEvent.readTrend(streamId)
        local channels = state.cropTrends[cropName] or { demand = {}, supply = {}, policy = {} }
        channels[trend.channel] = channels[trend.channel] or {}
        table.insert(channels[trend.channel], trend)
        state.cropTrends[cropName] = channels
    end

    local basePriceCount = GlobalMarketForcesMarketStateEvent.readCount(streamId)
    for _ = 1, basePriceCount do
        state.basePrices[streamReadString(streamId)] = streamReadFloat32(streamId)
    end

    self.state = state
    self:run(connection)
end

function GlobalMarketForcesMarketStateEvent.run(self, connection)
    if GlobalMarketForces == nil then return end
    if self.isRequest then
        if g_server ~= nil then
            -- Joining clients also need the station-level prices currently in
            -- effect, not only the narrative market timeline.
            GlobalMarketForces:applySellingStationPrices()
            g_server:broadcastEvent(GlobalMarketForcesMarketStateEvent.new(false))
        end
    elseif self.state ~= nil then
        GlobalMarketForces:applyNetworkMarketState(self.state)
    end
end

function GlobalMarketForcesMarketStateEvent.broadcastState()
    if g_server ~= nil then
        g_server:broadcastEvent(GlobalMarketForcesMarketStateEvent.new(false))
    end
end

if FSBaseMission ~= nil then
    FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, function()
        if g_server == nil and g_client ~= nil and g_client:getServerConnection() ~= nil then
            g_client:getServerConnection():sendEvent(GlobalMarketForcesMarketStateEvent.new(true))
        end
    end)
end
