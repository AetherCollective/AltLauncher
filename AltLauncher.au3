#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.2.1.1
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
Global $Title = "AltLauncher", $Profile_Set = False
ReadEnvironmentVariables()
If RegRead("HKCU\Environment", "AltLauncher_Path") = "" Then Setup()
ReadConfig()
CheckIfAlreadyRunning()
If CheckStateFile() = True Then RepairState()
ProfileSelect()
Do
	Sleep(100)
Until $Profile_Set = True
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
sleep(2000)
Exit
Func ReadINISection(ByRef $Ini, $Section)
	$Data = IniReadSection($Ini, $Section)
	If @error Then
		Local $Data[1][2]
		$Data[0][0] = 0
	EndIf
	Return $Data
EndFunc   ;==>ReadINISection
Func ReadEnvironmentVariables()
	EnvSet("SteamID3", RegRead("HKCU\Environment", "SteamID3"))
	EnvSet("SteamID64", RegRead("HKCU\Environment", "SteamID64"))
	EnvSet("UbisoftID", RegRead("HKCU\Environment", "UbisoftID"))
	EnvSet("RockstarID", RegRead("HKCU\Environment", "RockstarID"))
	EnvSet("AltLauncher_UseProfileFile", RegRead("HKCU\Environment", "AltLauncher_UseProfileFile"))
	EnvSet("AltLauncher_ButtonWidth", RegRead("HKCU\Environment", "AltLauncher_ButtonWidth"))
	EnvSet("AltLauncher_ButtonHeight", RegRead("HKCU\Environment", "AltLauncher_ButtonHeight"))
	EnvSet("AltLauncher_NumberOfButtonsPerDirection", RegRead("HKCU\Environment", "AltLauncher_NumberOfButtonsPerDirection"))
	EnvSet("AltLauncher_ButtonSpacing", RegRead("HKCU\Environment", "AltLauncher_ButtonSpacing"))
	EnvSet("AltLauncher_ButtonDirection", RegRead("HKCU\Environment", "AltLauncher_ButtonDirection"))
EndFunc   ;==>ReadEnvironmentVariables
Func ReadConfig()
	Global $Ini = @ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini"
	If Not FileExists($Ini) Then
		$SearchResults = _FileListToArrayRec(@ScriptDir, StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
		If Not IsArray($SearchResults) Then
			Switch MsgBox(4, $Title, "AltLauncher.ini not found. Would you like to download a template from the internet?")
				Case $IDYES
					$gameName = DetectGame()
					If IsInt($gameName) Then ExitMSG("Your game is not in our database. Exiting...")
					If IsString($gameName) Then
						$downloaded = DownloadGameConfig($gameName)
						If Int($downloaded) <> 1 Then ExitMSG(StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini could not be downloaded at this time. Please try again later.")
					EndIf
					$SearchResults = _FileListToArrayRec(@ScriptDir, StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
				Case $IDNO
					ExitMSG(StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini not found.")
			EndSwitch
		EndIf
		If $SearchResults[0] <> 1 Then ExitMSG("Multiple " & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini found. Please remove all but one and try again.")
		$Ini = @ScriptDir & "\" & $SearchResults[1]
	EndIf
	Global $Name = IniRead($Ini, "General", "Name", Null)
	Global $Path = IniRead($Ini, "General", "Path", Null)
	Global $Executable = IniRead($Ini, "General", "Executable", Null)
	Global $LaunchFlags = IniRead($Ini, "General", "LaunchFlags", Null)
	Global $MinWait = IniRead($Ini, "Settings", "MinWait", 0)
	Global $MaxWait = IniRead($Ini, "Settings", "MaxWait", 0)
	Global $UseRecyclingBin = IniRead($Ini, "Settings", "UseRecyclingBin", (RegRead("HKCU\Environment", "AltLauncher_UseRecyclingBin") <> "") ? RegRead("HKCU\Environment", "AltLauncher_UseRecyclingBin") : Null)
	Global $ProfilesPath = IniRead($Ini, "Profiles", "Path", (RegRead("HKCU\Environment", "AltLauncher_Path") <> "") ? RegRead("HKCU\Environment", "AltLauncher_Path") : "C:\AltLauncher")
	Global $ProfilesSubPath = IniRead($Ini, "Profiles", "SubPath", RegRead("HKCU\Environment", "AltLauncher_SubPath"))
	Global $Profile = ""
	If RegRead("HKCU\Environment", "AltLauncher_UseProfileFile") = "True" Then $Profile = FileRead($ProfilesPath & "\Selected Profile.txt")
	If @Compiled And $CmdLine[0] >= 1 Then
		Switch $CmdLine[1]
			Case "--"

			Case "--read"
				$filestate = False
				$hFile = FileOpen($ProfilesPath & "\Selected Profile.txt", 2)
				If $hFile = -1 Then ;hidden file check
					$attrib = FileGetAttrib($ProfilesPath & "\Selected Profile.txt")
					FileSetAttrib($ProfilesPath & "\Selected Profile.txt", "-H")
					$filestate = True
					$hFile = FileOpen($ProfilesPath & "\Selected Profile.txt", 2)
				EndIf
				FileRead($ProfilesPath & "\Selected Profile.txt")
				FileClose($hFile)
				If $filestate = True Then FileSetAttrib($ProfilesPath & "\Selected Profile.txt", "+" & $attrib)
			Case "--select"
				$Profile = ""
			Case "--setup"
				Setup()
			Case Else
				; Any other value is treated as a direct profile name
				$Profile = $CmdLine[1]
		EndSwitch
	EndIf
	Global $Registry = ReadINISection($Ini, "Registry")
	Global $Directories = ReadINISection($Ini, "Directories")
	Global $Files = ReadINISection($Ini, "Files")
EndFunc   ;==>ReadConfig
Func DetectGame()
	$success = False
	$url = "https://raw.githubusercontent.com/AetherCollective/AltLauncher-Templates/refs/heads/main/gamelist.ini"
	$savePath = @TempDir & "\AltLauncher\gamelist.ini"
	DirCreate(@TempDir & "\AltLauncher")
	For $i = 1 To 3 ;Retry up to 3 times
		$download = InetGet($url, $savePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)   ; flag 1 = overwrite, flag 1 = wait
		Do
			Sleep(100)
		Until InetGetInfo($download, $INET_DOWNLOADCOMPLETE)
		If FileExists($savePath) And FileGetSize($savePath) > 0 Then
			$success = True
			ExitLoop
		EndIf
		Sleep(1000)
	Next
	If Not $success Then Return 0 ; download failed
	$steamID = EnvGet("steamappid")
	If $steamID = "" Then Return 1 ; steam id not detected
	$games = IniReadSection($savePath, "Steam")
	If @error Then Return 2 ; database corrupted
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
	$success = False
	If $gameName = "" Then Return 2 ; game not found
	$url = "https://raw.githubusercontent.com/AetherCollective/AltLauncher-Templates/refs/heads/main/" & $gameName & "/AltLauncher.ini"
	$savePath = @ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".ini"
	For $i = 1 To 3 ;Retry up to 3 times
		$download = InetGet($url, $savePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)   ; flag 1 = overwrite, flag 1 = wait
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
	Return 0 ; download failed=
EndFunc   ;==>DownloadGameConfig
Func ProfileSelect()
	If $Profile <> "" Then
		$Profile_Set = True
		Return
	EndIf
	$aFolders = _FileListToArray($ProfilesPath, "*", $FLTA_FOLDERS)
	Const $iSpacing = (EnvGet("AltLauncher_ButtonSpacing") <> "" ? Int(EnvGet("AltLauncher_ButtonSpacing")) : 4)
	$iMaxPer = (EnvGet("AltLauncher_NumberOfButtonsPerDirection") <> "" ? Int(EnvGet("AltLauncher_NumberOfButtonsPerDirection")) : 5)
	$iButtonWidth = (EnvGet("AltLauncher_ButtonWidth") <> "" ? Int(EnvGet("AltLauncher_ButtonWidth")) : 120)
	$iButtonHeight = (EnvGet("AltLauncher_ButtonHeight") <> "" ? Int(EnvGet("AltLauncher_ButtonHeight")) : 55)
	$sLayout = (EnvGet("AltLauncher_ButtonDirection") <> "" ? EnvGet("AltLauncher_ButtonDirection") : "down")
	Global $iNumOfProfiles = 0
	If IsArray($aFolders) And UBound($aFolders) > 0 Then
		$iNumOfProfiles = $aFolders[0]
	EndIf
	Local $iCols, $iRows
	If $sLayout = "right" Then
		$iRows = Ceiling(($iNumOfProfiles + 1) / $iMaxPer)
		$iCols = _Min(($iNumOfProfiles + 1), $iMaxPer)
	Else ;down
		$iCols = Ceiling(($iNumOfProfiles + 1) / $iMaxPer)
		$iRows = _Min(($iNumOfProfiles + 1), $iMaxPer)
	EndIf
	$iWinW = ($iSpacing + $iButtonWidth + 1) * $iCols + $iSpacing + 2
	$iWinH = ($iSpacing + $iButtonHeight) * $iRows + $iSpacing + 30
	$hGUI = GUICreate($Title & " - Game: " & $Name, $iWinW, $iWinH, -1, -1, $WS_SYSMENU)
	GUISetOnEvent($GUI_EVENT_CLOSE, "HideProfileSelect")
	Local $iX = $iSpacing, $iY = $iSpacing
	For $i = 1 To $iNumOfProfiles + 1
		If $i <= $iNumOfProfiles Then
			$sLabel = $aFolders[$i]
		Else
			$sLabel = "+"
		EndIf
		$iStyle = ($sLabel = $Profile) ? BitOR($WS_BORDER, $WS_TABSTOP) : $WS_TABSTOP
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
	If $iNumOfProfiles = 0 Then ProfileSelected()
	GUISetState(@SW_SHOW)
EndFunc   ;==>ProfileSelect
Func ProfileSelected()
	GUISetState(@SW_HIDE)
	$Profile = ($iNumOfProfiles = 0) ? "+" : GUICtrlRead(@GUI_CtrlId)
	$Profile_Set = True
	If $Profile = "+" Then
		Do
			$ChosenName = InputBox($Title, "Please enter a new profile name.")
			If @error Then
				$Profile_Set = False
				GUISetState(@SW_SHOW)
			Else
				Select
					Case $ChosenName = ""
						MsgBox(48, $Title, 'Profile name cannot be blank. Please choose another name.')
					Case FileExists($ProfilesPath & '\' & $ChosenName) = True
						MsgBox(48, $Title, 'Profile "' & $ChosenName & '" already exists. Please choose another name.')
				EndSelect
			EndIf
		Until FileExists($ProfilesPath & '\' & $ChosenName) = False Or $Profile_Set = False
		DirCreate($ProfilesPath & '\' & $ChosenName)
		$Profile = $ChosenName
	EndIf
EndFunc   ;==>ProfileSelected
Func HideProfileSelect()
	Exit
EndFunc   ;==>HideProfileSelect
Func CreateProfileFolderIfEmpty()
	DirCreate($ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name)
EndFunc   ;==>CreateProfileFolderIfEmpty
Func CheckIfAlreadyRunning()
	If _Singleton("AltLauncher_" & $Name, 1) = 0 Then ;already running
		If MsgBox($MB_ICONERROR + $MB_RETRYCANCEL, $Title & " - Game: " & $Name, "AltLauncher is already active for this game. Only one instance allowed per game.") = 4 Then
			CheckIfAlreadyRunning()
		Else
			Exit
		EndIf
	EndIf
EndFunc   ;==>CheckIfAlreadyRunning
Func CheckStateFile()
	Return FileExists(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".state")
EndFunc   ;==>CheckStateFile
Func RepairState()
	$PreservedProfile = $Profile
	$Profile = FileRead(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".state")
	Restore()
	$Profile = $PreservedProfile
EndFunc   ;==>RepairState
Func WriteStateFile()
	FileWrite(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".state", $Profile)
EndFunc   ;==>WriteStateFile
Func ShowProgressBar()
	$Title &= " - Profile: " & $Profile & " - Game: " & $Name
	ProgressOn($Title, "Loading...", "", -1, -1, $DLG_NOTONTOP + $DLG_MOVEABLE)
EndFunc   ;==>ShowProgressBar
Func Backup()
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
	Global $EarlyExitCheck
	AdlibRegister("EarlyExitCheck", 1000)
	OnAutoItExitRegister("_Exit")
EndFunc   ;==>EnableChecks
Func RunLauncher()
	If FileExists(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & "-launcher.cmd") Then
		ProgressSet(100, "Starting Launcher...", "")
		ShellExecuteWait(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & "-launcher.cmd", "", ($Path = Null) ? @ScriptDir : $Path, $SHEX_OPEN, @SW_HIDE)
	EndIf
EndFunc   ;==>RunLauncher
Func RunGame()
	ProgressSet(100, "Launching Game...", "")
	ShellExecute($Executable, $LaunchFlags, ($Path = Null) ? @ScriptDir : $Path)
EndFunc   ;==>RunGame
Func WaitWhileGameRunning()
	ProgressSet(100, "Waiting for game to close...")
	While Not ProcessExists($Executable)
		Sleep(250)
	WEnd
	$timer = TimerInit()
	While ProcessExists($Executable)
		Sleep(250)
	WEnd
	If TimerDiff($timer) < $MinWait * 1000 Then
		While Not ProcessExists($Executable) And TimerDiff($timer) < $MaxWait * 1000
			Sleep(250)
		WEnd
		While ProcessExists($Executable)
			Sleep(250)
		WEnd
	EndIf
EndFunc   ;==>WaitWhileGameRunning
Func WhenGameCloses()
	WinActivate($Title)
	WinSetOnTop($Title, "", $WINDOWS_ONTOP)
	ProgressSet(100, "Game Closed.")
	DisableChecks()
	sleep(1000)
EndFunc   ;==>doExit
Func Restore()
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
		FileDelete(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".state")
		ProgressSet(100, "Success")
	EndIf
EndFunc   ;==>Restore
Func Manage_Registry($Mode, ByRef $Registry, ByRef $i)
	$RegPath = $Registry[$i][1]
	If $Mode = "Backup" Then
		ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '" "' & $RegPath & '.AltLauncher-Backup" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'import "' & $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Registry[$i][0] & '.reg"', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
	ElseIf $Mode = "Restore" Then
		ShellExecuteWait("reg.exe", 'export "' & $RegPath & '" "' & $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Registry[$i][0] & '.reg" /Y', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '.AltLauncher-Backup" "' & $RegPath & '" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '.AltLauncher-Backup" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
	EndIf
EndFunc   ;==>Manage_Registry
Func Manage_Directory($Mode, ByRef $Directories, ByRef $i)
	$DirPath = $Directories[$i][1]
	$BackupPath = $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0]
	If $Mode = "Backup" Then
		If Not FileExists($DirPath) Then DirCreate($DirPath)
		If Not FileExists($BackupPath) Then DirCreate($BackupPath)
		If DirMove($DirPath, $DirPath & '.AltLauncher-Backup', $FC_OVERWRITE) = 0 Then
			If FileWriteLine(@ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".log", "Backup failed! " & $DirPath & @CRLF) = 0 Then MsgBox(0, "error", "Backup failed! " & $DirPath)
		EndIf
		If DirCopy($BackupPath, $DirPath, $FC_OVERWRITE) = 0 Then FileWriteLine(@ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".log", "Transfer to game failed! " & $BackupPath & "=>" & $DirPath & @CRLF)
	ElseIf $Mode = "Restore" Then
		If $UseRecyclingBin = "True" Then
			If DirCopy($DirPath, $BackupPath, $FC_OVERWRITE) = 0 Then
				FileWriteLine(@ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".log", "Transfer to game failed! " & $DirPath & "=>" & $BackupPath & @CRLF)
			EndIf
		Else
			$GameFileList = _FileListToArrayRec($DirPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
			For $j = UBound($GameFileList) - 1 To 1 Step -1
				If FileCopy($DirPath & '\' & $GameFileList[$j], $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0] & '\' & $GameFileList[$j], $FC_OVERWRITE + $FC_CREATEPATH) = 0 Then FileWrite(@ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".log", "Transfer to profile failed! " & $DirPath & '\' & $GameFileList[$j] & "=>" & $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0] & '\' & $GameFileList[$j] & @CRLF)
			Next
			$ProfileFileList = _FileListToArrayRec($BackupPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
			For $j = UBound($ProfileFileList) - 1 To 1 Step -1
				If _ArraySearch($GameFileList, $ProfileFileList[$j]) <> -1 Then
					_ArrayDelete($ProfileFileList, $j)
				EndIf
			Next
			For $j = UBound($ProfileFileList) - 1 To 1 Step -1
				If $UseRecyclingBin = "False" Then
					FileDelete($ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0] & '\' & $ProfileFileList[$j])
				Else
					FileRecycle($ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0] & '\' & $ProfileFileList[$j])
				EndIf
			Next
			$FolderCleanupList = _FileListToArrayRec($BackupPath, "*", $FLTA_FOLDERS, $FLTAR_RECUR)
			For $j = UBound($FolderCleanupList) - 1 To 1 Step -1
				DirRemove($BackupPath & $FolderCleanupList[$j], $DIR_DEFAULT)
			Next
		EndIf
		If $UseRecyclingBin = "False" Then
			DirRemove($DirPath, $DIR_REMOVE)
		Else
			FileRecycle($DirPath)
		EndIf
		If DirMove($DirPath & '.AltLauncher-Backup', $DirPath) = 0 Then FileWriteLine(@ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".log", "Restore Failed! " & $DirPath & @CRLF)
	EndIf
EndFunc   ;==>Manage_Directory
Func Manage_File($Mode, ByRef $Files, ByRef $i)
	$FilePath = $Files[$i][1]
	$BackupPath = $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Files[$i][0]
	If $Mode = "Backup" Then
		FileMove($FilePath, $FilePath & '.AltLauncher-Backup', $FC_OVERWRITE + $FC_CREATEPATH)
		FileCopy($BackupPath, $FilePath, $FC_OVERWRITE + $FC_CREATEPATH)
	ElseIf $Mode = "Restore" Then
		If $UseRecyclingBin = "true" Then
			FileMove($FilePath, $BackupPath, $FC_OVERWRITE + $FC_CREATEPATH)
		Else
			If $UseRecyclingBin = "False" Then
				FileDelete($BackupPath)
			Else
				FileRecycle($BackupPath)
			EndIf
		EndIf
		FileMove($FilePath & '.AltLauncher-Backup', $FilePath, $FC_OVERWRITE + $FC_CREATEPATH)
	EndIf
EndFunc   ;==>Manage_File
Func DisableChecks()
	OnAutoItExitUnRegister("_Exit")
	AdlibUnRegister("EarlyExitCheck")
EndFunc
Func EarlyExitCheck()
	If _IsPressed("1B") Then ;Escape Key
		$EarlyExitCheck += 1
	Else
		$EarlyExitCheck = 0
	EndIf
	If $EarlyExitCheck >= 5 Then
		ProgressSet(100, "Early Exit Triggered!")
		sleep(1000)
		WhenGameCloses()
	EndIf
EndFunc   ;==>EarlyExitCheck
Func _Exit()
	WinActivate($Title)
	WinSetOnTop($Title, "", $WINDOWS_ONTOP)
	DisableChecks()
	Restore()
	sleep(1000)
	Exit
EndFunc   ;==>_Exit
Func ExitMSG($msg)
	Exit MsgBox($MB_OK + $MB_ICONERROR + $MB_SYSTEMMODAL, "AltLauncher", $msg)
EndFunc   ;==>ExitMSG
Func Setup()
	MsgBox(0, $Title, "Welcome to AltLauncher. Since this is the first time you've ran this program, we need to do some setup first." & @CRLF & @CRLF & "Click ok to proceed.")
	MsgBox(0, $Title, "Please select where you want your save slots to be stored on the next window.")
	RegWrite("HKCU\Environment", "AltLauncher_Path", "REG_SZ", FileSelectFolder($Title, "", $FSF_CREATEBUTTON, "C:\AltLauncher"))
	RegWrite("HKCU\Environment", "AltLauncher_SubPath", "REG_SZ", InputBox($Title, "If you need to set up a sub-path, enter it now." & @CRLF & "If you don't need this, leave blank and click ok."))
	Switch MsgBox(3, $Title, "Would you like to use the Recycling Bin when erasing a save slot?" & @CRLF & @CRLF & "Click 'Yes' to use the Recycling Bin." & @CRLF & "Click 'No' to permanently delete erased slots." & @CRLF & "Click 'Cancel' will preserve any erased save slots, restoring them on the next launch.")
		Case $IDYES
			RegWrite("HKCU\Environment", "AltLauncher_UseRecyclingBin", "REG_SZ", "True")
		Case $IDNO
			RegWrite("HKCU\Environment", "AltLauncher_UseRecyclingBin", "REG_SZ", "False")
		Case $IDCANCEL
			RegDelete("HKCU\Environment", "AltLauncher_UseRecyclingBin")
	EndSwitch
	Switch MsgBox(4, $Title, "Would you like to be asked which profile you would like to load each time you start a game?")
		Case $IDYES
			RegWrite("HKCU\Environment", "AltLauncher_UseProfileFile", "REG_SZ", "False")
		Case $IDNO
			RegWrite("HKCU\Environment", "AltLauncher_UseProfileFile", "REG_SZ", "True")
			If FileCopy(@ScriptDir & "\AltSetter.exe", RegRead("HKCU\Environment", "AltLauncher_Path"), 9) Then
				MsgBox(16, $Title, 'AltSetter has been automatically copied into "' & RegRead("HKCU\Environment", "AltLauncher_Path") & '"')
			Else
				MsgBox(48, $Title, 'You will need to copy AltSetter into "' & RegRead("HKCU\Environment", "AltLauncher_Path") & '"')
			EndIf
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
