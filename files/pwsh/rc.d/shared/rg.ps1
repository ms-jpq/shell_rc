$Env:RIPGREP_CONFIG_PATH = Join-Path -- ($IsWindows ? $Env:APPDATA : $Env:XDG_CONFIG_HOME) 'rg.conf'
