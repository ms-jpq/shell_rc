#!/usr/bin/env -S -- powershell

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$has_pkg = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'

if (!$has_pkg) {
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    Add-AppxPackage -Path 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx'

    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $latest = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1

    Write-Host -- $latest.browser_download_url
    Add-AppxPackage -Path $latest.browser_download_url
}
