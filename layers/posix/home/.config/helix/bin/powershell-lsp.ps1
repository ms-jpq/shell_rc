#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

$root = $IsWindows ? $Env:TEMP : (Join-Path -Path $HOME '.cache')
$lib = Join-Path -Path "$root" 'helix-rt' 'more' 'pwsh-es.ps1' 'lib'
$tmp = [IO.Directory]::CreateTempSubdirectory()

$argv = @(
    Join-Path -Path $lib 'PowerShellEditorServices' 'Start-EditorServices.ps1'
    '-BundledModulesPath', $lib
    '-FeatureFlags', '@()'
    '-AdditionalModules', '@()'
    '-Stdio'
    '-HostName', 'nvim'
    '-HostProfileId', '0'
    '-HostVersion', '1.0.0'
    '-LogLevel', 'Normal'
    '-LogPath', (Join-Path -Path $tmp 'powershell_es.log')
    '-SessionDetailsPath', (Join-Path -Path $tmp 'powershell_es.session.json')
)

$Env:NOCOLOR = '1'
Switch-Process -- pwsh -NoProfile -NonInteractive -Command @argv
