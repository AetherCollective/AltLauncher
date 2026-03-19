# AltLauncher

A save file manager for games that don't natively support multiple save profiles. AltLauncher lets multiple people share one PC and one game installation while keeping their save files, settings, and progress completely separate.

---

## What is it for?

Most games only support a single set of save files per installation. If multiple people play the same game on the same computer, they either overwrite each other's saves or have to manually back things up. AltLauncher solves this by swapping save files in and out automatically - before the game launches, it loads the selected person's saves; after the game closes, it saves them back.

The result is that each person gets their own independent game experience: separate progression, separate settings, separate everything. From the game's perspective, nothing unusual is happening.

---

## Who is it for?

### DID / Plural Systems

AltLauncher was built primarily for use by [DID (Dissociative Identity Disorder)](https://en.wikipedia.org/wiki/Dissociative_identity_disorder) systems and other plural systems, where multiple alters share a single body - and often a single computer.

Different alters frequently have different tastes in games, different playstyles, and different progress they want to preserve. Having one alter's save overwrite another's is frustrating and, in some systems, a real source of conflict.

With AltLauncher, each alter gets their own named profile. Whoever is fronting selects their profile when launching the game, and their saves are loaded automatically. When they're done, everything is saved back to their profile and the system is restored cleanly.

### Families and Shared PCs

AltLauncher works equally well for families where multiple people share a gaming PC. Parents and kids can each have their own save profiles for the same game without any risk of overwriting each other's progress. Each family member gets their own named profile, and selecting it at launch is all that's needed.

---

## How it works

AltLauncher is configured per-game via a `.ini` file that tells it where the game's save files live, what executable to launch, and any other game-specific settings. When you launch AltLauncher instead of the game directly:

1. A profile picker appears showing all available profiles
2. You select your profile (or create a new one)
3. AltLauncher swaps in your save files, directories, and registry keys
4. The game launches
5. When the game closes, your saves are written back to your profile and the previous state is restored

If the game crashes or AltLauncher is closed unexpectedly, a state file ensures saves are restored correctly on the next launch.

---

## Features

- **Per-profile save isolation** - files, folders, and registry keys all swapped per profile
- **Profile switcher** - hold Shift when the game closes, or enable `SwitchMode`, to switch which profile the session is saved to without relaunching
- **Safe Mode** - choose whether deleted saves go to the Recycle Bin, are permanently deleted, or are preserved
- **Auto-detection** - can detect your game via Steam App ID and download a pre-made config template automatically
- **Crash recovery** - state file prevents save loss if the process is interrupted mid-session
- **Early exit** - hold Escape for 5 seconds during play to trigger an emergency restore if the game freezes or fails to close normally
- **Customizable UI** - button layout, size, and direction are all configurable via environment variables

---

## Quick Start

### 1. Download and place AltLauncher

Download the [latest release](https://github.com/AetherCollective/AltLauncher/releases/latest) and place `AltLauncher.exe` next to your game's executable.

### 2. Set up Steam (or your launcher) to use AltLauncher

**For Steam games:**

1. Right-click the game → Properties
2. In Launch Options, enter the full path to `AltLauncher.exe` followed by `-- %command%`

```
"C:\Program Files (x86)\Steam\steamapps\common\Hollow Knight\AltLauncher.exe" -- %command%
```

**For non-Steam shortcuts:**

Put the full path to `AltLauncher.exe` in the Target box. Do **not** add `-- %command%` for non-Steam games.

### 3. Run once for setup

On first run, AltLauncher will guide you through setting your profiles folder location, Safe Mode preference, and platform IDs.

### 4. Launch and pick your profile

AltLauncher will show a profile picker each time you launch. Select your profile - or hit `+` to create a new one - and the game will start with your saves loaded automatically.

---

## Setup Wizard

On first run, AltLauncher will ask for:

1. Where to store profiles (defaults to `C:\AltLauncher`)
2. An optional sub-path inside each profile folder
3. Safe Mode preference - Recycle Bin, permanent delete, or preserve
4. Whether to prompt for a profile each launch or auto-load the last used one
5. Steam3 ID (auto-detected if only one Steam account exists on the machine)
6. Steam64 ID (auto-detected if possible)
7. Ubisoft ID

These are saved as Windows environment variables under `HKCU\Environment` and apply globally across all games.

---

## Game Launch Lifecycle

AltLauncher follows this exact sequence every time a game is launched:

1. **Backup** - registry keys, directories, and files are backed up from the game location
2. **Load profile** - the selected profile's saves are swapped into place
3. **Run launcher script** - if `AltLauncher-launcher.cmd` exists alongside the exe, it runs first
4. **Run game** - the game executable is launched
5. **Wait for game to close**
6. **Redirect hook** - if Shift is held or `SwitchMode` is enabled, the profile picker appears so saves can be redirected to a different profile
7. **Save to profile** - the session's saves are written back to the active profile
8. **Restore** - original files and registry keys are restored
9. **Cleanup** - the state file is deleted

---

## Beacon - USB Flash Drive Support

Beacon is a companion utility that lets you store your save profiles on a USB flash drive. Run `Beacon.exe` from the drive to activate it - AltLauncher will automatically use the drive's `AltLauncher` folder for that session without touching any of your permanent settings. Run it again to deactivate.

**How to use it:**

1. Place `Beacon.exe` in the root of your flash drive
2. Create a `AltLauncher` folder next to it (Beacon will create it automatically if it doesn't exist)
3. Optionally create a `AltLauncher\Environment.reg` file to carry your platform IDs and AltLauncher settings with the drive (see [Environment Variables](#environment-variables))
4. Run `Beacon.exe` before launching any game - a tray icon will appear confirming it's active
5. Launch your game through AltLauncher as normal
6. Run `Beacon.exe` again to stop it when you're done

**If the drive is disconnected mid-session**, AltLauncher will pause and wait for you to reconnect it before saving. If you can't reconnect the drive, hold **Escape for 5 seconds** to export your live save files as a zip to your desktop, then AltLauncher will exit cleanly.

**Environment.reg** - if your flash drive contains `AltLauncher\Environment.reg`, Beacon will import it on startup, applying your platform IDs and preferences automatically. Your existing settings are backed up and restored when Beacon stops, so nothing is permanently changed.

---

## Environment Variables

AltLauncher stores its global settings in `HKCU\Environment`. These act as defaults for all games and can be overridden per-game in the ini file.

### Core Settings

| Variable | Description | Values |
|---|---|---|
| `AltLauncher_Path` | Root folder where all profiles are stored | Absolute path |
| `AltLauncher_SubPath` | Optional subfolder inside each profile | String or empty |
| `AltLauncher_SafeMode` | How deleted files are handled during restore | `"True"`, `"False"`, or unset |
| `AltLauncher_UseProfileFile` | Auto-load last profile instead of prompting | `"True"` or `"False"` |
| `AltLauncher_SwitchMode` | Always prompt for profile switch after game closes | `"True"` or `"False"` |

### UI Layout

| Variable | Description | Default |
|---|---|---|
| `AltLauncher_ButtonWidth` | Width of each profile button | `120` |
| `AltLauncher_ButtonHeight` | Height of each profile button | `55` |
| `AltLauncher_ButtonSpacing` | Pixel spacing between buttons | `4` |
| `AltLauncher_NumberOfButtonsPerDirection` | Max buttons per row or column | `5` |
| `AltLauncher_ButtonDirection` | Layout direction | `"down"` or `"right"` |

### Platform IDs

| Variable | Description |
|---|---|
| `SteamID3` | Steam3 ID (folder name under `userdata`) |
| `SteamID64` | Steam64 ID (used by some games) |
| `UbisoftID` | Ubisoft Connect save folder ID |
| `RockstarID` | Rockstar Social Club ID |

---

## Profile Folder Structure

```
C:\AltLauncher\                     <- AltLauncher_Path
  └── Emily\                        <- Profile name
        └── <SubPath>\              <- AltLauncher_SubPath (if set)
              └── Hollow Knight\    <- Game name from ini
                    ├── Saves\      <- Directory backup
                    └── config.reg  <- Registry backup
```

---

## Switching Profiles Mid-Session

If one person started a gaming session and another finished it, you can redirect where the saves go when the game closes:

- **Hold Shift** while the game closes, or
- Set `AltLauncher_SwitchMode=True` to always be prompted

AltLauncher will show the profile picker again and save the session to whichever profile you choose.

---

## Command-Line Flags

| Flag | Behavior |
|---|---|
| `--` | No special behavior (used to pass Steam's `%command%`) |
| `--select` | Forces the profile selection window to appear |
| `--setup` | Runs the setup wizard |
| `<profile name>` | Any other value is treated as a direct profile name, skipping the picker |

---

## Safe Mode

Safe Mode controls what happens to files that exist in a profile but are no longer present in the game directory when restoring:

| Setting | Behavior |
|---|---|
| `True` | Extra files are sent to the Recycle Bin |
| `False` | Extra files are permanently deleted |
| Unset | The entire directory is moved wholesale - nothing is deleted |

---

## Early Exit

If the game freezes or AltLauncher fails to detect that the game has closed, hold **Escape for 5 seconds**. This triggers an emergency restore - files and registry keys are restored cleanly and AltLauncher exits safely.

---

## Troubleshooting

**Multiple INI files found** - Remove duplicates. Only one `AltLauncher.ini` is allowed per game directory.

**Game doesn't launch** - Check that `Executable` and `Path` in the ini are correct, and that paths with spaces are quoted.

**Profile switching doesn't work** - Make sure `AltLauncher_SwitchMode=True` is set, or hold Shift when the game closes.

**Files aren't restoring correctly** - Check your Safe Mode setting. Extra files may be getting recycled or deleted unexpectedly.

**Game saves to a different location than expected** - Some games redirect saves at runtime. Check the ini's `[Directories]` and `[Files]` sections point to where saves actually land, not just where the game's documentation says they go.

---

## Requirements

- Windows
- [AutoIt v3.3.16.0+](https://www.autoitscript.com/site/autoit/) (to run from source) or the compiled .exe

---


## Config Templates

Game-specific config files are maintained separately at [AetherCollective/AltLauncher-Templates](https://github.com/AetherCollective/AltLauncher-Templates). If your game is in the database, AltLauncher can download the config automatically on first launch. See [AetherCollective/AltLauncher-Templates/README.md](https://github.com/AetherCollective/AltLauncher-Templates?tab=readme-ov-file#altLauncher-config-reference) for how to write your own.

---

## License

See [LICENSE](LICENSE) for details.
