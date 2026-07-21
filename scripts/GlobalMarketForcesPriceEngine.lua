function GlobalMarketForces:getFillTypeIndex(cropName)
    if g_fillTypeManager == nil then return nil end
    if g_fillTypeManager.getFillTypeIndexByName ~= nil then
        return g_fillTypeManager:getFillTypeIndexByName(cropName)
    end
    return g_fillTypeManager.nameToIndex and g_fillTypeManager.nameToIndex[cropName] or nil
end

function GlobalMarketForces:captureBasePrices()
    self.basePrices = {}
    for cropName, _ in pairs(GlobalMarketForcesConfig.cropProfiles) do
        self.basePrices[cropName] = self:getCurrentFillTypePrice(cropName) or 1
    end
    self.market.basePricesCaptured = true
end

function GlobalMarketForces:getCurrentFillTypePrice(cropName)
    local fillTypeIndex = self:getFillTypeIndex(cropName)
    local fillType = fillTypeIndex and g_fillTypeManager:getFillTypeByIndex(fillTypeIndex) or nil
    return fillType and fillType.pricePerLiter or nil
end

function GlobalMarketForces:setFillTypePrice(cropName, price)
    local fillTypeIndex = self:getFillTypeIndex(cropName)
    local fillType = fillTypeIndex and g_fillTypeManager:getFillTypeByIndex(fillTypeIndex) or nil
    if fillType == nil then return false end
    fillType.pricePerLiter = price
    return true
end

function GlobalMarketForces:getAllSellingStations()
    if g_currentMission == nil then return {} end

    local stations, seen = {}, {}
    local function addStation(station)
        if station ~= nil and station.fillTypePrices ~= nil and not seen[station] then
            seen[station] = true
            table.insert(stations, station)
        end
    end

    local storageSystem = g_currentMission.storageSystem
    if storageSystem ~= nil and storageSystem.getUnloadingStations ~= nil then
        for _, station in pairs(storageSystem:getUnloadingStations() or {}) do addStation(station) end
    end

    -- Certain production-owned selling points, including Grain Mill, can be
    -- registered with the Economy Manager separately from the Storage System.
    -- The base-game Prices page reads the Economy Manager list.
    local economyManager = g_currentMission.economyManager
    if economyManager ~= nil then
        if economyManager.getSellingStations ~= nil then
            for _, station in pairs(economyManager:getSellingStations() or {}) do addStation(station) end
        elseif economyManager.sellingStations ~= nil then
            for _, station in pairs(economyManager.sellingStations) do addStation(station) end
        end
    end

    return stations
end

-- Temporary diagnostic for the base-game Grain Mill row. Its price remains
-- separate from other selling stations in the Prices menu, so record every
-- station reference through which the production point can be reached.
function GlobalMarketForces:logGrainMillStationSources()
    if g_currentMission == nil or g_fillTypeManager == nil then return end

    local barleyIndex = self:getFillTypeIndex("BARLEY")
    if barleyIndex == nil then return end

    local function getName(object)
        if object == nil then return "<nil>" end
        if object.getName ~= nil then
            local name = object:getName()
            if name ~= nil and name ~= "" then return name end
        end
        return "<unnamed>"
    end

    local function logStation(source, station)
        if station == nil then return end
        local name = getName(station)
        if not string.find(string.lower(name), "grain mill", 1, true) then return end
        local price = station.fillTypePrices and station.fillTypePrices[barleyIndex] or nil
        self:log(string.format(
            "GMF DIAG Grain Mill [%s] ref=%s name=%s barley=%s selling=%s owner=%s",
            source,
            tostring(station),
            name,
            tostring(price),
            tostring(station.isSellingPoint),
            tostring(station.owningPlaceable and station.owningPlaceable.ownerFarmId or station.ownerFarmId)
        ))
    end

    local storageSystem = g_currentMission.storageSystem
    if storageSystem ~= nil and storageSystem.getUnloadingStations ~= nil then
        for _, station in pairs(storageSystem:getUnloadingStations() or {}) do
            logStation("storageSystem", station)
        end
    end

    local economyManager = g_currentMission.economyManager
    if economyManager ~= nil then
        local stations = economyManager.getSellingStations and economyManager:getSellingStations() or economyManager.sellingStations
        for _, station in pairs(stations or {}) do
            logStation("economyManager", station)
        end
    end

    local productionChainManager = g_currentMission.productionChainManager
    if productionChainManager ~= nil and productionChainManager.getProductionPoints ~= nil then
        for _, productionPoint in pairs(productionChainManager:getProductionPoints() or {}) do
            local name = getName(productionPoint)
            local placeable = productionPoint.owningPlaceable
            local placeableName = getName(placeable)
            if string.find(string.lower(name .. " " .. placeableName), "grain mill", 1, true) then
                self:log(string.format("GMF DIAG Grain Mill production ref=%s name=%s placeable=%s", tostring(productionPoint), name, placeableName))
                logStation("productionPoint", productionPoint)
                logStation("productionPoint.sellingStation", productionPoint.sellingStation)
                logStation("productionPoint.unloadingStation", productionPoint.unloadingStation)
            end
        end
    end
end

function GlobalMarketForces:captureSellingStationBasePrices()
    if g_server == nil or g_currentMission == nil then return 0 end

    self.sellingStationBasePrices = self.sellingStationBasePrices or {}
    self.sellingStationBaseEffectivePrices = self.sellingStationBaseEffectivePrices or {}
    local capturedStations = 0
    for _, station in pairs(self:getAllSellingStations()) do
        if station.isSellingPoint == true and station.fillTypePrices ~= nil and self.sellingStationBasePrices[station] == nil then
            local basePrices = {}
            local baseEffectivePrices = {}
            for cropName, _ in pairs(GlobalMarketForcesConfig.marketProfiles) do
                local fillTypeIndex = self:getFillTypeIndex(cropName)
                local stationPrice = fillTypeIndex and station.fillTypePrices[fillTypeIndex] or nil
                if stationPrice ~= nil then
                    basePrices[cropName] = stationPrice
                    -- Capture the game's difficulty-adjusted, station-specific
                    -- effective price once. GMF owns future movement from this
                    -- fixed nominal baseline, rather than inheriting the base
                    -- game's seasonal and great-demand changes each month.
                    baseEffectivePrices[cropName] = self:getDefaultSellingStationPrice(station, fillTypeIndex, stationPrice)
                end
            end
            self.sellingStationBasePrices[station] = basePrices
            self.sellingStationBaseEffectivePrices[station] = baseEffectivePrices
            capturedStations = capturedStations + 1
        end
    end

    return capturedStations
end

function GlobalMarketForces:getSellingStationName(station, stationIndex)
    if station.getName ~= nil then
        local name = station:getName()
        if name ~= nil and name ~= "" then return name end
    end
    return "Selling station " .. tostring(stationIndex)
end

function GlobalMarketForces:isManagedFillType(fillTypeIndex)
    if g_fillTypeManager == nil then return false end
    local cropName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
    return cropName ~= nil and GlobalMarketForcesConfig.marketProfiles[cropName] ~= nil
end

function GlobalMarketForces.getSellingStationEffectiveFillTypePrice(station, superFunc, fillTypeIndex)
    if GlobalMarketForces:isManagedFillType(fillTypeIndex) and station.gmfEffectiveFillTypePrices ~= nil then
        local price = station.gmfEffectiveFillTypePrices[fillTypeIndex]
        if price ~= nil then return price end
    end
    return superFunc(station, fillTypeIndex)
end

function GlobalMarketForces:installSellingStationPriceOverride()
    if self.sellingStationPriceOverrideInstalled == true then return end
    if SellingStation == nil or SellingStation.getEffectiveFillTypePrice == nil then return end

    self.gmfOriginalSellingStationGetEffectiveFillTypePrice = SellingStation.getEffectiveFillTypePrice
    SellingStation.getEffectiveFillTypePrice = Utils.overwrittenFunction(
        SellingStation.getEffectiveFillTypePrice,
        GlobalMarketForces.getSellingStationEffectiveFillTypePrice
    )
    self.sellingStationPriceOverrideInstalled = true
end

function GlobalMarketForces:getDefaultSellingStationPrice(station, fillTypeIndex, basePrice)
    local getEffectiveFillTypePrice = self.gmfOriginalSellingStationGetEffectiveFillTypePrice
    if getEffectiveFillTypePrice == nil then return basePrice end

    -- Temporarily restore the station's captured, difficulty-adjusted base price
    -- so the original game method can calculate its normal effective price.
    local marketPrice = station.fillTypePrices[fillTypeIndex]
    station.fillTypePrices[fillTypeIndex] = basePrice
    local defaultPrice = getEffectiveFillTypePrice(station, fillTypeIndex)
    station.fillTypePrices[fillTypeIndex] = marketPrice
    return defaultPrice
end

function GlobalMarketForces:clearPricesFrameCache(pricesFrame)
    -- The Prices frame retains data independently from the visible row list.
    -- Clear only known price/station data containers; do not touch GUI controls,
    -- selected-fill-type state, or callback tables.
    local cacheNames = {
        "priceData",
        "pricesData",
        "priceCache",
        "stationPriceData",
        "sellingStationData",
        "sellingStationCache",
        "stationPriceCache"
    }

    for _, cacheName in ipairs(cacheNames) do
        local cache = pricesFrame[cacheName]
        if type(cache) == "table" then
            for key in pairs(cache) do
                cache[key] = nil
            end
        end
    end
end

-- Temporary: find the exact cached entry used by the Prices frame for Grain
-- Mill. The station itself is updated, so the stale value must live in this
-- GUI-side data tree.
function GlobalMarketForces:logGrainMillPricesFrameData(pricesFrame)
    if pricesFrame == nil then return end

    local grainMillStation = nil
    for _, station in pairs(self:getAllSellingStations()) do
        if string.lower(self:getSellingStationName(station, "")) == "grain mill" then
            grainMillStation = station
            break
        end
    end
    if grainMillStation == nil then return end

    local visited, detailVisited, matches, detailLines = {}, {}, 0, 0
    local function summarize(entry)
        local details, count = {}, 0
        for key, value in pairs(entry) do
            if type(key) == "string" and (type(value) == "string" or type(value) == "number" or type(value) == "boolean") then
                count = count + 1
                if count <= 10 then table.insert(details, key .. "=" .. tostring(value)) end
            end
        end
        return table.concat(details, ", ")
    end

    local function logEntryTree(entry, path, depth)
        if type(entry) ~= "table" or detailVisited[entry] or depth > 3 or detailLines >= 24 then return end
        detailVisited[entry] = true
        detailLines = detailLines + 1
        self:log(string.format("GMF DIAG PricesFrame detail [%s] ref=%s %s", path, tostring(entry), summarize(entry)))
        for key, value in pairs(entry) do
            if type(value) == "table" and detailLines < 24 then
                logEntryTree(value, path .. "." .. tostring(key), depth + 1)
            end
        end
    end

    local function scan(entry, path, depth)
        if type(entry) ~= "table" or visited[entry] or depth > 3 or matches >= 12 then return end
        visited[entry] = true

        local containsName = false
        for _, value in pairs(entry) do
            if type(value) == "string" and string.find(string.lower(value), "grain mill", 1, true) ~= nil then
                containsName = true
                break
            end
        end
        if containsName or entry.station == grainMillStation or entry.sellingStation == grainMillStation then
            matches = matches + 1
            self:log(string.format("GMF DIAG PricesFrame [%s] ref=%s %s", path, tostring(entry), summarize(entry)))
            if containsName then
                logEntryTree(entry, path, 0)
            end
        end

        for key, value in pairs(entry) do
            if type(value) == "table" then
                scan(value, path .. "." .. tostring(key), depth + 1)
            end
        end
    end

    self:log("GMF DIAG PricesFrame scan start ref=" .. tostring(pricesFrame))
    scan(pricesFrame, "pricesFrame", 0)
end

function GlobalMarketForces:installPricesFrameOpenOverride(pricesFrame)
    if pricesFrame == nil or pricesFrame.gmfPriceSyncOverrideInstalled == true or pricesFrame.onFrameOpen == nil then return end

    local superFunc = pricesFrame.onFrameOpen
    pricesFrame.onFrameOpen = function(frame, ...)
        superFunc(frame, ...)
        -- The frame populates station rows during its own open sequence. Delay
        -- the sync briefly so production-point rows are present before copying
        -- the authoritative GMF prices into their GUI station objects.
        GlobalMarketForces.gmfDiagnosticPricesFrame = frame
        GlobalMarketForces.gmfDiagnosticPricesFrameDelay = 4
    end
    pricesFrame.gmfPriceSyncOverrideInstalled = true
end
function GlobalMarketForces:refreshOpenPricesMenu()
    if g_gui == nil or g_gui.screenControllers == nil or InGameMenu == nil then return end
    local inGameMenu = g_gui.screenControllers[InGameMenu]
    if inGameMenu == nil then return end

    local pricesFrame = inGameMenu.inGameMenuPricesFrame or inGameMenu.inGameMenuPriceFrame or inGameMenu.pricesFrame or inGameMenu.priceFrame
    if pricesFrame == nil then
        for fieldName, value in pairs(inGameMenu) do
            if type(fieldName) == "string" and type(value) == "table" and string.find(string.lower(fieldName), "price", 1, true) ~= nil then
                pricesFrame = value
                break
            end
        end
    end
    if pricesFrame == nil then return end

    -- A production point such as Grain Mill can retain an old entry in the
    -- frame's price-data cache even when its visible row list is rebuilt.
    self:clearPricesFrameCache(pricesFrame)

    -- onFrameOpen rebuilds every station row from the freshly cleared data.
    if pricesFrame.onFrameOpen ~= nil then
        pricesFrame:onFrameOpen()
    elseif pricesFrame.updatePriceData ~= nil then
        pricesFrame:updatePriceData()
    elseif pricesFrame.updatePrices ~= nil then
        pricesFrame:updatePrices()
    elseif pricesFrame.reloadData ~= nil then
        pricesFrame:reloadData()
    end

end

function GlobalMarketForces:applySellingStationPrices()
    if g_server == nil then return end
    self:captureSellingStationBasePrices()

    local month = (self.market or {}).currentMonthIndex or 1
    for station, basePrices in pairs(self.sellingStationBasePrices or {}) do
        if station ~= nil and station.isSellingPoint == true and station.fillTypePrices ~= nil then
            local stationName = self:getSellingStationName(station, station.index or "?")
            local baseEffectivePrices = self.sellingStationBaseEffectivePrices[station] or {}
            station.gmfEffectiveFillTypePrices = station.gmfEffectiveFillTypePrices or {}
            for cropName, basePrice in pairs(basePrices) do
                local fillTypeIndex = self:getFillTypeIndex(cropName)
                if fillTypeIndex ~= nil and station.acceptedFillTypes ~= nil and station.acceptedFillTypes[fillTypeIndex] then
                    local modifier = self:calculateCropModifier(cropName, month)
                    local defaultPrice = nil
                    if GlobalMarketForcesConfig.debug then
                        defaultPrice = self:getDefaultSellingStationPrice(station, fillTypeIndex, basePrice)
                    end
                    local nominalPrice = baseEffectivePrices[cropName] or basePrice
                    local newPrice = nominalPrice * modifier
                    station.gmfEffectiveFillTypePrices[fillTypeIndex] = newPrice
                    GlobalMarketForcesStationPriceEvent.sendEvent(station, fillTypeIndex, newPrice)
                    if defaultPrice ~= nil then
                        local differencePercent = defaultPrice ~= 0 and ((newPrice / defaultPrice) - 1) * 100 or 0
                        self:log(string.format("%s | %s: default %.6f, GMF %.6f (%+.1f%%), GMF modifier %.4fx", stationName, cropName, defaultPrice, newPrice, differencePercent, modifier))
                    end
                end
            end
        end
    end

end

function GlobalMarketForces:calculateCropModifier(cropName, monthIndex)
    local curve = GlobalMarketForcesConfig.seasonalCurves[cropName]
    local season = 1
    if curve then
        local raw = curve[((monthIndex - 1) % 12) + 1] or 1
        season = 1 + ((raw - 1) * ((GlobalMarketForcesConfig.marketProfiles[cropName] or {}).seasonalWeight or 1))
    end
    local volatility = 1 + (((math.sin(monthIndex * 1.731) + math.sin(monthIndex * 0.413) + math.sin(monthIndex * 2.917)) / 3) * (((GlobalMarketForcesConfig.marketProfiles[cropName] or {}).volatility or 0.03)))
    local modifier = self:getLongTermTrendModifier(cropName, monthIndex) * season * self:getWorldEventModifier(cropName, monthIndex) * volatility * GlobalMarketForcesConfig.globalPriceMultiplier
    return math.max(GlobalMarketForcesConfig.minimumPriceMultiplier, math.min(GlobalMarketForcesConfig.maximumPriceMultiplier, modifier))
end

function GlobalMarketForces:applyCropPrices()
    self.cropPriceHistory = self.cropPriceHistory or {}
    for cropName, basePrice in pairs(self.basePrices or {}) do
        local newPrice = basePrice * self:calculateCropModifier(cropName, self.market.currentMonthIndex)
        self:setFillTypePrice(cropName, newPrice)
        self.cropPriceHistory[cropName] = self.cropPriceHistory[cropName] or {}
        self.cropPriceHistory[cropName][self.market.currentMonthIndex] = newPrice
    end
    self:applySellingStationPrices()
    self:refreshOpenPricesMenu()
end
