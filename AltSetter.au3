#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\AltLauncher.ico
#AutoIt3Wrapper_Outfile=Build\AltSetter.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.1.0.3
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <Math.au3>
Opt("GUIOnEventMode", True)
Opt("TrayIconHide", True)

$Profile = FileRead(@ScriptDir & "\Selected Profile.txt")

; Check for launch flag
If $CmdLine[0] > 0 Then
	$hFile = FileOpen(@ScriptDir & "\Selected Profile.txt", 2)
	FileWrite($hFile, $CmdLine[1])
	FileClose($hFile)
	Exit
EndIf

; Get list of folders in script directory
Local $aFolders = _FileListToArray(@ScriptDir, "*", $FLTA_FOLDERS)
If @error Then
	MsgBox(16, "Error", "No folders found in script directory.")
	Exit
EndIf

; Create GUI
Local $iButtonSpacing = 4
Local $iMaxButtonsPerColumn = 6
Local $iButtonWidth = 120
Local $iButtonHeight = 60

; Calculate window size based on number of buttons
Local $iNumColumns = Ceiling($aFolders[0] / $iMaxButtonsPerColumn)
Local $iNumRows = _Min($aFolders[0], $iMaxButtonsPerColumn)
Local $iWindowWidth = $iNumColumns * ($iButtonWidth + $iButtonSpacing) + $iButtonSpacing + $iButtonSpacing + 2
Local $iWindowHeight = ($iNumRows + 1) * ($iButtonHeight + $iButtonSpacing) - ($iButtonHeight / 2)

Local $hGUI = GUICreate("AltLauncher", $iWindowWidth, $iWindowHeight, -1, -1, $WS_SYSMENU)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CloseGUI")

; Create buttons
Local $iX = $iButtonSpacing
Local $iY = $iButtonSpacing
For $i = 1 To $aFolders[0]
	Local $hButton = GUICtrlCreateButton($aFolders[$i], $iX, $iY, $iButtonWidth, $iButtonHeight, $aFolders[$i] = $Profile ? $WS_BORDER + $WS_TABSTOP : $WS_TABSTOP)
	If GUICtrlSetOnEvent($hButton, "_ButtonClick") = 0 Then Exit MsgBox(0, "Error", "Can't register 'click' event for " & $aFolders[$i] & @CRLF & "[button]:" & $hButton)

	$iY += $iButtonHeight + $iButtonSpacing
	If Mod($i, $iMaxButtonsPerColumn) = 0 Then
		$iY = $iButtonSpacing
		$iX += $iButtonWidth + $iButtonSpacing
	EndIf
Next

GUISetState(@SW_SHOW)

; Main loop
While 1
	Sleep(100)
WEnd

; GUI close event handler
Func _CloseGUI()
	Exit
EndFunc   ;==>_CloseGUI

; Button click event handler
Func _ButtonClick()
	Local $restore = False
	Local $sButtonText = GUICtrlRead(@GUI_CtrlId)
	$hFile = FileOpen(@ScriptDir & "\Selected Profile.txt", 2)
	If $hFile = -1 Then
		$restore = True
		$attrib = FileGetAttrib(@ScriptDir & "\Selected Profile.txt")
		FileSetAttrib(@ScriptDir & "\Selected Profile.txt", "-H")
		$hFile = FileOpen(@ScriptDir & "\Selected Profile.txt", 2)
	EndIf
	FileWrite($hFile, $sButtonText)
	FileClose($hFile)
	If $restore = True Then FileSetAttrib(@ScriptDir & "\Selected Profile.txt", "+" & $attrib)
	If FileExists(@ScriptDir & "\" & $sButtonText & "\AltProfile.exe") Then
		ProcessClose("alienfx-gui.exe")
		ShellExecute(@ScriptDir & "\" & $sButtonText & "\AltProfile.exe")
	EndIf
	Exit
EndFunc   ;==>_ButtonClick
