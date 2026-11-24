# Void Survivors 3D

The PC version of **Void Survivors**, built in **Godot 4**: the same systems as the Android game,
turned into an on-rails 3D space shooter. The ship flies forward on its own, you steer
and it fires automatically, and every kill drops XP to level up and build your loadout across a
five-stage campaign.

- **`DESIGN.md`** is the full design: every system, with real numbers. It's shared with the Android
  game (repository `void-survivors-`). §14 covers the 3D adaptation.
- **`UPDATE-LOG.md`** lists every change the Android game got after this project started (new numbers, new
  systems) and how each fits the 3D game. Read it alongside `DESIGN.md`.
- **`scripts/tuning.gd`** is the tuning block: every gameplay number in one file (like `CFG` in the
  Android game).
- Platforms: Windows and Linux (Fedora first).

**Where we are:** milestone 1, a playable slice of stage 1. You get rail flight, VESPER and its
Autocannon, the Larva swarm, XP gems and level-up cards with 4 weapons and all 12 passives.

---

## Just play it (no Godot needed)

Every push builds the game automatically (GitHub Actions).

1. Open the repository on GitHub and click **Releases** (right-hand side).
2. Open **Latest build** and download:
   - Linux: `VoidSurvivors3D-linux.tar.gz`
   - Windows: `VoidSurvivors3D-windows.zip`
3. Linux: right-click the file in Dolphin and choose **Extract > Extract archive here**, then double-click
   `VoidSurvivors3D.x86_64`. If nothing happens, right-click it, choose **Properties > Permissions**, tick
   **Is executable**, and try again.

---

## Work on it in Godot (first time)

### 1. Install Godot 4.7 (once)

On Fedora KDE, the easy way is **Discover** (the shopping-bag icon):

1. Open **Discover**, search for **Godot**, and install **Godot Engine** (not the "Mono" or ".NET" version).
2. Check the version is **4.7 or newer**.

Or in a terminal:

```bash
flatpak install flathub org.godotengine.Godot
```

### 2. Get the project (once)

Open **Konsole** and paste:

```bash
cd ~
git clone https://github.com/divinegigas/void-survivors-3d.git
cd void-survivors-3d
git checkout claude/void-survivors-3d-godot-5pdwy3
```

To get new versions later:

```bash
cd ~/void-survivors-3d
git pull
```

### 3. Open it

1. Start Godot. The **Project Manager** window opens.
2. Click **Import** (top left), browse to your home folder > `void-survivors-3d`, select
   **`project.godot`** and click **Open**, then **Import** (or **Import & Edit**).
3. The editor opens. The first time, it spends a few seconds importing fonts (a progress bar).
4. Press **F5** (or the ▶ **Run Project** button at the top right) to play. **F8** stops it.

---

## How to play

| | Mouse | Keyboard | Gamepad |
|---|---|---|---|
| Steer | move the mouse | WASD or arrow keys | left stick or d-pad |
| Fire | automatic | automatic | automatic |
| Pick a card | click | 1 / 2 / 3, or arrows + Enter | stick + A |
| Pause | | Esc or P | Start |
| Fullscreen | | F11 (or Alt+Enter) | |

- Only the **white dot** in the middle of your ship can be hit. The ship itself is safe.
- Dodge the **pink shots**. A hit costs 1 heart, makes you blink (safe) for 1.2 s and erases nearby shots.
- Fly **over** the **mint gems** to collect them. Missed gems are lost.
- The **reticle** ahead of you turns **gold** when your guns are locked onto a bug.

---

## Tweak the balance

Everything is in **`scripts/tuning.gd`**. In Godot: in the **FileSystem** panel (bottom left), open
`scripts` and double-click **`tuning.gd`**. Change a number, press **Ctrl+S**, then **F5** to try it.
Each line has a comment saying what it does. Lines marked **[3D]** are new for the PC version; all
others are the Android values.

---

## Fonts and licences

Bangers and Comic Neue are under the SIL Open Font License (`fonts/OFL-*.txt`). Everything else
(models, effects, music later) is original and generated in code.
