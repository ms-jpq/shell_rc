#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'

$Env:SHELL = (Get-Command -Name pwsh).Path


Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'

Set-PSReadLineOption -HistoryNoDuplicates -HistorySavePath (Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) '.local' 'state' 'shell_history' 'pwsh')

if ($IsWindows) {
    $Env:MSYSTEM = 'MSYS'
    $Env:Path = @(Join-Path -Path $Env:APPDATA 'bin' $Env:Path) | Join-String -Separator ([IO.Path]::PathSeparator)
}


oh-my-posh init pwsh --config (Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) 'posh' 'config.yml') | Invoke-Expression
