#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

Set-Location -- $PSScriptRoot

$lock = $args | Select-Object -First 1
$arg0 = $args | Select-Object -Skip 1 -First 1
$argv = $args | Select-Object -Skip 2
$tmp = [System.IO.Path]::GetTempPath()
$f = Join-Path -Path $tmp "$lock"

if (!$IsWindows) {
    exit 1
}

while ($true) {
    try {
        $fd = New-Object -TypeName System.IO.FileStream -ArgumentList $f, ([System.IO.FileMode]::OpenOrCreate), ([System.IO.FileAccess]::ReadWrite), ([System.IO.FileShare]::None)

        try {
            & $arg0 $argv
            exit $LastExitCode
        }
        finally {
            $fd.Close()
        }
    }
    catch [System.IO.IOException] {
        Write-Host -- $Error
        Start-Sleep -Milliseconds 88
    }
}
