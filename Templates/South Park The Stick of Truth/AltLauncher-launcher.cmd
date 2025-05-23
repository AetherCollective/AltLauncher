tasklist | find /i "upc.exe" >nul 2>&1
IF ERRORLEVEL 1 (
Echo Launching Ubisoft Connect *REQUIRED*...
"C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe"
timeout /T 15 /NOBREAK >Nul
)