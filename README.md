# win10-setup-script

## Introduction

A basic script for setting up a Windows 10 gaming PC at home. The key goal here is for it to be a clean and minimal install.

## Explanation

I figured it would be mostly useless to package my own custom .iso of Windows, since it's a 5GB file and for the most part the custom package removal doesn't really help a huge amount.

The core of this script is in the build.ps1 file.

The script starts by staging some updates, it doesn't really properly update, but I figured that we may as well do it while we are running Powershell as admin. It then runs some scripts that I have procurred and modified from around the internet. These scripts are located in the .\scripts\ directory.

    1. DebloaterWin10.ps1 - a fairly well known script that removes all sorts of bloat Win10 comes with

    2. disableconsumerfeatures.reg - a basic reg edit to disable Candy Crush, Solitaire etc from the Start Menu

    3. uninstall_onedrive.bat - uninstalls onedrive :O which is shockingly hard to do

After these scripts have ran we do some regediting to remove startup items. I want nothing on startup with this device. Which I know is a pipedream, but you know, close. We then disable indexing on all drives, which is one of those random things which doesn't really speed up the device but does wear and tear the HDDs for no reason. 

Taskbar.bat just removes the crappy search bar that doesn't do anything in the bottom left hand corner, making for a cleaner aesthetic. We edit the explorer settings so that we can view file extensions by default. 

Next we turn dark mode on. Then install choco and get it installing all the basics I want on a fresh windows installation. Which will change from time to time, but basically: a web browser, utilities, messaging and steam.

After that we're pretty much done. Just clean up the desktop from all the installations. Set Java to do it's thing since it doesn't do that itself for some reason, thanks Minecraft for forcing me to acknowledge Java exists. A teeny bit more cleanup, stopping Windows from running nonsense. Set a quick bit of policy silently in OandO.

Wait for everything to stop processing, and perform a restart to clean up the stragglers.

## TL;DR

On a fresh windows 10 build you can extract the contents of this repo and then run build.ps1 it makes things cleaner. 

To run it: 
* Press the Windows key
* Type "powershell"
* Right click on "powershell" and select "run as administrator"
* Paste the following: `Set-ExecutionPolicy unrestricted`
* Run `build.ps1`

## Download Windows 10
Use the [Windows media creation tool](https://www.microsoft.com/en-ca/software-download/windows10) to get a copy of Windows 10.

## O&O Shut Up 10
I used [O&O Shut Up 10](https://www.oo-software.com/en/shutup10) using the `ooshutup10.cfg` file as a parameter. 

## Resources Used (will add to later)
* https://github.com/Sycnex/Windows10Debloater
