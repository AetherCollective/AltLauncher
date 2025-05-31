#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.1.0.4
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_Before=cmd /c echo %fileversion% > "%scriptdir%\VERSION"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <File.au3>
#include <Misc.au3>
Opt("TrayIconHide", True)
Opt("ExpandEnvStrings", True)
Global $Title = "AltLauncher"

RegisterVariables()
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
Func ReadConfig()
	Global $Ini = @ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".ini"
	If Not FileExists($Ini) Then
		$SearchResults = _FileListToArrayRec(@ScriptDir, StringTrimRight(@ScriptName, 4) & ".ini", $FLTAR_FILES, $FLTAR_RECUR)
		If $SearchResults[0] = 1 Then $Ini = @ScriptDir & "\" & $SearchResults[0]
		If $SearchResults[0] <> 1 Then ExitMSG("AltLauncher.ini not found.")
	EndIf
	Global $Name = IniRead($Ini, "General", "Name", Null)
	Global $Path = IniRead($Ini, "General", "Path", Null)
	Global $Executable = IniRead($Ini, "General", "Executable", Null)
	Global $LaunchFlags = IniRead($Ini, "General", "LaunchFlags", Null)
	Global $MinWait = IniRead($Ini, "Settings", "MinWait", 0)
	Global $MaxWait = IniRead($Ini, "Settings", "MaxWait", 0)
	Global $ForbidDeletions = IniRead($Ini, "Settings", "ForbidDeletions", (EnvGet("AltLauncher_ForbidDeletions") <> "") ? EnvGet("AltLauncher_ForbidDeletions") : False)
	Global $ProfilesPath = IniRead($Ini, "Profiles", "Path", (EnvGet("AltLauncher_Path") <> "") ? EnvGet("AltLauncher_Path") : "C:\AltLauncher")
	Global $ProfilesSubPath = IniRead($Ini, "Profiles", "SubPath", EnvGet("AltLauncher_SubPath"))
EndFunc   ;==>ReadConfig
Func ProcessConfig()
	Global $Registry = ReadINISection($Ini, "Registry")
	Global $Directories = ReadINISection($Ini, "Directories")
	Global $Files = ReadINISection($Ini, "Files")
EndFunc   ;==>ProcessConfig
Func ProcessCMDLine()
	Global $Profile = (@Compiled And ($cmdlineraw <> "" And $cmdline[1] <> "--")) ? $cmdline[1] : FileRead($ProfilesPath & "\Selected Profile.txt")
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
	$OriginalFileList = _FileListToArrayRec($DirPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
	$BackupFileList = _FileListToArrayRec($BackupPath, "*", $FLTAR_FILES, $FLTAR_RECUR)
	If $Mode = "backup" Then
		If Not FileExists($DirPath) Then DirCreate($DirPath)
		If Not FileExists($BackupPath) Then DirCreate($BackupPath)
		DirMove($DirPath, $DirPath & '.AltLauncher-Backup', $FC_OVERWRITE)
		DirCopy($BackupPath, $DirPath, $FC_OVERWRITE)
	ElseIf $Mode = "restore" Then
		If $ForbidDeletions = "True" Then
			DirCopy($DirPath, $BackupPath, $FC_OVERWRITE)
		Else
			For $j = UBound($BackupFileList) - 1 To 1 Step -1
				If _ArraySearch($OriginalFileList, $BackupFileList[$j]) <> -1 Then
					_ArrayDelete($BackupFileList, $j)
				EndIf
			Next
			For $j = 1 To UBound($BackupFileList) - 1
				FileDelete($ProfilesPath & '\' & $Profile & '\' & $ProfilesSubPath & '\' & $Name & '\' & $BackupFileList[$j])
			Next
		EndIf
		DirRemove($DirPath, $DIR_REMOVE)
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
		If $ForbidDeletions = "true" Then
			FileMove($FilePath, $BackupPath, $FC_OVERWRITE + $FC_CREATEPATH)
		Else
			FileDelete($BackupPath)
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
