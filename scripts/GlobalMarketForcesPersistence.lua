-- Savegame persistence for the generated five-year market timeline.
function GlobalMarketForces:loadMarketState()
    self.market = self.market or {}
    self.market.currentMonthIndex = self.market.currentMonthIndex or 1
    self.market.randomSeed = self.market.randomSeed or math.random(100000, 999999999)
    self.generatedEvents = self.generatedEvents or {}
    self.globalTrends = self.globalTrends or {}
    self.cropTrends = self.cropTrends or {}
    self.basePrices = self.basePrices or {}
    self.cropPriceHistory = self.cropPriceHistory or {}
    self.market.cropForecasts = self.market.cropForecasts or {}
    self.market.globalCycleForecasts = self.market.globalCycleForecasts or {}
end

function GlobalMarketForces:saveMarketState()
    self.marketDirty = true
end

local function readTrendList(xmlFile, key)
    local trends = {}
    local index = 0
    while xmlFile:hasProperty(key .. "(" .. index .. ")") do
        local trendKey = key .. "(" .. index .. ")"
        table.insert(trends, {
            channel = xmlFile:getString(trendKey .. "#channel") or "",
            trendType = xmlFile:getString(trendKey .. "#trendType") or "",
            startMonth = xmlFile:getInt(trendKey .. "#startMonth") or 1,
            durationMonths = xmlFile:getInt(trendKey .. "#durationMonths") or 1,
            severity = xmlFile:getFloat(trendKey .. "#severity") or 1
        })
        index = index + 1
    end
    return trends
end

local function writeTrendList(xmlFile, key, trends)
    for index, trend in ipairs(trends or {}) do
        local trendKey = key .. "(" .. (index - 1) .. ")"
        xmlFile:setString(trendKey .. "#channel", trend.channel)
        xmlFile:setString(trendKey .. "#trendType", trend.trendType)
        xmlFile:setInt(trendKey .. "#startMonth", trend.startMonth)
        xmlFile:setInt(trendKey .. "#durationMonths", trend.durationMonths)
        xmlFile:setFloat(trendKey .. "#severity", trend.severity)
    end
end

function GlobalMarketForces:readMarketStateFromXML(xmlFile, key)
    local stateKey = key .. ".globalMarketForces"
    if not xmlFile:hasProperty(stateKey .. "#generated") then return end

    self.market = self.market or {}
    self.market.currentMonthIndex = xmlFile:getInt(stateKey .. "#currentMonthIndex") or 1
    self.market.maxMonths = xmlFile:getInt(stateKey .. "#maxMonths") or GlobalMarketForcesConfig.maxMonths or 60
    self.market.basePricesCaptured = xmlFile:getBool(stateKey .. "#basePricesCaptured") or false
    self.market.generated = xmlFile:getBool(stateKey .. "#generated") or false
    self.market.randomSeed = xmlFile:getInt(stateKey .. "#randomSeed")
    self.market.eventsGeneratedThroughYear = xmlFile:getInt(stateKey .. "#eventsGeneratedThroughYear") or GlobalMarketForcesConfig.maxYears or 5
    self.market.cropForecasts = {}
    local forecastIndex = 0
    while xmlFile:hasProperty(stateKey .. ".cropForecast(" .. forecastIndex .. ")") do
        local forecastKey = stateKey .. ".cropForecast(" .. forecastIndex .. ")"
        local forecastName = xmlFile:getString(forecastKey .. "#key")
        if forecastName ~= nil then self.market.cropForecasts[forecastName] = { issueMonth=xmlFile:getInt(forecastKey .. "#issueMonth") or 0, months=xmlFile:getInt(forecastKey .. "#months") or 0, confidence=xmlFile:getFloat(forecastKey .. "#confidence") or 0, direction=xmlFile:getString(forecastKey .. "#direction") or "Stable", version=xmlFile:getInt(forecastKey .. "#version") or 0 } end
        forecastIndex = forecastIndex + 1
    end
    self.market.globalCycleForecasts = {}
    local globalForecastIndex = 0
    while xmlFile:hasProperty(stateKey .. ".globalCycleForecast(" .. globalForecastIndex .. ")") do
        local forecastKey = stateKey .. ".globalCycleForecast(" .. globalForecastIndex .. ")"
        local endMonth = xmlFile:getInt(forecastKey .. "#endMonth")
        if endMonth ~= nil then self.market.globalCycleForecasts[endMonth] = { issueMonth=xmlFile:getInt(forecastKey .. "#issueMonth") or 0, direction=xmlFile:getString(forecastKey .. "#direction") or "Stable", confidence=xmlFile:getFloat(forecastKey .. "#confidence") or 0 } end
        globalForecastIndex = globalForecastIndex + 1
    end

    self.globalTrends = readTrendList(xmlFile, stateKey .. ".globalTrend")
    self.generatedEvents = readTrendList(xmlFile, stateKey .. ".event")
    for _, event in ipairs(self.generatedEvents) do
        event.eventType = event.trendType
        event.trendType = nil
    end

    self.cropTrends = {}
    local cropIndex = 0
    while xmlFile:hasProperty(stateKey .. ".cropTrend(" .. cropIndex .. ")") do
        local cropKey = stateKey .. ".cropTrend(" .. cropIndex .. ")"
        local cropName = xmlFile:getString(cropKey .. "#crop") or ""
        local channel = xmlFile:getString(cropKey .. "#channel") or ""
        if cropName ~= "" and channel ~= "" then
            self.cropTrends[cropName] = self.cropTrends[cropName] or { demand = {}, supply = {}, policy = {} }
            table.insert(self.cropTrends[cropName][channel], {
                channel = channel,
                trendType = xmlFile:getString(cropKey .. "#trendType") or "",
                startMonth = xmlFile:getInt(cropKey .. "#startMonth") or 1,
                durationMonths = xmlFile:getInt(cropKey .. "#durationMonths") or 1,
                severity = xmlFile:getFloat(cropKey .. "#severity") or 1
            })
        end
        cropIndex = cropIndex + 1
    end

    self.basePrices = {}
    local priceIndex = 0
    while xmlFile:hasProperty(stateKey .. ".basePrice(" .. priceIndex .. ")") do
        local priceKey = stateKey .. ".basePrice(" .. priceIndex .. ")"
        local cropName = xmlFile:getString(priceKey .. "#crop") or ""
        if cropName ~= "" then self.basePrices[cropName] = xmlFile:getFloat(priceKey .. "#value") or 1 end
        priceIndex = priceIndex + 1
    end
end

function GlobalMarketForces:writeMarketStateToXML(xmlFile, key)
    local stateKey = key .. ".globalMarketForces"
    local market = self.market or {}
    xmlFile:setInt(stateKey .. "#currentMonthIndex", market.currentMonthIndex or 1)
    xmlFile:setInt(stateKey .. "#maxMonths", market.maxMonths or GlobalMarketForcesConfig.maxMonths or 60)
    xmlFile:setBool(stateKey .. "#basePricesCaptured", market.basePricesCaptured == true)
    xmlFile:setBool(stateKey .. "#generated", market.generated == true)
    if market.randomSeed ~= nil then xmlFile:setInt(stateKey .. "#randomSeed", market.randomSeed) end
    xmlFile:setInt(stateKey .. "#eventsGeneratedThroughYear", market.eventsGeneratedThroughYear or 0)

    local forecastIndex = 0
    for forecastName, forecast in pairs(market.cropForecasts or {}) do
        local forecastKey = stateKey .. ".cropForecast(" .. forecastIndex .. ")"
        xmlFile:setString(forecastKey .. "#key", forecastName); xmlFile:setInt(forecastKey .. "#issueMonth", forecast.issueMonth or 0); xmlFile:setInt(forecastKey .. "#months", forecast.months or 0); xmlFile:setFloat(forecastKey .. "#confidence", forecast.confidence or 0); xmlFile:setString(forecastKey .. "#direction", forecast.direction or "Stable"); xmlFile:setInt(forecastKey .. "#version", forecast.version or 0)
        forecastIndex = forecastIndex + 1
    end
    local globalForecastIndex = 0
    for endMonth, forecast in pairs(market.globalCycleForecasts or {}) do
        local forecastKey = stateKey .. ".globalCycleForecast(" .. globalForecastIndex .. ")"
        xmlFile:setInt(forecastKey .. "#endMonth", endMonth); xmlFile:setInt(forecastKey .. "#issueMonth", forecast.issueMonth or 0); xmlFile:setString(forecastKey .. "#direction", forecast.direction or "Stable"); xmlFile:setFloat(forecastKey .. "#confidence", forecast.confidence or 0)
        globalForecastIndex = globalForecastIndex + 1
    end

    writeTrendList(xmlFile, stateKey .. ".globalTrend", self.globalTrends)

    local events = {}
    for _, event in ipairs(self.generatedEvents or {}) do
        table.insert(events, {
            channel = "event",
            trendType = event.eventType,
            startMonth = event.startMonth,
            durationMonths = event.durationMonths,
            severity = event.severity
        })
    end
    writeTrendList(xmlFile, stateKey .. ".event", events)

    local cropIndex = 0
    for cropName, channels in pairs(self.cropTrends or {}) do
        for _, channelName in ipairs({ "demand", "supply", "policy" }) do
            for _, trend in ipairs(channels[channelName] or {}) do
                local cropKey = stateKey .. ".cropTrend(" .. cropIndex .. ")"
                xmlFile:setString(cropKey .. "#crop", cropName)
                xmlFile:setString(cropKey .. "#channel", channelName)
                xmlFile:setString(cropKey .. "#trendType", trend.trendType)
                xmlFile:setInt(cropKey .. "#startMonth", trend.startMonth)
                xmlFile:setInt(cropKey .. "#durationMonths", trend.durationMonths)
                xmlFile:setFloat(cropKey .. "#severity", trend.severity)
                cropIndex = cropIndex + 1
            end
        end
    end

    local priceIndex = 0
    for cropName, price in pairs(self.basePrices or {}) do
        local priceKey = stateKey .. ".basePrice(" .. priceIndex .. ")"
        xmlFile:setString(priceKey .. "#crop", cropName)
        xmlFile:setFloat(priceKey .. "#value", price)
        priceIndex = priceIndex + 1
    end
end

function GlobalMarketForces:loadMarketStateFromSavegame()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then return end
    local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
    if savegameDirectory == nil then return end

    local xmlFile = XMLFile.loadIfExists("GlobalMarketForcesMarketState", savegameDirectory .. "/globalMarketForces.xml", "globalMarketForces")
    if xmlFile == nil then
        self:ensureLongTermTrendHorizon()
        self:ensureWorldEventHorizon()
        self:applyCropPrices()
        return
    end

    self:readMarketStateFromXML(xmlFile, "globalMarketForces")
    xmlFile:delete()
    if self:pruneExpiredMarketEntries() > 0 then self:saveMarketState() end
    self:ensureLongTermTrendHorizon()
    self:ensureWorldEventHorizon()
    self:applyCropPrices()
end

function GlobalMarketForces:saveMarketStateToSavegame()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then return end
    local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
    if savegameDirectory == nil then return end

    self:pruneExpiredMarketEntries()
    self:ensureLongTermTrendHorizon()
    self:ensureWorldEventHorizon()
    local xmlFile = XMLFile.create("GlobalMarketForcesMarketState", savegameDirectory .. "/globalMarketForces.xml", "globalMarketForces")
    self:writeMarketStateToXML(xmlFile, "globalMarketForces")
    xmlFile:save()
    xmlFile:delete()
    self.marketDirty = false
end

-- Global mods are not savegame objects, so the engine does not call their
-- saveToXMLFile/loadFromXMLFile methods automatically. Attach to the mission
-- lifecycle and keep the state in a dedicated file inside each savegame folder.
if Mission00 ~= nil then
    Mission00.loadItemsFinished = Utils.appendedFunction(Mission00.loadItemsFinished, function()
        GlobalMarketForces:loadMarketStateFromSavegame()
    end)
end

if FSCareerMissionInfo ~= nil then
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, function()
        GlobalMarketForces:saveMarketStateToSavegame()
    end)
end
