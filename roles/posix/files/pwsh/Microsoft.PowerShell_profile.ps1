Set-StrictMode -Version 'Latest'

Set-PSReadLineOption -EditMode 'Emacs'
Set-PSReadlineKeyHandler -Key 'Tab' -Function 'MenuComplete'
oh-my-posh init pwsh --config (Join-Path -- "$LOCALAPPDATA" 'posh.yml') | Invoke-Expression
