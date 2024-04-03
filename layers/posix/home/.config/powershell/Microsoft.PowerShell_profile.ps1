#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'

$Env:SHELL = (Get-Command -Name pwsh).Path


Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'

Set-PSReadLineOption -HistoryNoDuplicates -HistorySavePath (Join-Path -Path $HOME '.local' 'state' 'shell_history' 'pwsh')

$appdata = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
$pf = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)

if ($IsWindows) {
    if ($null -eq $Env:MSYSTEM) {
        $Env:MSYSTEM = 'MSYS'
    }
    if ($null -eq $Env:MSYS) {
        $Env:MSYS = 'winsymlinks:nativestrict'
    }
    $Env:Path = @(
        Join-Path -Path $appdata 'bin'
        Join-Path -Path $pf 'Git' 'usr' 'bin'
        $Env:Path
    ) | Join-String -Separator ([IO.Path]::PathSeparator)
}

if ($null -eq $Env:TZ) {
    $tz = ""
    [TimeZoneInfo]::TryConvertWindowsIdToIanaId((Get-TimeZone).Id, [ref] $tz) | Out-Null
    if (! $null -eq $tz) {
        $Env:TZ = $tz
    }
    Remove-Variable -Name tz
}

if ($null -eq $Env:XDG_CONFIG_HOME) {
    $Env:XDG_CONFIG_HOME = $IsWindows ? $Env:LOCALAPPDATA : (Join-Path -Path $HOME '.config')
}

if ($null -eq $Env:XDG_DATA_HOME) {
    $Env:XDG_DATA_HOME = $IsWindows ? $Env:LOCALAPPDATA : (Join-Path -Path $HOME '.local' 'share')
}

if ($null -eq $Env:XDG_STATE_HOME) {
    $Env:XDG_STATE_HOME = $IsWindows ? $Env:TEMP : (Join-Path -Path $HOME '.local' 'state')
}

if ($null -eq $Env:XDG_CACHE_HOME) {
    $Env:XDG_CACHE_HOME = $IsWindows ? $Env:TEMP : (Join-Path -Path $HOME '.cache')
}

oh-my-posh init pwsh --config (Join-Path -Path $appdata 'posh' 'config.yml') | Invoke-Expression

Remove-Variable -Name appdata
Remove-Variable -Name pf
