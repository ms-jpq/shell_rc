#!/usr/bin/env -S -- powershell

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
Set-PSDebug -Trace 1

$has_pkg = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'

if (!$has_pkg) {
    $vc_libs = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    $xaml_ui = 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx'

    $t_vc_libs = $vc_libs | Split-Path -Leaf
    $t_xaml_ui = $xaml_ui | Split-Path -Leaf

    Invoke-WebRequest -Uri $vc_libs -OutFile $t_vc_libs
    Invoke-WebRequest -Uri $xaml_ui -OutFile $t_xaml_ui

    Add-AppxPackage -Path $t_vc_libs
    Add-AppxPackage -Path $t_xaml_ui

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
}
