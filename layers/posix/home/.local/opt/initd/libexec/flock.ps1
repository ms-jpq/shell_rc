#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

Set-Location -- $PSScriptRoot

$lock = $args | Select-Object -First 1
$argv = $args | Select-Object -Skip 1
$tmp = [System.IO.Path]::GetTempPath()
$f = Join-Path -Path $tmp "$lock"

while ($true) {
    try {
        $fd = New-Object -TypeName System.IO.FileStream -ArgumentList $f, ([System.IO.FileMode]::OpenOrCreate), ([System.IO.FileAccess]::ReadWrite), ([System.IO.FileShare]::None)
        try {

            & @argv
            exit $LastExitCode
        }
        finally {
            $fd.Close()
        }
    }
    catch {
        Start-Sleep -Milliseconds 88
    }
}
