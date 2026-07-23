GlobalMarketForces=GlobalMarketForces or {}
GlobalMarketForces.MOD_NAME=g_currentModName or "FS25_GlobalMarketForces"
GlobalMarketForces.MOD_DIRECTORY=g_currentModDirectory or ""
GlobalMarketForces.market={currentMonthIndex=1,maxMonths=60,basePricesCaptured=false,generated=false,randomSeed=nil}
GlobalMarketForces.lastKnownPeriod=nil

function GlobalMarketForces:getText(key, fallback, ...)
    local environment = g_i18n ~= nil and g_i18n.modEnvironments ~= nil and g_i18n.modEnvironments[self.MOD_NAME] or nil
    local text = environment ~= nil and environment.texts[key] or nil
    text = text ~= nil and text ~= "" and text or fallback or key
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end

function GlobalMarketForces:log(msg)
    if self:isLoggingEnabled() then
        print(string.format("[%s] %s",self.MOD_NAME,tostring(msg)))
    end
end

function GlobalMarketForces:loadMap()
    self.market.maxMonths=GlobalMarketForcesConfig.maxMonths or 60
    self:loadCustomCropAliases()
    self:installSellingStationPriceOverride()
    self:registerDetectedCustomCropProfiles()
    self:registerReportActionEvents()
    if g_server ~= nil then
        self:loadMarketState()
        self:captureBasePrices()
        if not self.market.generated then
            self:generateLongTermTrends()
            self:generateInitialWorldEvents()
            self.market.generated=true
        end
        self.market.trendProfileSchemaVersion = GlobalMarketForcesConfig.trendProfileSchemaVersion or 1
        self:ensureLongTermTrendHorizon()
        self:ensureWorldEventHorizon()
        self:applyCropPrices()
    end
    self:registerMenuPage()
end

function GlobalMarketForces:deleteMap() end
function GlobalMarketForces:update(dt)
    self:checkMonthChange()
    self:updateCustomCropDiscovery(dt)
    if self.priceMenuRefreshPending then
        self.priceMenuRefreshPending = false
        self:refreshOpenPricesMenu()
    end
end
function GlobalMarketForces:getCurrentPeriodSafe() return g_currentMission and g_currentMission.environment and g_currentMission.environment.currentPeriod or nil end

function GlobalMarketForces:checkMonthChange()
    if g_server == nil then return end
    local p=self:getCurrentPeriodSafe()
    if not p then return end
    if not self.lastKnownPeriod then self.lastKnownPeriod=p; return end
    if p~=self.lastKnownPeriod then
        self.lastKnownPeriod=p
        self.market.currentMonthIndex=self.market.currentMonthIndex+1
        self:pruneExpiredMarketEntries(self.market.currentMonthIndex)
        self:ensureLongTermTrendHorizon()
        self:ensureWorldEventHorizon()
        self:applyCropPrices()
        self:saveMarketState()
        if GlobalMarketForcesMarketStateEvent ~= nil then
            GlobalMarketForcesMarketStateEvent.broadcastState()
        end
    end
end

addModEventListener(GlobalMarketForces)
