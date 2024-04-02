#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'

$Env:SHELL = (Get-Command -Name pwsh).Path


Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'

Set-PSReadLineOption -HistoryNoDuplicates -HistorySavePath (Join-Path -Path $HOME '.local' 'state' 'shell_history' 'pwsh')

$appdata = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
$pf = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)

if ($IsWindows) {
    $Env:MSYSTEM = 'MSYS'
    $Env:MSYS = 'winsymlinks:nativestrict'
    $Env:Path = @(
        Join-Path -Path $appdata 'bin'
        Join-Path -Path $pf 'Git' 'usr' 'bin'
        Join-Path -Path $pf 'Neovim' 'bin'
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

oh-my-posh init pwsh --config (Join-Path -Path $appdata 'posh' 'config.yml') | Invoke-Expression

Remove-Variable -Name appdata
Remove-Variable -Name pf
