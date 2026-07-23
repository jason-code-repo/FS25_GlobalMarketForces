FS25 Global Market Forces v0.18.3.0 Persistence Repair

Changes:
- Replaced os.time() in GlobalMarketForcesPersistence.lua with math.random(100000, 999999999).
- Added defensive self.market initialization before indexing self.market.currentMonthIndex or self.market.randomSeed.
- Kept GUI removed.
- Kept GlobalMarketForces.lua first in modDesc.xml source order so extension files attach methods to an existing GlobalMarketForces table.

This patch specifically targets the runtime error:
GlobalMarketForcesPersistence.lua:1: attempt to index nil with 'time'
