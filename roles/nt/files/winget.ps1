#!/usr/bin/env pwsh

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

foreach ($pkg in $args) {
  winget list --id $pkg
  if ($?) {
    winget upgrade --id $pkg
  } else {
    winget install --id $pkg
  }
}
