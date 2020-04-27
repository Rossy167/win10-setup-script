# run this:
    # Set-Location $wherever-you-downloaded-the-setup-script
    # Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    # .\build.ps1


# pay lip service to the idea of updates while we're at it

Install-PackageProvider NuGet 
Install-Module PSWindowsUpdate 
Get-WindowsUpdate -ForceDownload
Get-WindowsUpdate -ForceInstall

# debloat 

.\scripts\DebloatWin10.ps1
.\scripts\disableconsumerfeatures.reg
.\scripts\uninstall_onedrive.bat

# remove start up items

$properties = Get-Item -path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty property
$properties | ForEach-Object { Remove-ItemProperty -path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -name $_ }

$properties = Get-Item -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty property
$properties | ForEach-Object { Remove-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -name $_ }

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

# install all wanted packages (basically rebloat ngl)

.\scripts\InstallChoco.ps1

$packages = @('sysinternals', 'chromium', 'github-desktop', 'firefox', 'steam', 'vscode', 'javaruntime', 'jdk11', 'vlc', '7zip', 'qbittorrent', 'python', 'discord', 'notepad++')
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
      
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\AppID\SmartScreenSpecific" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable | out-null
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable | out-null

# disable services

cmd /c sc config DiagTrack start= disabled | out-null
cmd /c sc config dmwappushservice start= disabled | out-null
cmd /c sc config diagnosticshub.standardcollector.service start= disabled | out-null
cmd /c sc config TrkWks start= disabled | out-null
cmd /c sc config WMPNetworkSvc start= disabled | out-null # Shouldn't exist but just making sure ...
Set-Content C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl -Value "" -Force

# mess with the screwey windows update and delivery settings

New-ItemProperty -ErrorAction SilentlyContinue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DownloadMode" -PropertyType DWORD -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\" -Name "SystemSettingsDownloadMode" -Value 0 | Out-Null
Set-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" -Name "SystemPaneSuggestionsEnabled" -Value 0 | Out-Null

# o and o stuff
$path = Get-Location
$path = $path.path + "\OOSU10.exe"
Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $path
Start-Sleep -Seconds 15
.\OOSU10.exe ooshutup10.cfg /silent /nosrp

#Restart PC
Write-Host 'Restarting in 30 seconds'
Start-Sleep -Seconds 30
Restart-Computer -Force
