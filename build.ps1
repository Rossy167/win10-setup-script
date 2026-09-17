# run this:
    # Set-Location $wherever-you-downloaded-the-setup-script
    # Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    # .\build.ps1

# what do we call it
$pcname = Read-Host -Prompt 'What do you want to call your PC? '
Rename-Computer -NewName $pcname -PassThru | Out-Null

# pay lip service to the idea of updates while we're at it

Install-PackageProvider NuGet -Force
Install-Module -Name PendingReboot -Force
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -ForceDownload
Get-WindowsUpdate -ForceInstall

# debloat 

.\scripts\DebloatWin10.ps1
reg import .\scripts\disableconsumerfeatures.reg
.\scripts\uninstall_onedrive.bat

function Disable-Indexing {
    Param($Drive)
    $obj = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter='$Drive'"
    $indexing = $obj.IndexingEnabled
    if("$indexing" -eq $True){
        write-host "Disabling indexing of drive $Drive"
        $obj | Set-WmiInstance -Arguments @{IndexingEnabled=$False} | Out-Null
    }
}

$drives = get-volume | Select-Object -ExpandProperty driveletter
$drives | ForEach-Object { Disable-Indexing $_":" }

# appearance

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 0
Set-ItemProperty $key HideFileExt 0
Set-ItemProperty $key ShowSuperHidden 1
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Force

.\scripts\taskbar.bat

$Bags = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
$DLID = '{885A186E-A440-4ADA-812B-DB871B942259}'
(Get-ChildItem $bags -recurse | Where-Object PSChildName -like $DLID ) | Remove-Item
 Get-Process explorer | Stop-Process

# install all wanted packages (basically rebloat ngl)

.\scripts\InstallChoco.ps1

$packages = @('chromium', 'autohotkey', 'github-desktop', 'firefox', 'steam', 'vscode', 'javaruntime', 'jdk11', 'vlc', '7zip', 'qbittorrent', 'python', 'discord', 'notepad++', 'pcsx2')
$packages | ForEach-Object {choco install $_ -y}
Write-Host 'Giving everything time to install'
Start-Sleep -Seconds 60

# remove all the shit that choco has dumped on the desktop

Remove-Item C:\Users\*\Desktop\*lnk -Force

# Set the java environment variables because it beats doing it manually

$path = 'C:\Program Files\Java'
$jdk = Get-ChildItem -Path $path -Filter "jdk*" | Select-Object -ExpandProperty FullName
$jre = Get-ChildItem -Path $path -Filter "jre*" | Select-Object -ExpandProperty FullName

setx /M JAVA_HOME $jdk
setx /M JRE_HOME $jre

# disable scheduled tasks
      
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\AppID\SmartScreenSpecific" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable | Out-Null
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable | Out-Null

# disable services

cmd /c sc config DiagTrack start= disabled | Out-Null
cmd /c sc config dmwappushservice start= disabled | Out-Null
cmd /c sc config diagnosticshub.standardcollector.service start= disabled | Out-Null
cmd /c sc config TrkWks start= disabled | Out-Null
cmd /c sc config WMPNetworkSvc start= disabled | Out-Null # Shouldn't exist but just making sure ...
Set-Content C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl -Value "" -Force

# mess with the screwey windows update and delivery settings

New-ItemProperty -ErrorAction SilentlyContinue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DownloadMode" -PropertyType DWORD -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\" -Name "SystemSettingsDownloadMode" -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" -Name "SystemPaneSuggestionsEnabled" -Value 0 | Out-Null

# remove start up items

$properties = Get-Item -path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty property
$properties | ForEach-Object { Remove-ItemProperty -path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -name $_ }

$properties = Get-Item -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run | Select-Object -ExpandProperty property
$properties | ForEach-Object { Remove-ItemProperty -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run -name $_ }

# o and o stuff
# Note: O&O rewrote ShutUp10 on .NET 8 as of v2.0, and its tweak category codes
# have changed numbering schemes multiple times over the years (this cfg is from
# the old S/P/Y/C/L/U/W/M/N/O scheme). Even ChrisTitusTech's WinUtil eventually
# dropped cfg-file automation for this exact reason — codes drift faster than
# anyone can track. /quiet is the one flag documented consistently across every
# version; if settings silently don't apply, the cfg itself likely needs
# regenerating: open OOSU10.exe's GUI once, set your preferences, and re-export.
$path = Get-Location
$path = $path.path + "\OOSU10.exe"
try {
    Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $path
    Start-Sleep -Seconds 15
    .\OOSU10.exe ooshutup10.cfg /quiet
} catch {
    Write-Host "O&O ShutUp10 step failed, skipping: $_"
}

# set dolphin config to not be in documents
New-Item -Path HKCU:\Software -Name 'Dolphin Emulator' -Force
Set-ItemProperty -Path 'HKCU:\Software\Dolphin Emulator' -Name "UserConfigPath" -Value 'D:\EmulatorLibrary\DolphinSettings\'

# add powershell profile, and some scripts i use regularly, will probs add more to later
New-Item -Path $profile -ItemType File -Force
Set-Content -Path $profile -Value "function Stop-AMDBloat {
    Get-Process | Where-Object processname -like *radeon* | Stop-Process
}

function fish {
    bash -c 'fish'
}

function Block-Steam {
        New-NetFirewallRule -Action block -Program 'C:\Program Files (x86)\Common Files\Steam\SteamService.exe' -Profile any -Direction Outbound -Displayname 'Block-Steam Rossy' | Out-Null
        New-NetFirewallRule -Action block -Program 'C:\Program Files (x86)\Steam\bin\cef\cef.win7x64\steamwebhelper.exe' -Profile any -Direction Outbound -Displayname 'Block-Steam Rossy' | Out-Null
        New-NetFirewallRule -Action block -Program 'C:\program files (x86)\steam\steam.exe' -Profile any -direction Outbound -Displayname 'Block-Steam Rossy' | Out-Null
        New-NetFirewallRule -Action block -Program 'C:\Program Files (x86)\Common Files\Steam\SteamService.exe' -Profile any -Direction Inbound -Displayname 'Block-Steam Rossy' | Out-Null
        New-NetFirewallRule -Action block -Program 'C:\Program Files (x86)\Steam\bin\cef\cef.win7x64\steamwebhelper.exe' -Profile any -Direction Inbound -Displayname 'Block-Steam Rossy' | Out-Null
        New-NetFirewallRule -Action block -Program 'C:\program files (x86)\steam\steam.exe' -Profile any -direction Inbound -Displayname 'Block-Steam Rossy' | Out-Null
}

function Unblock-Steam {
        Get-NetFirewallRule | Where-Object DisplayName -eq 'Block-Steam Rossy' | Remove-NetFirewallRule | Out-Null
}" -Force

# enable bash
# Old method manually sideloaded a .appx, which Microsoft's trust requirements now make unreliable.
# wsl --install is the officially supported equivalent and does the same job in one line.
wsl --install -d Debian --no-launch

#Restart PC
$rebootPending = Test-PendingReboot | Select-Object -ExpandProperty isrebootpending
if ($rebootPending) {
	Write-Host 'Restarting in 30 seconds'
	Start-Sleep -Seconds 30
	Restart-Computer -Force
}
