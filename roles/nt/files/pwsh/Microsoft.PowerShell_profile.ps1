Set-StrictMode -Version 'Latest'

Set-PSReadLineOption -EditMode 'Emacs'

function main {
  $Env:Path = "$(Join-Path $HOME 'local' 'bin');$Env:Path"
}

Remove-Item -Path Function:main

Invoke-Expression (&starship 'init' 'powershell')
