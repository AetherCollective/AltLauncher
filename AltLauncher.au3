#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.3.0.1
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <InetConstants.au3>
#include <Math.au3>
#include <Misc.au3>
#include <WindowsConstants.au3>
Opt("GUIOnEventMode", True)
Opt("TrayIconHide", True)
Opt("ExpandEnvStrings", True)

Global $AppName = "AltLauncher"
Global $Title = $AppName
Global $Registry, $Directories, $Files
Global $GUI[]
Global $Config[]
Global $Profile[]
$Profile["Name"] = ""

; Derived script paths (computed once)
Global Const $ScriptBaseName = StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1)
Global Const $StateFile = @ScriptDir & "\" & $ScriptBaseName & ".state"
Global Const $LauncherCmd = @ScriptDir & "\" & $ScriptBaseName & "-launcher.cmd"
Global Const $BEACON_ENV = "AltLauncher_BeaconPath"
Global $BeaconActive = False
Global $bEarlyExit = False

ReadEnvironmentVariables()
If RegRead("HKCU\Environment", "AltLauncher_Path") = "" And EnvGet($BEACON_ENV) = "" Then Setup()
ReadConfig()
CheckBeacon()
CheckIfAlreadyRunning()
If CheckStateFile() = True Then RepairState()
ProfileSelect()
Do
	Sleep(100)
Until $Profile["Name"] <> ""
CreateProfileFolderIfEmpty()
WriteStateFile()
ShowProgressBar()
Backup()
EnableChecks()
RunLauncher()
RunGame()
WaitWhileGameRunning()
WhenGameCloses()
Restore()
Sleep(2000)
Exit

Func CheckBeacon()
	; If beacon is running, AltLauncher_BeaconPath overrides ProfilesPath for this session only.
	; Nothing is written to the environment, ini, or disk.
	Local $sPath = EnvGet($BEACON_ENV)
	If $sPath = "" Then Return
	$Config["ProfilesPath"] = $sPath
	$BeaconActive = True
EndFunc   ;==>CheckBeacon

Func BeaconAlive()
	Local $sPath = RegRead("HKCU\Environment", $BEACON_ENV)
	If @error Or $sPath = "" Then Return False
	Return FileExists($sPath)
EndFunc   ;==>BeaconAlive

Func WaitForDriveReconnect()
	; Called when beacon was active at startup but drive is now gone.
	; Waits until beacon re-registers or user triggers emergency export.
	$Title = $AppName & " - Drive Disconnected"
	ProgressOn($Title, "Drive disconnected.", "Reconnect your drive and re-run Beacon, or hold Escape for 5 seconds to export saves to desktop.", -1, -1, $DLG_MOVEABLE)
	ProgressSet(0, "Waiting for drive...")
	Local $iEscapeCount = 0
	While Not BeaconAlive()
		Sleep(250)
		If _IsPressed("1B") Then
			$iEscapeCount += 1
		Else
			$iEscapeCount = 0
		EndIf
		If $iEscapeCount >= 20 Then ; 5 seconds at 250ms intervals
			ProgressSet(100, "Emergency export triggered...")
			_EmergencyZipToDesktop()
			Return
		EndIf
	WEnd
	; Beacon came back re-read path from registry in case drive letter changed
	Local $sPath = RegRead("HKCU\Environment", $BEACON_ENV)
	If Not @error And $sPath <> "" Then
		$Config["ProfilesPath"] = $sPath
		EnvSet($BEACON_ENV, $sPath)
		UpdateProfileBasePath()
	EndIf
	ProgressSet(100, "Drive reconnected.")
	Sleep(1000)
EndFunc   ;==>WaitForDriveReconnect

Func _EmergencyZipToDesktop()
	; Zip all live game save files to the desktop preserving folder structure.
	; Used when the profile drive is inaccessible and saves need to be preserved.
	Local $sZipPath = @DesktopDir & "\" & $Config["Game"] & "_emergency_" & @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC & ".zip"
	Local $sStagingDir = @TempDir & "\AltLauncher_Emergency"
	DirRemove($sStagingDir, 1)
	DirCreate($sStagingDir)
	For $i = 1 To $Directories[0][0]
		If FileExists($Directories[$i][1]) Then DirCopy($Directories[$i][1], $sStagingDir & "\" & $Directories[$i][0], 1)
	Next
	For $i = 1 To $Files[0][0]
		If FileExists($Files[$i][1]) Then FileCopy($Files[$i][1], $sStagingDir & "\" & $Files[$i][0], $FC_OVERWRITE + $FC_CREATEPATH)
	Next
	Local $sCmd = 'Compress-Archive -Path "' & $sStagingDir & '\*" -DestinationPath "' & $sZipPath & '" -Force'
	RunWait(@ComSpec & ' /c powershell -NoProfile -Command "' & $sCmd & '"', "", @SW_HIDE)
	DirRemove($sStagingDir, 1)
	If FileExists($sZipPath) Then
		MsgBox($MB_OK + $MB_ICONINFORMATION, $AppName, "Saves exported to:" & @CRLF & $sZipPath)
	Else
		MsgBox($MB_OK + $MB_ICONWARNING, $AppName, "Emergency export failed. Saves may still be in the game directory.")
	EndIf
EndFunc   ;==>_EmergencyZipToDesktop

Func ReadINISection(ByRef $Ini, $Section)
	Local $Data = IniReadSection($Ini, $Section)
	If @error Then
		Local $Data[1][2]
		$Data[0][0] = 0
	EndIf
	Return $Data
EndFunc   ;==>ReadINISection

Func ReadEnvironmentVariables()
	Local $i = 1
	While True
		Local $sName = RegEnumVal("HKCU\Environment", $i)
		If @error Then ExitLoop
		If StringLeft($sName, 12) = "AltLauncher_" Then
			EnvSet($sName, RegRead("HKCU\Environment", $sName))
		EndIf
		$i += 1
	WEnd
	EnvSet("SteamID3", RegRead("HKCU\Environment", "SteamID3"))
	EnvSet("SteamID64", RegRead("HKCU\Environment", "SteamID64"))
	EnvSet("UbisoftID", RegRead("HKCU\Environment", "UbisoftID"))
	EnvSet("RockstarID", RegRead("HKCU\Environment", "RockstarID"))
	EnvSet($BEACON_ENV, RegRead("HKCU\Environment", $BEACON_ENV))
EndFunc   ;==>ReadEnvironmentVariables

Func ReadConfig()
	$Config["Ini"] = @ScriptDir & "\" & $ScriptBaseName & ".ini"
	If Not FileExists($Config["Ini"]) Then
		$SearchResults = _FileListToArrayRec(@ScriptDir, $ScriptBaseName & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
		If Not IsArray($SearchResults) Then
			Switch MsgBox(4, $Title, "AltLauncher.ini not found. Would you like to download a template from the internet?")
				Case $IDYES
					$gameName = DetectGame()
					If $gameName = -1 Or $gameName = 0 Or $gameName = 1 Or $gameName = 2 Then ExitMSG("Your game is not in our database. Exiting...")
					If IsString($gameName) Then
						$downloaded = DownloadGameConfig($gameName)
						If Int($downloaded) <> 1 Then ExitMSG($ScriptBaseName & ".ini could not be downloaded at this time. Please try again later.")
					EndIf
					$SearchResults = _FileListToArrayRec(@ScriptDir, $ScriptBaseName & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
				Case $IDNO
					ExitMSG($ScriptBaseName & ".ini not found.")
			EndSwitch
		EndIf
		If $SearchResults[0] <> 1 Then ExitMSG("Multiple " & $ScriptBaseName & ".ini found. Please remove all but one and try again.")
		$Config["Ini"] = @ScriptDir & "\" & $SearchResults[1]
	EndIf
	$Config["Game"] = IniRead($Config["Ini"], "General", "Name", Null)
	$Config["Path"] = IniRead($Config["Ini"], "General", "Path", Null)
	$Config["Executable"] = IniRead($Config["Ini"], "General", "Executable", Null)
	$Config["LaunchFlags"] = IniRead($Config["Ini"], "General", "LaunchFlags", Null)
	$Config["MinWait"] = IniRead($Config["Ini"], "Settings", "MinWait", 0)
	$Config["MaxWait"] = IniRead($Config["Ini"], "Settings", "MaxWait", 0)
	$Config["SaveDelay"] = IniRead($Config["Ini"], "Settings", "SaveDelay", 0)
	$Config["SafeMode"] = IniRead($Config["Ini"], "Settings", "SafeMode", (EnvGet("AltLauncher_SafeMode") <> "") ? EnvGet("AltLauncher_SafeMode") : Null)
	$Config["SwitchMode"] = IniRead($Config["Ini"], "Settings", "SwitchMode", (EnvGet("AltLauncher_SwitchMode") <> "") ? EnvGet("AltLauncher_SwitchMode") : "False")
	$Config["ProfilesPath"] = IniRead($Config["Ini"], "Profiles", "Path", (EnvGet("AltLauncher_Path") <> "") ? EnvGet("AltLauncher_Path") : "C:\AltLauncher")
	$Config["SubPath"] = IniRead($Config["Ini"], "Profiles", "SubPath", EnvGet("AltLauncher_SubPath"))
	If EnvGet("AltLauncher_UseProfileFile") = "True" Then $Profile["Name"] = FileRead($Config["ProfilesPath"] & "\Selected Profile.txt")
	If @Compiled And $CmdLine[0] >= 1 Then
		Switch $CmdLine[1]
			Case "--"

			Case "--read"
				$Profile["Name"] = ReadSelectedProfileFile($Config["ProfilesPath"] & "\Selected Profile.txt")
			Case "--select"
				$Profile["Name"] = ""
			Case "--setup"
				Setup()
			Case Else
				; Any other value is treated as a direct profile name
				$Profile["Name"] = $CmdLine[1]
		EndSwitch
	EndIf
	$Registry = ReadINISection($Config["Ini"], "Registry")
	$Directories = ReadINISection($Config["Ini"], "Directories")
	$Files = ReadINISection($Config["Ini"], "Files")
EndFunc   ;==>ReadConfig

Func ReadSelectedProfileFile($sPath)
	$fileWasHidden = False
	$hFile = FileOpen($sPath)
	If $hFile = -1 Then
		$attrib = FileGetAttrib($sPath)
		FileSetAttrib($sPath, "-H")
		$fileWasHidden = True
		$hFile = FileOpen($sPath)
	EndIf
	$sProfile = FileRead($hFile)
	FileClose($hFile)
	If $fileWasHidden Then FileSetAttrib($sPath, "+" & $attrib)
	Return $sProfile
EndFunc   ;==>ReadSelectedProfileFile

Func DetectGame()
	; Return values: -1=not found, 0=download failed, 1=no steam id, 2=db corrupt, string=game name
	$success = False
	$url = "https://raw.githubusercontent.com/AetherCollective/AltLauncher-Templates/refs/heads/main/gamelist.ini"
	$savePath = @TempDir & "\AltLauncher\gamelist.ini"
	DirCreate(@TempDir & "\AltLauncher")
	For $i = 1 To 3 ; Retry up to 3 times
		$download = InetGet($url, $savePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		Do
			Sleep(100)
		Until InetGetInfo($download, $INET_DOWNLOADCOMPLETE)
		If FileExists($savePath) And FileGetSize($savePath) > 0 Then
			$success = True
			ExitLoop
		EndIf
		Sleep(1000)
	Next
	If Not $success Then Return 0    ; download failed
	$steamID = EnvGet("steamappid")
	If $steamID = "" Then Return 1   ; no steam id detected
	$games = IniReadSection($savePath, "Steam")
	If @error Then Return 2          ; db corrupt
	$gameName = ""
	For $i = 1 To $games[0][0]
		If $games[$i][1] = $steamID Then
			$gameName = $games[$i][0]
			ExitLoop
		EndIf
	Next
	If $gameName = "" Then Return -1 ; game not found
	$gameName = StringRegExpReplace($gameName, '^"(.*)"$', '\1')
	Return $gameName
EndFunc   ;==>DetectGame

Func DownloadGameConfig($gameName)
	; Return values: 1=success, 0=download failed, -1=game not found
	$success = False
	If $gameName = "" Then Return -1
	$url = "https://raw.githubusercontent.com/AetherCollective/AltLauncher-Templates/refs/heads/main/" & $gameName & "/AltLauncher.ini"
	$savePath = @ScriptDir & "\" & $ScriptBaseName & ".ini"
	For $i = 1 To 3 ; Retry up to 3 times
		$download = InetGet($url, $savePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		Do
			Sleep(100)
		Until InetGetInfo($download, $INET_DOWNLOADCOMPLETE)
		If FileExists($savePath) And FileGetSize($savePath) > 0 Then
			$success = True
			ExitLoop
		EndIf
		Sleep(1000)
	Next
	If $success Then Return 1 ; download successful
	Return 0                  ; download failed
EndFunc   ;==>DownloadGameConfig

Func UpdateProfileBasePath()
	$Profile["BasePath"] = $Config["ProfilesPath"] & '\' & $Profile["Name"] & '\' & $Config["SubPath"] & '\' & $Config["Game"] & '\'
EndFunc   ;==>UpdateProfileBasePath

Func ProfileSelect()
	If $Profile["Name"] <> "" Then Return
	$aFolders = _FileListToArray($Config["ProfilesPath"], "*", $FLTA_FOLDERS)
	Const $iSpacing = (EnvGet("AltLauncher_ButtonSpacing") <> "" ? Int(EnvGet("AltLauncher_ButtonSpacing")) : 4)
	$iMaxPer = (EnvGet("AltLauncher_NumberOfButtonsPerDirection") <> "" ? Int(EnvGet("AltLauncher_NumberOfButtonsPerDirection")) : 5)
	$iButtonWidth = (EnvGet("AltLauncher_ButtonWidth") <> "" ? Int(EnvGet("AltLauncher_ButtonWidth")) : 120)
	$iButtonHeight = (EnvGet("AltLauncher_ButtonHeight") <> "" ? Int(EnvGet("AltLauncher_ButtonHeight")) : 55)
	$sLayout = (EnvGet("AltLauncher_ButtonDirection") <> "" ? EnvGet("AltLauncher_ButtonDirection") : "down")
	$GUI["NumOfProfiles"] = 0
	If IsArray($aFolders) And UBound($aFolders) > 0 Then $GUI["NumOfProfiles"] = $aFolders[0]
	Local $iCols, $iRows
	If $sLayout = "right" Then
		$iRows = Ceiling(($GUI["NumOfProfiles"] + 1) / $iMaxPer)
		$iCols = _Min(($GUI["NumOfProfiles"] + 1), $iMaxPer)
	Else ; down
		$iCols = Ceiling(($GUI["NumOfProfiles"] + 1) / $iMaxPer)
		$iRows = _Min(($GUI["NumOfProfiles"] + 1), $iMaxPer)
	EndIf
	$iWinW = ($iSpacing + $iButtonWidth + 1) * $iCols + $iSpacing + 2
	$iWinH = ($iSpacing + $iButtonHeight) * $iRows + $iSpacing + 30
	$GUI["Handle"] = GUICreate($Title & " - Game: " & $Config["Game"], $iWinW, $iWinH, -1, -1, $WS_SYSMENU)
	GUISetOnEvent($GUI_EVENT_CLOSE, "SilentExit", $GUI["Handle"])
	Local $iX = $iSpacing, $iY = $iSpacing
	For $i = 1 To $GUI["NumOfProfiles"] + 1
		$sLabel = ($i <= $GUI["NumOfProfiles"]) ? $aFolders[$i] : "+"
		$iStyle = ($sLabel = $Profile["Name"]) ? BitOR($WS_BORDER, $WS_TABSTOP) : $WS_TABSTOP
		$hButton = GUICtrlCreateButton($sLabel, $iX, $iY, $iButtonWidth, $iButtonHeight, $iStyle)
		If GUICtrlSetOnEvent($hButton, "ProfileSelected") = 0 Then
			Exit MsgBox(0, "Error", "Can't register click event for: " & $sLabel & @CRLF & "[CtrlID]: " & $hButton)
		EndIf
		If $sLayout = "down" Then
			$iY += $iButtonHeight + $iSpacing
			If Mod($i, $iMaxPer) = 0 Then
				$iY = $iSpacing
				$iX += $iButtonWidth + $iSpacing
			EndIf
		Else
			$iX += $iButtonWidth + $iSpacing
			If Mod($i, $iMaxPer) = 0 Then
				$iX = $iSpacing
				$iY += $iButtonHeight + $iSpacing
			EndIf
		EndIf
	Next
	If $GUI["NumOfProfiles"] = 0 Then
		ProfileSelected()
		Return
	EndIf
	GUISetState(@SW_SHOW)
EndFunc   ;==>ProfileSelect

Func ProfileSelected()
	GUISetState(@SW_HIDE)
	$Profile["Name"] = ($GUI["NumOfProfiles"] = 0) ? "+" : GUICtrlRead(@GUI_CtrlId)
	If $Profile["Name"] = "+" Then
		Do
			$ChosenName = InputBox($Title, "Please enter a new profile name.")
			If @error Then
				$Profile["Name"] = ""
				GUISetState(@SW_SHOW)
			Else
				Select
					Case $ChosenName = ""
						MsgBox(48, $Title, 'Profile name cannot be blank. Please choose another name.')
					Case FileExists($Config["ProfilesPath"] & '\' & $ChosenName) = True
						MsgBox(48, $Title, 'Profile "' & $ChosenName & '" already exists. Please choose another name.')
				EndSelect
			EndIf
		Until FileExists($Config["ProfilesPath"] & '\' & $ChosenName) = False Or $Profile["Name"] = ""
		If $Profile["Name"] <> "" Then
			DirCreate($Config["ProfilesPath"] & '\' & $ChosenName)
			$Profile["Name"] = $ChosenName
		EndIf
	EndIf
	If $Profile["Name"] <> "" Then UpdateProfileBasePath()
EndFunc   ;==>ProfileSelected

Func SilentExit()
	Exit
EndFunc   ;==>SilentExit

Func CreateProfileFolderIfEmpty()
	DirCreate($Config["ProfilesPath"] & '\' & $Profile["Name"] & '\' & $Config["SubPath"] & '\' & $Config["Game"])
EndFunc   ;==>CreateProfileFolderIfEmpty

Func CheckIfAlreadyRunning()
	If _Singleton("AltLauncher_" & $Config["Game"], 1) = 0 Then
		If MsgBox($MB_ICONERROR + $MB_RETRYCANCEL, $Title & " - Game: " & $Config["Game"], "AltLauncher is already active for this game. Only one instance allowed per game.") = 4 Then
			CheckIfAlreadyRunning()
		Else
			Exit
		EndIf
	EndIf
EndFunc   ;==>CheckIfAlreadyRunning

Func CheckStateFile()
	Return FileExists($StateFile)
EndFunc   ;==>CheckStateFile

Func RepairState()
	$PreservedProfile = $Profile["Name"]
	$Profile["Name"] = FileRead($StateFile)
	Restore()
	$Profile["Name"] = $PreservedProfile
EndFunc   ;==>RepairState

Func WriteStateFile()
	FileWrite($StateFile, $Profile["Name"])
EndFunc   ;==>WriteStateFile

Func ShowProgressBar()
	$Title = $AppName & " - Profile: " & $Profile["Name"] & " - Game: " & $Config["Game"]
	ProgressOn($Title, "Loading...", "", -1, -1, $DLG_NOTONTOP + $DLG_MOVEABLE)
EndFunc   ;==>ShowProgressBar

Func Backup()
	If $BeaconActive And Not BeaconAlive() Then WaitForDriveReconnect()
	For $i = 1 To $Registry[0][0]
		ProgressSet(($i / $Registry[0][0] * 33.33), $i & "/" & $Registry[0][0] & ": " & $Registry[$i][1])
		Manage_Registry("Backup", $Registry, $i)
	Next
	For $i = 1 To $Directories[0][0]
		ProgressSet(($i / $Directories[0][0] * 33.33 + 33.33), $i & "/" & $Directories[0][0] & ": " & $Directories[$i][1])
		Manage_Directory("Backup", $Directories, $i)
	Next
	For $i = 1 To $Files[0][0]
		ProgressSet(($i / $Files[0][0] * 33.33 + 66.66), $i & "/" & $Files[0][0] & ": " & $Files[$i][1])
		Manage_File("Backup", $Files, $i)
	Next
EndFunc   ;==>Backup

Func EnableChecks()
	$GUI["EarlyExitCheck"] = 0
	AdlibRegister("EarlyExitCheck", 1000)
	OnAutoItExitRegister("_Exit")
EndFunc   ;==>EnableChecks

Func RunLauncher()
	If FileExists($LauncherCmd) Then
		ProgressSet(100, "Starting Launcher...", "")
		ShellExecuteWait($LauncherCmd, "", ($Config["Path"] = Null) ? @ScriptDir : $Config["Path"], $SHEX_OPEN, @SW_HIDE)
	EndIf
EndFunc   ;==>RunLauncher

Func RunGame()
	ProgressSet(100, "Launching Game...", "")
	ShellExecute($Config["Executable"], $Config["LaunchFlags"], ($Config["Path"] = Null) ? @ScriptDir : $Config["Path"])
EndFunc   ;==>RunGame

Func WaitWhileGameRunning()
	ProgressSet(100, "Waiting for game to close...")
	While Not ProcessExists($Config["Executable"])
		Sleep(250)
		If $bEarlyExit Then Return
	WEnd
	$timer = TimerInit()
	While ProcessExists($Config["Executable"])
		Sleep(250)
		If $bEarlyExit Then Return
	WEnd
	If TimerDiff($timer) < $Config["MinWait"] * 1000 Then
		While Not ProcessExists($Config["Executable"]) And TimerDiff($timer) < $Config["MaxWait"] * 1000
			Sleep(250)
			If $bEarlyExit Then Return
		WEnd
		While ProcessExists($Config["Executable"])
			Sleep(250)
			If $bEarlyExit Then Return
		WEnd
	EndIf
EndFunc   ;==>WaitWhileGameRunning

Func WhenGameCloses()
	WinActivate($Title)
	WinSetOnTop($Title, "", $WINDOWS_ONTOP)
	ProgressSet(100, "Game Closed.")
	DisableChecks()
	Sleep(1000 + $Config["SaveDelay"])
	RedirectHook()
EndFunc   ;==>WhenGameCloses

Func DisableChecks()
	OnAutoItExitUnRegister("_Exit")
	AdlibUnRegister("EarlyExitCheck")
EndFunc   ;==>DisableChecks

Func RedirectHook()
	If $Config["SwitchMode"] = "True" Or _IsPressed("10") Then
		WinSetOnTop($Title, "", $WINDOWS_NOONTOP)
		$Profile["StoredProfile"] = $Profile["Name"]
		$Profile["Name"] = ""
		ProfileSelect()
		GUISetOnEvent($GUI_EVENT_CLOSE, "CancelRedirect", $GUI["Handle"])
		Do
			Sleep(100)
		Until $Profile["Name"] <> ""
		WinSetOnTop($Title, "", $WINDOWS_ONTOP)
		CreateProfileFolderIfEmpty()
		UpdateProfileBasePath()
		WriteStateFile()
		$Title = $AppName & " - Profile: " & $Profile["Name"] & " - Game: " & $Config["Game"]
		ProgressOn($Title, "Saving...", "", -1, -1, $DLG_NOTONTOP + $DLG_MOVEABLE)
	EndIf
EndFunc   ;==>RedirectHook

Func CancelRedirect()
	$iret = MsgBox($MB_ICONQUESTION + $MB_YESNO, $Title, "Are you sure? This will send the save files to " & $Profile["StoredProfile"] & "'s folder.")
	Switch $iret
		Case $IDYES
			$Profile["Name"] = $Profile["StoredProfile"]
			GUISetState(@SW_HIDE)
		Case $IDNO
			$Profile["Name"] = ""
	EndSwitch
EndFunc   ;==>CancelRedirect

Func Restore()
	If $BeaconActive And Not BeaconAlive() Then WaitForDriveReconnect()
	If CheckStateFile() = True Then
		For $i = 1 To $Registry[0][0]
			ProgressSet(($i / $Registry[0][0] * 33.33), $i & "/" & $Registry[0][0] & ": " & $Registry[$i][1], "Saving...")
			Manage_Registry("Restore", $Registry, $i)
		Next
		For $i = 1 To $Directories[0][0]
			ProgressSet(($i / $Directories[0][0] * 33.33 + 33.33), $i & "/" & $Directories[0][0] & ": " & $Directories[$i][1])
			Manage_Directory("Restore", $Directories, $i)
		Next
		For $i = 1 To $Files[0][0]
			ProgressSet(($i / $Files[0][0] * 33.33 + 66.66), $i & "/" & $Files[0][0] & ": " & $Files[$i][1])
			Manage_File("Restore", $Files, $i)
		Next
		FileDelete($StateFile)
		ProgressSet(100, "Success")
	EndIf
EndFunc   ;==>Restore

Func Manage_Registry($Mode, ByRef $Registry, ByRef $i)
	$RegPath = $Registry[$i][1]
	$BackupPath = $Profile["BasePath"] & $Registry[$i][0]
	Switch $Mode
		Case "Backup"
			ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '" "' & $RegPath & '.AltLauncher-Backup" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
			ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
			ShellExecuteWait("reg.exe", 'import "' & $BackupPath & '.reg"', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		Case "Restore"
			ShellExecuteWait("reg.exe", 'export "' & $RegPath & '" "' & $BackupPath & '.reg" /Y', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
			ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
			ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '.AltLauncher-Backup" "' & $RegPath & '" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
			ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '.AltLauncher-Backup" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
	EndSwitch
EndFunc   ;==>Manage_Registry

Func Manage_Directory($Mode, ByRef $Directories, ByRef $i)
	$DirPath = $Directories[$i][1]
	$BackupPath = $Profile["BasePath"] & $Directories[$i][0]
	Switch $Mode
		Case "Backup"
			If Not FileExists($DirPath) Then DirCreate($DirPath)
			If Not FileExists($BackupPath) Then DirCreate($BackupPath)
			DirMove($DirPath, $DirPath & '.AltLauncher-Backup', $FC_OVERWRITE)
			DirCopy($BackupPath, $DirPath, $FC_OVERWRITE)
		Case "Restore"
			$GameFileList = _FileListToArrayRec($DirPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
			Local $oGameFileMap[]
			For $j = 1 To UBound($GameFileList) - 1
				FileCopy($DirPath & '\' & $GameFileList[$j], $BackupPath & '\' & $GameFileList[$j], $FC_OVERWRITE + $FC_CREATEPATH)
				$oGameFileMap[$GameFileList[$j]] = True
			Next
			$ProfileFileList = _FileListToArrayRec($BackupPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
			Local $aStaleFiles[UBound($ProfileFileList)]
			Local $iStaleCount = 0
			For $j = 1 To UBound($ProfileFileList) - 1
				If Not MapExists($oGameFileMap, $ProfileFileList[$j]) Then
					$aStaleFiles[$iStaleCount] = $ProfileFileList[$j]
					$iStaleCount += 1
				EndIf
			Next
			Switch $Config["SafeMode"]
				Case "True"
					For $j = 0 To $iStaleCount - 1
						FileRecycle($BackupPath & '\' & $aStaleFiles[$j])
					Next
					$FolderCleanupList = _FileListToArrayRec($BackupPath, "*", $FLTA_FOLDERS, $FLTAR_RECUR)
					For $j = UBound($FolderCleanupList) - 1 To 1 Step -1
						FileRecycle($BackupPath & $FolderCleanupList[$j])
					Next
				Case "False"
					For $j = 0 To $iStaleCount - 1
						FileDelete($BackupPath & '\' & $aStaleFiles[$j])
					Next
					$FolderCleanupList = _FileListToArrayRec($BackupPath, "*", $FLTA_FOLDERS, $FLTAR_RECUR)
					For $j = UBound($FolderCleanupList) - 1 To 1 Step -1
						DirRemove($BackupPath & $FolderCleanupList[$j], $DIR_DEFAULT)
					Next
				Case Null
					FileMove($DirPath, $BackupPath, $FC_OVERWRITE + $FC_CREATEPATH)
			EndSwitch
			DirRemove($DirPath, $DIR_REMOVE)
			DirMove($DirPath & '.AltLauncher-Backup', $DirPath)
	EndSwitch
EndFunc   ;==>Manage_Directory

Func Manage_File($Mode, ByRef $Files, ByRef $i)
	$FilePath = $Files[$i][1]
	$BackupPath = $Profile["BasePath"] & $Files[$i][0]
	Switch $Mode
		Case "Backup"
			FileMove($FilePath, $FilePath & '.AltLauncher-Backup', $FC_OVERWRITE + $FC_CREATEPATH)
			FileCopy($BackupPath, $FilePath, $FC_OVERWRITE + $FC_CREATEPATH)
		Case "Restore"
			$FileExists = FileExists($FilePath)
			FileMove($FilePath, $BackupPath, $FC_OVERWRITE + $FC_CREATEPATH)
			Switch $Config["SafeMode"]
				Case "True"
					If Not $FileExists Then FileRecycle($BackupPath)
				Case "False"
					If Not $FileExists Then FileDelete($BackupPath)
				Case Null
			EndSwitch
			FileMove($FilePath & '.AltLauncher-Backup', $FilePath, $FC_OVERWRITE + $FC_CREATEPATH)
	EndSwitch
EndFunc   ;==>Manage_File

Func EarlyExitCheck()
	If _IsPressed("1B") Then
		$GUI["EarlyExitCheck"] += 1
	Else
		$GUI["EarlyExitCheck"] = 0
	EndIf
	If $GUI["EarlyExitCheck"] >= 5 Then
		ProgressSet(100, "Early Exit Triggered!")
		$bEarlyExit = True
	EndIf
EndFunc   ;==>EarlyExitCheck

Func _Exit()
	WinActivate($Title)
	WinSetOnTop($Title, "", $WINDOWS_ONTOP)
	DisableChecks()
	Restore()
	Sleep(1000)
	Exit
EndFunc   ;==>_Exit

Func ExitMSG($msg)
	Exit MsgBox($MB_OK + $MB_ICONERROR + $MB_SYSTEMMODAL, "AltLauncher", $msg)
EndFunc   ;==>ExitMSG

Func Setup()
	MsgBox(0, $Title, "Welcome to AltLauncher. Since this is the first time you've ran this program, we need to do some setup first." & @CRLF & @CRLF & "Click ok to proceed.")
	MsgBox(0, $Title, "Where would you like to store your save profiles? A folder picker will open on the next screen.")
	RegWrite("HKCU\Environment", "AltLauncher_Path", "REG_SZ", FileSelectFolder($Title, "", $FSF_CREATEBUTTON, "C:\AltLauncher"))
	RegWrite("HKCU\Environment", "AltLauncher_SubPath", "REG_SZ", InputBox($Title, "Do you need a sub-folder inside each profile? If so, enter it here. Most people can leave this blank."))
	Switch MsgBox(3, $Title, "What should happen to old save files when you switch profiles?" & @CRLF & @CRLF & "Yes - Send them to the Recycle Bin (safest, takes up space)" & @CRLF & "No - Delete them permanently" & @CRLF & "Cancel - Keep them and restore on next launch")
		Case $IDYES
			RegWrite("HKCU\Environment", "AltLauncher_SafeMode", "REG_SZ", "True")
		Case $IDNO
			RegWrite("HKCU\Environment", "AltLauncher_SafeMode", "REG_SZ", "False")
		Case $IDCANCEL
			RegDelete("HKCU\Environment", "AltLauncher_SafeMode")
	EndSwitch
	Switch MsgBox(4, $Title, "Should AltLauncher ask you which profile to use each time you launch a game?" & @CRLF & @CRLF & "Yes - Always ask me" & @CRLF & "No - Remember my last choice")
		Case $IDYES
			RegWrite("HKCU\Environment", "AltLauncher_UseProfileFile", "REG_SZ", "False")
		Case $IDNO
			RegWrite("HKCU\Environment", "AltLauncher_UseProfileFile", "REG_SZ", "True")
	EndSwitch
	Switch MsgBox(4, $Title, "Should AltLauncher ask you which profile to save under when a game closes?" & @CRLF & @CRLF & "Yes - Always ask me" & @CRLF & "No - Always save under the profile I launched with" & @CRLF & @CRLF & 'You can still switch manually by holding "Shift" when a game closes.')
		Case $IDYES
			RegWrite("HKCU\Environment", "AltLauncher_SwitchMode", "REG_SZ", "True")
		Case $IDNO
			RegWrite("HKCU\Environment", "AltLauncher_SwitchMode", "REG_SZ", "False")
	EndSwitch
	$AutoDetectSteam3 = _FileListToArray("C:\Program Files (x86)\Steam\userdata", "*", $FLTA_FOLDERS)
	If $AutoDetectSteam3[0] = 1 Then
		RegWrite("HKCU\Environment", "SteamID3", "REG_SZ", $AutoDetectSteam3[1])
	Else
		RegWrite("HKCU\Environment", "SteamID3", "REG_SZ", InputBox($Title, "Enter your Steam3 ID." & @CRLF & @CRLF & "You can get your Steam3 at https://steamid.io/" & @CRLF))
	EndIf
	$AutoDetectSteam64 = _FileListToArray("C:\Program Files (x86)\Steam\config\avatarcache", "*", $FLTA_Files)
	If $AutoDetectSteam64[0] = 1 Then
		RegWrite("HKCU\Environment", "SteamID64", "REG_SZ", StringLeft($AutoDetectSteam64[1], StringInStr($AutoDetectSteam64[1], ".", 0, -1) - 1))
	Else
		RegWrite("HKCU\Environment", "SteamID64", "REG_SZ", InputBox($Title, "Enter your Steam64 ID." & @CRLF & @CRLF & "You can get your Steam64 at https://steamid.io/" & @CRLF))
	EndIf
	$AutoDetectUbisoftID = _FileListToArray("C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames", "*", $FLTA_FOLDERS)
	If IsArray($AutoDetectUbisoftID) And $AutoDetectUbisoftID[0] = 1 Then
		RegWrite("HKCU\Environment", "UbisoftID", "REG_SZ", $AutoDetectUbisoftID[1])
	Else
		RegWrite("HKCU\Environment", "UbisoftID", "REG_SZ", InputBox($Title, "Enter your Ubisoft ID." & @CRLF & @CRLF & "Consult the readme.md on how to obtain this." & @CRLF))
	EndIf
	Exit MsgBox(0, $Title, "Setup Complete. Please relaunch AltLauncher.")
EndFunc   ;==>Setup
