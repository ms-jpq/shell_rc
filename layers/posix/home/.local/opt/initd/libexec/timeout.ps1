#!/usr/bin/env -S -- powershell -nologo -noprofile

Set-StrictMode -Version 'Latest'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

$pf = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
$env = Join-Path -Path $pf "Git" | Join-Path -ChildPath "usr" | Join-Path -ChildPath "bin" | Join-Path -ChildPath "env.exe"
$proc = Start-Process -PassThru -NoNewWindow -FilePath $env -ArgumentList $args[1..($args.Length - 1)]

if ($proc.ExitCode -eq $null) {
    Wait-Process -Id $proc.Id -Timeout $args[0]
}

exit $proc.ExitCode
