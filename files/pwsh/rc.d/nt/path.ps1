$Env:MSYSTEM = 'MSYS'
$Env:Path = @(
  Join-Path -- "$Env:APPDATA" 'bin'
  "$Env:Path"
  Join-Path -- "$Env:SystemDrive" 'msys64' 'ucrt64' 'bin'
  Join-Path -- "$Env:SystemDrive" 'msys64' 'usr' 'bin'
) | Join-String -Separator ';'
