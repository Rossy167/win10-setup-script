# win10-setup-script

A script for setting up a Windows 10 gaming PC at home from a fresh install. The goal is a clean, minimal, debloated system, configured the way I like it, without babysitting a dozen manual steps.

## Repo structure

```
win10-setup-script/
├── build.ps1              # main entry point — run this
├── ooshutup10.cfg          # config for O&O ShutUp10 (see note below)
└── scripts/
    ├── DebloatWin10.ps1           # removes Windows 10 bloatware
    ├── disableconsumerfeatures.reg # disables Candy Crush, Solitaire, etc. from Start Menu
    ├── uninstall_onedrive.bat      # fully uninstalls OneDrive
    ├── taskbar.bat                 # removes the search box from the taskbar
    └── InstallChoco.ps1            # installs the Chocolatey package manager
```

## What it does

**Updates.** Stages Windows updates first. This doesn't do a full proper update cycle, but PowerShell's already running as admin at this point, so it's a reasonable time to kick it off.

**Debloat.** Runs the three scripts in `scripts/` above: strips out the built-in bloatware, disables the Start Menu's promoted/consumer apps, and removes OneDrive (which is surprisingly hard to get rid of properly).

**Cleanup.** Removes startup items — I want nothing launching on login, which is a bit of a losing battle but worth attempting — disables indexing on all drives (doesn't meaningfully speed anything up, mostly just extra wear on the disk for no benefit), and removes leftover scheduled tasks and telemetry services.

**Appearance.** Removes the taskbar search box, turns on dark mode, and enables file extensions in Explorer by default.

**Installs.** Installs Chocolatey, then a fixed list of everything I want on a fresh machine: browser, utilities, messaging, Steam, dev tools. This list will drift over time as my preferences change.

**Finishing up.** Cleans up desktop shortcuts left behind by the installers, sets `JAVA_HOME`/`JRE_HOME` (thanks, Minecraft, for making Java unavoidable), applies a couple of privacy tweaks via O&O ShutUp10, sets up WSL with Debian, adds a couple of PowerShell profile functions I use often, and restarts once everything's settled.

## Usage

On a fresh Windows 10 install, extract this repo anywhere, then:

1. Press the Windows key and type `powershell`
2. Right-click **PowerShell** → **Run as administrator**
3. Run:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope CurrentUser
   .\build.ps1
   ```

> This is a personal script that makes real changes to the registry, installed apps, and system services. Read through `build.ps1` and the files in `scripts/` before running it on anything you care about.

## Getting Windows 10

Use the [Windows Media Creation Tool](https://www.microsoft.com/software-download/windows10) if you need an installer.

## A note on testing

I don't currently have a Windows machine to run this end-to-end. The logic has been checked carefully and a few real bugs have been fixed along the way, but it hasn't been verified start-to-finish on real hardware since. If you hit an issue, please open one — I'll take a look even without a live Windows box to reproduce on.

## O&O ShutUp10

Privacy tweaks are applied via [O&O ShutUp10](https://www.oo-software.com/en/shutup10), using `ooshutup10.cfg`.

O&O has rewritten this app more than once since I first set this up, and its tweak category codes have changed numbering schemes along the way. If your settings don't seem to be applying, open `OOSU10.exe`'s GUI once, set your preferences there, and re-export the config — that's more reliable than trying to keep this file hand-synced with whatever version O&O currently ships.

## Why not just use WinUtil / Windows10Debloater / etc.?

Good question — those are more comprehensive and more actively maintained. This isn't trying to compete with them. It's the specific set of tweaks and installs I run on my own machines, kept small enough that I know exactly what every line does. If you want a general-purpose, actively maintained tool, I'd genuinely point you to one of these instead:

* [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil)
* [Windows10Debloater](https://github.com/Sycnex/Windows10Debloater)
* [Windows11Debloater](https://github.com/teeotsa/windows-11-debloat)
* [O&O AppBuster](https://www.oo-software.com/en/ooappbuster)
* [Optimizer](https://github.com/hellzerg/optimizer)
* [Bloatynosy](https://github.com/builtbybel/Bloatynosy)

## Credits

* [Sycnex/Windows10Debloater](https://github.com/Sycnex/Windows10Debloater) — the base for `DebloatWin10.ps1`
