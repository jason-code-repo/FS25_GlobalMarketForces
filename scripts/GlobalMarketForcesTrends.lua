-- Group-specific trend generator for FS25_GlobalMarketForces.
-- Global trend remains one active timeline. Crop demand/supply/policy trend pools are selected by profileGroup.

GlobalMarketForcesTrends = {}

GlobalMarketForcesTrends.globalDefinitions = {
    bullMarket = { displayName = "Global Commodity Bull Market", minYears = 1, maxYears = 5, baseImpact = 0.22 },
    bearMarket = { displayName = "Global Commodity Bear Market", minYears = 1, maxYears = 5, baseImpact = -0.20 },
    commoditySupercycle = { displayName = "Commodity Supercycle", minYears = 3, maxYears = 5, baseImpact = 0.45 },
    globalRecession = { displayName = "Global Recession", minYears = 1, maxYears = 4, baseImpact = -0.28 },
    energyInflation = { displayName = "Energy Inflation Cycle", minYears = 1, maxYears = 4, baseImpact = 0.16 }
}

GlobalMarketForcesTrends.groupDefinitions = {
    grain = {
        demand = {
            demandExpansion = { displayName = "Crop Demand Expansion", minYears = 1, maxYears = 5, baseImpact = 0.38 },
            demandCollapse = { displayName = "Crop Demand Collapse", minYears = 1, maxYears = 5, baseImpact = -0.45 },
            biofuelDemand = { displayName = "Biofuel Demand Cycle", minYears = 1, maxYears = 5, baseImpact = 0.52, cropBias = { MAIZE = 1.35, SOYBEAN = 1.25, CANOLA = 1.20, SUNFLOWER = 1.10 } },
            feedDemand = { displayName = "Animal Feed Export Demand Cycle", minYears = 1, maxYears = 5, baseImpact = 0.34, cropBias = { MAIZE = 1.35, BARLEY = 1.20, OAT = 1.15, SORGHUM = 1.15 } },
            maizeEthanolBoom = { displayName = "Maize Ethanol Boom", minYears = 1, maxYears = 5, baseImpact = 0.72, cropBias = { MAIZE = 1.55, SORGHUM = 1.15 } },
            soybeanExportSurge = { displayName = "Soybean Export Surge", minYears = 1, maxYears = 5, baseImpact = 0.58, cropBias = { SOYBEAN = 1.55, CANOLA = 1.10 } },
            canolaDieselDemand = { displayName = "Canola Renewable Diesel Demand", minYears = 1, maxYears = 5, baseImpact = 0.68, cropBias = { CANOLA = 1.60, SUNFLOWER = 1.15, SOYBEAN = 1.10 } },
            wheatStapleShortage = { displayName = "Wheat Staple Food Shortage", minYears = 1, maxYears = 5, baseImpact = 0.55, cropBias = { WHEAT = 1.60, BARLEY = 1.15, OAT = 1.10 } },
            riceExportDemand = { displayName = "Rice Export Demand", minYears = 1, maxYears = 5, baseImpact = 0.42, cropBias = { RICE = 1.45, LONGGRAINRICE = 1.65 } },
            stapleFoodDemand = { displayName = "Staple Food Demand Growth", minYears = 1, maxYears = 5, baseImpact = 0.32, cropBias = { RICE = 1.35, LONGGRAINRICE = 1.25, WHEAT = 1.15 } }
        },
        supply = {
            normalSupply = { displayName = "Normal Supply Conditions", minYears = 1, maxYears = 5, baseImpact = 0 },
            cropOversupply = { displayName = "Crop Oversupply Cycle", minYears = 1, maxYears = 5, baseImpact = -0.34 },
            recordHarvest = { displayName = "Record Harvest Pressure", minYears = 1, maxYears = 3, baseImpact = -0.42 },
            tightInventories = { displayName = "Tight Inventory Cycle", minYears = 1, maxYears = 4, baseImpact = 0.36 },
            acreageExpansion = { displayName = "Acreage Expansion", minYears = 1, maxYears = 4, baseImpact = -0.24 },
            acreageReduction = { displayName = "Acreage Reduction", minYears = 1, maxYears = 4, baseImpact = 0.26 },
            riceWeatherStress = { displayName = "Rice Weather Stress", minYears = 1, maxYears = 3, baseImpact = 0.40, cropBias = { RICE = 1.50, LONGGRAINRICE = 1.45 } },
            riceIdealGrowingConditions = { displayName = "Ideal Rice Growing Conditions", minYears = 1, maxYears = 3, baseImpact = -0.30, cropBias = { RICE = 1.35, LONGGRAINRICE = 1.30 } }
        },
        policy = {
            neutralPolicy = { displayName = "Neutral Policy Environment", minYears = 1, maxYears = 5, baseImpact = 0 },
            renewableFuelMandate = { displayName = "Renewable Fuel Mandate", minYears = 1, maxYears = 5, baseImpact = 0.34, cropBias = { MAIZE = 1.35, CANOLA = 1.35, SOYBEAN = 1.15, SUNFLOWER = 1.10 } },
            exportRestriction = { displayName = "Export Restrictions", minYears = 1, maxYears = 3, baseImpact = -0.28 },
            exportSubsidy = { displayName = "Export Subsidy", minYears = 1, maxYears = 4, baseImpact = 0.24 },
            riceImportRestrictions = { displayName = "Rice Import Restrictions", minYears = 1, maxYears = 4, baseImpact = 0.22, cropBias = { RICE = 1.35, LONGGRAINRICE = 1.35 } },
            riceExportRestriction = { displayName = "Rice Export Restrictions", minYears = 1, maxYears = 3, baseImpact = -0.24, cropBias = { RICE = 1.30, LONGGRAINRICE = 1.30 } }
        }
    },

    vegetable = {
        demand = {
            freshProduceDemand = { displayName = "Fresh Produce Demand", minYears = 1, maxYears = 3, baseImpact = 0.34 },
            processingDemand = { displayName = "Vegetable Processing Demand", minYears = 1, maxYears = 4, baseImpact = 0.36 },
            healthFoodTrend = { displayName = "Health Food Trend", minYears = 1, maxYears = 4, baseImpact = 0.30, cropBias = { SPINACH = 1.45, GREENBEAN = 1.25, PEA = 1.20, CARROT = 1.15 } },
            freezerAisleExpansion = { displayName = "Frozen Food Demand", minYears = 1, maxYears = 4, baseImpact = 0.32, cropBias = { GREENBEAN = 1.35, PEA = 1.30, CARROT = 1.15, POTATO = 1.20 } },
            rootCropDemand = { displayName = "Root Crop Demand", minYears = 1, maxYears = 4, baseImpact = 0.28, cropBias = { POTATO = 1.35, CARROT = 1.20, PARSNIP = 1.25, REDBEET = 1.20 } },
            localProduceSlump = { displayName = "Fresh Produce Demand Slump", minYears = 1, maxYears = 3, baseImpact = -0.36 }
        },
        supply = {
            normalVegetableSupply = { displayName = "Normal Vegetable Supply", minYears = 1, maxYears = 3, baseImpact = 0 },
            vegetableOversupply = { displayName = "Vegetable Oversupply", minYears = 1, maxYears = 2, baseImpact = -0.35 },
            diseasePressure = { displayName = "Vegetable Disease Pressure", minYears = 1, maxYears = 2, baseImpact = 0.42 },
            laborShortage = { displayName = "Vegetable Labor Shortage", minYears = 1, maxYears = 3, baseImpact = 0.30 },
            exceptionalGrowingConditions = { displayName = "Exceptional Vegetable Growing Conditions", minYears = 1, maxYears = 2, baseImpact = -0.28 },
            storageLosses = { displayName = "Storage Losses", minYears = 1, maxYears = 2, baseImpact = 0.26 }
        },
        policy = {
            neutralProducePolicy = { displayName = "Neutral Produce Policy", minYears = 1, maxYears = 5, baseImpact = 0 },
            produceSubsidy = { displayName = "Fresh Produce Subsidy", minYears = 1, maxYears = 4, baseImpact = 0.20 },
            foodSafetyRegulation = { displayName = "Food Safety Regulation Costs", minYears = 1, maxYears = 3, baseImpact = 0.16 },
            importCompetition = { displayName = "Imported Produce Competition", minYears = 1, maxYears = 4, baseImpact = -0.24 },
            schoolNutritionProgram = { displayName = "School Nutrition Program", minYears = 1, maxYears = 4, baseImpact = 0.18, cropBias = { CARROT = 1.25, SPINACH = 1.25, PEA = 1.15 } }
        }
    },

    sugarCrop = {
        demand = {
            sugarDemandGrowth = { displayName = "Sugar Demand Growth", minYears = 1, maxYears = 4, baseImpact = 0.34 },
            ethanolDemandGrowth = { displayName = "Ethanol Demand Growth", minYears = 1, maxYears = 5, baseImpact = 0.42, cropBias = { SUGARCANE = 1.45, SUGARBEET = 1.15 } },
            sugarDemandSlump = { displayName = "Sugar Demand Slowdown", minYears = 1, maxYears = 3, baseImpact = -0.32 },
            foodProcessingDemand = { displayName = "Food Processing Demand", minYears = 1, maxYears = 4, baseImpact = 0.26, cropBias = { SUGARBEET = 1.20 } }
        },
        supply = {
            normalSugarSupply = { displayName = "Normal Sugar Supply", minYears = 1, maxYears = 4, baseImpact = 0 },
            sugarSupplyShortage = { displayName = "Sugar Supply Shortage", minYears = 1, maxYears = 3, baseImpact = 0.38 },
            beetHarvestPressure = { displayName = "Sugar Beet Harvest Pressure", minYears = 1, maxYears = 2, baseImpact = 0.34, cropBias = { SUGARBEET = 1.55 } },
            caneWeatherStress = { displayName = "Sugarcane Weather Stress", minYears = 1, maxYears = 3, baseImpact = 0.40, cropBias = { SUGARCANE = 1.60 } },
            strongSugarHarvest = { displayName = "Strong Sugar Harvest", minYears = 1, maxYears = 3, baseImpact = -0.30 }
        },
        policy = {
            neutralSugarPolicy = { displayName = "Neutral Sugar Policy", minYears = 1, maxYears = 5, baseImpact = 0 },
            ethanolMandate = { displayName = "Ethanol Blending Mandate", minYears = 1, maxYears = 5, baseImpact = 0.32, cropBias = { SUGARCANE = 1.45, SUGARBEET = 1.15 } },
            sugarExportSupport = { displayName = "Sugar Export Support", minYears = 1, maxYears = 4, baseImpact = 0.24 },
            sugarImportPressure = { displayName = "Sugar Import Pressure", minYears = 1, maxYears = 4, baseImpact = -0.24 }
        }
    },

    orchard = {
        demand = {
            premiumFoodDemand = { displayName = "Premium Food Demand", minYears = 2, maxYears = 5, baseImpact = 0.24 },
            wineExportGrowth = { displayName = "Wine Export Growth", minYears = 2, maxYears = 5, baseImpact = 0.32, cropBias = { GRAPE = 1.55 } },
            oliveOilDemand = { displayName = "Olive Oil Demand Growth", minYears = 2, maxYears = 5, baseImpact = 0.30, cropBias = { OLIVE = 1.55 } },
            tourismDemand = { displayName = "Agri-Tourism Demand", minYears = 2, maxYears = 5, baseImpact = 0.18 },
            premiumDemandSlump = { displayName = "Premium Food Demand Slump", minYears = 2, maxYears = 5, baseImpact = -0.22 }
        },
        supply = {
            normalOrchardSupply = { displayName = "Normal Orchard Supply", minYears = 2, maxYears = 5, baseImpact = 0 },
            poorHarvestSeason = { displayName = "Poor Orchard Harvest", minYears = 1, maxYears = 3, baseImpact = 0.30 },
            orchardExpansion = { displayName = "Orchard Expansion", minYears = 3, maxYears = 5, baseImpact = -0.20 },
            waterStress = { displayName = "Orchard Water Stress", minYears = 1, maxYears = 4, baseImpact = 0.28 },
            idealOrchardSeason = { displayName = "Ideal Orchard Season", minYears = 1, maxYears = 3, baseImpact = -0.18 }
        },
        policy = {
            neutralOrchardPolicy = { displayName = "Neutral Orchard Policy", minYears = 2, maxYears = 5, baseImpact = 0 },
            exportIncentives = { displayName = "Premium Export Incentives", minYears = 2, maxYears = 5, baseImpact = 0.18 },
            waterRestrictions = { displayName = "Water Usage Restrictions", minYears = 1, maxYears = 4, baseImpact = 0.24 },
            regionalBrandSupport = { displayName = "Regional Brand Support", minYears = 2, maxYears = 5, baseImpact = 0.16 }
        }
    },

    industrial = {
        demand = {
            textileMarketExpansion = { displayName = "Textile Market Expansion", minYears = 1, maxYears = 5, baseImpact = 0.46, cropBias = { COTTON = 1.70 } },
            textileDemandSlump = { displayName = "Textile Demand Slump", minYears = 1, maxYears = 5, baseImpact = -0.38, cropBias = { COTTON = 1.50 } },
            manufacturingDemand = { displayName = "Manufacturing Demand", minYears = 1, maxYears = 4, baseImpact = 0.28 }
        },
        supply = {
            normalIndustrialSupply = { displayName = "Normal Industrial Crop Supply", minYears = 1, maxYears = 5, baseImpact = 0 },
            cottonWeatherStress = { displayName = "Cotton Weather Stress", minYears = 1, maxYears = 3, baseImpact = 0.38, cropBias = { COTTON = 1.55 } },
            cottonRecordHarvest = { displayName = "Cotton Record Harvest", minYears = 1, maxYears = 3, baseImpact = -0.36, cropBias = { COTTON = 1.45 } }
        },
        policy = {
            neutralIndustrialPolicy = { displayName = "Neutral Industrial Policy", minYears = 1, maxYears = 5, baseImpact = 0 },
            textileImportPressure = { displayName = "Textile Import Pressure", minYears = 1, maxYears = 4, baseImpact = -0.26, cropBias = { COTTON = 1.50 } },
            cottonExportSubsidy = { displayName = "Cotton Export Subsidy", minYears = 1, maxYears = 4, baseImpact = 0.28, cropBias = { COTTON = 1.50 } },
            tradePolicyShock = { displayName = "Industrial Trade Policy Shock", minYears = 1, maxYears = 4, baseImpact = -0.24 }
        }
    }
,
    forage = {
        demand = {
            dairyFeedDemand = { displayName = "Dairy Feed Demand", minYears = 1, maxYears = 4, baseImpact = 0.34, cropBias = { SILAGE = 1.45, HAY = 1.25, GRASS = 1.25 } },
            forageDemandGrowth = { displayName = "Forage Demand Growth", minYears = 1, maxYears = 4, baseImpact = 0.28 },
            beddingDemand = { displayName = "Bedding Demand", minYears = 1, maxYears = 4, baseImpact = 0.18, cropBias = { STRAW = 1.60 } },
            hayExportDemand = { displayName = "Hay Export Demand", minYears = 1, maxYears = 4, baseImpact = 0.22, cropBias = { HAY = 1.45 } },
            forageDemandSlump = { displayName = "Forage Demand Slump", minYears = 1, maxYears = 3, baseImpact = -0.26 }
        },
        supply = {
            normalForageSupply = { displayName = "Normal Forage Supply", minYears = 1, maxYears = 4, baseImpact = 0 },
            forageShortage = { displayName = "Forage Shortage", minYears = 1, maxYears = 3, baseImpact = 0.34 },
            excellentHaySeason = { displayName = "Excellent Hay Season", minYears = 1, maxYears = 2, baseImpact = -0.26, cropBias = { HAY = 1.35, GRASS = 1.25 } },
            silageOversupply = { displayName = "Silage Oversupply", minYears = 1, maxYears = 3, baseImpact = -0.24, cropBias = { SILAGE = 1.40 } },
            droughtReducedPasture = { displayName = "Drought-Reduced Pasture", minYears = 1, maxYears = 3, baseImpact = 0.30, cropBias = { GRASS = 1.40, HAY = 1.20 } }
        },
        policy = {
            neutralForagePolicy = { displayName = "Neutral Forage Policy", minYears = 1, maxYears = 5, baseImpact = 0 },
            dairySupportProgram = { displayName = "Dairy Support Program", minYears = 1, maxYears = 5, baseImpact = 0.18, cropBias = { SILAGE = 1.30, HAY = 1.15, GRASS = 1.15 } },
            conservationGrasslandProgram = { displayName = "Conservation Grassland Program", minYears = 1, maxYears = 5, baseImpact = 0.14, cropBias = { GRASS = 1.35, HAY = 1.20 } },
            forageImportCompetition = { displayName = "Forage Import Competition", minYears = 1, maxYears = 4, baseImpact = -0.18 }
        }
    }

}

function GlobalMarketForces:getProfileGroup(cropName)
    local profile = GlobalMarketForcesConfig.marketProfiles[cropName]
    return profile ~= nil and profile.profileGroup or "grain"
end

function GlobalMarketForces:getDefinitionsForCropChannel(cropName, channelName)
    local groupName = self:getProfileGroup(cropName)
    local groupDefinitions = GlobalMarketForcesTrends.groupDefinitions[groupName] or GlobalMarketForcesTrends.groupDefinitions.grain
    return groupDefinitions[channelName] or {}
end

function GlobalMarketForces:generateLongTermTrends()
    self.globalTrends = {}
    self.cropTrends = {}
    if GlobalMarketForcesConfig.enableGlobalTrends then self:generateGlobalTrendTimeline() end
    for cropName, _ in pairs(GlobalMarketForcesConfig.marketProfiles) do
        self.cropTrends[cropName] = { demand = {}, supply = {}, policy = {} }
        self:generateCropChannelTrendTimeline(cropName, "demand", self:getDefinitionsForCropChannel(cropName, "demand"))
        self:generateCropChannelTrendTimeline(cropName, "supply", self:getDefinitionsForCropChannel(cropName, "supply"))
        self:generateCropChannelTrendTimeline(cropName, "policy", self:getDefinitionsForCropChannel(cropName, "policy"))
    end
end

function GlobalMarketForces:normalizeTrendDurationMonths(definition, remainingMonths)
    local minMonths = (definition.minYears or 1) * GlobalMarketForcesConfig.monthsPerYear
    local maxMonths = (definition.maxYears or 5) * GlobalMarketForcesConfig.monthsPerYear
    local duration = self:getMarketRandomInteger(minMonths, maxMonths)
    if duration > remainingMonths then duration = remainingMonths end
    if remainingMonths - duration > 0 and remainingMonths - duration < minMonths then duration = remainingMonths end
    return duration
end

-- A cropBias table means that this is a named, crop-targeted trend. Trends
-- without one are intentionally broad and apply to the whole profile group.
function GlobalMarketForces:isCropTrendDefinitionRelevant(definition, cropName)
    local referenceCrop = self:getTrendReferenceCrop(cropName)
    return definition ~= nil and (definition.cropBias == nil or definition.cropBias[cropName] ~= nil or definition.cropBias[referenceCrop] ~= nil)
end

function GlobalMarketForces:pickWeightedDefinition(definitions, cropName)
    local keys = {}
    for key, definition in pairs(definitions) do
        if cropName == nil or self:isCropTrendDefinitionRelevant(definition, cropName) then
            table.insert(keys, key)
        end
    end
    if #keys == 0 then return nil, nil end
    local selectedKey = keys[self:getMarketRandomInteger(1, #keys)]
    return selectedKey, definitions[selectedKey]
end

function GlobalMarketForces:generateGlobalTrendTimeline()
    local month = 1
    while month <= self.market.maxMonths do
        local remaining = self.market.maxMonths - month + 1
        local trendType, definition = self:pickWeightedDefinition(GlobalMarketForcesTrends.globalDefinitions)
        if trendType == nil then return end
        local duration = self:normalizeTrendDurationMonths(definition, remaining)
        table.insert(self.globalTrends, { channel = "global", trendType = trendType, startMonth = month, durationMonths = duration, severity = self:getMarketRandomInteger(55, 100) / 100 })
        month = month + duration
    end
end

function GlobalMarketForces:generateCropChannelTrendTimeline(cropName, channelName, definitions)
    local month = 1
    while month <= self.market.maxMonths do
        local remaining = self.market.maxMonths - month + 1
        local trendType, definition = self:pickWeightedDefinition(definitions, cropName)
        if trendType == nil then return end
        local duration = self:normalizeTrendDurationMonths(definition, remaining)
        table.insert(self.cropTrends[cropName][channelName], { channel = channelName, trendType = trendType, startMonth = month, durationMonths = duration, severity = self:getMarketRandomInteger(45, 100) / 100 })
        month = month + duration
    end
end

function GlobalMarketForces:getTrendDurationMonths(definition)
    local minMonths = math.max(12, (definition.minYears or GlobalMarketForcesConfig.minTrendYears or 1) * GlobalMarketForcesConfig.monthsPerYear)
    local maxMonths = math.max(minMonths, math.min(60, (definition.maxYears or GlobalMarketForcesConfig.maxTrendYears or 5) * GlobalMarketForcesConfig.monthsPerYear))
    return self:getMarketRandomInteger(minMonths, maxMonths)
end

function GlobalMarketForces:getTimelineNextStartMonth(entries, fallbackMonth)
    local nextStartMonth = fallbackMonth
    for _, entry in ipairs(entries or {}) do
        nextStartMonth = math.max(nextStartMonth, (entry.startMonth or fallbackMonth) + (entry.durationMonths or 1))
    end
    return nextStartMonth
end

function GlobalMarketForces:extendGlobalTrendTimeline(targetMonth)
    self.globalTrends = self.globalTrends or {}
    local nextStartMonth = self:getTimelineNextStartMonth(self.globalTrends, self.market.currentMonthIndex or 1)
    while nextStartMonth <= targetMonth do
        local trendType, definition = self:pickWeightedDefinition(GlobalMarketForcesTrends.globalDefinitions)
        if trendType == nil then return end
        local duration = self:getTrendDurationMonths(definition)
        table.insert(self.globalTrends, { channel = "global", trendType = trendType, startMonth = nextStartMonth, durationMonths = duration, severity = self:getMarketRandomInteger(55, 100) / 100 })
        nextStartMonth = nextStartMonth + duration
    end
end

function GlobalMarketForces:extendCropChannelTrendTimeline(cropName, channelName, definitions, targetMonth)
    self.cropTrends[cropName] = self.cropTrends[cropName] or { demand = {}, supply = {}, policy = {} }
    local entries = self.cropTrends[cropName][channelName] or {}
    self.cropTrends[cropName][channelName] = entries
    local nextStartMonth = self:getTimelineNextStartMonth(entries, self.market.currentMonthIndex or 1)
    while nextStartMonth <= targetMonth do
        local trendType, definition = self:pickWeightedDefinition(definitions, cropName)
        if trendType == nil then return end
        local duration = self:getTrendDurationMonths(definition)
        table.insert(entries, { channel = channelName, trendType = trendType, startMonth = nextStartMonth, durationMonths = duration, severity = self:getMarketRandomInteger(45, 100) / 100 })
        nextStartMonth = nextStartMonth + duration
    end
end

function GlobalMarketForces:ensureLongTermTrendHorizon()
    local currentMonth = (self.market or {}).currentMonthIndex or 1
    local horizonMonths = GlobalMarketForcesConfig.marketPlanningHorizonMonths or 60
    local targetMonth = currentMonth + horizonMonths - 1

    if GlobalMarketForcesConfig.enableGlobalTrends then
        self:extendGlobalTrendTimeline(targetMonth)
    end

    for cropName, _ in pairs(GlobalMarketForcesConfig.marketProfiles) do
        self:extendCropChannelTrendTimeline(cropName, "demand", self:getDefinitionsForCropChannel(cropName, "demand"), targetMonth)
        self:extendCropChannelTrendTimeline(cropName, "supply", self:getDefinitionsForCropChannel(cropName, "supply"), targetMonth)
        self:extendCropChannelTrendTimeline(cropName, "policy", self:getDefinitionsForCropChannel(cropName, "policy"), targetMonth)
    end
end

-- Existing saves retain their market timeline. When a crop is intentionally
-- moved into a new profile group, regenerate only that crop's forward trend
-- channels so its report and prices use the new market logic immediately.
function GlobalMarketForces:migrateTrendProfileSchema()
    local targetVersion = GlobalMarketForcesConfig.trendProfileSchemaVersion or 1
    self.market = self.market or {}
    if (self.market.trendProfileSchemaVersion or 1) >= targetVersion then return false end

    self.cropTrends = self.cropTrends or {}
    local currentMonth = self.market.currentMonthIndex or 1
    local targetMonth = currentMonth + (GlobalMarketForcesConfig.marketPlanningHorizonMonths or 60) - 1
    for _, cropName in ipairs({ "SUGARBEET", "SUGARCANE" }) do
        if GlobalMarketForcesConfig.marketProfiles[cropName] ~= nil then
            self.cropTrends[cropName] = { demand = {}, supply = {}, policy = {} }
            self:extendCropChannelTrendTimeline(cropName, "demand", self:getDefinitionsForCropChannel(cropName, "demand"), targetMonth)
            self:extendCropChannelTrendTimeline(cropName, "supply", self:getDefinitionsForCropChannel(cropName, "supply"), targetMonth)
            self:extendCropChannelTrendTimeline(cropName, "policy", self:getDefinitionsForCropChannel(cropName, "policy"), targetMonth)
        end
    end

    self.market.cropForecasts = {}
    self.market.trendProfileSchemaVersion = targetVersion
    self:log("Updated sugar crop trend profiles for this savegame")
    return true
end

function GlobalMarketForces:isTrendActive(trend, monthIndex)
    return monthIndex >= trend.startMonth and monthIndex < trend.startMonth + trend.durationMonths
end

function GlobalMarketForces:pruneExpiredMarketEntries(monthIndex)
    monthIndex = monthIndex or ((self.market or {}).currentMonthIndex or 1)
    local removedCount = 0

    local function pruneList(entries)
        local activeOrFuture = {}
        for _, entry in ipairs(entries or {}) do
            local endMonth = (entry.startMonth or 1) + (entry.durationMonths or 1)
            if monthIndex < endMonth then
                table.insert(activeOrFuture, entry)
            else
                removedCount = removedCount + 1
            end
        end
        return activeOrFuture
    end

    self.globalTrends = pruneList(self.globalTrends)
    self.generatedEvents = pruneList(self.generatedEvents)

    for _, channels in pairs(self.cropTrends or {}) do
        for _, channelName in ipairs({ "demand", "supply", "policy" }) do
            channels[channelName] = pruneList(channels[channelName])
        end
    end

    return removedCount
end

function GlobalMarketForces:getTrendRampFactor(trend, monthIndex)
    local progress = (monthIndex - trend.startMonth) / math.max(1, trend.durationMonths - 1)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    return progress * progress * (3 - (2 * progress))
end

function GlobalMarketForces:getDefinitionForCropTrend(channelName, trendType, cropName)
    local definitions = self:getDefinitionsForCropChannel(cropName, channelName)
    return definitions[trendType]
end

function GlobalMarketForces:getCropChannelWeight(channelName)
    if channelName == "demand" then return GlobalMarketForcesConfig.cropDemandTrendWeight end
    if channelName == "supply" then return GlobalMarketForcesConfig.cropSupplyTrendWeight end
    if channelName == "policy" then return GlobalMarketForcesConfig.cropPolicyTrendWeight end
    return 1
end

function GlobalMarketForces:getCropChannelSensitivity(profile, channelName)
    if channelName == "demand" then return profile.demandSensitivity or 1 end
    if channelName == "supply" then return profile.supplySensitivity or 1 end
    if channelName == "policy" then return profile.policySensitivity or 1 end
    return 1
end

function GlobalMarketForces:getGlobalTrendModifier(cropName, monthIndex)
    local profile = GlobalMarketForcesConfig.marketProfiles[cropName] or {}
    local modifier = 1
    for _, trend in ipairs(self.globalTrends or {}) do
        if self:isTrendActive(trend, monthIndex) then
            local definition = GlobalMarketForcesTrends.globalDefinitions[trend.trendType]
            if definition then modifier = modifier * (1 + (definition.baseImpact * trend.severity * self:getTrendRampFactor(trend, monthIndex) * (profile.globalTrendSensitivity or 1) * GlobalMarketForcesConfig.globalTrendWeight)) end
        end
    end
    return modifier
end

function GlobalMarketForces:getCropChannelTrendModifier(cropName, channelName, monthIndex)
    local profile = GlobalMarketForcesConfig.marketProfiles[cropName] or {}
    local modifier = 1
    for _, trend in ipairs((((self.cropTrends or {})[cropName] or {})[channelName] or {})) do
        if self:isTrendActive(trend, monthIndex) then
            local definition = self:getDefinitionForCropTrend(channelName, trend.trendType, cropName)
            if self:isCropTrendDefinitionRelevant(definition, cropName) then
                local referenceCrop = self:getTrendReferenceCrop(cropName)
                local bias = (definition.cropBias and (definition.cropBias[cropName] or definition.cropBias[referenceCrop])) or 1
                modifier = modifier * (1 + (definition.baseImpact * trend.severity * self:getTrendRampFactor(trend, monthIndex) * bias * self:getCropChannelSensitivity(profile, channelName) * self:getCropChannelWeight(channelName)))
            end
        end
    end
    return modifier
end

function GlobalMarketForces:getLongTermTrendModifier(cropName, monthIndex)
    return self:getGlobalTrendModifier(cropName, monthIndex) * self:getCropChannelTrendModifier(cropName, "demand", monthIndex) * self:getCropChannelTrendModifier(cropName, "supply", monthIndex) * self:getCropChannelTrendModifier(cropName, "policy", monthIndex)
end

function GlobalMarketForces:getActiveGlobalTrends(monthIndex)
    local active = {}
    for _, trend in ipairs(self.globalTrends or {}) do if self:isTrendActive(trend, monthIndex) then table.insert(active, trend) end end
    return active
end

function GlobalMarketForces:getActiveCropChannelTrends(cropName, channelName, monthIndex)
    local active = {}
    for _, trend in ipairs((((self.cropTrends or {})[cropName] or {})[channelName] or {})) do
        local definition = self:getDefinitionForCropTrend(channelName, trend.trendType, cropName)
        if self:isTrendActive(trend, monthIndex) and self:isCropTrendDefinitionRelevant(definition, cropName) then
            table.insert(active, trend)
        end
    end
    return active
end

function GlobalMarketForces:getActiveCropTrends(cropName, monthIndex)
    local active = {}
    for _, channelName in ipairs({ "demand", "supply", "policy" }) do
        for _, trend in ipairs(self:getActiveCropChannelTrends(cropName, channelName, monthIndex)) do table.insert(active, trend) end
    end
    return active
end
