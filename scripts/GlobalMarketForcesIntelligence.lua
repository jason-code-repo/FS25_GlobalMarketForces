GlobalMarketForcesIntelligence={}
-- Keep the report's neutral band narrow enough for normal global and
-- crop-specific conditions to be visible to the player. This affects only
-- Outlook labels; it does not alter the GMF price calculation.
function GlobalMarketForces:getAnalystRatingFromModifier(x) if x>=1.30 then return "Strong Buy" elseif x>=1.08 then return "Buy" elseif x>0.92 then return "Hold" elseif x>0.70 then return "Sell" end return "Strong Sell" end
function GlobalMarketForces:getFarmerOutlookFromRating(r) if r=="Strong Buy" then return "Excellent" elseif r=="Buy" then return "Good" elseif r=="Hold" then return "Average" elseif r=="Sell" then return "Poor" end return "Avoid" end
function GlobalMarketForces:getFarmerRecommendationFromOutlook(o) if o=="Excellent" then return "Aggressively Expand" elseif o=="Good" then return "Expand Production" elseif o=="Average" then return "Maintain Acreage" elseif o=="Poor" then return "Reduce Production" end return "Consider Avoiding" end
function GlobalMarketForces:getDirectionFromDelta(d) if d>=0.25 then return "Strong Upward" elseif d>=0.08 then return "Upward" elseif d<=-0.25 then return "Strong Downward" elseif d<=-0.08 then return "Downward" end return "Stable" end
function GlobalMarketForces:getMomentumLabel(d) if d=="Strong Upward" then return "Strong Uptrend" elseif d=="Upward" then return "Uptrend" elseif d=="Downward" then return "Downtrend" elseif d=="Strong Downward" then return "Strong Downtrend" end return "Stable" end
function GlobalMarketForces:getConfidenceLabelFromScore(s) if s>=90 then return "Very High" elseif s>=75 then return "High" elseif s>=55 then return "Medium" elseif s>=35 then return "Low" end return "Very Low" end
function GlobalMarketForces:getMarketConditionLabelFromScore(s) if s>=85 then return "Stable" elseif s>=65 then return "Mostly Stable" elseif s>=45 then return "Mixed" elseif s>=25 then return "Volatile" end return "Highly Volatile" end
function GlobalMarketForces:getAverageModifierForWindow(c,start,months) local last=start+months-1; local total,count=0,0; for m=start,last do total=total+self:calculateCropModifier(c,m); count=count+1 end; return count>0 and total/count or self:calculateCropModifier(c,start) end
function GlobalMarketForces:getTrendDisplayName(t,cropName) local d=t.channel=="global" and GlobalMarketForcesTrends.globalDefinitions[t.trendType] or self:getDefinitionForCropTrend(t.channel,t.trendType,cropName); return d and d.displayName or t.trendType end
function GlobalMarketForces:getTrendBaseImpact(t,cropName) local d=t.channel=="global" and GlobalMarketForcesTrends.globalDefinitions[t.trendType] or self:getDefinitionForCropTrend(t.channel,t.trendType,cropName); return d and d.baseImpact or 0 end
function GlobalMarketForces:getCropDriverLabels(c,m)
 local drivers,risks={},{}
 local function addByImpact(label, impact)
  if impact > 0.0001 then table.insert(drivers,label)
  elseif impact < -0.0001 then table.insert(risks,label) end
 end
 for _,t in ipairs(self:getActiveGlobalTrends(m)) do addByImpact(self:getTrendDisplayName(t,c),self:getTrendBaseImpact(t,c)) end
 for _,t in ipairs(self:getActiveCropTrends(c,m)) do
  local label=string.upper(string.sub(t.channel,1,1))..string.sub(t.channel,2)..": "..self:getTrendDisplayName(t,c)
  addByImpact(label,self:getTrendBaseImpact(t,c))
 end
 for _,e in ipairs(self:getActiveEvents(m)) do
  local d=GlobalMarketForcesEvents.definitions[e.eventType]
  local referenceCrop=self:getTrendReferenceCrop(c)
  local cropImpact=d and d.cropImpacts and (d.cropImpacts[c] or d.cropImpacts[referenceCrop])
  if cropImpact ~= nil then addByImpact(d.displayName,cropImpact*(d.priceDirection or 1)) end
 end
 return drivers,risks
end
function GlobalMarketForces:getDynamicConfidenceScore(c,months)
 local m=self.market.currentMonthIndex or 1; local score=100
 if months>12 then score=score-45 elseif months>6 then score=score-30 else score=score-12 end
 local events=self:getActiveEvents(m); score=score-(#events*6)
 local sev=0; for _,e in ipairs(events) do sev=sev+(e.severity or 0) end; score=score-math.min(18,sev*9)
 local pos,neg=0,0; for _,t in ipairs(self:getActiveCropTrends(c,m)) do local b=self:getTrendBaseImpact(t,c); if b>0.05 then pos=pos+1 elseif b<-0.05 then neg=neg+1 end end
 if pos>0 and neg>0 then score=score-18 end
 score=score-math.min(12,((GlobalMarketForcesConfig.marketProfiles[c] or {}).volatility or 0)*150)
 return math.max(20,math.min(95,score))
end

-- A deterministic pseudo-random value prevents opening the report from
-- rerolling a forecast. The resulting forecast is also persisted per month.
function GlobalMarketForces:getForecastNoise(key)
 local seed=(self.market and self.market.randomSeed) or 1
 local value=seed
 for i=1,#key do value=(value*31+string.byte(key,i))%2147483647 end
 return (value%100000)/100000
end

function GlobalMarketForces:getForecastDirection(actualDirection, confidence, key)
 local noise=self:getForecastNoise(key)
 if noise <= confidence/100 then return actualDirection end
 local errorNoise=self:getForecastNoise(key..":error")
 if actualDirection=="Strong Upward" then return errorNoise<0.5 and "Upward" or "Stable" end
 if actualDirection=="Upward" then return errorNoise<0.5 and "Stable" or "Downward" end
 if actualDirection=="Strong Downward" then return errorNoise<0.5 and "Downward" or "Stable" end
 if actualDirection=="Downward" then return errorNoise<0.5 and "Stable" or "Upward" end
 return errorNoise<0.5 and "Upward" or "Downward"
end

function GlobalMarketForces:getIssuedCropForecast(c,months,actualDirection)
 local issueMonth=self.market.currentMonthIndex or 1
 self.market.cropForecasts=self.market.cropForecasts or {}
 local key=c..":"..months
 local forecast=self.market.cropForecasts[key]
 if forecast~=nil and forecast.issueMonth==issueMonth and forecast.version==GlobalMarketForcesConfig.marketIntelligence.forecastVersion then return forecast end
 local confidence=self:getDynamicConfidenceScore(c,months)
 forecast={issueMonth=issueMonth,months=months,confidence=confidence,direction=self:getForecastDirection(actualDirection,confidence,key..":"..issueMonth),version=GlobalMarketForcesConfig.marketIntelligence.forecastVersion}
 self.market.cropForecasts[key]=forecast
 self:saveMarketState()
 return forecast
end

function GlobalMarketForces:getForecastSentence(label,direction,confidence)
 local words={ ["Strong Upward"]="rise strongly", Upward="improve", Stable="remain broadly steady", Downward="weaken", ["Strong Downward"]="weaken sharply" }
 local movement=words[direction] or "remain uncertain"
 if confidence>=75 then return label..": Prices are expected to "..movement.."."
 elseif confidence>=55 then return label..": Prices may "..movement.."."
 end
 return label..": The outlook is uncertain, though prices could "..movement.."."
end

function GlobalMarketForces:getCropMarketIntelligence(c)
 local cur=self.market.currentMonthIndex or 1; local cm=self:calculateCropModifier(c,cur)
 local st,mt,lt=GlobalMarketForcesConfig.marketIntelligence.shortTermMonths,GlobalMarketForcesConfig.marketIntelligence.mediumTermMonths,GlobalMarketForcesConfig.marketIntelligence.longTermMonths
 local shortForecast=self:getIssuedCropForecast(c,st,self:getDirectionFromDelta(self:getAverageModifierForWindow(c,cur,st)-cm))
 local mediumForecast=self:getIssuedCropForecast(c,mt,self:getDirectionFromDelta(self:getAverageModifierForWindow(c,cur,mt)-cm))
 local longForecast=self:getIssuedCropForecast(c,lt,self:getDirectionFromDelta(self:getAverageModifierForWindow(c,cur,lt)-cm))
 local rating=self:getAnalystRatingFromModifier(cm); local out=self:getFarmerOutlookFromRating(rating); local drivers,risks=self:getCropDriverLabels(c,cur); local marketType=(GlobalMarketForcesConfig.marketProfiles[c] or {}).marketType or "crop"
 return {fillTypeName=c,marketType=marketType,currentModifier=cm,analystRating=rating,farmerOutlook=out,farmerRecommendation=self:getFarmerRecommendationFromOutlook(out),momentumLabel=self:getMomentumLabel(shortForecast.direction),shortTermDirection=shortForecast.direction,mediumTermDirection=mediumForecast.direction,longTermDirection=longForecast.direction,shortTermConfidence=shortForecast.confidence,mediumTermConfidence=mediumForecast.confidence,longTermConfidence=longForecast.confidence,forecastReliability=self:getConfidenceLabelFromScore(shortForecast.confidence),marketCondition=self:getMarketConditionLabelFromScore(shortForecast.confidence),drivers=drivers,risks=risks}
end
function GlobalMarketForces:getMarketIntelligenceSnapshot() local rows={}; for c,_ in pairs(GlobalMarketForcesConfig.marketProfiles) do table.insert(rows,self:getCropMarketIntelligence(c)) end; local rank={Excellent=5,Good=4,Average=3,Poor=2,Avoid=1}; table.sort(rows,function(a,b) return (rank[a.farmerOutlook] or 0)>(rank[b.farmerOutlook] or 0) end); return rows end
function GlobalMarketForces:joinLabels(t,empty) if not t or #t==0 then return empty or "none" end; local s=""; for i,v in ipairs(t) do if i>1 then s=s..", " end; s=s..v end; return s end
