GlobalMarketForcesConfig = {}
GlobalMarketForcesConfig.debug = false
GlobalMarketForcesConfig.globalPriceMultiplier = 1.0
GlobalMarketForcesConfig.minimumPriceMultiplier = 0.35
GlobalMarketForcesConfig.maximumPriceMultiplier = 3.75
GlobalMarketForcesConfig.minTrendYears = 1
GlobalMarketForcesConfig.maxTrendYears = 5
GlobalMarketForcesConfig.monthsPerYear = 12
GlobalMarketForcesConfig.maxYears = 5
GlobalMarketForcesConfig.maxMonths = 60
GlobalMarketForcesConfig.marketPlanningHorizonMonths = 60
GlobalMarketForcesConfig.enableGlobalTrends = true
GlobalMarketForcesConfig.enableCropDemandTrends = true
GlobalMarketForcesConfig.enableCropSupplyTrends = true
GlobalMarketForcesConfig.enableCropPolicyTrends = true
GlobalMarketForcesConfig.globalTrendWeight = 0.35
GlobalMarketForcesConfig.cropDemandTrendWeight = 1.55
GlobalMarketForcesConfig.cropSupplyTrendWeight = 1.25
GlobalMarketForcesConfig.cropPolicyTrendWeight = 0.90
GlobalMarketForcesConfig.worldEventWeight = 0.85
GlobalMarketForcesConfig.marketIntelligence = { enabled=true, shortTermMonths=6, mediumTermMonths=24, longTermMonths=60, leadersToShow=3 }

-- v0.10.0 profile groups.
-- The runtime uses the merged GlobalMarketForcesConfig.cropProfiles table, but this structure lets us tune crop categories separately.
GlobalMarketForcesConfig.grainProfiles = {
  WHEAT={volatility=0.040,seasonalWeight=1.00,globalTrendSensitivity=1.00,demandSensitivity=1.00,supplySensitivity=1.00,policySensitivity=1.00,profileGroup="grain"},
  BARLEY={volatility=0.035,seasonalWeight=0.90,globalTrendSensitivity=0.90,demandSensitivity=0.85,supplySensitivity=0.90,policySensitivity=0.90,profileGroup="grain"},
  OAT={volatility=0.035,seasonalWeight=0.85,globalTrendSensitivity=0.80,demandSensitivity=0.80,supplySensitivity=0.85,policySensitivity=0.85,profileGroup="grain"},
  MAIZE={volatility=0.045,seasonalWeight=1.05,globalTrendSensitivity=1.05,demandSensitivity=1.10,supplySensitivity=1.10,policySensitivity=1.25,profileGroup="grain"},
  SOYBEAN={volatility=0.055,seasonalWeight=1.15,globalTrendSensitivity=1.10,demandSensitivity=1.25,supplySensitivity=1.05,policySensitivity=1.15,profileGroup="grain"},
  CANOLA={volatility=0.050,seasonalWeight=1.10,globalTrendSensitivity=1.15,demandSensitivity=1.20,supplySensitivity=1.00,policySensitivity=1.35,profileGroup="grain"},
  SUNFLOWER={volatility=0.050,seasonalWeight=1.00,globalTrendSensitivity=1.00,demandSensitivity=1.05,supplySensitivity=1.00,policySensitivity=1.10,profileGroup="grain"},
  SORGHUM={volatility=0.040,seasonalWeight=0.95,globalTrendSensitivity=0.90,demandSensitivity=0.90,supplySensitivity=0.95,policySensitivity=0.90,profileGroup="grain"},
  RICE={volatility=0.040,seasonalWeight=1.10,globalTrendSensitivity=0.90,demandSensitivity=1.15,supplySensitivity=1.25,policySensitivity=1.10,profileGroup="grain"},
  LONGGRAINRICE={volatility=0.050,seasonalWeight=1.10,globalTrendSensitivity=0.95,demandSensitivity=1.25,supplySensitivity=1.20,policySensitivity=1.10,profileGroup="grain"}
}

GlobalMarketForcesConfig.vegetableProfiles = {
  POTATO={volatility=0.050,seasonalWeight=1.05,globalTrendSensitivity=0.90,demandSensitivity=1.20,supplySensitivity=1.20,policySensitivity=0.75,profileGroup="vegetable"},
  CARROT={volatility=0.065,seasonalWeight=1.15,globalTrendSensitivity=0.70,demandSensitivity=1.30,supplySensitivity=1.30,policySensitivity=0.60,profileGroup="vegetable"},
  PARSNIP={volatility=0.060,seasonalWeight=1.10,globalTrendSensitivity=0.70,demandSensitivity=1.25,supplySensitivity=1.25,policySensitivity=0.60,profileGroup="vegetable"},
  REDBEET={volatility=0.060,seasonalWeight=1.10,globalTrendSensitivity=0.75,demandSensitivity=1.20,supplySensitivity=1.25,policySensitivity=0.65,profileGroup="vegetable"},
  GREENBEAN={volatility=0.070,seasonalWeight=1.20,globalTrendSensitivity=0.65,demandSensitivity=1.35,supplySensitivity=1.35,policySensitivity=0.55,profileGroup="vegetable"},
  PEA={volatility=0.065,seasonalWeight=1.15,globalTrendSensitivity=0.70,demandSensitivity=1.30,supplySensitivity=1.25,policySensitivity=0.60,profileGroup="vegetable"},
  SPINACH={volatility=0.080,seasonalWeight=1.25,globalTrendSensitivity=0.60,demandSensitivity=1.40,supplySensitivity=1.40,policySensitivity=0.50,profileGroup="vegetable"},
  ONION={volatility=0.060,seasonalWeight=1.10,globalTrendSensitivity=0.75,demandSensitivity=1.20,supplySensitivity=1.20,policySensitivity=0.65,profileGroup="vegetable"},
  SUGARBEET={volatility=0.045,seasonalWeight=1.00,globalTrendSensitivity=1.00,demandSensitivity=1.10,supplySensitivity=1.10,policySensitivity=1.00,profileGroup="vegetable"}
}

-- Reserved for future orchard/perennial crop support, for example GRAPE and OLIVE.
GlobalMarketForcesConfig.orchardProfiles = {
  GRAPE={volatility=0.030,seasonalWeight=0.90,globalTrendSensitivity=0.85,demandSensitivity=1.15,supplySensitivity=0.90,policySensitivity=1.00,profileGroup="orchard"},
  OLIVE={volatility=0.028,seasonalWeight=0.85,globalTrendSensitivity=0.80,demandSensitivity=1.10,supplySensitivity=0.90,policySensitivity=1.05,profileGroup="orchard"}
}

GlobalMarketForcesConfig.industrialProfiles = {
  COTTON={volatility=0.070,seasonalWeight=1.00,globalTrendSensitivity=1.30,demandSensitivity=1.20,supplySensitivity=1.00,policySensitivity=1.40,profileGroup="industrial"}
}


GlobalMarketForcesConfig.forageProfiles = {
  GRASS={volatility=0.030,seasonalWeight=1.20,globalTrendSensitivity=0.55,demandSensitivity=1.20,supplySensitivity=1.35,policySensitivity=0.65,profileGroup="forage",marketType="crop"},
  HAY={volatility=0.035,seasonalWeight=1.15,globalTrendSensitivity=0.55,demandSensitivity=1.30,supplySensitivity=1.30,policySensitivity=0.65,profileGroup="forage",marketType="crop"},
  SILAGE={volatility=0.040,seasonalWeight=1.10,globalTrendSensitivity=0.65,demandSensitivity=1.40,supplySensitivity=1.25,policySensitivity=0.75,profileGroup="forage",marketType="crop"},
  STRAW={volatility=0.030,seasonalWeight=1.05,globalTrendSensitivity=0.50,demandSensitivity=1.10,supplySensitivity=1.20,policySensitivity=0.55,profileGroup="forage",marketType="crop"}
}


function GlobalMarketForcesConfig.mergeProfileGroup(target, source)
  for cropName, profile in pairs(source) do
    target[cropName] = profile
  end
end

GlobalMarketForcesConfig.cropProfiles = {}
GlobalMarketForcesConfig.mergeProfileGroup(GlobalMarketForcesConfig.cropProfiles, GlobalMarketForcesConfig.grainProfiles)
GlobalMarketForcesConfig.mergeProfileGroup(GlobalMarketForcesConfig.cropProfiles, GlobalMarketForcesConfig.vegetableProfiles)
GlobalMarketForcesConfig.mergeProfileGroup(GlobalMarketForcesConfig.cropProfiles, GlobalMarketForcesConfig.orchardProfiles)
GlobalMarketForcesConfig.mergeProfileGroup(GlobalMarketForcesConfig.cropProfiles, GlobalMarketForcesConfig.industrialProfiles)
GlobalMarketForcesConfig.mergeProfileGroup(GlobalMarketForcesConfig.cropProfiles, GlobalMarketForcesConfig.forageProfiles)

-- marketProfiles is the runtime lookup used by the price engine and market intelligence.
GlobalMarketForcesConfig.marketProfiles = GlobalMarketForcesConfig.cropProfiles

GlobalMarketForcesConfig.seasonalCurves = {
 WHEAT={1.08,1.06,1.03,1.00,0.96,0.92,0.88,0.91,0.96,1.02,1.07,1.10}, BARLEY={1.06,1.05,1.02,1.00,0.97,0.93,0.90,0.92,0.97,1.01,1.05,1.08}, OAT={1.05,1.04,1.02,1.00,0.98,0.95,0.92,0.94,0.98,1.01,1.04,1.06}, MAIZE={1.10,1.08,1.05,1.01,0.98,0.94,0.90,0.88,0.93,1.00,1.06,1.11}, SOYBEAN={1.09,1.07,1.04,1.01,0.97,0.93,0.90,0.92,0.97,1.03,1.08,1.12}, CANOLA={1.07,1.05,1.03,1.00,0.97,0.94,0.91,0.93,0.98,1.02,1.06,1.09}, SUNFLOWER={1.08,1.06,1.03,1.00,0.96,0.93,0.91,0.94,0.99,1.03,1.07,1.10}, SORGHUM={1.06,1.04,1.02,1.00,0.97,0.94,0.91,0.93,0.97,1.01,1.05,1.07},
 POTATO={1.04,1.03,1.01,0.99,0.96,0.94,0.95,0.98,1.02,1.05,1.07,1.06}, SUGARBEET={1.03,1.02,1.00,0.98,0.96,0.95,0.96,0.99,1.03,1.06,1.07,1.05}, COTTON={1.08,1.06,1.04,1.01,0.98,0.95,0.93,0.95,1.00,1.06,1.10,1.11}, RICE={1.07,1.05,1.03,1.00,0.96,0.93,0.92,0.96,1.02,1.07,1.09,1.08}, LONGGRAINRICE={1.08,1.06,1.03,1.00,0.96,0.93,0.92,0.97,1.03,1.08,1.10,1.09},
 GRAPE={1.02,1.02,1.01,1.00,0.99,0.98,0.98,0.99,1.00,1.02,1.03,1.03}, OLIVE={1.01,1.01,1.00,1.00,0.99,0.99,0.98,0.99,1.00,1.01,1.02,1.02}
}
