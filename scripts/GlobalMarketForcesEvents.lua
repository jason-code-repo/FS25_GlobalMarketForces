GlobalMarketForcesEvents={}
GlobalMarketForcesEvents.definitions={
 drought={displayName="Drought",minDuration=2,maxDuration=8,probabilityPerYear=0.45,priceDirection=1,cropImpacts={WHEAT=0.18,BARLEY=0.14,OAT=0.12,MAIZE=0.25,SOYBEAN=0.22,CANOLA=0.10,SUNFLOWER=0.08,SORGHUM=0.15,POTATO=0.14,SUGARBEET=0.16,SUGARCANE=0.20,COTTON=0.18,RICE=0.22,LONGGRAINRICE=0.24,GRASS=0.28,HAY=0.24,SILAGE=0.18,STRAW=0.12}},
 war={displayName="Conflict / Trade Disruption",minDuration=6,maxDuration=24,probabilityPerYear=0.20,priceDirection=1,cropImpacts={WHEAT=0.30,BARLEY=0.18,OAT=0.10,MAIZE=0.10,SOYBEAN=0.08,CANOLA=0.25,SUNFLOWER=0.22,SORGHUM=0.12,POTATO=0.06,SUGARBEET=0.10,SUGARCANE=0.16,COTTON=0.26,RICE=0.16,LONGGRAINRICE=0.20,GRASS=0.08,HAY=0.08,SILAGE=0.10,STRAW=0.14}},
 fuelSpike={displayName="Fuel Price Spike",minDuration=3,maxDuration=12,probabilityPerYear=0.35,priceDirection=1,cropImpacts={WHEAT=0.07,BARLEY=0.06,OAT=0.05,MAIZE=0.10,SOYBEAN=0.09,CANOLA=0.09,SUNFLOWER=0.08,SORGHUM=0.07,POTATO=0.08,SUGARBEET=0.10,SUGARCANE=0.14,COTTON=0.11,RICE=0.10,LONGGRAINRICE=0.11,GRASS=0.08,HAY=0.09,SILAGE=0.10,STRAW=0.06}},
 bumperHarvest={displayName="Bumper Harvest",minDuration=2,maxDuration=5,probabilityPerYear=0.35,priceDirection=-1,cropImpacts={WHEAT=0.16,BARLEY=0.14,OAT=0.12,MAIZE=0.18,SOYBEAN=0.12,CANOLA=0.10,SUNFLOWER=0.08,SORGHUM=0.10,POTATO=0.16,SUGARBEET=0.16,SUGARCANE=0.12,COTTON=0.18,RICE=0.15,LONGGRAINRICE=0.14,GRASS=0.22,HAY=0.18,SILAGE=0.16,STRAW=0.14}},
 exportBoom={displayName="Export Demand Boom",minDuration=4,maxDuration=10,probabilityPerYear=0.25,priceDirection=1,cropImpacts={WHEAT=0.12,BARLEY=0.08,OAT=0.06,MAIZE=0.10,SOYBEAN=0.17,CANOLA=0.15,SUNFLOWER=0.13,SORGHUM=0.09,POTATO=0.07,SUGARBEET=0.12,SUGARCANE=0.20,COTTON=0.20,RICE=0.18,LONGGRAINRICE=0.22,GRASS=0.06,HAY=0.08,SILAGE=0.08,STRAW=0.05}}
}
function GlobalMarketForces:generateWorldEventsForYear(year)
    local yearStartMonth = ((year - 1) * GlobalMarketForcesConfig.monthsPerYear) + 1
    for eventType, definition in pairs(GlobalMarketForcesEvents.definitions) do
        if self:getMarketRandomFloat() <= definition.probabilityPerYear then
            table.insert(self.generatedEvents, {
                eventType = eventType,
                startMonth = yearStartMonth + self:getMarketRandomInteger(0, GlobalMarketForcesConfig.monthsPerYear - 1),
                durationMonths = self:getMarketRandomInteger(definition.minDuration, definition.maxDuration),
                severity = self:getMarketRandomInteger(40, 100) / 100
            })
        end
    end
end

function GlobalMarketForces:ensureWorldEventHorizon()
    local currentMonth = (self.market or {}).currentMonthIndex or 1
    local horizonMonths = GlobalMarketForcesConfig.marketPlanningHorizonMonths or 60
    local targetYear = math.ceil((currentMonth + horizonMonths - 1) / GlobalMarketForcesConfig.monthsPerYear)
    local generatedThroughYear = self.market.eventsGeneratedThroughYear or 0
    while generatedThroughYear < targetYear do
        generatedThroughYear = generatedThroughYear + 1
        self:generateWorldEventsForYear(generatedThroughYear)
    end
    self.market.eventsGeneratedThroughYear = generatedThroughYear
end

function GlobalMarketForces:generateInitialWorldEvents()
    self.generatedEvents = {}
    self:ensureMarketRandomState()
    self.market.eventsGeneratedThroughYear = 0
    self:ensureWorldEventHorizon()
end
function GlobalMarketForces:isEventActive(e,m) return m>=e.startMonth and m<e.startMonth+e.durationMonths end
function GlobalMarketForces:getActiveEvents(m) local a={}; for _,e in ipairs(self.generatedEvents or {}) do if self:isEventActive(e,m) then table.insert(a,e) end end; return a end
function GlobalMarketForces:getWorldEventModifier(c,m) local mod=1; local referenceCrop=self:getTrendReferenceCrop(c); for _,e in ipairs(self.generatedEvents or {}) do if self:isEventActive(e,m) then local d=GlobalMarketForcesEvents.definitions[e.eventType]; local b=d and d.cropImpacts and (d.cropImpacts[c] or d.cropImpacts[referenceCrop]); if b then mod=mod*(1+(b*e.severity*(d.priceDirection or 1)*(GlobalMarketForcesConfig.worldEventWeight or 1))) end end end; return mod end
