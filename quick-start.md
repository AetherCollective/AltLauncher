
## 1.  Download AltLauncher and place it next to your game’s EXE.

Download: [link](https://github.com/AetherCollective/AltLauncher/releases/latest)  
**AltLauncher.Updater.exe** is optional.
  -   If you launch your game through the updater, it will silently update **AltLauncher.exe** before starting the game.
  -   Use it if you always want the newest version automatically.

---

## 2.  Configure Steam to launch your game through AltLauncher.
You only need to do this once per game.

> For Steam games:

1.  Right‑click the game => Properties
2.  In Launch Options, enter the full path to AltLauncher.exe (or the updater), followed by: `-- %command%`

Example: `"C:\Program Files (x86)\Steam\steamapps\common\Hollow Knight Silksong\AltLauncher.Updater.exe" -- %command%`

> For non‑Steam shortcuts:
  - Put the full path to AltLauncher.exe (or the updater) in the Target box.  
  - Do NOT add `-- %command%` for non‑Steam games.

## 3. Run once for setup.

AltLauncher needs to set up before being used. Simply run it to be guided through the process.

## 4. Launch the game, pick your user, and enjoy.

AltLauncher will handle swapping saves and configs automatically. If you run into an error, [let us know](https://github.com/AetherCollective/AltLauncher/issues/new/choose)!

## Extra: Switching users mid‑play

If one user started the session and another finished it, and you need to save under the other user, hold Shift while the game closes.
AltLauncher will prompt you to choose which user to save the session as.
