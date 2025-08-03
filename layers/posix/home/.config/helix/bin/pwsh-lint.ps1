#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

$root = $IsWindows ? $Env:TEMP : (Join-Path -Path $HOME '.cache')
$lib = Join-Path -Path "$root" 'helix-rt' 'more' 'pwsh-es.ps1' 'lib' 'PSScriptAnalyzer'
$analyzer = Join-Path -Path (Get-ChildItem -Path $lib -Filter '*') 'PSScriptAnalyzer.psm1'

Import-Module -- $analyzer
Invoke-ScriptAnalyzer -EnableExit -IncludeDefaultRules -Path "$args"
