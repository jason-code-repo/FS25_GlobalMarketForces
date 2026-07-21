-- Synchronizes GMF-managed effective station prices to clients. Raw
-- fillTypePrices remain under base-game ownership so GMF can preserve the
-- station's nominal difference while replacing seasonal price movement.
GlobalMarketForcesStationPriceEvent = {}
local GlobalMarketForcesStationPriceEvent_mt = Class(GlobalMarketForcesStationPriceEvent, Event)

function GlobalMarketForcesStationPriceEvent.emptyNew()
    return Event.new(GlobalMarketForcesStationPriceEvent_mt)
end

function GlobalMarketForcesStationPriceEvent.new(station, fillTypeIndex, price)
    local self = GlobalMarketForcesStationPriceEvent.emptyNew()
    self.station = station
    self.fillTypeIndex = fillTypeIndex
    self.price = price
    return self
end

function GlobalMarketForcesStationPriceEvent:readStream(streamId, connection)
    self.station = NetworkUtil.readNodeObject(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self.price = streamReadFloat32(streamId)
    self:run(connection)
end

function GlobalMarketForcesStationPriceEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.station)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
    streamWriteFloat32(streamId, self.price)
end

function GlobalMarketForcesStationPriceEvent:run(connection)
    if self.station ~= nil then
        self.station.gmfEffectiveFillTypePrices = self.station.gmfEffectiveFillTypePrices or {}
        self.station.gmfEffectiveFillTypePrices[self.fillTypeIndex] = self.price
    end

    -- The event runs on each client after its local effective price is updated.
    -- Rebuild once in the next update rather than once per changed crop.
    if GlobalMarketForces ~= nil then
        GlobalMarketForces.priceMenuRefreshPending = true
    end
end

function GlobalMarketForcesStationPriceEvent.sendEvent(station, fillTypeIndex, price)
    if g_server ~= nil and station ~= nil then
        g_server:broadcastEvent(GlobalMarketForcesStationPriceEvent.new(station, fillTypeIndex, price))
    end
end
