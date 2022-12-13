# #!/usr/bin/env pwsh

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'


# Disable Defrag
Disable-ScheduledTask -TaskName 'Microsoft\Windows\Defrag\ScheduledDefrag'


# Show File Ext
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type 'DWord' -Value 0
Stop-Process -Force -ProcessName: 'Explorer'


# Enabkle Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
