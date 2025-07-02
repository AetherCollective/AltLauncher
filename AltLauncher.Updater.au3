#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.Updater.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.1.0.3
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Math.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <InetConstants.au3>
#include <StringConstants.au3>
#include "Include\JSON.au3"
Global $versionUrl = "https://api.github.com/repos/AetherCollective/AltLauncher/tags?per_page=1"
Global $updateUrl = "https://github.com/AetherCollective/AltLauncher/releases/latest/download/AltLauncher.exe" ; URL for the new EXE
Func GetOnlineVersion()
	AdlibRegister("StallCheck", 5000)
	$hDownload = InetGet($versionUrl, @TempDir & "\AltLauncher.json", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
	Do
		Sleep(250)
	Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
	InetClose($hDownload)
	Global $Json = _JSON_Parse(FileRead(@TempDir & "\AltLauncher.json"))
	If @error Then Exit ShellExecute(@ScriptDir & "\AltLauncher.exe", $cmdlineraw)
	Return _Json_Get($Json, "[0].name")
EndFunc   ;==>GetOnlineVersion
Func IsNewerVersion($localVersion, $onlineVersion)
	Local $localParts = StringSplit($localVersion, ".")
	Local $onlineParts = StringSplit($onlineVersion, ".")
	For $i = 1 To _Min($localParts[0], $onlineParts[0])
		If Number($onlineParts[$i]) > Number($localParts[$i]) Then Return True
		If Number($onlineParts[$i]) < Number($localParts[$i]) Then Return False
	Next
	Return $onlineParts[0] > $localParts[0]
EndFunc   ;==>IsNewerVersion
Func UpdateProgram()
	Local $tempFile = @TempDir & "\AltLauncher.exe"
	InetGet($updateUrl, $tempFile, $INET_FORCERELOAD)
	If @error Then MsgBox($MB_ICONINFORMATION, "AltLauncher Updater", "Error: Failed to download the update. The update will be skipped this time.")
	FileMove($tempFile, @ScriptDir & "\AltLauncher.exe", $FC_OVERWRITE + $FC_CREATEPATH)
EndFunc   ;==>UpdateProgram
Func StallCheck()
	AdlibUnRegister("StallCheck")
	Switch MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_SETFOREGROUND, "AltLauncher Updater", "Updating is taking unusually long. This could be due to an outage. Would you like to skip updating this time?")
		Case $IDYES
			Exit ShellExecute(@ScriptDir & "\AltLauncher.exe", $cmdlineraw)
		Case $IDNO
			AdlibRegister("StallCheck", 20000)
	EndSwitch
EndFunc   ;==>StallCheck
Local $localVersion = FileGetVersion(@ScriptDir & "\AltLauncher.exe") ; Replace with your local version
Local $onlineVersion = GetOnlineVersion()
If IsNewerVersion($localVersion, $onlineVersion) Then UpdateProgram()
ShellExecute(@ScriptDir & "\AltLauncher.exe", $cmdlineraw) ; Restart the application
