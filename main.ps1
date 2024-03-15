#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'
$PSNativeCommandUseErrorActionPreference = $true


if (($index = [Array]::IndexOf($args, '--')) -eq -1) {
    $index = $args.Length
}
$hosts = $args[0..($index - 1)]
$argv = ($index + 1 -ge $args.Length) ? @() : $args[($index + 1)..$($args.Length - 1)]


$bsh = ('--norc', '--noprofile', '-Eeuo', 'pipefail', '-O' , 'dotglob' , '-O', 'nullglob' , '-O', 'extglob', '-O', 'failglob', '-O', 'globstar')
$ssh = @(
    'ssh',
    '-o', 'ClearAllForwardings=yes',
    '-o', 'ControlMaster=auto',
    '-o', "ControlPath=$PWD/var/tmp/%C"
)
