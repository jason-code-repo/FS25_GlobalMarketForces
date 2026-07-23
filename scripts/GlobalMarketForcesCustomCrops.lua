-- Runtime support for map-provided fruit types. Profiles are registered using
-- the fill type's original name so all existing price and report lookups work.

function GlobalMarketForces:normalizeCustomCropName(name)
    return string.lower(string.gsub(tostring(name or ""), "[^%w]", ""))
end

function GlobalMarketForces:loadCustomCropAliases()
    if self.customCropAliasesLoaded then return 0 end
    self.customCropAliasesLoaded = true

    local aliases = {}
    local filePath = (self.MOD_DIRECTORY or "") .. "config/GlobalMarketForcesCustomCropMappings.xml"
    if XMLFile == nil or XMLFile.loadIfExists == nil then
        print(string.format("[%s] Unable to load custom crop mappings: XMLFile API is unavailable", self.MOD_NAME))
        GlobalMarketForcesConfig.customCropAliases = aliases
        return 0
    end

    local xmlFile = XMLFile.loadIfExists("GlobalMarketForcesCustomCropMappings", filePath, "customCropMappings")
    if xmlFile == nil then
        print(string.format("[%s] Unable to load custom crop mappings from %s", self.MOD_NAME, filePath))
        GlobalMarketForcesConfig.customCropAliases = aliases
        return 0
    end

    xmlFile:iterate("customCropMappings.crop", function(_, key)
        local aliasName = xmlFile:getString(key .. "#alias")
        local referenceCrop = xmlFile:getString(key .. "#referenceCrop")
        local profileGroup = xmlFile:getString(key .. "#profileGroup")
        local normalizedAlias = self:normalizeCustomCropName(aliasName)
        if normalizedAlias ~= "" and referenceCrop ~= nil and GlobalMarketForcesConfig.marketProfiles[referenceCrop] ~= nil then
            aliases[normalizedAlias] = {
                profileGroup = profileGroup,
                referenceCrop = referenceCrop
            }
        else
            print(string.format("[%s] Ignoring invalid custom crop mapping: %s", self.MOD_NAME, tostring(aliasName)))
        end
    end)
    xmlFile:delete()

    local aliasCount = 0
    for _ in pairs(aliases) do aliasCount = aliasCount + 1 end
    GlobalMarketForcesConfig.customCropAliases = aliases
    self:log("Loaded " .. tostring(aliasCount) .. " custom crop mappings")
    return aliasCount
end

function GlobalMarketForces:getCustomCropAlias(name)
    local normalizedName = self:normalizeCustomCropName(name)
    return (GlobalMarketForcesConfig.customCropAliases or {})[normalizedName]
end

function GlobalMarketForces:getTrendReferenceCrop(cropName)
    local profile = (GlobalMarketForcesConfig.marketProfiles or {})[cropName]
    return profile and profile.referenceCrop or cropName
end

function GlobalMarketForces:isRegisteredFruitType(cropName)
    if g_fruitTypeManager == nil then return false end
    if g_fruitTypeManager.getFruitTypeByName ~= nil then
        if g_fruitTypeManager:getFruitTypeByName(cropName) ~= nil then return true end
        if g_fruitTypeManager:getFruitTypeByName(string.lower(cropName)) ~= nil then return true end
    end

    local normalizedName = self:normalizeCustomCropName(cropName)
    for fruitName, _ in pairs(g_fruitTypeManager.nameToIndex or {}) do
        if self:normalizeCustomCropName(fruitName) == normalizedName then return true end
    end
    return false
end

function GlobalMarketForces:isSellableFillType(fillTypeIndex)
    for _, station in ipairs(self:getAllSellingStations()) do
        if station.isSellingPoint == true and station.fillTypePrices ~= nil and station.fillTypePrices[fillTypeIndex] ~= nil then
            return true
        end
    end
    return false
end

function GlobalMarketForces:getRegisteredFillTypeNames()
    local names, seen = {}, {}
    if g_fillTypeManager == nil then return names end

    local fillTypes = g_fillTypeManager.getFillTypes and g_fillTypeManager:getFillTypes() or g_fillTypeManager.fillTypes or {}
    for fillTypeIndex, fillType in pairs(fillTypes) do
        local cropName = fillType and fillType.name or nil
        if cropName == nil and type(fillTypeIndex) == "number" and g_fillTypeManager.getFillTypeNameByIndex ~= nil then
            cropName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
        end
        if cropName ~= nil and cropName ~= "" and not seen[cropName] then
            seen[cropName] = true
            table.insert(names, cropName)
        end
    end

    -- Some maps expose a custom fruit through nameToIndex before it appears in
    -- getFillTypes(). Add those canonical internal names as a second source;
    -- isSellableFillType still prevents non-sellable inputs from being managed.
    for cropName, _ in pairs(g_fillTypeManager.nameToIndex or {}) do
        if cropName ~= nil and cropName ~= "" and not seen[cropName] then
            seen[cropName] = true
            table.insert(names, cropName)
        end
    end
    return names
end

function GlobalMarketForces:registerCustomCropProfile(cropName, descriptor)
    local profiles = GlobalMarketForcesConfig.marketProfiles
    if profiles[cropName] ~= nil then return false end

    local sourceProfile = descriptor.referenceCrop and profiles[descriptor.referenceCrop] or GlobalMarketForcesConfig.genericCustomCropProfile
    if sourceProfile == nil then return false end

    local profile = {}
    for key, value in pairs(sourceProfile) do profile[key] = value end
    profile.profileGroup = descriptor.profileGroup or profile.profileGroup or "grain"
    profile.referenceCrop = descriptor.referenceCrop
    profile.isCustomCrop = true
    profiles[cropName] = profile

    local referenceCurve = descriptor.referenceCrop and GlobalMarketForcesConfig.seasonalCurves[descriptor.referenceCrop] or nil
    if referenceCurve ~= nil then
        GlobalMarketForcesConfig.seasonalCurves[cropName] = {}
        for month, value in ipairs(referenceCurve) do GlobalMarketForcesConfig.seasonalCurves[cropName][month] = value end
    end

    self:log("Registered custom crop profile: " .. cropName .. " (" .. profile.profileGroup .. ")")
    return true
end

function GlobalMarketForces:registerDetectedCustomCropProfiles(reportDiagnostics)
    if g_fillTypeManager == nil or g_fruitTypeManager == nil then return 0 end

    local registeredCount, unknownFruitCount, sellableFruitCount, alreadyManagedCount = 0, 0, 0, 0
    local skippedNames = {}
    for _, cropName in ipairs(self:getRegisteredFillTypeNames()) do
        local fillTypeIndex = self:getFillTypeIndex(cropName)
        if fillTypeIndex ~= nil and self:isRegisteredFruitType(cropName) then
            if GlobalMarketForcesConfig.marketProfiles[cropName] ~= nil then
                alreadyManagedCount = alreadyManagedCount + 1
            else
                unknownFruitCount = unknownFruitCount + 1
                if self:isSellableFillType(fillTypeIndex) then
                    sellableFruitCount = sellableFruitCount + 1
                    local alias = self:getCustomCropAlias(cropName)
                    local descriptor = alias or {profileGroup="grain"}
                    if self:registerCustomCropProfile(cropName, descriptor) then registeredCount = registeredCount + 1 end
                elseif #skippedNames < 20 then
                    table.insert(skippedNames, cropName)
                end
            end
        end
    end

    if reportDiagnostics and (unknownFruitCount > 0 or registeredCount > 0) then
        print(string.format(
            "[%s] Custom crop scan: %d unprofiled fruit type(s), %d sellable, %d registered, %d already managed",
            self.MOD_NAME,
            unknownFruitCount,
            sellableFruitCount,
            registeredCount,
            alreadyManagedCount
        ))
        if #skippedNames > 0 then
            print(string.format(
                "[%s] Custom crop scan skipped fruit type(s) without a detected selling-station price: %s",
                self.MOD_NAME,
                table.concat(skippedNames, ", ")
            ))
        end
    end
    self.customCropUnprofiledFruitCount = unknownFruitCount
    self.customCropSellableFruitCount = sellableFruitCount
    return registeredCount
end

function GlobalMarketForces:applyNewCustomCropProfiles(registeredCount, source)
    if registeredCount <= 0 then return end

    self:captureBasePrices()
    self:ensureLongTermTrendHorizon()
    self:ensureWorldEventHorizon()
    self:applyCropPrices()
    print(string.format("[%s] Registered %d custom crop market profile(s) %s", self.MOD_NAME, registeredCount, source))
end

-- loadMap can run before a custom map has registered all of its selling
-- stations. Re-run detection after map items finish loading, then establish
-- prices and a complete trend horizon for any profiles discovered at that
-- later, authoritative point in mission setup.
function GlobalMarketForces:activateDetectedCustomCropProfiles()
    local registeredCount = self:registerDetectedCustomCropProfiles(true)
    self:applyNewCustomCropProfiles(registeredCount, "after map loading")

    -- loadItemsFinished occurs before the game has entered gameplay on some
    -- custom maps. Their station-price tables can appear a few seconds later,
    -- so retry briefly without ever registering non-sellable fruit types.
    if (self.customCropUnprofiledFruitCount or 0) > (self.customCropSellableFruitCount or 0) then
        self.customCropDiscoveryRetryAttempts = 6
        self.customCropDiscoveryRetryTimer = 1000
    end
    return registeredCount
end

function GlobalMarketForces:updateCustomCropDiscovery(dt)
    local remainingAttempts = self.customCropDiscoveryRetryAttempts or 0
    if remainingAttempts <= 0 then return end

    self.customCropDiscoveryRetryTimer = (self.customCropDiscoveryRetryTimer or 0) - dt
    if self.customCropDiscoveryRetryTimer > 0 then return end

    local isFinalAttempt = remainingAttempts == 1
    local registeredCount = self:registerDetectedCustomCropProfiles(isFinalAttempt)
    self:applyNewCustomCropProfiles(registeredCount, "after delayed map-economy discovery")

    self.customCropDiscoveryRetryAttempts = remainingAttempts - 1
    self.customCropDiscoveryRetryTimer = 1000
end
