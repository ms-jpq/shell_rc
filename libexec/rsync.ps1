#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

Write-Output -- $src, $dst
$rows = Get-ChildItem -Force -Recurse -Path $src

foreach ($row in $rows) {
    $rel = $row.FullName.Substring($src.Length + 1)
    $sink = Join-Path -Path $dst $rel

    Write-Output -- $rel

    if ($row.PSIsContainer) {
        if (!(Test-Path -Path $sink)) {
            New-Item -Force -ItemType 'Directory' -Path $sink
        }
    }
    else {
        Copy-Item -Force -Path $row -Destination $sink
    }
}
