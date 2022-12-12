Set-StrictMode -Version 'Latest'


function main {
  $pwsh_targets = [Collections.ArrayList]@()
  $new_paths = [Collections.ArrayList]@()
  $new_mods = [Collections.ArrayList]@()

  $pwsh_targets.AddRange(@(
    'apriori'
  ))
  if ($IsWindows) {
    $pwsh_targets.Add('nt')
  }
  $pwsh_targets.AddRange(@(
    'shared'
    'aposteriori'
  ))

  $profile = Split-Path -- $PROFILE
  foreach ($target in $pwsh_targets) {
    $rcs = Join-Path -- $profile 'rc.d' $target
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

  $new_mods.Add($Env:PSModulePath)

  $Env:Path = $new_paths | Join-String -Separator ';'
  $Env:PSModulePath = $new_mods | Join-String -Separator ';'
}


main | Out-Null
Remove-Item -Path Function:main
