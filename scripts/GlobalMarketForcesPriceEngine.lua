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

function GlobalMarketForces:captureSellingStationBasePrices()
    if g_server == nil or g_currentMission == nil then return 0 end

    self.sellingStationBasePrices = self.sellingStationBasePrices or {}
    local capturedStations = 0
    for _, station in pairs(self:getAllSellingStations()) do
        if station.isSellingPoint == true and station.fillTypePrices ~= nil and self.sellingStationBasePrices[station] == nil then
            local basePrices = {}
            for cropName, _ in pairs(GlobalMarketForcesConfig.marketProfiles) do
                local fillTypeIndex = self:getFillTypeIndex(cropName)
                local stationPrice = fillTypeIndex and station.fillTypePrices[fillTypeIndex] or nil
                if stationPrice ~= nil then basePrices[cropName] = stationPrice end
            end
            self.sellingStationBasePrices[station] = basePrices
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
    if GlobalMarketForces:isManagedFillType(fillTypeIndex) and station.fillTypePrices ~= nil then
        local price = station.fillTypePrices[fillTypeIndex]
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

function GlobalMarketForces:refreshOpenPricesMenu()
    if g_gui == nil or g_gui.screenControllers == nil or InGameMenu == nil then return end
    local inGameMenu = g_gui.screenControllers[InGameMenu]
    if inGameMenu == nil then return end

    local pricesFrame = inGameMenu.inGameMenuPricesFrame or inGameMenu.pricesFrame or inGameMenu.priceFrame
    if pricesFrame == nil then
        for fieldName, value in pairs(inGameMenu) do
            if type(fieldName) == "string" and type(value) == "table" and string.find(string.lower(fieldName), "price", 1, true) ~= nil then
                pricesFrame = value
                break
            end
        end
    end
    if pricesFrame == nil or inGameMenu.currentPage ~= pricesFrame then return end

    -- onFrameOpen rebuilds every station row. The lighter updatePrices callback
    -- can leave a cached row behind for certain station types such as Grain Mill.
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
            for cropName, basePrice in pairs(basePrices) do
                local fillTypeIndex = self:getFillTypeIndex(cropName)
                if fillTypeIndex ~= nil and station.acceptedFillTypes ~= nil and station.acceptedFillTypes[fillTypeIndex] then
                    local modifier = self:calculateCropModifier(cropName, month)
                    local defaultPrice = nil
                    if GlobalMarketForcesConfig.debug then
                        defaultPrice = self:getDefaultSellingStationPrice(station, fillTypeIndex, basePrice)
                    end
                    local newPrice = basePrice * modifier
                    station.fillTypePrices[fillTypeIndex] = newPrice
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
