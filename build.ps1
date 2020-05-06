# run this:
    # Set-Location $wherever-you-downloaded-the-setup-script
    # Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    # .\build.ps1

# what do we call it
$pcname = Read-Host -Prompt 'What do you want to call your PC? '
Rename-Computer -NewName $pcname -PassThru | Out-Null

# pay lip service to the idea of updates while we're at it

Install-PackageProvider NuGet 
Install-Module -Name PendingReboot -Force
Install-Module PSWindowsUpdate 
Get-WindowsUpdate -ForceDownload
Get-WindowsUpdate -ForceInstall

# debloat 

.\scripts\DebloatWin10.ps1
.\scripts\disableconsumerfeatures.reg
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
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0

.\scripts\taskbar.bat

$Bags = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
$DLID = '{885A186E-A440-4ADA-812B-DB871B942259}'
(Get-ChildItem $bags -recurse | Where-Object PSChildName -like $DLID ) | Remove-Item
 Get-Process explorer | Stop-Process

# install all wanted packages (basically rebloat ngl)

.\scripts\InstallChoco.ps1

$packages = @('chromium', 'github-desktop', 'firefox', 'steam', 'vscode', 'javaruntime', 'jdk11', 'vlc', '7zip', 'qbittorrent', 'python', 'discord', 'notepad++')
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

$properties = Get-Item -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty property
$properties | ForEach-Object { Remove-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -name $_ }

# o and o stuff
$path = Get-Location
$path = $path.path + "\OOSU10.exe"
Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $path
Start-Sleep -Seconds 15
.\OOSU10.exe ooshutup10.cfg /silent /nosrp

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
}" -Force

# enable bash
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Invoke-WebRequest -Uri https://aka.ms/wsl-debian-gnulinux -OutFile c:\linux.appx -UseBasicParsing
$location = get-location | Select-Object -ExpandProperty path
Set-Location C:\
Add-AppxPackage .\linux.appx
Remove-Item linux.appx
Set-Location $location 

#Restart PC
$rebootPending = Test-PendingReboot | Select-Object -ExpandProperty isrebootpending
if ($rebootPending) {
	Write-Host 'Restarting in 30 seconds'
	Start-Sleep -Seconds 30
	Restart-Computer -Force
}
