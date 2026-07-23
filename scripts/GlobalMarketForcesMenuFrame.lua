-- Custom in-game menu page: "Global Market Forces" tab.

GlobalMarketForcesMenuFrame = {}
local GlobalMarketForcesMenuFrame_mt = Class(GlobalMarketForcesMenuFrame, TabbedMenuFrameElement)

local function text(key, fallback, ...)
    return GlobalMarketForces:getText(key, fallback, ...)
end

local function labelKey(prefix, value)
    return prefix .. string.lower(string.gsub(value or "", "[^%w]", ""))
end

function GlobalMarketForcesMenuFrame.new(target, customMt)
    local self = GlobalMarketForcesMenuFrame:superClass().new(target, customMt or GlobalMarketForcesMenuFrame_mt)
    self.name = "globalMarketForcesMenu"
    self.marketRows = {}
    return self
end

function GlobalMarketForcesMenuFrame:onFrameOpen()
    GlobalMarketForcesMenuFrame:superClass().onFrameOpen(self)
    self.marketRows = GlobalMarketForces:getMarketIntelligenceSnapshot()
    self:updateGlobalConditions()
    self:showMarketTable()
    if self.marketTable ~= nil then
        self.marketTable:reloadData()
    end
end

function GlobalMarketForcesMenuFrame:getGlobalTrendOutlookSentence(globalTrends, month)
    if not GlobalMarketForces:isForecastEnabled() then return nil end
    local activeTrend = globalTrends[1]
    if activeTrend == nil then return nil end

    local endMonth = activeTrend.startMonth + activeTrend.durationMonths
    local remainingMonths = endMonth - month
    if remainingMonths > 6 then
        return text("gmf_brief_noNearTermChange", "Analysts don't anticipate near term changes in the market.")
    end

    local nextTrend = nil
    for _, candidate in ipairs(GlobalMarketForces.globalTrends or {}) do
        if candidate.startMonth >= endMonth and (nextTrend == nil or candidate.startMonth < nextTrend.startMonth) then
            nextTrend = candidate
        end
    end

    if nextTrend == nil then
        return text("gmf_brief_awaitingOutlook", "Analysts are awaiting a clearer outlook for the next market cycle.")
    end

    if nextTrend.trendType == activeTrend.trendType then
        return nil
    end

    local definition = GlobalMarketForcesTrends.globalDefinitions[nextTrend.trendType]
    local actualDirection = definition and definition.baseImpact or 0
    local confidence = GlobalMarketForces:adjustForecastConfidence(remainingMonths <= 2 and 78 or 65)
    GlobalMarketForces.market.globalCycleForecasts = GlobalMarketForces.market.globalCycleForecasts or {}
    local forecast = GlobalMarketForces.market.globalCycleForecasts[endMonth]
    if forecast == nil or forecast.issueMonth ~= month then
        local predictedDirection = GlobalMarketForces:getForecastDirection(actualDirection > 0 and "Upward" or "Downward", confidence, "global:" .. endMonth .. ":" .. month)
        forecast = { issueMonth = month, direction = predictedDirection, confidence = confidence }
        GlobalMarketForces.market.globalCycleForecasts[endMonth] = forecast
        GlobalMarketForces:saveMarketState()
    end
    local direction = forecast.direction == "Upward" and 1 or forecast.direction == "Downward" and -1 or 0
    if direction > 0 then
        return text("gmf_brief_optimistic", "Analysts are optimistic upcoming changes to the market are going to support crop prices.")
    elseif direction < 0 then
        return text("gmf_brief_concerned", "Analysts are afraid changes to the market are going to put further pressure on crop prices.")
    end
    return nil
end

function GlobalMarketForcesMenuFrame:updateGlobalConditions()
    if self.globalConditions == nil then return end

    local month = GlobalMarketForces.market.currentMonthIndex or 1
    local globalTrends = GlobalMarketForces:getActiveGlobalTrends(month)
    local events = GlobalMarketForces:getActiveEvents(month)
    local trendNarratives = {
        bullMarket = text("gmf_brief_bullMarket", "Commodity markets are in a broad upswing, generally supporting crop prices."),
        bearMarket = text("gmf_brief_bearMarket", "Commodity markets are in a broad downturn, generally weighing on crop prices."),
        commoditySupercycle = text("gmf_brief_commoditySupercycle", "A long-term commodity boom is providing broad support for crop prices."),
        globalRecession = text("gmf_brief_globalRecession", "A global slowdown is reducing demand and putting broad pressure on prices."),
        energyInflation = text("gmf_brief_energyInflation", "Higher energy costs are adding broad support to commodity prices.")
    }
    local eventNarratives = {
        drought = text("gmf_brief_drought", "Dry conditions are tightening supplies."),
        war = text("gmf_brief_war", "Trade disruption is adding market risk."),
        fuelSpike = text("gmf_brief_fuelSpike", "Higher fuel costs are raising production and transport costs."),
        bumperHarvest = text("gmf_brief_bumperHarvest", "Strong harvests are adding supply and softening prices."),
        exportBoom = text("gmf_brief_exportBoom", "Export demand is providing additional market support.")
    }
    local globalStatements = {}
    local matchingConditions = {}
    local mixedConditions = {}

    for _, trend in ipairs(globalTrends) do
        local definition = GlobalMarketForcesTrends.globalDefinitions[trend.trendType]
        table.insert(globalStatements, {
            text = trendNarratives[trend.trendType] or (GlobalMarketForces:getTrendDisplayName(trend, nil) .. " is influencing broad market prices."),
            direction = definition and (definition.baseImpact > 0 and 1 or definition.baseImpact < 0 and -1 or 0) or 0
        })
    end

    local globalDirection = globalStatements[1] and globalStatements[1].direction or 0
    for _, event in ipairs(events) do
        local definition = GlobalMarketForcesEvents.definitions[event.eventType]
        local condition = {
            text = eventNarratives[event.eventType] or text("gmf_brief_genericEvent", "A broad world event is affecting market conditions."),
            direction = definition and (definition.priceDirection or 0) or 0
        }
        if globalDirection ~= 0 and condition.direction ~= 0 and condition.direction ~= globalDirection then
            table.insert(mixedConditions, condition)
        else
            table.insert(matchingConditions, condition)
        end
    end

    local analystOutlook = self:getGlobalTrendOutlookSentence(globalTrends, month)

    if #globalStatements == 0 and #matchingConditions == 0 and #mixedConditions == 0 then
        local brief = text("gmf_brief_calm", "Broad market conditions are currently calm, with no major global drivers active.")
        if analystOutlook ~= nil then brief = brief .. " " .. analystOutlook end
        self.globalConditions:setText(text("gmf_marketBriefPrefix", "MARKET BRIEF: ") .. brief)
    else
        local sentences = {}
        for _, statement in ipairs(globalStatements) do table.insert(sentences, statement.text) end
        for _, condition in ipairs(matchingConditions) do table.insert(sentences, condition.text) end
        for index, condition in ipairs(mixedConditions) do
            local text = condition.text
            if index == 1 then text = GlobalMarketForces:getText("gmf_however", "However, ") .. string.lower(string.sub(text, 1, 1)) .. string.sub(text, 2) end
            table.insert(sentences, text)
        end
        if analystOutlook ~= nil then table.insert(sentences, analystOutlook) end
        self.globalConditions:setText(text("gmf_marketBriefPrefix", "MARKET BRIEF: ") .. table.concat(sentences, " "))
    end
end

function GlobalMarketForcesMenuFrame:onGuiSetupFinished()
    GlobalMarketForcesMenuFrame:superClass().onGuiSetupFinished(self)
    self.menuTitle:setText(text("gmf_menuTitle", "Market Report"))
    self.marketColumnHeader:setText(text("gmf_columnMarket", "Market"))
    self.outlookColumnHeader:setText(text("gmf_columnOutlook", "Outlook"))
    self.accuracyColumnHeader:setText(text("gmf_columnAccuracy", "Forecast Accuracy"))
    self.momentumColumnHeader:setText(text("gmf_columnMomentum", "Momentum"))
    self.marketTableInstruction:setText(text("gmf_selectMarket", "SELECT A MARKET FOR A DETAILED REPORT"))
    self.backToMarketReport:setText(text("gmf_backToReport", "BACK TO MARKET REPORT"))
    self.atAGlanceHeading:setText(text("gmf_headingAtAGlance", "AT A GLANCE"))
    self.farmGuidanceHeading:setText(text("gmf_headingFarmGuidance", "FARM GUIDANCE"))
    self.priceTimingHeading:setText(text("gmf_headingPriceTiming", "PRICE TIMING"))
    self.marketSupportsHeading:setText(text("gmf_headingMarketSupports", "MARKET SUPPORTS"))
    self.whatToWatchHeading:setText(text("gmf_headingWhatToWatch", "WHAT TO WATCH"))
    self.marketTable:setDataSource(self)
    self.marketTable:setDelegate(self)
    self.marketTable.onClickCallback = function()
        -- SmoothList callbacks can prepend their target to the callback arguments.
        -- Read the list's current selection so the clicked crop always matches the detail page.
        self:onClickMarketRow(self.marketTable, self.marketTable.selectedSectionIndex, self.marketTable.selectedIndex)
    end
end

function GlobalMarketForcesMenuFrame:showMarketTable()
    self.marketTableHeader:setVisible(true)
    self.marketTable:setVisible(true)
    self.marketListSlider:setVisible(true)
    self.marketTableInstruction:setVisible(true)
    self.cropDetailPage:setVisible(false)
end

function GlobalMarketForcesMenuFrame:showCropDetail(row)
    if row == nil then return end

    self.marketTableHeader:setVisible(false)
    self.marketTable:setVisible(false)
    self.marketListSlider:setVisible(false)
    self.marketTableInstruction:setVisible(false)
    self.cropDetailPage:setVisible(true)

    self.detailTitle:setText(text("gmf_detailTitle", "%s Market Outlook", row.displayName or row.fillTypeName))
    if row.forecastDisabled then
        self.detailOutlook:setText(text("gmf_detailDisabled", "Outlook: %s. Forecast accuracy is disabled for this savegame.", self:getLocalizedLabel("gmf_outlook_", row.farmerOutlook)))
    else
        self.detailOutlook:setText(text("gmf_detailOutlook", "Outlook: %s. Selling conditions are %s. Forecast confidence is %s.", self:getLocalizedLabel("gmf_outlook_", row.farmerOutlook), string.lower(self:getLocalizedLabel("gmf_condition_", row.marketCondition)), string.lower(self:getLocalizedLabel("gmf_confidence_", row.forecastReliability))))
    end
    self.detailRecommendation:setText(self:getFarmGuidance(row))
    if row.forecastDisabled then
        self.detailHorizons:setText(text("gmf_forecastsDisabled", "Forecasts are disabled for this savegame."))
    else
        self.detailHorizons:setText(GlobalMarketForces:getForecastSentence(text("gmf_termNear", "Near term"), row.shortTermDirection, row.shortTermConfidence) .. "\n" .. GlobalMarketForces:getForecastSentence(text("gmf_termLaterThisYear", "Later this year"), row.mediumTermDirection, row.mediumTermConfidence) .. "\n" .. GlobalMarketForces:getForecastSentence(text("gmf_termLong", "Long term"), row.longTermDirection, row.longTermConfidence))
    end
    self.detailDrivers:setText(self:getReadableSupportSummary(row.drivers))
    self.detailRisks:setText(self:getReadableRiskSummary(row.risks))
end

function GlobalMarketForcesMenuFrame:getFarmGuidance(row)
    if row.farmerOutlook == "Excellent" then
        return "Prices are favorable. Consider expanding carefully or holding some inventory for stronger sales."
    elseif row.farmerOutlook == "Good" then
        return "Prices are supportive. Maintain your plan or expand cautiously where costs and storage allow."
    elseif row.farmerOutlook == "Poor" then
        return "Prices face pressure. Be cautious about expanding acreage and review costs before planting."
    elseif row.farmerOutlook == "Avoid" then
        return "Conditions are weak. Limit new acreage where practical and focus on controlling costs."
    end
    return "The market is balanced. Maintain acreage and sell when local prices meet your farm's targets."
end

function GlobalMarketForcesMenuFrame:joinNaturalList(items)
    if #items == 0 then return "" end
    if #items == 1 then return items[1] end
    if #items == 2 then return items[1] .. " and " .. items[2] end
    return table.concat(items, ", ", 1, #items - 1) .. ", and " .. items[#items]
end

function GlobalMarketForcesMenuFrame:capitalizeSentence(text)
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

function GlobalMarketForcesMenuFrame:getReadableFactorSentence(factor, isSupport)
    local channel, label = string.match(factor, "^(%a+): (.+)$")
    local subject = string.lower(label or factor)
    local verb = string.match(subject, "[^s]s$") ~= nil and "are" or "is"
    local ending

    if channel == "Demand" then
        ending = isSupport and " " .. verb .. " strengthening the market." or " " .. verb .. " weakening the market."
    elseif channel == "Supply" then
        ending = isSupport and " " .. verb .. " tightening supplies." or " " .. verb .. " adding supply pressure."
    elseif channel == "Policy" then
        ending = isSupport and " " .. verb .. " supporting prices." or " " .. verb .. " weighing on prices."
    else
        ending = isSupport and " " .. verb .. " providing broader market support." or " " .. verb .. " adding broader market pressure."
    end

    return self:capitalizeSentence(subject .. ending)
end

function GlobalMarketForcesMenuFrame:getReadableSupportSummary(drivers)
    if drivers == nil or #drivers == 0 then return "No major support factors are active right now." end
    local sentences = {}
    for _, driver in ipairs(drivers) do table.insert(sentences, self:getReadableFactorSentence(driver, true)) end
    return table.concat(sentences, " ")
end

function GlobalMarketForcesMenuFrame:getReadableRiskSummary(risks)
    if risks == nil or #risks == 0 then return "No major risks are active right now." end
    local sentences = {}
    for _, risk in ipairs(risks) do table.insert(sentences, self:getReadableFactorSentence(risk, false)) end
    return table.concat(sentences, " ")
end

function GlobalMarketForcesMenuFrame:onClickMarketRow(list, section, index)
    local selectedIndex = list.selectedIndex or index
    self:showCropDetail(self.marketRows[selectedIndex])
end

function GlobalMarketForcesMenuFrame:onClickBackToMarketReport()
    self.marketRows = GlobalMarketForces:getMarketIntelligenceSnapshot()
    self:showMarketTable()
    self.marketTable:reloadData()
end

function GlobalMarketForcesMenuFrame:getLocalizedLabel(prefix, value)
    return text(labelKey(prefix, value), value)
end

function GlobalMarketForcesMenuFrame:getNumberOfSections()
    return 1
end

function GlobalMarketForcesMenuFrame:getNumberOfItemsInSection(list, section)
    return #self.marketRows
end

function GlobalMarketForcesMenuFrame:getTitleForSectionHeader(list, section)
    return nil
end

function GlobalMarketForcesMenuFrame:populateCellForItemInSection(list, section, index, cell)
    local row = self.marketRows[index]
    if row == nil then return end

    cell:getAttribute("marketName"):setText(row.displayName or row.fillTypeName)
    cell:getAttribute("marketOutlook"):setText(self:getLocalizedLabel("gmf_outlook_", row.farmerOutlook))
    cell:getAttribute("marketReliability"):setText(self:getLocalizedLabel("gmf_confidence_", row.forecastReliability))
    cell:getAttribute("marketMomentum"):setText(self:getLocalizedLabel("gmf_momentum_", row.momentumLabel))
end

-- Registers through the GUI screen controller. This is available during loadMap,
-- unlike g_currentMission.inGameMenu, which may not be assigned at that point.
function GlobalMarketForces:registerMenuPage()
    if self.menuPageRegistered then return end
    local inGameMenu = g_gui ~= nil and g_gui.screenControllers[InGameMenu] or nil
    if inGameMenu == nil then
        return
    end

    local pageName = "globalMarketForcesMenu"
    local position = #inGameMenu.pagingElement.elements - 1

    self.menuFrame = GlobalMarketForcesMenuFrame.new()
    g_gui:loadProfiles(self.MOD_DIRECTORY .. "gui/GlobalMarketForcesMenuProfiles.xml")
    g_gui:loadGui(self.MOD_DIRECTORY .. "gui/GlobalMarketForcesMenu.xml", "GlobalMarketForcesMenu", self.menuFrame, true)

    inGameMenu.controlIDs[pageName] = nil
    inGameMenu[pageName] = self.menuFrame
    inGameMenu.pagingElement:addElement(self.menuFrame)
    inGameMenu:exposeControlsAsFields(pageName)

    for i, child in ipairs(inGameMenu.pagingElement.elements) do
        if child == self.menuFrame then
            table.remove(inGameMenu.pagingElement.elements, i)
            table.insert(inGameMenu.pagingElement.elements, position, child)
            break
        end
    end

    for i, page in ipairs(inGameMenu.pagingElement.pages) do
        if page.element == self.menuFrame then
            table.remove(inGameMenu.pagingElement.pages, i)
            table.insert(inGameMenu.pagingElement.pages, position, page)
            break
        end
    end

    inGameMenu.pagingElement:updateAbsolutePosition()
    inGameMenu.pagingElement:updatePageMapping()
    inGameMenu:registerPage(self.menuFrame, position, nil)
    -- The mod-card artwork is too detailed for the narrow in-game tab strip.
    -- Use a dedicated transparent glyph for a clean, legible Market Report tab.
    -- Page-tab UVs use the engine's 1024-unit icon space. A 256-unit
    -- rectangle only selects a corner of the texture on this control.
    inGameMenu:addPageTab(self.menuFrame, self.MOD_DIRECTORY .. "gui/marketReportIcon.dds", GuiUtils.getUVs({0, 0, 1024, 1024}))

    for i, child in ipairs(inGameMenu.pageFrames) do
        if child == self.menuFrame then
            table.remove(inGameMenu.pageFrames, i)
            table.insert(inGameMenu.pageFrames, position, child)
            break
        end
    end

    inGameMenu:rebuildTabList()
    self.menuPageRegistered = true
end
