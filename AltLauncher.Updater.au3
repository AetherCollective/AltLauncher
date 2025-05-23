#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltLauncher.Updater.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.1.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Math.au3>

; Define URLs
Global $versionUrl = "https://github.com/AetherCollective/AltLauncher/raw/refs/heads/main/VERSION" ; URL with the online version
Global $updateUrl = "https://github.com/AetherCollective/AltLauncher/releases/latest/download/AltLauncher.exe" ; URL for the new EXE

; Fetch Online Version
Func GetOnlineVersion()
	Local $onlineVersion = InetRead($versionUrl)
	If @error Then Exit MsgBox(16, "AltLauncher.Updater", "Error: Failed to fetch online version.")
	Return StringStripCR(StringStripWS(BinaryToString($onlineVersion), 8)) ; Remove extra whitespace
EndFunc   ;==>GetOnlineVersion

; Compare Versions
Func IsNewerVersion($localVersion, $onlineVersion)
	Local $localParts = StringSplit($localVersion, ".")
	Local $onlineParts = StringSplit($onlineVersion, ".")
	For $i = 1 To _Min($localParts[0], $onlineParts[0])
		If Number($onlineParts[$i]) > Number($localParts[$i]) Then Return True
		If Number($onlineParts[$i]) < Number($localParts[$i]) Then Return False
	Next
	Return $onlineParts[0] > $localParts[0] ; Compare number of parts
EndFunc   ;==>IsNewerVersion

; Prompt and Update
Func UpdateProgram($updateUrl)
	; Download New EXE
	Local $tempFile = @TempDir & "\AltLauncher.exe"
	InetGet($updateUrl, $tempFile, 1)
	If @error Then
		MsgBox(16, "AltLauncher.Updater", "Error: Failed to download the update.")
		Exit
	EndIf

	; Replace Current EXE
	FileMove($tempFile, @ScriptDir & "\AltLauncher.exe", 9)
EndFunc   ;==>UpdateProgram

; Main Script Logic
Local $localVersion = FileGetVersion(@ScriptDir & "\AltLauncher.exe") ; Replace with your local version
Local $onlineVersion = GetOnlineVersion()
If IsNewerVersion($localVersion, $onlineVersion) Then UpdateProgram($updateUrl)
ShellExecute(@ScriptDir & "\AltLauncher.exe", $cmdlineraw) ; Restart the application
