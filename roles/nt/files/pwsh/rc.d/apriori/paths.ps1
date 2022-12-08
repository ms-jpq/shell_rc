$Env:Path = @(
  Join-Path $Env:SystemDrive 'msys64' 'usr' 'bin'
  Join-Path $Env:SystemDrive 'msys64' 'ucrt64' 'bin'
  $Env:Path
) | Join-String -Separator ';'
