tasklist | find /i "Launcher.exe" >nul 2>&1
IF ERRORLEVEL 1 (
Echo Launching Ubisoft Connect *REQUIRED*...
"C:\Path\To\Launcher.exe"
timeout /T 15 /NOBREAK >Nul
)