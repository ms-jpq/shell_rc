#!/usr/bin/env -S -- pwsh

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

foreach ($pkg in $args) {
    winget list --id $pkg
    if ($?) {
        winget upgrade --id $pkg
    }
    else {
        winget install --accept-package-agreements --accept-source-agreements --id $pkg
    }
}

exit $LASTEXITCODE
