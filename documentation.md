# AltLauncher - User Documentation

AltLauncher is a profile‑based save‑slot manager for PC games.It works by temporarily swapping your game’s save files, registry keys, and configuration directories with profile‑specific versions, then restoring them when the game closes.

This document explains every configuration option, environment variable, and INI field so users and modders can fully understand how AltLauncher behaves.

---

## 1. Environment Variables

AltLauncher stores persistent settings in:

> HKCU\Environment

These variables override INI settings when present.

---

### 1.1 Core AltLauncher Variables

| Variable | Description | Values |
| --- | --- | --- |
| AltLauncher_Path | Root folder where all profiles are stored. | Absolute path |
| AltLauncher_SubPath | Optional subfolder inside each profile. | String or empty |
| AltLauncher_SafeMode | Controls how deleted files are handled during restore. | "True", "False", or unset" |
| AltLauncher_UseProfileFile | Whether to auto‑load last profile instead of prompting. | "True" or "False" |
| AltLauncher_SwitchMode | Enables profile switching after game closes (Shift‑close behavior). | "True" or "False" |

---

### 1.2 UI Layout Variables

These control the profile selection window.

| Variable | Description | Defaults |
|---|---|---|
| AltLauncher_ButtonWidth | Width of each profile button. | 120 |
| AltLauncher_ButtonHeight | Height of each profile button. | 55 |
| AltLauncher_ButtonSpacing | Pixel spacing between buttons. | 4 |
| AltLauncher_NumberOfButtonsPerDirection | Max buttons per row/column. | 5 |
| AltLauncher_ButtonDirection | Layout direction: "down" or "right". | "down" |

---

### 1.3 Platform ID Variables

These are used by templates and game‑specific configs.

| Variable | Description |
|---|---|
| SteamID3 | Your Steam3 ID (folder name under userdata). |
| SteamID64 | Your Steam64 ID (used by some games). |
| UbisoftID | Ubisoft Connect save folder ID. |
| RockstarID | Rockstar Social Club ID. |

---

## 2. INI Configuration

Each game has an INI file named:

> AltLauncher.ini

This file defines what AltLauncher should back up, restore, and manipulate.

---

### 2.1 [General] Section

| Key | Description |
|---|---|
| Name | Display name of the game. |
| Path | Working directory for launching the game. |
| Executable | The game’s executable filename. |
| LaunchFlags | Optional command‑line flags passed to the game. |

---

### 2.2 [Settings] Section

  

| Key | Description |

|---|---|
| MinWait | Minimum time (seconds) the game must run before AltLauncher considers it “launched”. |
| MaxWait | Maximum time to wait for the game to relaunch itself (some games restart once). |
| SafeMode | Overrides environment variable AltLauncher_SafeMode. |

---

### 2.3 [Profiles] Section

| Key | Description |
|---|---|
| Path | Root folder for all profiles. |
| SubPath | Optional subfolder inside each profile. |

---

### 2.4 [Registry] Section

Each entry defines a registry key to swap.

Example:

> SaveSettings=HKCU\Software\MyGame\Settings

Meaning:
* During Backup, the key is exported, deleted, and replaced with the profile’s version.
* During Restore, the key is exported back into the profile, then the original is restored.

---

### 2.5 [Directories] Section

Each entry defines a directory to swap.

Example:

> SaveFolder=%USERPROFILE%\Documents\MyGame\Saves

Behavior:

* The directory is moved to *.AltLauncher-Backup
* The profile’s directory is copied into place
* On restore, the process reverses

SafeMode affects how extra files are handled (see section 4).

---

### 2.6 [Files] Section

Each entry defines a single file to swap.

Example:

> ConfigFile=%APPDATA%\MyGame\config.ini

Behavior mirrors directory handling but for individual files.

---

## 3. Profile System

Profiles live inside:

>  <AltLauncher_Path>\<ProfileName>\<SubPath>\<GameName>\

Each profile contains:

  * Registry backups (*.reg)
  * Directory backups
  * File backups

---

## 4. Safe Mode Behavior

SafeMode controls how AltLauncher handles extra files that exist in the profile but not in the game directory.

| Mode | Meaning |
|---|---|
| True | Extra files are moved to the Recycle Bin. |
| False | Extra files are permanently deleted. |
| Null (unset) | Entire directory is moved wholesale; no cleanup. |

This applies only during Restore.

---

## 5. Command‑Line Flags

AltLauncher supports several command‑line arguments:

| Flag | Behavior |
|---|---|
| -- | No special behavior. |
| --read | Reads the selected profile from Selected Profile.txt. |
| --select | Forces profile selection window to appear. |
| --setup | Runs the setup wizard. |
| \<anything else> | Treated as a direct profile name. |

---

## 6. State File

AltLauncher writes a temporary state file:
 
> AltLauncher.state

This stores the active profile so that if AltLauncher crashes or the PC shuts down, it can restore the correct files on next launch.

---

## 7. Game Launch Lifecycle

AltLauncher follows this exact sequence:

1. Backup
  * Registry keys
  * Directories
  * Files
2. Load Profile's
  * Registry keys
  * Directories
  * Files
3. Run Launcher Script (optional)
	If AltLauncher-launcher.cmd exists.
	
4. Run Game
5. Wait for Game to Close
6. RedirectHook
	Allows switching profiles after game closes (Shift key or SwitchMode).
	
7. Save to Profile's
  * Registry keys
  * Directories
  * Files
  
8. Restore
	Restores original files and registry keys.
	
9. Cleanup
	Deletes .state file.

---

## 8. Early Exit Behavior

Pressing and hold Escape for 5 seconds triggers an emergency restore:

  * Restores original files
  * Restores registry keys
  * Closes AltLauncher safely

Useful when the game freezes or AltLauncher fails to recognize that the game has closed.

---

## 9. Setup Wizard Behavior

On first run, AltLauncher asks for:

1. Profile storage location
2. Optional subpath
3. SafeMode preference
4. Whether to auto‑select last profile
5. Steam3 ID (auto‑detected if possible)
6. Steam64 ID
7. Ubisoft ID

These values are stored in environment variables.

---

## 10. Folder Structure Overview

Game Folder:
  * AltLauncher.exe
  * AltLauncher.ini
  * AltLauncher.Updater.exe (optional)
  * AltLauncher.state (temporary)

Profile Folder:
  * Profiles\
    * \<ProfileName>\
      * \<SubPath>\
        * \<GameName>\
          * \<RegistryName>.reg
          * \<DirectoryName>\...
          * \<FileName>

---

## 11. Troubleshooting

 **AltLauncher says multiple INI files found**

Remove duplicates; only one INI file is allowed.

**Game doesn’t launch**

Check:
* Executable path
* Path working directory
* Missing quotes around paths with spaces

**Profile switching doesn’t work**

Check:
* AltLauncher_SwitchMode=True
* Or hold Shift when the game closes

**Files aren’t restoring**

Check SafeMode settings - extra files may be recycled or deleted.
