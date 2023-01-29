Set-StrictMode -Version 'Latest'

Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadLineKeyHandler -Key 'Tab' -Function 'MenuComplete'


if ($IsWindows) {
    $Env:MSYSTEM = 'MSYS'
    $Env:Path = @(
        Join-Path -- "$Env:APPDATA" 'bin'
        "$Env:Path"
        Join-Path -- "$Env:SystemDrive" 'msys64' 'ucrt64' 'bin'
        Join-Path -- "$Env:SystemDrive" 'msys64' 'usr' 'bin'
    ) | Join-String -Separator ';'
}


oh-my-posh init pwsh --config (Join-Path -- ($IsWindows ? "$Env:LOCALAPPDATA" : "$Env:XDG_CONFIG_HOME") 'posh.yml') | Invoke-Expression
