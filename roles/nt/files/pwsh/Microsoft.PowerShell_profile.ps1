Set-StrictMode -Version 'Latest'


function main {
  Set-PSReadLineOption -EditMode 'Emacs'
  Set-PSReadlineKeyHandler -Key 'Tab' -Function 'MenuComplete'

  $Env:Path = "$(Join-Path $Env:LOCALAPPDATA 'bin');$Env:Path"
  $Env:RIPGREP_CONFIG_PATH = Join-Path $Env:APPDATA 'rg.conf'

  Invoke-Expression (&starship 'init' 'powershell')
}


Remove-Item -Path Function:main

