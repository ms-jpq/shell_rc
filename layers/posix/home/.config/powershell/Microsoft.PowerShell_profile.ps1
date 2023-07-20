#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'

Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'


if ($IsWindows) {
    $Env:MSYSTEM = 'MSYS'
    $Env:Path = @(
        Join-Path -- $Env:APPDATA 'bin'
        $Env:Path
        Join-Path -- $Env:SystemDrive 'msys64' 'ucrt64' 'bin'
        Join-Path -- $Env:SystemDrive 'msys64' 'usr' 'bin'
    ) | Join-String -Separator ([IO.Path]::PathSeparator)
}


oh-my-posh init pwsh --config (Join-Path -- ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) 'posh' 'config.yml') | Invoke-Expression
