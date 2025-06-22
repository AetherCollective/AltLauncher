# AltLauncher Documentation

## Introduction

**AltLauncher** is a utility designed to streamline the launching and profile management of games by handling registry modifications, directory adjustments, and file operations. This documentation will guide users through setting up and configuring AltLauncher for use with their preferred games.

YouTube Video: https://www.youtube.com/watch?v=l9H_WKFcTcQ

[![YouTube Video](https://img.youtube.com/vi/l9H_WKFcTcQ/maxresdefault.jpg)](https://www.youtube.com/watch?v=l9H_WKFcTcQ)

## Installation & Setup

### 1. Moving AltLauncher to the Game Directory
To ensure proper functionality:

-   Place `AltLauncher.exe` and `AltLauncher.ini` inside the game’s main directory. 
-   If you wish to use the auto-updater, you should also place `AltLauncher.Updater.exe` inside the game's main directory too.
-   The executable should reside in the same folder as the game's primary `.exe` file.

### 2. Configuring `AltLauncher.ini`
The **AltLauncher.ini** file dictates the behavior of the launcher. You will need to gather the necessary registry paths, directory locations, and file dependencies.

#### Obtaining Paths
To correctly populate `AltLauncher.ini`, consult **PCGamingWiki**:

1.  Search for your game on [PCGamingWiki](https://www.pcgamingwiki.com).
2.  Locate registry paths, save file locations, and configuration directories.
3.  Use the provided information to define your `AltLauncher.ini` settings.

Before you do all the hard work yourself, see if there's an AltLauncher.ini for your game in the [Templates](https://github.com/AetherCollective/AltLauncher/tree/main/Templates/) area.

#### Structure of `AltLauncher.ini`
Here are key fields that require user configuration:

**General Settings**

```ini
[General]
Name=GameName
Path=C:\path\to\game\folder
Executable=GameExecutable.exe
LaunchFlags=-some_flag
```

-   **`Name`**: Display name of the game.
-   **`Path`**: Optional path to game's folder.
-   **`Executable`**: The game’s `.exe` file name.
-   **`LaunchFlags`**: Optional command-line arguments for custom execution.

**Settings**

```ini
[Settings]
MinWait=5
MaxWait=10
```

-   **`MinWait` / `MaxWait`**: Defines how long AltLauncher waits before confirming the game has closed.

**Profile Management**

```ini
[Profiles]
Path=%USERPROFILE%\Documents\AltLauncher
SubPath=Saves
```
-   Overrides where the game's save files are stored on a per-game basis.
-   **`Path`**: Location where AltLauncher stores profile-related files.
-   **`SubPath`**: Subdirectory where game-specific profiles reside.

**Mapping your game**  

Each entry for **Registry**, **Directories**, and **Files** follows a **key=value** mapping. 

The key is the user-preference unique name of the .reg file, Directory, or File and will be mapped to 
```ini
%AltLauncher_Path%\<ProfileName>\%AltLauncher_SubPath%\%Name%
```
-   **%Name%**  refers to the Name field in `AltLauncher.ini`Directories

The value is the path of the registry, directory, or file your game needs to map. This could be a folder leading to where your game's savedata is, or a configuration file. You could even decide to map each individual file slot (if your game stores their slots in separate files). 

**Registry**

##### Examples: 
```ini
Registry=HKEY_CURRENT_USER\Software\Burst2flame Entertainment\Stolen Realm
```
```ini
HKLM=HKEY_LOCAL_MACHINE\SOFTWARE\Wizards of the Coast\MTGArena
HKCU=HKEY_CURRENT_USER\Software\Wizards Of The Coast\MTGA
```

###### HKEY_LOCAL_MACHINE paths requires you to run AltLauncher as an Administrator.

**Directories**

Directories can have an empty key field, which will use the root folder of `%AltLauncher_Path%\<ProfileName>\%AltLauncher_SubPath%\%Name%`. Useful if your game stores all its save files in a single directory.

##### Examples:
```ini
=C:\Program Files (x86)\Steam\userdata\1101577702\1798020
```
```ini
saves=C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames\4dd63af8-2773-4b68-a6bb-22498c58d514\4502
```

**Files**
##### Examples:
```ini
6898594.save=C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames\4dd63af8-2773-4b68-a6bb-22498c58d514\4502\6898594.save
119004278.save=C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames\4dd63af8-2773-4b68-a6bb-22498c58d514\4502\119004278.save
```

### 3. Set up your Environment Paths
  - It is recommended to set the `%AltLauncher_Path%` to point to where you want your save files to be stored. 
	  - By default, this is `C:\Alters`, but you could set it to any cloud-synced folder if you wish.
  - You may also want to set the `%AltLauncher_SubPath%` if you desire a certain sub-folder structure. 
	  - For example: a subpath value of `Files\GameSaves` with the default path would resolve to `C:\Alters\<ProfileName>\Files\GameSaves`. By default, this is blank.

### 4. Command-Line Usage
AltLauncher can be executed with command-line parameters:

```
AltLauncher.exe "ProfileName"

```

-   Replace `"ProfileName"` with the desired profile folder name.
-   When running from a script or batch file, ensure the profile name matches one present in the `Profiles` directory.
- If you do not define a profile, it will check the `%AltLauncher_Path%\Selected_Profile.txt` file and use it's value. If this file is missing or is invalid, you will receive an error.

### 5. Utility Program - AltSetter
AltSetter is a utility program to select a profile that can be used instead of the command line option. You should place it inside the directory you set for `%AltLauncher_Path%`. Using this program sets the `%AltLauncher_Path%\Selected_Profile.txt` file.

## Usage Workflow
1.  **Launch AltLauncher** via `AltLauncher.exe` or command-line.
2.  The script will process the configuration, registry settings, and profile data.
3.  If necessary, it will back up files before launching the game.
4.  The game launches, and AltLauncher monitors its process.
5.  Once the game closes, AltLauncher restores settings and exits gracefully.

## Auto-Updater
AltLauncher comes with an auto-updater program that can act as a drop-in replacement for AltLauncher. It will automatically update AltLauncher to the latest version before execution. If you wish to use as a drop-in replacement, just update your shortcut/launcher to launch `AltLauncher.Updater.exe` instead of `AltLauncher.exe`

## Tips
  - On Steam, you can modify the launch options to run the game through AltLauncher:
	  - `"C:\Path\To\AltLauncher.exe" -- %command%`
  - AltLauncher can detect when a save file has been erased by the player and can recycling or delete them from the profile folder. This behavior can be controlled with the environment variable: `AltLauncher_UseRecyclingBin` or the ini setting: `[Settings]UseRecyclingBin`
	  - When set to `True`, erased files will be sent to the recycling bin. This allows the user to recover the files if deleted by accident.
	  - When set to `False`, erased files will be permanently deleted. Be careful as this offers no way to recover your deleted saves.
	  -	When unset, erased files will be preserved. Your deleted save files will be restored the next time you run AltLauncher. This is the default setting.
  - AltLauncher supports **environment variable expansion**, allowing dynamic resolution of paths:
	-   `%USERPROFILE%` will automatically expand to `C:\Users\YourUsername`
	-   `%LOCALAPPDATA%` expands to `C:\Users\YourUsername\AppData\Local`
	-   `%APPDATA%` expands to `C:\Users\YourUsername\AppData\Roaming`
	-   `%PROGRAMFILES%` expands to `C:\Program Files`
	-   `%PROGRAMFILES(x86)%` expands to `C:\Program Files (x86)`
	-   `%PROGRAMDATA%` expands to `C:\ProgramData`
  - Set the environment paths `%SteamID3%`, `%SteamID64%`, and `%UbisoftID%` to your user-id. 
	  - You can obtain your user-id by checking the following directories: 
		  - `C:\Program Files (x86)\Steam\userdata`
		  - `C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames`
	  - You can look up your `%SteamID64%` by visiting [steamid.io](https://steamid.io/)
      ##### You can use these environment variables inside `AltLauncher.ini` for flexible path resolution.

## Troubleshooting
  - If **AltLauncher.ini** is missing, ensure it's located in the same directory as `AltLauncher.exe`.
  - If the game fails to launch, verify that the `Executable` entry matches the correct `.exe` file.
  - If profiles are not loading correctly, check the `ProfilesPath` for missing directories.
  - If save files are not being swapped out when changing profiles, check and make sure your directories are correctly mapped in `AltLauncher.ini`. See [Obtaining Paths](https://github.com/AetherCollective/AltLauncher?tab=readme-ov-file#obtaining-paths).
  - If all else fails, we have a [Discord](https://discord.gg/zVAa2vkU5M) server where you can receive support! 

## Known Issues
While traditional cloud syncing is supported and recommended, on-demand cloud syncing is not. Backups that normally generate at runtime do not get deleted properly when this feature is on. Please turn off this feature in your cloud syncing app, settings like `always available offline/locally` usually aren't enough:

  - OneDrive: Files On-Demand - [link](https://support.microsoft.com/en-us/office/save-disk-space-with-onedrive-files-on-demand-for-windows-0e6860d3-d9f3-4971-b321-7092438fb38e#ocpExpandoHeadTitleContainer:~:text=How%20to%20turn%20on%20Files%20on%20Demand)
  - Google Drive: Streaming Mode - [link](https://support.google.com/drive/answer/13401938?sjid=17121236587031128354-NA#zippy=%2Cwhen-you-switch-from-streaming-to-mirroring:~:text=To-,switch%20from%20streaming%20to%20mirroring,-%3A)
  - Dropbox: Online-Only Files - [link](https://help.dropbox.com/sync/make-files-online-only)
  - Nextcloud: Virtual File Support - [link](https://docs.nextcloud.com/desktop/latest/navigating.html#configuring-nextcloud-account-settings:~:text=The%20little%20button%20with%20three%20dots%20(the%20overflow%20menu)%20that%20sits%20to%20the%20right%20of%20the%20sync%20status%20bar%20offers%20additional%20options%3A)

## Screenshots
![AltLauncher](https://github.com/user-attachments/assets/5f72428a-ecc9-4ad5-ac4e-85fa006f897c)
![AltSetter](https://github.com/user-attachments/assets/30dedf93-d374-4a71-a013-7c0338f9d0bf)
![Steam](https://github.com/user-attachments/assets/1d99c311-326f-440c-86b3-9960744a730d)
[![Running](https://img.youtube.com/vi/dk0EhCbnRkw/0.jpg)](https://www.youtube.com/watch?v=dk0EhCbnRkw)
