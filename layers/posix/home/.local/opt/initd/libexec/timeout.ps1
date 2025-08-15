#!/usr/bin/env -S -- powershell -nologo -noprofile

Set-StrictMode -Version 'Latest'
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

$proc = Start-Process -PassThru -NoNewWindow -FilePath $args[1] -ArgumentList $args[2..($args.Length - 1)]

if ($proc.ExitCode -eq $null) {
    Wait-Process -Id $proc.Id -Timeout $args[0]
}

exit $proc.ExitCode
