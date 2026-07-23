GlobalMarketForces=GlobalMarketForces or {}
GlobalMarketForces.MOD_NAME=g_currentModName or "FS25_GlobalMarketForces"
GlobalMarketForces.MOD_DIRECTORY=g_currentModDirectory or ""
GlobalMarketForces.market={currentMonthIndex=1,maxMonths=60,basePricesCaptured=false,generated=false,randomSeed=nil}
GlobalMarketForces.lastKnownPeriod=nil

function GlobalMarketForces:log(msg)
    if GlobalMarketForcesConfig and GlobalMarketForcesConfig.debug then
        print(string.format("[%s] %s",self.MOD_NAME,tostring(msg)))
    end
end

function GlobalMarketForces:loadMap()
    self.market.maxMonths=GlobalMarketForcesConfig.maxMonths or 60
    self:loadCustomCropAliases()
    self:installSellingStationPriceOverride()
    self:loadMarketState()
    self:registerDetectedCustomCropProfiles()
    self:registerReportActionEvents()
    self:captureBasePrices()
    if not self.market.generated then
        self:generateLongTermTrends()
        self:generateInitialWorldEvents()
        self.market.generated=true
    end
    self:ensureLongTermTrendHorizon()
    self:ensureWorldEventHorizon()
    self:applyCropPrices()
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
    end
end

addModEventListener(GlobalMarketForces)
