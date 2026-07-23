# Global Market Forces

Global Market Forces adds a living crop economy to Farming Simulator 25. Crop prices respond to broad market cycles, crop-specific demand and supply conditions, policy, seasonal patterns, and world events.

The mod includes a farmer-focused **Market Report** in the in-game menu, providing a quick overview of each crop's outlook, forecast accuracy, momentum, and the wider market conditions influencing prices.

## Features

- Endless global market cycles, including expansion, slowdown, recession, and recovery conditions.
- Individual crop trends for demand, supply, and policy.
- Broad world events that can support or pressure market prices.
- Crop-specific seasonal curves and volatility.
- A readable Market Brief explaining current global conditions and near-term analyst outlooks.
- Clickable crop detail reports with practical farm guidance, price timing, market supports, and risks to watch.
- GMF pricing applied to selling stations while preserving each station's normal price differences.
- Station-level comparison logging for reviewing the default game price against the GMF price.
- Persistent market state: trends and events continue between save sessions.
- Multiplayer support.

## Installation

1. Download the latest `FS25_GlobalMarketForces_*.zip` release.
2. Place the ZIP file directly in your Farming Simulator 25 mods folder:

   ```text
   Documents/My Games/FarmingSimulator2025/mods
   ```

3. Enable **Global Market Forces** on the savegame's mod-selection screen.
4. Load the savegame.

Do not extract the ZIP into the mods folder.

## Using the Market Report

Open the in-game pause menu and select the green market-report tab.

The overview contains:

- **Market Brief** - the broad global cycle, any offsetting world conditions, and the near-term analyst outlook.
- **Outlook** - the crop's overall selling conditions.
- **Accuracy** - how dependable the forecast is at the current time.
- **Momentum** - the expected direction of the market.

Select a crop row to open its detailed report. The report explains what the outlook means for your farm, expected price direction, supporting conditions, and risks worth monitoring.

## Pricing Behavior

For crops managed by GMF, each selling station begins with its own difficulty-adjusted base price. GMF then applies its crop modifier:

```text
station base price x GMF crop modifier
```

This keeps the normal price differences between stations while allowing the global market system to control the overall movement of managed crop prices. GMF pricing intentionally replaces the base game's station seasonal and great-demand price behavior for those crops.

## Savegame Data

GMF stores market state in this file inside each savegame folder:

```text
globalMarketForces.xml
```

This file preserves the market month, scheduled global cycles, crop trends, world events, and generated market state. Keep it when moving or backing up a savegame if you want the market timeline to continue unchanged.

## Compatibility

- Designed for Farming Simulator 25.
- Supports maps with ordinary selling stations and production-point selling stations.
- Economic difficulty is respected through each station's captured in-game base price.
- Other mods that directly overwrite selling-station prices may conflict with GMF's managed crop prices.

## Development and Debugging

When debug logging is enabled in the configuration, the game log records price comparisons in this form:

```text
Station | CROP: default 0.000000, GMF 0.000000 (+0.0%), GMF modifier 0.0000x
```

Prices are expressed per liter in the log. The Prices menu displays the equivalent per 1,000 liters.

## License

No license has been selected yet. Add a license file before accepting external contributions or redistributing source code under specific terms.
