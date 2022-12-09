Set-StrictMode -Version 'Latest'


function main {
  #$Env:MSYS = 'winsymlinks:nativestrict'
  $Env:MSYSTEM = 'MSYS'

  $pwsh_targets = @(
    'apriori'
    'shared'
    'aposteriori'
  )

  $new_paths = [Collections.ArrayList]@()
  $new_mods = [Collections.ArrayList]@()

  foreach ($target in $pwsh_targets) {
    $rcs = Join-Path -- (Split-Path $PROFILE) 'rc.d' $target
    $fns = Join-Path -- $rcs 'fn'
    $rc_bin = Join-Path -- $rcs 'bin'

    if (Test-Path -PathType 'Container' $fns) {
      $new_mods.Add($fns)
    }

    foreach ($rc in @(Get-ChildItem -Path $rcs -Filter '*.ps1')) {
      . $rc
    }

    if (Test-Path -PathType Container $rc_bin) {
      $new_paths.Add($rc_bin)
    }
  }

  $new_paths.AddRange(@(
    Join-Path -- (Split-path -- $Env:APPDATA) 'bin'
    $Env:Path
    Join-Path -- $Env:SystemDrive 'msys64' 'ucrt64' 'bin'
    Join-Path -- $Env:SystemDrive 'msys64' 'usr' 'bin'
  ))
  $new_mods.Add($Env:PSModulePath)

  $Env:Path = $new_paths | Join-String -Separator ';'
  $Env:PSModulePath = $new_mods | Join-String -Separator ';'
}


main | Out-Null
Remove-Item -Path Function:main
