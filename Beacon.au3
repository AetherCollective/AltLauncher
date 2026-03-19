#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\Beacon.exe
#AutoIt3Wrapper_Res_Description=Beacon for AltLauncher
#AutoIt3Wrapper_Res_Fileversion=0.1.0.0
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <TrayConstants.au3>
Opt("TrayAutoPause", 0)
Opt("TrayIconHide", 0)
Opt("TrayMenuMode", 1)
Opt("TrayOnEventMode", 1)

Global Const $ENV_PATH = "AltLauncher_BeaconPath"
Global Const $ENV_KILL = "AltLauncher_BeaconKill"
Global Const $BACKUP_KEY = "HKCU\Software\AltLauncher"
Global Const $sBeaconPath = @ScriptDir & "\AltLauncher"
Global Const $sEnvReg = $sBeaconPath & "\Environment.reg"
Global $bDrivePresent = True

If Not FileExists($sBeaconPath) Then DirCreate($sBeaconPath)

If RegRead("HKCU\Environment", $ENV_PATH) <> "" Then
	RegWrite("HKCU\Environment", $ENV_KILL, "REG_SZ", "1")
	Exit
EndIf

_ImportEnvironmentReg()

RegWrite("HKCU\Environment", $ENV_PATH, "REG_SZ", $sBeaconPath)
RegDelete("HKCU\Environment", $ENV_KILL)

TraySetToolTip($sBeaconPath)
TraySetIcon(@ScriptDir & "\Resources\AltLauncher_Beacon.ico")
TraySetClick(8)

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent($idExit, "_TrayExit")

AdlibRegister("_CheckKill", 250)
AdlibRegister("_CheckDrive", 1000)

TrayTip("AltLauncher", "Beacon is running!" & @CRLF & "Saves will be stored in: " & $sBeaconPath, 5, $TIP_ICONASTERISK)

While True
	Sleep(100)
WEnd

Func _ImportEnvironmentReg()
	If Not FileExists($sEnvReg) Then Return
	Local $sContent = FileRead($sEnvReg)
	Local $aMatches = StringRegExp($sContent, '"([^"]+)"=', 3)
	If @error Or UBound($aMatches) = 0 Then Return
	For $i = 0 To UBound($aMatches) - 1
		Local $sKey = $aMatches[$i]
		Local $sVal = RegRead("HKCU\Environment", $sKey)
		If @error Then
			RegWrite($BACKUP_KEY, $sKey & "|existed", "REG_DWORD", 0)
		Else
			RegWrite($BACKUP_KEY, $sKey, "REG_SZ", $sVal)
			RegWrite($BACKUP_KEY, $sKey & "|existed", "REG_DWORD", 1)
		EndIf
	Next
	RunWait(@ComSpec & ' /c reg import "' & $sEnvReg & '"', "", @SW_HIDE)
EndFunc   ;==>_ImportEnvironmentReg

Func _RestoreEnvironmentReg()
	Local $i = 1
	While True
		Local $sName = RegEnumVal($BACKUP_KEY, $i)
		If @error Then ExitLoop
		If StringInStr($sName, "|existed") Then
			$i += 1
			ContinueLoop
		EndIf
		If RegRead($BACKUP_KEY, $sName & "|existed") = 1 Then
			RegWrite("HKCU\Environment", $sName, "REG_SZ", RegRead($BACKUP_KEY, $sName))
		Else
			RegDelete("HKCU\Environment", $sName)
		EndIf
		$i += 1
	WEnd
	RegDelete($BACKUP_KEY)
EndFunc   ;==>_RestoreEnvironmentReg

Func _CheckDrive()
	Local $bNowPresent = FileExists($sBeaconPath)
	If $bNowPresent = $bDrivePresent Then Return
	$bDrivePresent = $bNowPresent
	If Not $bNowPresent Then
		TrayTip("AltLauncher", "Drive disconnected. Beacon is still active for this session.", 5, $TIP_ICONASTERISK)
	Else
		_ImportEnvironmentReg()
		RegWrite("HKCU\Environment", $ENV_PATH, "REG_SZ", $sBeaconPath)
		TrayTip("AltLauncher", "Drive reconnected.", 3, $TIP_ICONASTERISK)
	EndIf
EndFunc   ;==>_CheckDrive

Func _CheckKill()
	If RegRead("HKCU\Environment", $ENV_KILL) = "1" Then _Shutdown()
EndFunc   ;==>_CheckKill

Func _TrayExit()
	_Shutdown()
EndFunc   ;==>_TrayExit

Func _Shutdown()
	AdlibUnRegister("_CheckKill")
	AdlibUnRegister("_CheckDrive")
	_RestoreEnvironmentReg()
	RegDelete("HKCU\Environment", $ENV_PATH)
	RegDelete("HKCU\Environment", $ENV_KILL)
	TrayTip("AltLauncher", "Beacon has been stopped.", 3, $TIP_ICONASTERISK)
	Sleep(500)
	Exit
EndFunc   ;==>_Shutdown
