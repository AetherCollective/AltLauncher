#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.1.0.12
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_After=cmd /c echo %fileversion% > "%scriptdir%\VERSION"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <File.au3>
#include <Misc.au3>
Opt("TrayIconHide", True)
Opt("ExpandEnvStrings", True)
Global $Title = "AltLauncher"

RegisterVariables()
ReadEnvironmentVariables()
If RegRead("HKCU\Environment", "AltLauncher_Path") = "" Then Setup()
ReadConfig()
ProcessCMDLine()
ProcessConfig()
CheckIfAlreadyRunning()
If CheckStateFile() = True Then RepairState()
WriteStateFile()
CreateProfileFolderIfEmpty()
ShowProgressBar()
Backup()
EnableChecks()
RunLauncherIfNeeded()
RunGame()
WaitWhileGameRunning()
doExit()

Func RegisterVariables()
	Global $backup = "backup", $restore = "restore"
EndFunc   ;==>RegisterVariables
Func ReadINISection(ByRef $Ini, $Section)
	Local $Data = IniReadSection($Ini, $Section)
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
EndFunc   ;==>ReadEnvironmentVariables
Func ReadConfig()
	Global $Ini = @ScriptDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini"
	If Not FileExists($Ini) Then
		$SearchResults = _FileListToArrayRec(@ScriptDir, StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
		If Not IsArray($SearchResults) Then ExitMSG(StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1) - 1) & ".ini not found.")
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
	Global $Profile = FileRead($ProfilesPath & "\Selected Profile.txt")
	If $Profile = "" Then ExitMSG("Fronting File not set at " & $ProfilesPath & "\Selected Profile.txt")
EndFunc   ;==>ReadConfig
Func ProcessConfig()
	Global $Registry = ReadINISection($Ini, "Registry")
	Global $Directories = ReadINISection($Ini, "Directories")
	Global $Files = ReadINISection($Ini, "Files")
EndFunc   ;==>ProcessConfig
Func ProcessCMDLine()
	Global $Profile = (@Compiled And ($CmdLine[0] >= 1 And $CmdLine[1] <> "--")) ? $CmdLine[1] : FileRead($ProfilesPath & "\Selected Profile.txt")
	If $Profile = "" Then ExitMSG("Fronting File not set at " & $ProfilesPath & "\Selected Profile.txt")
EndFunc   ;==>ProcessCMDLine
Func CreateProfileFolderIfEmpty()
	DirCreate($ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name)
EndFunc   ;==>CreateProfileFolderIfEmpty
Func CheckIfAlreadyRunning()
	Do
		$ProcessList = ProcessList("AltLauncher.exe")
		Sleep(250)
	Until $ProcessList[0][0] < 2
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
	$Title &= " - Profile: "
	ProgressOn($Title & $Profile, "Loading...", "", -1, -1, $DLG_NOTONTOP + $DLG_MOVEABLE)
EndFunc   ;==>ShowProgressBar
Func RunLauncherIfNeeded()
	If FileExists(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & "-launcher.cmd") Then
		ProgressSet(100, "Starting Launcher...", "")
		ShellExecuteWait(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & "-launcher.cmd", "", ($Path = Null) ? @ScriptDir : $Path, $SHEX_OPEN, @SW_HIDE)
	EndIf
EndFunc   ;==>RunLauncherIfNeeded
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
	ProgressSet(100, "Game Closed.")
EndFunc   ;==>WaitWhileGameRunning
Func Backup()
	For $i = 1 To $Registry[0][0]
		ProgressSet(($i / $Registry[0][0] * 33.33), $i & "/" & $Registry[0][0] & ": " & $Registry[$i][1])
		Manage_Registry($backup, $Registry, $i)
	Next
	For $i = 1 To $Directories[0][0]
		ProgressSet(($i / $Directories[0][0] * 33.33 + 33.33), $i & "/" & $Directories[0][0] & ": " & $Directories[$i][1])
		Manage_Directory($backup, $Directories, $i)
	Next
	For $i = 1 To $Files[0][0]
		ProgressSet(($i / $Files[0][0] * 33.33 + 66.66), $i & "/" & $Files[0][0] & ": " & $Files[$i][1])
		Manage_File($backup, $Files, $i)
	Next
EndFunc   ;==>Backup
Func Restore()
	If CheckStateFile() = True Then
		For $i = 1 To $Registry[0][0]
			ProgressSet(($i / $Registry[0][0] * 33.33), $i & "/" & $Registry[0][0] & ": " & $Registry[$i][1], "Saving...")
			Manage_Registry($restore, $Registry, $i)
		Next
		For $i = 1 To $Directories[0][0]
			ProgressSet(($i / $Directories[0][0] * 33.33 + 33.33), $i & "/" & $Directories[0][0] & ": " & $Directories[$i][1])
			Manage_Directory($restore, $Directories, $i)
		Next
		For $i = 1 To $Files[0][0]
			ProgressSet(($i / $Files[0][0] * 33.33 + 66.66), $i & "/" & $Files[0][0] & ": " & $Files[$i][1])
			Manage_File($restore, $Files, $i)
		Next
		FileDelete(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".state")
		ProgressSet(100, "Success")
	EndIf
EndFunc   ;==>Restore
Func Manage_Registry($Mode, ByRef $Registry, ByRef $i)
	Local $RegPath = $Registry[$i][1]
	If $Mode = "backup" Then
		ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '" "' & $RegPath & '.AltLauncher-Backup" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'import "' & $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Registry[$i][0] & '.reg"', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
	ElseIf $Mode = "restore" Then
		ShellExecuteWait("reg.exe", 'export "' & $RegPath & '" "' & $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Registry[$i][0] & '.reg" /Y', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'copy "' & $RegPath & '.AltLauncher-Backup" "' & $RegPath & '" /S /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
		ShellExecuteWait("reg.exe", 'delete "' & $RegPath & '.AltLauncher-Backup" /F', @ScriptDir, $SHEX_OPEN, @SW_HIDE)
	EndIf
EndFunc   ;==>Manage_Registry
Func Manage_Directory($Mode, ByRef $Directories, ByRef $i)
	Local $DirPath = $Directories[$i][1]
	Local $BackupPath = $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0]
	If $Mode = "backup" Then
		If Not FileExists($DirPath) Then DirCreate($DirPath)
		If Not FileExists($BackupPath) Then DirCreate($BackupPath)
		DirMove($DirPath, $DirPath & '.AltLauncher-Backup', $FC_OVERWRITE)
		DirCopy($BackupPath, $DirPath, $FC_OVERWRITE)
	ElseIf $Mode = "restore" Then
		If $UseRecyclingBin = "True" Then
			DirCopy($DirPath, $BackupPath, $FC_OVERWRITE)
		Else
			$GameFileList = _FileListToArrayRec($DirPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
			For $j = UBound($GameFileList) - 1 To 1 Step -1
				FileCopy($DirPath & '\' & $GameFileList[$j], $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Directories[$i][0] & '\' & $GameFileList[$j], $FC_OVERWRITE + $FC_CREATEPATH)
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
		DirMove($DirPath & '.AltLauncher-Backup', $DirPath)
	EndIf
EndFunc   ;==>Manage_Directory
Func Manage_File($Mode, ByRef $Files, ByRef $i)
	Local $FilePath = $Files[$i][1]
	Local $BackupPath = $ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $Files[$i][0]
	If $Mode = "backup" Then
		FileMove($FilePath, $FilePath & '.AltLauncher-Backup', $FC_OVERWRITE + $FC_CREATEPATH)
		FileCopy($BackupPath, $FilePath, $FC_OVERWRITE + $FC_CREATEPATH)
	ElseIf $Mode = "restore" Then
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
Func EnableChecks()
	Global $EarlyExitCheck
	AdlibRegister("EarlyExitCheck", 1000)
	OnAutoItExitRegister("OnExit")
EndFunc   ;==>EnableChecks
Func EarlyExitCheck()
	If _IsPressed("1B") Then ;Escape Key
		$EarlyExitCheck += 1
	Else
		$EarlyExitCheck = 0
	EndIf
	If $EarlyExitCheck >= 5 Then
		ProgressSet(100, "Early Exit Triggered!")
		doExit()
	EndIf
EndFunc   ;==>EarlyExitCheck
Func OnExit()
	doExit(True)
EndFunc   ;==>OnExit
Func doExit($immediately = False)
	OnAutoItExitUnRegister("OnExit")
	AdlibUnRegister("EarlyExitCheck")
	WinActivate($Title)
	WinSetOnTop($Title, "", $WINDOWS_ONTOP)
	If $immediately = False Then Sleep(1000)
	Restore()
	Exit Sleep(($immediately = True) ? 0 : 3000)
EndFunc   ;==>doExit
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
	If $AutoDetectUbisoftID[0] = 1 Then
		RegWrite("HKCU\Environment", "UbisoftID", "REG_SZ", $AutoDetectUbisoftID[1])
	Else
		RegWrite("HKCU\Environment", "UbisoftID", "REG_SZ", InputBox($Title, "Enter your Ubisoft ID." & @CRLF & @CRLF & "Consult the readme.md on how to obtain this." & @CRLF))
	EndIf
	Exit MsgBox(0, $Title, "Setup Complete. Please relaunch AltLauncher.")
EndFunc   ;==>Setup
