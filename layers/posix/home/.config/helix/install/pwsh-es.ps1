#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSStyle.OutputRendering = 'PlainText'

$uri = 'https://github.com/PowerShell/PowerShellEditorServices/releases/latest/download/PowerShellEditorServices.zip'

$tmp = $Env:RUN
$out = Split-Path -Leaf -Path $uri

if ((-not ($null -eq $Env:CI)) -and $IsMacOS) {
    exit
}

Invoke-WebRequest -Uri $uri -OutFile $out
Expand-Archive -Force -DestinationPath $tmp -Path $out

if (Test-Path -Path $Env:LIB) {
    Remove-Item -Recurse -Force -Path $Env:LIB
}

Copy-Item -Recurse -Force -Path $tmp -Destination $Env:LIB
