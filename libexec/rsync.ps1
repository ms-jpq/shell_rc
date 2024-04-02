#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

Get-ChildItem -Force -Recurse -Path $src | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length + 1)
    $sink = Join-Path -Path $dst $rel

    if ($_.PSIsContainer) {
        if (!(Test-Path -Path $sink)) {
            New-Item -Force -ItemType 'Directory' -Path $sink
        }
    }
    else {
        Copy-Item -Force -Path $_.FullName -Destination $sink
    }
}
