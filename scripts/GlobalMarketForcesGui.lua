-- In-game HUD report view.
-- Toggle with a keybind (default: LSHIFT + M, see modDesc.xml inputBinding) to show/hide
-- a full-screen text panel listing the current market intelligence snapshot.

GlobalMarketForcesGui = {}
GlobalMarketForces.showReport = false
GlobalMarketForces.reportActionEventId = nil

function GlobalMarketForces:registerReportActionEvents()
    if self.reportActionEventId ~= nil then return end
    if g_inputBinding == nil then return end

    local success, actionEventId = g_inputBinding:registerActionEvent("GMF_TOGGLE_REPORT", self, GlobalMarketForces.onToggleReport, false, true, false, true)
    if success then
        self.reportActionEventId = actionEventId
        g_inputBinding:setActionEventTextVisibility(actionEventId, true)
    end
end

function GlobalMarketForces:onToggleReport(actionName, inputValue, callbackState, isAnalog)
    self.showReport = not self.showReport
end

function GlobalMarketForces:draw()
    if not self.showReport then return end
    if g_client == nil then return end

    local rows = self:getMarketIntelligenceSnapshot()

    local x = 0.02
    local y = 0.95
    local lineHeight = 0.018
    local textSize = getCorrectTextSize(0.014)

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

    setTextColor(1, 0.85, 0.2, 1)
    setTextBold(true)
    renderText(x, y, textSize, "GLOBAL MARKET FORCES - Market Outlook (press bound key to close)")
    setTextBold(false)
    y = y - lineHeight * 1.4

    setTextColor(0.8, 0.8, 0.8, 1)
    renderText(x, y, textSize, string.format("%-16s %-9s %-11s %-13s %s", "Market", "Type", "Outlook", "Reliability", "Momentum"))
    y = y - lineHeight

    setTextColor(1, 1, 1, 1)
    for _, row in ipairs(rows) do
        if y < 0.05 then break end
        renderText(x, y, textSize, string.format("%-16s %-9s %-11s %-13s %s", row.fillTypeName, row.marketType, row.farmerOutlook, row.forecastReliability, row.momentumLabel))
        y = y - lineHeight
    end

    -- Restore defaults so we don't affect any other HUD element drawn after us.
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)
end
