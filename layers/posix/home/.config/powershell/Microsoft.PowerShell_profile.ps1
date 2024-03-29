#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'

$Env:SHELL = (Get-Command -Name pwsh).Path


Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'

Set-PSReadLineOption -HistoryNoDuplicates -HistorySavePath (Join-Path -Path $HOME '.local' 'state' 'shell_history' 'pwsh')

$appdata = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)

if ($IsWindows) {
    $Env:MSYSTEM = 'MSYS'
    $Env:Path = @(Join-Path -Path $appdata 'bin' $Env:Path) | Join-String -Separator ([IO.Path]::PathSeparator)
}

if ($Env:TZ -eq $null) {
    $tz = ""
    [TimeZoneInfo]::TryConvertWindowsIdToIanaId((Get-TimeZone).Id, [ref] $tz) | Out-Null
    if (! $tz -eq $null) {
        $Env:TZ = $tz
    }
    Remove-Variable -Name tz
}

oh-my-posh init pwsh --config (Join-Path -Path $appdata 'posh' 'config.yml') | Invoke-Expression

Remove-Variable -Name appdata
