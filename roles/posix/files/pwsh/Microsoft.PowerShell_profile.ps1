Set-StrictMode -Version 'Latest'

Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadlineKeyHandler -Key 'Tab' -Function 'MenuComplete'


$Env:MSYSTEM = 'MSYS'
$Env:Path = @(
  Join-Path -- "$Env:APPDATA" 'bin'
  "$Env:Path"
  Join-Path -- "$Env:SystemDrive" 'msys64' 'ucrt64' 'bin'
  Join-Path -- "$Env:SystemDrive" 'msys64' 'usr' 'bin'
) | Join-String -Separator ';'


oh-my-posh init pwsh --config (Join-Path -- ($IsWindows ? "$Env:LOCALAPPDATA" : "$XDG_CONFIG_HOME") 'posh.yml') | Invoke-Expression
