# Void Survivors: Game Design

This is the single source of truth for Void Survivors' systems. Two games share it:

- **Void Survivors (Android):** a top-down vertical shooter. It's the reference build, and every number
  below comes from its code (`www/game.js`, the `CFG` block and data tables).
- **Void Survivors 3D (PC, Godot 4):** the same systems as an on-rails space shooter in the style
  of the classic 90s rail shooters. See **§14 3D adaptation** for what changes.

When a system changes in either game, update this file so the two stay in step.

---

## 1. Pitch

A shooter where your ship fires on its own, wrapped in survivor-like progression. You fly through
waves of a gross organic insect **hive fleet**. Every kill drops **XP gems** and you have to fly over
them to collect them. Each level-up offers **3 cards**: upgrade something you own, or add a new
weapon or support module. One **run** is a **five-stage campaign**, and your loadout carries from stage to
stage. **Credits** from bounties buy new ships and per-ship upgrades in the **Hangar** between runs.

**Tone:** pop-art comic look (thick ink outlines, flat cel shading with halftone dots, POW!/SPLAT!
lettering) against horror bugs, with a late-90s cel-anime cast of pilots and Persona-style kinetic menus.

---

## 2. Core loop and controls

- The ship **fires its weapons automatically**. The player only steers.
- **Mobile:** drag anywhere. Your finger moves a target point and the ship chases it at its
  **handling** speed (`1100 units/s × ship handling`), so your finger never covers the ship.
- **Hitbox:** only a tiny white dot (radius 4) can be hit, bullet-hell style. Hits cost 1 hull,
  then give 1.2s of blinking invulnerability and clear enemy bullets within 70 units (mercy).
- **XP gems** drift downward. Inside your **magnet radius** (34 × pickup stat) they fly to you at
  440/s. Missed gems are lost. Gems are worth 1 (small) or 5 (big).
- **XP needed** for the next level is `round(6 + 3·(L−1) + 0.35·(L−1)²)`. XP gain is scaled by
  `gainRate = 0.5`.
- **Level-up** pauses the game and shows 3 cards (plus REROLL if owned). After picking, you get
  0.8s of grace invulnerability.
- **Double-tap** fires the **ultimate** (from level 10 on; see §7).
- The world is **360 units wide**, and its height fits the screen.

---

## 3. Loadout and level-up cards

- **The signature weapon:** each ship starts with its own weapon in a **bonus slot**. It levels like
  any other weapon and fires **20% faster** than the same weapon picked up later (`signatureCooldown 0.8`).
- **Slots grow with the stage:** 2 weapons + 2 support modules on stage 1, then +1 of each per stage:
  3+3, 4+4, 5+5, and **6+6** on stage 5.
- **Cards:** each of the 3 cards is a **coin flip** between "upgrade something you own" and "a new
  system" (only while a slot is free). A new system is a weapon or a passive, chosen 50/50.
- **Rarity:** weapons and passives are each **common** (green), **uncommon** (purple) or **rare** (gold).
  Pick weights are common 4, uncommon 2, rare 1 *per item*. Cards are framed in the tier colour.
- **Max level** is 5 (Hull Plating is 3). When everything is full and maxed, cards fall back to
  *Field Repair* (+1 hull) or a *Salvage Cache* (+15 credits).
- **Level 10** replaces the normal cards with a choice of 3 of the 6 **ultimates**.

---

## 4. Weapons (13)

`cd` is the cooldown in seconds. All cooldowns are multiplied by the cooldown modifier (§5).
`count` = extra projectiles from Multishot.

| Weapon | Tier | Behaviour (per level L) |
|---|---|---|
| **Autocannon** | common | Straight shots, cd 0.16 (0.13 at L4+), dmg 8+2L. 1 barrel, 2 at L3, 3 at L5 (+count, max 5). The basic gun; VESPER's signature. |
| **Spread Shot** | common | A fan of 2+L+count shots across (16+9L)°, cd 0.62−0.05L, dmg 7.5+1.5L, speed 560. |
| **Homing Rockets** | common | 1+⌊L/2⌋+count rockets launched sideways that steer to the nearest enemy (turn 6 rad/s, up to 460/s). They explode for 20+8L in a radius of (22+3L)×area. cd 1.45−0.12L. |
| **Wing Cannons** | common | Two escort pods at ±24 fire straight shots. dmg 10×(0.4+0.15L), cd 0.16×1.3 (×1.0 at L3+). |
| **Flak Burst** | common | A shell (420/s) bursts after 0.45s or on impact into 6+2L+2·count shrapnel (dmg 7+2.5L, life (0.45 + 0.1 at L4)×area). cd 1.15−0.08L. Twin angled shells at L5. |
| **Ricochet Disc** | common | 1+⌊L/2⌋+count discs bounce off every screen edge for 3+0.4L s, piercing, rehitting each enemy every 0.25s. dmg 10+5L, radius (7, or 10 at L4+)×area. cd 2.4−0.2L. |
| **Pulse Laser** | uncommon | A beam straight up from the ship, on for 0.7+0.12L s every 2.7−0.22L s. Width (8+3L)×area, (70+30L) damage per second. LANCE's signature. |
| **Orbit Shards** | uncommon | min(8, 1+⌈0.8L⌉+count) blades circle the ship at radius 40×area. dmg 10+5L, 0.3s per-enemy rehit. **They erase enemy bullets they touch.** |
| **Plasma Wave** | uncommon | A wide, slow arc (260/s) that pierces everything. Half-width (40+8L)×area, dmg 9+5L (+8 at L4+). cd 1.9−0.12L. A second wave at L5. |
| **Hunter Drones** | uncommon | min(4, 1+⌊(L−1)/2⌋+count) drones hover around the ship and shoot the nearest enemy within 320. dmg 7+2.5L (+4 at L4+), cd 0.5 (0.4 at L2+). |
| **Arc Lightning** | rare | Zaps the nearest enemy (range 300), then jumps 2/3/3/5/7 (+count) times within 110×area. dmg 16+7L, cd 1.4−0.1L. |
| **Railgun** | rare | A huge, piercing shot at 1500/s. dmg 60+30L (+40 at L4+), cd 2.1−0.2L. Twin rails at L5. |
| **Nova Burst** | rare | A shockwave around the ship every 6.5−0.7L s, radius (70+18L)×area, dmg 35+20L. **It erases enemy bullets.** |

---

## 5. Passives / support modules (12)

| Passive | Tier | Effect per level |
|---|---|---|
| Rapid Fire | common | Weapon cooldowns ×0.9 |
| Power Core | common | +12% damage |
| Tractor Beam | common | +30% pickup radius |
| Data Core | common | +10% XP |
| Hull Plating | common | +1 max hull and repair 1 (max level 3) |
| Velocity Rounds | uncommon | +15% projectile speed; bullets pierce 1 enemy at L3, 2 at L5 |
| Blast Amplifier | uncommon | +15% area (blast radius, laser width, orbit radius, disc size) |
| Bounty Hunter | uncommon | +20% credits from kills |
| Reactive Armor | uncommon | When hit, a shockwave (radius 60+15L, +40 at L5; dmg 30+20L) clears bullets; 1.5× invulnerability from L3 |
| Multishot | rare | Extra projectiles: +1 at L1, +2 at L3, +3 at L5; +5% damage at L2 and at L4 |
| Targeting Computer | rare | +7% chance per level of double damage |
| Nano Repair | rare | Repairs 1 hull every 52−7L s |

**Modifier stack:** damage = ship power × Hangar damage upgrades + passives. Cooldown modifier =
1 / (ship fire rate) × 0.9^RapidFire. Overdrive (ultimate) multiplies cooldowns by 0.33.

---

## 6. Ships (12) and pilots

Every ship has one **signature weapon** and base stats:
**hull** (hits), **power** (damage ×), **fire rate** (×), **pickup** (magnet ×) and **handling** (×).
Ship unlock price depends on its weapon's tier: **common 300, uncommon 900, rare 2000** credits.
VESPER is free.

| Ship | Weapon | Role | Hull | Pow | Rate | Pick | Hand | Pilot |
|---|---|---|---|---|---|---|---|---|
| VESPER | Autocannon | All-rounder | 3 | 1.00 | 1.00 | 1.00 | 1.00 | Ren Takeda (m), the everyman; messy brown hair, headband |
| TRIDENT | Wing Cannons | Fast trigger | 3 | 0.90 | 1.15 | 1.00 | 1.00 | Mei Lin (f), cheerful wing leader; twin buns |
| HORNET | Homing Rockets | Heavy hitter | 3 | 1.10 | 0.95 | 1.00 | 1.00 | Pip "Kaboom" Varga (f), manic demolition gremlin; pink pigtails, goggles |
| BULWARK | Flak Burst | Tank, slow to turn | 5 | 1.00 | 0.90 | 1.00 | 0.70 | Bram Okafor (m), stoic giant; beard, scar |
| HALO | Ricochet Disc | Scavenger | 3 | 1.00 | 1.00 | 1.35 | 1.00 | Lumi Asteria (f), serene; silver hair, star clip, halo |
| TIDE | Plasma Wave | Crowd control | 3 | 0.95 | 1.00 | 1.00 | 0.95 | Marina Reyes (f), surfer; teal waves, flower |
| HIVE | Hunter Drones | Commander | 3 | 1.00 | 1.00 | 1.20 | 0.90 | Theo Lindqvist (m), drone nerd; glasses, headset |
| LANCE | Pulse Laser | Glass cannon | 2 | 1.25 | 1.00 | 1.00 | 1.15 | Sable Kurosawa (f), cold sniper; black hair, blunt bangs |
| CORONA | Orbit Shards | Brawler | 4 | 0.95 | 1.00 | 1.00 | 1.10 | Rox Moreno (f), punk brawler; orange undercut |
| TEMPEST | Arc Lightning | Storm caller | 3 | 1.00 | 1.10 | 1.00 | 1.00 | Zeke Arashi (m), cocky; electric-blue spikes, bolt tattoo |
| NEEDLE | Railgun | Sniper | 2 | 1.30 | 0.95 | 1.00 | 1.20 | Iris Nakamura (f), calm; targeting visor, ponytail |
| PULSAR | Nova Burst | Close-range bruiser | 4 | 1.05 | 1.00 | 1.00 | 0.85 | Sol Vance (m), veteran ace; silver slicked hair |

**Pilots:**
- **The cast:** 7 women and 5 men, original characters drawn in a late-90s cel-anime style.
- **Expressions:** each pilot has 3: **normal**, **hurt** (hull below max) and **critical** (1 hull, or 34% or less).
- **Where they appear:** the HUD face (bottom right; it flinches when hit), the ship-select wheel (the
  pilot stands behind the ship), the title screen, the pause and results screens, and the ultimate
  cut-in (§7).
- **Lines:** each pilot has a **quote** and an **ultimate shout**. The full list is in `www/pilots.js`.
- **Art:** the portraits are code-drawn placeholders. Final art will be hand-made, as three PNGs per pilot
  (5:6 aspect, eyes about 45% down).

---

## 7. Ultimates

Offered at **level 10** as 3 of the 6. Fired with a **double-tap** (two quick taps within 380ms).
Firing **freezes the game for a 1.8s cut-in**: a strip of the pilot's eyes, the pilot swooping in, the
move's name slammed in, the pilot's shout and a stinger sound. Then the move fires.

| Ultimate | Effect | Recharge |
|---|---|---|
| Megaton | 400 damage to every enemy on screen, wipes all bullets | 75s |
| Overdrive | All weapon cooldowns ×0.33 for 8s | 60s |
| Time Warp | Enemies and their bullets at 25% speed for 7s | 60s |
| Missile Storm | 32 homing rockets (40 dmg, 30 radius) over about 2s | 50s |
| Phase Ram | Untouchable for 6s; contact deals 220 damage per second and eats bullets | 50s |
| Black Hole | A well 200 units ahead of the ship pulls enemies and bullets in for 6s (160 damage per second at its core) | 65s |

---

## 8. Hangar (between runs)

- **The bank:** credits are one shared bank, saved on the device.
- **Per-ship upgrades:** every ship has its **own** upgrade levels, all bought in the Hangar.
- **Prices:** `round(base × growth^level × 3)`, where the `upgradeCostMul` of 3 is already applied.
- **Two taps to buy:** the first tap shows TAP AGAIN.

| Upgrade | Effect per level | Max | Base | Growth |
|---|---|---|---|---|
| Hull Plating | +1 hull | 3 | 60 | 2.2 |
| Weapon Calibration | +6% power | 10 | 20 | 1.35 |
| Trigger Tuning | +5% fire rate | 10 | 20 | 1.35 |
| Magnet Coils | +12% pickup | 5 | 15 | 1.4 |
| Thrusters | +8% handling | 5 | 20 | 1.4 |
| Flight Recorder | +6% XP | 5 | 25 | 1.45 |
| Salvage Rights | +10% credits | 5 | 30 | 1.5 |
| Reroll Chip | +1 card reroll per run | 3 | 80 | 2 |
| Second Wind | Survive one fatal hit per run | 1 | 400 | 1 |
| Deflector Shield | A bubble that blocks one hit, then recharges in 40/32/25/19/14 s | 5 | 500 | 1.6 |

**Bounty:** small enemies pay 1 credit, Bloaters 3, mini-bosses 40/60/80 and final bosses 300 (500 for the
Seraph). You collect `bountyRate = 0.6` of that, times credit modifiers. Credits are **banked at each
stage clear** and on death or quit. A full five-stage run earns about 5,400 credits.

---

## 9. Run structure: the five-stage campaign

- **A full run** starts on stage 1 and carries **everything** to the next stage: weapons, passives and
  their levels, pilot level, and the ultimate. Between stages you're healed to full, the ultimate
  recharges, and slots grow by +1 of each kind.
- **Clearing a stage** unlocks the next on the stage select screen. **Skipping ahead** starts a fresh
  loadout with a **head start of 8 level-ups per skipped stage**.
- **Each stage lasts 8:00:**
  - Mini-bosses arrive at **2:00, 4:00 and 6:00**, each with a 3s WARNING.
  - At **8:00** the clock stops, the regular swarm stops, and the **final boss** arrives.
  - Killing the final boss kills the remaining swarm and clears the stage.
- **The enemy swarm** comes in timed waves: a gap of 1.6s shrinking to 0.5s over the first 320s
  (×2.5 while a boss is alive). Enemy health grows 35% per minute, and enemy bullet speed rises up
  to 1.7× by 8:00.

**Difficulty per stage** (k = stage − 1):
- Enemy health +50%·k, and health also grows 20%·k faster during the stage.
- Mini-boss and final-boss health +100%·k (boss health × `bossHpMul 0.5` overall).
- Bullets +7%·k faster, waves 10%·k closer together, enemies fire 15%·k more often.

| # | Stage | Look | Mini-bosses (2:00 / 4:00 / 6:00) | Final boss | Music |
|---|---|---|---|---|---|
| 1 | **Hive Fleet** | Indigo halftone sky, sparkles, speed lines | Brood Brute · Spore Mother · Scythe Wraith | **Hive Queen** | "Hive Surf": surf rock + 90s shooter metal + a dash of dubstep, 168 BPM |
| 2 | **Warp Zone** | Black warp tunnel, cyan/magenta streaks | Phase Brute · Flux Mother · Rift Wraith | **Warp Wyrm** | "Warp Rider": speed metal + reverb-drenched electro bass, 186 BPM |
| 3 | **The Deep** | Teal water, light rays, rising bubbles | Reef Crusher · Siren Sac · Deep Reaper | **Abyssal Maw** | "Abyssal Drift": slow psychedelic rock (organ, phaser, wah), 92 BPM |
| 4 | **Inside the Leviathan** | Flesh walls, veins, blood cells, heartbeat pulse | Bile Tick · Polyp Mother · Marrow Wraith | **Leviathan Heart** | "Heart of the Beast": doom metal crushed into glitch hop, 100 BPM |
| 5 | **Prismatic Void** | Rainbow halftone, prism shards | Prism Brute · Halo Mother · Mirror Wraith | **Seraph of the Void** | "Seraph": a slow, majestic intro (72 BPM), then a fast JRPG final battle (160 BPM) |

Each stage also recolours the regular swarm and changes the wave mix (for example, The Deep has more lamprey eels).

---

## 10. Enemies (the hive fleet: legless horror bugs)

| Enemy | HP | Behaviour |
|---|---|---|
| **Larva** | 20 | Pulsing maggot with a lamprey mouth. Drifts down; aimed single shot every 1.6–2.8s. |
| **Lamprey** | 14 | Segmented flesh-worm in chains of 5, swaying sideways; occasional shot straight down. |
| **Flayer** | 26 | One-eyed wasp with torn wings. Stops, flashes for 0.7s, then dives stinger-first at your position (360/s). |
| **Bloater** | 120 | Pus sac covered in eyes. Settles, strafes, and its mouth gapes before a ring of 10+ shots every 2.2s. Leaves after 14s. |

**Visuals:**
- Every creature has a thin white silhouette outline over the ink.
- Eyes **track the player** and blink, slime drips from mouths, and each kill sprays purple or acid-green
  ichor and leaves a fading stain.
- About half the comic words are wet ones: SPLAT!, GLORP!, SQUELCH!.

---

## 11. Bosses

Mini-bosses use the same three brains in every stage (re-skinned and renamed):

- **Brute** (a tick swollen with eggs): sways side to side and fires an aimed 7-shot fan (9 below
  half health) every 1.4s (1.0). Every 3rd volley adds side sprays; it calls in 3 Larvae every 5s.
- **Mother** (a pus-sac blimp): alternating 16-shot spore rings every 1.7s. Below half health, a
  spinning double stream. Spawns 4 Lampreys every 7s.
- **Wraith** (a bone skull with a ribcage and scythe-blade wings): sweeps twin streams from both
  scythes, then dashes over your position and fires three aimed 7-shot fans.

Final bosses (3 phases where listed; each phase change clears the screen with a shout):

- **Hive Queen** (stage 1): spiral arms (3, then 4), aimed claw volleys, rings from phase 2 on, and larva/flayer broods. Eyes go red in phase 3.
- **Warp Wyrm** (stage 2): a glowing serpent with a trailing body.
  - Drops **curtains of shots with one gap** to slip through (slanted in phase 2).
  - Its body segments spit aimed shots.
  - It **teleports** every 7s (5s), reappearing with an 18-shot ring.
- **Abyssal Maw** (stage 3): an anglerfish horror.
  - Fires volleys of **wobbling bubbles**.
  - Its **lure** flashes, then fires a fast beam of shots at where you were.
  - Its **jaw** snaps out a 20-shot ring of teeth, and it spawns lampreys in phase 2.
- **Leviathan Heart** (stage 4): **every heartbeat is a ring of shots**. It beats every 1.1, 0.85, then
  0.65 s. Every 3rd beat adds an aimed fan, phase 2 adds artery streams, and phase 3 adds double rings.
  It pumps out Larvae.
- **Seraph of the Void** (stage 5, the final boss): six wings, a weeping porcelain mask, a spiked halo.
  - **Phase 1:** aimed and wide feather fans, plus slow 24-shot rings.
  - **"KNEEL."** Phase 2: four rotating beams made of shots, plus rings and aimed bursts.
  - **"I AM ENDLESS!"** Phase 3: twin counter-rotating spirals, a rain of feathers and aimed bursts.

---

## 12. Presentation

- **Art:**
  - Pop-art comic style: ink outlines, flat colour with a hard shadow and halftone dots, a highlight
    and a starburst for every kill.
  - Each stage has its own sky and ambient motion.
  - Enemy bullets are pink with a cream core and an ink rim, kept the most readable thing on screen.
  - XP gems are bright mint with a glow and a white rim.
- **Menus (Persona-style motion):**
  - Slanted panels with hard shadows that slam in staggered, alternating sides with a little overshoot.
  - Red, black and gold diagonal wipes between screens.
  - The ship-select **wheel** has the ship in front and its pilot behind; locked ships are silhouettes.
- **HUD:**
  - XP bar, LV, clock, credits, and hull as hearts.
  - Stage progress with boss markers.
  - Signature weapon plus slot rows with tier colours and levels.
  - The pilot's face, and the ultimate countdown ("2x TAP!" when ready).
- **Audio:** all original, synthesized live (no sound files).
  - One track per stage.
  - Quiet, rate-limited sound effects for each weapon volley and kill.
  - A big level-up fanfare and a card-pick "ka-ching" that grows fancier with rarity.
  - Cut-in and boss-warning stingers.
  - Music sits slightly under the effects.
- **Fonts:** Bangers (display) and Comic Neue (body), both under the SIL Open Font License.

---

## 13. Tuning philosophy (lessons from playtests)

- **A fresh run must always be able to kill fodder.** Later stages get harder mainly through pressure
  (density, bullet speed, fire rate, faster health growth), and bosses carry most of the health scaling.
- **The snowball is the fantasy.** With carry-over, check that bosses still last about 30–90s and
  that a full campaign pays enough to feel rewarding without buying out the Hangar.
- **Never compete with the bullets.** Anything that could be confused with an enemy bullet or an XP gem
  (blood, effects, backgrounds) is kept low-contrast or a different colour.
- **Sound effects** play one sound per volley, with per-sound rate limits, so busy moments never turn to mush.

---

## 14. 3D adaptation (Void Survivors 3D, PC / Godot 4)

The **systems, numbers, content and tone stay the same.** What changes is the camera and space:

- **On rails:** the ship flies forward automatically along a path through each stage, in a 90s
  rail-shooter style. The player steers within a **screen-space box**, roughly a 2D plane in
  front of the camera. The **360-wide world** maps onto that plane, so tuning numbers carry
  over with a single scale factor.
- **Threats** come from ahead and from the sides. Enemy bullet patterns (rings, fans, spirals, curtains)
  are generated in the plane facing the player and travel toward the camera, so the bullet-hell
  reading survives. The hitbox stays a tiny dot at the ship's core; consider showing it as a reticle.
- **Weapons** fire forward into the depth.
  - *Laser* becomes a forward beam, *Wave* a wide forward arc, *Ricochet Disc* bounces off the
    play-box walls.
  - *Nova* is a sphere, *Orbit Shards* circle the ship, *Homing Rockets* curve into the depth.
  - Aim assist: target the nearest enemy within a forward cone.
- **XP gems** stream toward the player along the rail; magnet pull works in the plane.
- **Stages** become rail paths with set pieces:
  - Hive Fleet: through a swarm cloud.
  - Warp Zone: a tunnel.
  - The Deep: underwater canyons.
  - Leviathan: inside the creature, down the throat to the heart chamber.
  - Prismatic Void: a fractured prismatic space.
  - Bosses happen in arenas where the rail circles or holds position.
- **Controls:** mouse or gamepad steering, optional keyboard; ultimate on a button; pause; rebindable keys.
- **Look:** keep the pop-art comic identity with toon/cel shaders, ink outlines (inverted-hull or
  post-process), halftone shadows and 2D comic lettering for the starbursts. The pilots stay 2D portraits
  in the UI.
- **Audio:** the same five tracks and sound design; port the synth approach, or render the stems.
- **Platforms:** Windows and Linux (Fedora first), exported by GitHub Actions.
