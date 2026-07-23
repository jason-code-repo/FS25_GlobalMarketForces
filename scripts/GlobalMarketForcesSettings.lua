-- Adds GMF's per-save forecast setting to the native Game Settings page.
GlobalMarketForcesSettings = {}
GlobalMarketForcesSettings.MOD_NAME = g_currentModName or "FS25_GlobalMarketForces"
GlobalMarketForcesSettings.SETTINGS = { "Disabled", "Low", "Normal", "High", "Perfect" }

function GlobalMarketForcesSettings.getText(key, fallback)
    local environment = g_i18n ~= nil and g_i18n.modEnvironments ~= nil and g_i18n.modEnvironments[GlobalMarketForcesSettings.MOD_NAME] or nil
    return environment ~= nil and environment.texts[key] or fallback
end

function GlobalMarketForcesSettings.getState()
    local setting = GlobalMarketForces:getSavegameSettings().forecastAccuracy
    for index, value in ipairs(GlobalMarketForcesSettings.SETTINGS) do
        if value == setting then return index end
    end
    return 3
end

function GlobalMarketForcesSettings.addOption(layout, option, id, titleText, tooltipText, settingsClone)
    option.id = id
    option.target = GlobalMarketForces
    option.onClickCallback = GlobalMarketForcesSettings.onForecastAccuracyChanged
    option.buttonLRChange = GlobalMarketForcesSettings.onForecastAccuracyChanged

    local toolTip = option.elements[1]
    if toolTip ~= nil then
        toolTip.text = tooltipText
        toolTip.sourceText = tooltipText
    end

    local optionTitle = settingsClone.elements[2]:clone()
    optionTitle.id = id .. "Title"
    optionTitle:applyProfile("fs25_settingsMultiTextOptionTitle", true)
    optionTitle:setText(titleText)

    local container = settingsClone:clone()
    container.id = id .. "Container"
    container:applyProfile("fs25_multiTextOptionContainer", true)
    for key in pairs(container.elements) do container.elements[key] = nil end
    container:addElement(optionTitle)
    container:addElement(option)
    layout:addElement(container)
end

function GlobalMarketForcesSettings.initSettingsGui(frame)
    if GlobalMarketForces == nil or frame == nil or frame.gameSettingsLayout == nil or frame.economicDifficulty == nil then return end

    if frame.globalMarketForcesForecastAccuracy == nil then
        local layout = frame.gameSettingsLayout
        local template = layout.elements[5]
        local headerTemplate = layout.elements[7]
        if template == nil or headerTemplate == nil then return end

        local header = headerTemplate:clone()
        header:applyProfile("fs25_settingsSectionHeader", true)
        header:setText(GlobalMarketForcesSettings.getText("gmf_settings_header", "GLOBAL MARKET FORCES"))
        header.focusChangeData = {}
        header.focusId = FocusManager.serveAutoFocusId()
        layout:addElement(header)

        local option = frame.economicDifficulty:clone()
        option.texts = {}
        for index, value in ipairs(GlobalMarketForcesSettings.SETTINGS) do option.texts[index] = value end

        frame.globalMarketForcesForecastAccuracy = option
        GlobalMarketForcesSettings.addOption(
            layout,
            option,
            "globalMarketForcesForecastAccuracy",
            GlobalMarketForcesSettings.getText("gmf_forecast_accuracy", "Forecast Accuracy"),
            GlobalMarketForcesSettings.getText("gmf_forecast_accuracy_tooltip", "Controls how reliable Market Report forecasts are in this savegame."),
            template
        )
        layout:invalidateLayout()
    end

    frame.globalMarketForcesForecastAccuracy:setState(GlobalMarketForcesSettings.getState())
end

-- MultiTextOption invokes callbacks with its target as the first argument.
-- Keep the fallback for game versions or controls that omit a target, but
-- read the state from the second argument for the standard Game Settings UI.
function GlobalMarketForcesSettings.onForecastAccuracyChanged(target, state, element)
    if type(target) == "number" then
        element = state
        state = target
        target = GlobalMarketForces
    end

    local setting = GlobalMarketForcesSettings.SETTINGS[state]
    if setting == nil then return end

    -- The local host must update its authoritative savegame state immediately.
    -- Sending an event first works for remote clients, but does not reliably
    -- invoke a loopback event for the host's own Game Settings control.
    if g_currentMission ~= nil and g_currentMission.getIsServer ~= nil and g_currentMission:getIsServer() then
        if GlobalMarketForces:setForecastAccuracy(setting) and g_server ~= nil then
            g_server:broadcastEvent(GlobalMarketForcesForecastSettingsEvent.new(setting))
        end
    else
        GlobalMarketForcesForecastSettingsEvent.sendEvent(setting)
    end
end

function GlobalMarketForcesSettings.init()
    if InGameMenuSettingsFrame ~= nil then
        InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, GlobalMarketForcesSettings.initSettingsGui)
    end
end

GlobalMarketForcesSettings.init()
