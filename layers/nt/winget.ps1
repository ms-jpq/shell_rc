#!/usr/bin/env -S -- powershell

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$has_pkg = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'

if (!$has_pkg) {
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    Add-AppxPackage -Path 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx'

    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $bundle = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1
    $license = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('License1.xml') } | Select-Object -First 1

    Write-Host -- $bundle
    Write-Host -- $license
    
    $t_bundle = $bundle.browser_download_url | Split-Path -Leaf
    $t_license = $license.browser_download_url | Split-Path -Leaf

    Invoke-WebRequest -Uri $bundle.browser_download_url -OutFile $t_bundle
    Invoke-WebRequest -Uri $license.browser_download_url -OutFile $t_license

    Add-AppxProvisionedPackage -Online -PackagePath $t_bundle -LicensePath $t_license

    winget.exe list --accept-source-agreements
}
