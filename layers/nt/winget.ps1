#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

$has_pkg = $IsWindows ? (Get-AppPackage -name 'Microsoft.DesktopAppInstaller') : $false

if (!$has_pkg) {
    if ($IsWindows) {
        Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    }

    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $latest = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1

    if ($IsWindows) {
        Add-AppxPackage -Path $latest.browser_download_url
    }
    else {
        Write-Host -- $latest.browser_download_url
    }
}
