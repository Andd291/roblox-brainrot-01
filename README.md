# Brainrot Bazaar — roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Andd291/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Andd291/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A 3D Steal-a-Brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
Wild brainrots walk the conveyor belt, players buy them with E, place them on their base to earn money per
second, steal from each other (a locked base cannot be stolen from), outrun the tsunami that sweeps the map,
and rebirth for a permanent income boost.

## The game

- **The cast:** 13 absurd characters of our own — Mie Goreng Golem, Durian Raja, Cone Traffic Samurai,
  Nasi Padang Dragon, Indomie Sultan, Gado-Gado God and more — on five rarities (Common → Mythic) with
  Golden, Diamond and Rainbow mutations. Each shows its name, rarity and money-per-second on a floating label.
- **The loop:** brainrots spawn on the belt and walk past; buy one, it sits on a plot on your base and pays
  you every second; buy rarer ones and climb the ladder.
- **The tension:** press E on another player's brainrot to steal it and carry it home over your head; lock
  your base for 60 seconds to stop thieves; a tsunami sweeps the map every couple of minutes and washes
  anyone caught outside their base back home, dropping what they carried.
- **The progression:** rebirth (spend money and give up your brainrots for +50% income forever) and three
  upgrades — Base Capacity, Income Boost and Speed Boots.
- **The world:** a built 3D plaza with a fountain, eight bases in a ring, the conveyor belt, trees, lamps,
  drifting clouds and a tsunami wall — all built in code by `src/server/WorldBuilder.luau`.

## Layout

- `src/shared/` — `Config.luau` (all tuning), `BrainrotData.luau` (the cast, rarities, mutations),
  `BrainrotFactory.luau` (builds each brainrot's 3D model), `Remotes.luau` (the client-server channels),
  `Util.luau` (formatting, weighted rolls).
- `src/server/` — `init.server.luau` (bootstrap), `WorldBuilder.luau`, `StateService.luau` (the single
  source of truth for player data), `BaseService.luau` (bases, plots, the money tick), `SpawnerService.luau`
  (the belt and buying), `StealService.luau` (stealing, carrying, the base lock), `WaveService.luau`
  (the tsunami), `RebirthService.luau` (rebirths and upgrades).
- `src/client/` — `Main.client.luau` (bootstrap), `HudController.luau` (money, lock/rebirth/upgrades,
  wave banner, feed, next tier), `InteractionController.luau` (the contextual E hint),
  `EffectsController.luau` (sparkles, floating text, sounds).
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as
  `.gitkeep` or `.DS_Store`, which fail an entry), and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; `screenshots/` holds
  captures of the game running in Roblox Studio; `PLAY.json` names the published place.
- One of your screenshots must also be your game's first thumbnail on Roblox: the same picture, uploaded
  on the Creator Dashboard with your game's icon.
- `TOUR.json` is the optional tour: for each screenshot, the keys that bring the game to that screen.

Build it and run it as the grader does, writing `out/` in place of `/output`:

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
