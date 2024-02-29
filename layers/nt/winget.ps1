#!/usr/bin/env -S -- powershell -nologo -noprofile

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-PSDebug -Trace 1

$go = $($ENV:DOCKER -eq 1) -or !$(Get-AppPackage -name 'Microsoft.DesktopAppInstaller')

if ($go) {
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    Add-AppxPackage -Path 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx'

    # $vc = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    # $t_vc = $vc | Split-Path -Leaf

    # Write-Host -- $t_vc

    # Invoke-WebRequest -Uri $vc -OutFile $t_vc

    # Start-Process -Wait -FilePath $t_vc -ArgumentList '/install', '/quiet', '/norestart'

    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $bundle = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1
    $license = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('License1.xml') } | Select-Object -First 1

    Write-Host -- $bundle
    Write-Host -- $license

    $t_bundle = $bundle.browser_download_url | Split-Path -Leaf
    $t_license = $license.browser_download_url | Split-Path -Leaf

    Invoke-WebRequest -Uri $license.browser_download_url -OutFile $t_license
    Invoke-WebRequest -Uri $bundle.browser_download_url -OutFile $t_bundle

    Add-AppxProvisionedPackage -Online -PackagePath $t_bundle -LicensePath $t_license

    # $localappdata = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    # $location = Join-Path -Path $localappdata -ChildPath (Join-Path -Path 'Microsoft' -ChildPath (Join-Path -Path 'WindowsApps' -ChildPath 'winget.exe'))

    # foreach ($i in 1..60) {
    #     if (Test-Path -Path $location) {
    #         exit 0
    #     }

    #     Write-Host -- $i
    #     Start-Sleep -Seconds 1
    # }

    # throw "test -f $location"
    Start-Sleep -Seconds 9
}
