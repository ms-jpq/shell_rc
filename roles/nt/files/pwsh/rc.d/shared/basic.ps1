$Env:PAGER = 'less'
$Env:LESS = @(
  '--quit-on-intr'
  '--quit-if-one-screen'
  '--mouse'
  '--RAW-CONTROL-CHARS'
  '--tilde'
  '--tabs=2'
  '--QUIET'
  '--ignore-case'
  '--no-histdups'
) | Join-String -Separator ' '
$Env:LESSHISTFILE = Join-Path $Env:TMP 'less-hist'

$Env:TIME_STYLE = 'long-iso'
$Env:EDITOR = 'nvim'
$Env:MANPAGER = 'nvim +Man!'

New-Alias -Force -Name 'cat' -Value 'bat'
