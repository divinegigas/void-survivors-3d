# Update log: Android changes since the 3D project started

The 3D project began from the Android game's design as it stood on **20 Nov 2026, 23:18** (Android commit
`20d36ed`, "Kickoff prompt"). This repository's `DESIGN.md` is a copy of that version (plus §14.1, the 3D
numbers). The Android game has kept growing since then. This log lists **every change made to it after that point**,
in order, and says how each fits the 3D game.

- **The Android `DESIGN.md` is the up-to-date reference** (repository `void-survivors-`, branch `main`). Every
  number below matches it and the Android `CFG` block (`www/game.js`) as of 23 Nov 2026.
- **What's already built here** (milestone 1: rail flight, VESPER's Autocannon, Larva swarm, gems, cards, HUD) still
  uses the old Android numbers. Section 1 lists exactly what to change in `scripts/tuning.gd`.
- Each entry is tagged:
  - **USE** — bring it over as is (same rule, same numbers).
  - **ADAPT** — same idea, but it needs a 3D twist (described).
  - **SKIP** — a phone-only fix that doesn't apply to the 3D game (the reason is given).

---

## 1. Quick fix list for `scripts/tuning.gd` (things already built)

| Setting (Android name) | Old (in tuning.gd now) | New | Notes |
|---|---|---|---|
| `level.length` | 480 (8:00) | **420 (7:00)** | |
| `level.mini_bosses` | 120, 240, 360 | **105, 210, 315** (1:45, 3:30, 5:15) | |
| `spawn.ramp_seconds` | 320 | **280** | swarm reaches full intensity sooner |
| `enemy_hp_growth_per_min` | 0.35 | **0.45** | of the enemy's starting health, per minute |
| `boss_hp_mul` | 0.5 | **1.0** | every boss has double health |
| `post_level_up_invuln` | 0.8 | **1.5** | blinking safety after picking a card |
| *(new)* `post_pause_invuln` | — | **1.5** | same safety after unpausing |
| *(new)* `xp.early_mul` | — | **[0.5, 0.6, 0.7, 0.8, 0.9]** | levels 1–5 need less XP |

The rest of the new settings belong to systems not built in 3D yet, and they're listed with each entry below.

---

## 2. Every change, in order

### 2.1 Shorter, tougher stages · new enemies on every stage (21 Nov) — **USE**

- 7-minute stages, mini-bosses at 1:45 / 3:30 / 5:15 (section 1).
- Enemy health +45% of base per minute (was 35%); every boss has double health (`bossHpMul 1.0`).
- **Final bosses are 1.3× bigger** (hitbox and model: `finalBossSize 1.3`) and **every final boss has 3 phases**,
  switching at 66% and 33% health, each angrier (the Warp Wyrm and Abyssal Maw got new third phases).
- **Stages 2–5 each have their own 4 regular enemies** instead of recoloured stage 1 bugs. They fill the same four
  roles (drone, weaver, diver, gunner), each with a twist. The full table is in Android `DESIGN.md` §9:
  Warp Zone: Blink Mite, Phase Eel, Warp Streak, Prism Node ·
  The Deep: Drift Jelly, Gulper Eel, Bone Piranha, Spine Urchin ·
  Leviathan: Blood Fluke, Tapeworm, Leech, Polyp ·
  Prismatic Void: Eye Shard, Halo Chain, Mirror Blade, Hollow Cherub.
- **In 3D:** use the "falls down" → "approaches along the rail" mapping from §14.1 (× `approach_mul`). Sideways moves
  (Blink Mite's warp, Phase Eel's zig-zag) happen in the steering plane. Divers lunge toward the camera at your
  position. Ring and fan patterns are built in the plane facing you, as §14 already says.

### 2.2 Unique mini-bosses for stages 2–5 · new bullet types (21 Nov) — **USE / ADAPT**

- Each stage has its own three mini-bosses (Android `DESIGN.md` §11):
  Rift Manta, Flux Oculus, Static Wraith · Dread Nautilus, Siren Bloom, Gulper King ·
  Bile Bladder, Parasite King, Phagocyte · Prism Knight, Halo Choir, The Reflection.
- Mini-bosses get **+25% health** on top of the boss multiplier (`miniBossHpMul 1.25`). Base health 2200 / 3600 / 5200
  for the 1st / 2nd / 3rd, × (1 + stage − 1).
- Two new bullet types: **lobbed acid** (arcs down under gravity) and **slow-then-fast** shots (start slow, then
  accelerate up to a top speed).
- **In 3D (ADAPT):** lobbed acid can arc across the plane toward the bottom of the steering box (gravity in screen
  space) while it travels toward you. "Lunges at you" (Gulper King, Phagocyte) become lunges toward the camera.
  **The Reflection** mirrors your position across the box's centre line. **Static Wraith** teleports within the arena.

### 2.3 Bosses scale with your firepower (21 Nov) — **USE**

- When any boss arrives, its health × `firepower ^ 0.6` (`bossPowerScale`; 0 = off).
- Firepower = damage × fire rate × (1 + 0.35 × extra Multishot projectiles) × (1 + crit chance), 1.0 for a fresh ship.
- Why: a maxed Hangar plus damage passives (about 16× firepower) killed final bosses in 3–4 seconds.

### 2.4 Ultimates: bigger impact, upgrade cards, hidden invincibility (21 Nov) — **USE / ADAPT**

- **Impact** after the cut-in (Android `DESIGN.md` §7):
  - one white frame, then a colour flash and three shockwaves in the ultimate's colour
  - comic speed lines, the ultimate's symbol swelling behind the action
  - 0.35 s of slow motion (`ultImpact`)
  - a layered sound
  - a glowing screen edge while it runs
  - extras for some ultimates: a mushroom cloud for Megaton, a giant clock face for Time Warp, flame and
    afterimage auras for Overdrive and Phase Ram
- **Ultimate upgrades:** at pilot levels 20, 30, 40… the cards are 3 ultimate upgrades instead
  (`ultUpgradeEvery 10`). Each pick is +1 ultimate level, fully recharges it, and plays a fanfare.
  - **Amplify** (×4 max): stronger and longer, with per-ultimate numbers in §7.
  - **Quick Charge** (×3 max): 15% faster recharge each.
  - **Two unique perks per ultimate:** Fallout / Chain Reaction · Piercing Rounds / Vacuum ·
    Deep Freeze / Time Thief · Cluster Warheads / Encore · Grand Finale / Battering Ram ·
    Twin Singularity / Supernova.
- **Secret:** 2 s of invincibility after an ultimate fires, with no blinking (`ultGhost 2.0`).
- **In 3D (ADAPT):** slow motion maps to `Engine.time_scale`. Shockwaves become expanding rings, or spheres for
  Nova-like ultimates. The screen-edge glow is a full-screen shader. The Black Hole sits 200 units *ahead in depth*
  (on the rail) rather than above the ship. Twin Singularity puts the two holes left and right of you in the plane.
  The ultimate fires on a button, as §14 says.

### 2.5 Ships are earned · the reveal cinematic (21 Nov) — **USE**

These are the final rules; the 21 Nov commits refined them in steps.

- The first time you play, the Hangar holds **only VESPER**.
- A run that ends (death, quit or stage clear) **after beating at least one boss** unlocks the **next** ship, cheapest
  first: Vesper, Trident, Hornet, Bulwark, Halo, Tide, Hive, Lance, Corona, Tempest, Needle, Pulsar.
- Tier gates (`shipUnlockStage`): common ships need a **stage 1** boss, uncommon a **stage 2** boss, rare a
  **stage 3** boss. If the next ship needs more, the results say e.g. "BEAT A STAGE 2 BOSS TO UNLOCK UNCOMMON SHIPS".
- A new ship joins the ship wheel tagged **NEW!**, still a silhouette ("PILOT: ???") until you buy it.
- **The reveal (~5 s, skippable after 1.2 s)**, before the results screen:
  - death sting or victory fanfare as the screen dims
  - 0.9 s: hazard stripes and "NEW PILOT · APPROACHING" with alarm beeps
  - 2.0 s: the pilot's silhouette sweeps in on a slab in the ship's colour, the ship streaks past
  - 3.3 s: white flash, "UNLOCKED!" and a fanfare
  - then a wipe to the results
- **In 3D:** it's all 2D UI, so build it on a CanvasLayer like the other menus. The streaking ship can be the real
  3D ship model as a black silhouette.

### 2.6 Secret stage: Boss Rush (21 Nov) — **USE / ADAPT**

- Beat stage 5 **at full health** → the win screen offers "SECRET STAGE: BOSS RUSH!", and stage select shows stage
  "??" from then on (head start: 40 level-ups).
- All 20 bosses in campaign order: the first at 0:12, then **one every minute whether or not the last one is dead**
  (`rush.first 12`, `rush.gap 60`).
- Each boss brings its home stage's music and sky. The swarm mixes every stage's enemies, with 1.6× longer gaps
  (`rush.swarmMul`). Difficulty is stage 5's.
- Killing the Seraph wins: "LEGEND!".
- **In 3D (ADAPT):** the rail could loop through a remix of each stage's set pieces, swapping environment, sky and
  music as each new boss arrives.

### 2.7 Settings menu (21 Nov) — **ADAPT**

- A SETTINGS button on the title and pause screens.
- **Music** and **Sound effects** sliders (0–100%), saved with your progress.
- **Vibration** on/off.
- **Reset Progress**: an "ARE YOU SURE?" screen; erasing takes two taps. It wipes credits, ships, upgrades, stages,
  secrets and best times, keeps sound settings, and restarts.
- **Stage music** page: see below.
- **In 3D:** vibration becomes **gamepad rumble** on/off. Add the PC basics there too: fullscreen / windowed, mouse
  sensitivity, and key rebinding (§14).

### 2.8 Longer safety windows (21 Nov) — **USE**

1.5 s of blinking invincibility after picking a card (was 0.8) and, new, 1.5 s after unpausing (section 1).

### 2.9 Progression tweaks (21 Nov) — **USE**

- **Easier start:** levels 1–5 need ×0.5 / 0.6 / 0.7 / 0.8 / 0.9 of the XP (`xp.earlyMul`).
- **Level caps grow with the stage:** weapons and passives can reach level **5 / 8 / 11 / 14 / 17** on stages 1–5
  (`levelCapByStage`; Boss Rush uses stage 5's).
  - Above 5, a weapon **overcharges**: +15% damage and ×0.95 cooldown per level (`overchargeDmg`, `overchargeCd`).
    Otherwise it behaves as level 5.
  - Passives keep growing more gently above 5: Rapid −5%, Power +8%, Blast +8%, Velocity +10%, Crit +3% (max 60%),
    Tractor +20%, Data Core +6%, Bounty +12%.
  - Reactive Armor and Nano Repair stop at 5, Hull Plating at 3.
- **Card weights** (`cardWeight`): Rapid Fire ×1.5; **Multishot ×0.35**, the rarest card.
- **Multishot** now has 3 levels, each **+1 projectile for every weapon** (extra cannon barrels, spread shots,
  rockets, laser beams, wing shots, echo novas, orbit blades, chain jumps, rails, flak shells, discs, waves, drones).
- **Secret pity:** each run in a row that ends without clearing a stage makes rare cards 30% likelier, up to 2.5×
  (`pityPerFail`, `pityMax`). Clearing a stage resets it. Never shown to the player.
- **Results screen:** under the bounty total, a box "SPEND IT: N SHIP UPGRADES READY ›" (or "SAVE UP FOR SHIP
  UPGRADES ›") that jumps straight to this ship's Hangar upgrades.

### 2.10 Music: 10 unlockable tracks, a reveal, a stage-music picker, a menu theme (21–22 Nov) — **USE / ADAPT**

- **Three original tracks per stage**:

  | Stage | Track 1 | Track 2 | Track 3 |
  |---|---|---|---|
  | 1 | Hive Surf | Larva Stomp (surf-punk) | Swarm Protocol (dubstep metal) |
  | 2 | Warp Rider | Lightspeed Debt (synthwave speed metal) | Tachyon Blues (drum & bass) |
  | 3 | Abyssal Drift | Kelp Cathedral (organ psychedelia) | Pressure Bloom (stoner rock) |
  | 4 | Heart of the Beast | Arterial Engine (glitch hop + doom) | Clot (sludge doom) |
  | 5 | Seraph | Halo Requiem (hymn into battle) | Last Wing (toccata into battle) |

- Starting a stage counts a play. The 2nd track unlocks after **10 plays** of that stage, the 3rd after **20**
  (`trackUnlockPlays [0, 10, 20]`).
- **Reveal:** at the end of that run, after any ship reveal, a "NEW TRACK INCOMING" reveal plays: hazard stripes,
  a spinning record and a bouncing equalizer while the new song plays, then "UNLOCKED!". The new track becomes the
  stage's track.
- **Picking tracks:** Settings → STAGE MUSIC cycles and previews unlocked tracks per stage and shows the plays until
  the next one.
  - Once any stage has a 2nd track, **stage select gets a ♪ MUSIC button** (BACK · ♪ MUSIC · HANGAR).
  - It opens a screen with every stage's 3 tracks. Tap one to hear it and make it that stage's music: gold = selected,
    with an equalizer while it plays.
  - Locked tracks show "? ? ?" and the plays needed; stages you haven't reached show LOCKED.
  - LAUNCH starts the last-picked stage.
- **Menu theme "Launch Bay"** (heroic synthwave rock, A major, 128 BPM) plays on the title, Hangar and stage select,
  and **keeps playing without restarting** as you move between those screens. The results screen stays quiet after the
  victory or defeat sting, and the theme returns on the next menu. The Boss Rush uses each stage's chosen track.
- **In 3D (ADAPT):** §14 says "port the synth or render the stems".
  - The simplest route is to **render each song to a looping audio file**. The Android repo's
    `tools/test/render-music.js` already renders songs offline. Extend it to render one full loop past the intro and
    note the loop point, then use Godot's looping Ogg streams.
  - An autoload "music player" node makes it easy to keep the menu theme going across menu scenes.
  - PC has no "first tap before sound" rule, so the theme can start on the title right away.

### 2.11 New HUD layout (21 Nov) — **ADAPT**

- **Phone layout:**
  - big pilot portrait bottom left (about 30% bigger)
  - big hearts along the bottom, pulsing on your last heart
  - stage progress under the clock at the top centre
  - pause button top right; ultimate button bottom right
- **In 3D:** the screen is landscape, so keep the spirit, not the exact spots:
  - pilot portrait bottom left, hearts bottom centre, ultimate gauge bottom right
  - XP bar across the top, clock and stage progress top centre
  - no pause button needed (Esc / Start)

### 2.12 Power-up drops (22–23 Nov) — **USE / ADAPT**

- Every regular enemy you destroy rolls once for a drop (`CFG.drops`). Bosses never drop, and neither does the
  swarm that dies with a final boss.
- Drops drift down slowly and bob, and your magnet pulls them in like gems.
- Grabbing one plays a jingle and a comic word: REPAIR! / MAGNET! / SHIELD! / FLAMER!
- Drops are **rare: about 2 a stage** at full health (the owner tried more and found it far too many).

| Drop | Look | Chance per kill | Effect |
|---|---|---|---|
| Repair | red cross | 0.03% + **0.05% per missing heart** | +1 hull (nothing at full hull) |
| Magnet | red horseshoe magnet | 0.18% | every XP gem on screen flies to you at 700/s |
| Spare Shield | blue shield badge | 0.1% | a spinning blue hexagon around the ship; blocks one hit; **never recharges**; one at a time; the Hangar Deflector (which recharges) takes hits first; carries to the next stage |
| Flamethrower | orange flame | 0.09% | 24 s; a cone of fire from the ship's nose, 150 long (× area), ±18°; 150 damage/s (× damage bonuses) to every enemy in it, ticking every 0.1 s; **eats enemy bullets** in the cone; a fuel gauge under the ship blinks in the last 3 s; another flamer refills it to 24 s |

Other numbers: `fallSpeed 45`, `pickRadius 20`, `vacuumSpeed 700`. Icons are drawn as a white ink-outlined disc with a
spinning burst in the drop's colour behind it.

- **In 3D (ADAPT):**
  - Drops stream toward you along the rail like gems (`xp.rail_speed`), and the magnet pulls them in the plane.
  - Make the icons camera-facing billboards (like the gems) or small toon models with the spinning burst.
  - **The flamethrower is a cone pointing forward into the depth.** Test each enemy and enemy bullet for being inside
    a cone in front of the ship: depth 0–150, widening at ±18°. Draw it as layered flickering toon flame shapes with
    ink outlines, plus ember particles. It should feel like a big forward stream of fire.

### 2.13 No-fly zones at the top and bottom, with a frosted blur (22–23 Nov) — **SKIP**

- **Android:** the ship can't fly within 90 units of the top or bottom of the screen (`flyTop`, `flyBottom`), so it
  never sits under the XP bar or behind the hearts, portrait and ultimate button. Both strips are blurred (lighter on
  top) with a cool tint. The ship, enemy bullets and HUD are drawn sharp on top.
- **Why skip in 3D:** this is a fix for a phone, where your finger and the HUD crowd the play area. In 3D the steering
  box already sets the limits. If the HUD ever covers the edges of the box, shrink the box (`box.height`, `box.margin`)
  instead.
- **Keep the principle:** never hide enemy bullets behind HUD or effects (§14.1 already draws them on top).

### Not game changes

- Android-only tooling: `HANDOFF.md` (working notes) and `tools/test/` (headless Playwright scripts: a campaign bot,
  a music renderer, a flow smoke test). Worth copying the idea: a **headless test** in Godot (run with `--headless`
  and a test script) that plays a stage and prints boss fight lengths.

---

## 3. Still open (shared with the Android game)

- **Prizes for clearing stages 4 and 5** (not decided yet). Ideas: alternate pilot outfits or ship paint jobs (with
  the same reveal), a 7th and 8th ultimate, a starting perk or extra reroll, prestige ship variants, a hard mode, a
  bestiary.
- **Balance to watch:** boss fight lengths with firepower scaling, the 20-minute Boss Rush, level caps and overcharge,
  Multishot rarity, the early XP curve, drop rates.
