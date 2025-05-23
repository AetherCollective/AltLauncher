
# AltLauncher Documentation

## Introduction

**AltLauncher** is a utility designed to streamline the launching and profile management of games by handling registry modifications, directory adjustments, and file operations. This documentation will guide users through setting up and configuring AltLauncher for use with their preferred games.

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
Executable=GameExecutable.exe
LaunchFlags=-some_flag
```

-   **`Name`**: Display name of the game.
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
  - AltLauncher supports **environment variable expansion**, allowing dynamic resolution of paths:
	-   `%USERPROFILE%` will automatically expand to `C:\Users\YourUsername\`
	-   `%APPDATA%` expands to `C:\Users\YourUsername\AppData\Roaming\`
  - Set the environment paths `%SteamID%` and `%UbisoftID%` to your user-id. 
	  - You can obtain your user-id by checking the following directories: 
	  - `C:\Program Files (x86)\Steam\userdata`
	  - `C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames`
      ##### You can use these environment variables inside `AltLauncher.ini` for flexible path resolution.

## Troubleshooting

-   If **AltLauncher.ini** is missing, ensure it's located in the same directory as `AltLauncher.exe`.
-   If the game fails to launch, verify that the `Executable` entry matches the correct `.exe` file.
-   If profiles are not loading correctly, check the `ProfilesPath` for missing directories.
-   If all else fails, we have a [Discord](https://discord.gg/zVAa2vkU5M) server where you can receive support! 