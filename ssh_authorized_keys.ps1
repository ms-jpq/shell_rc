#!/usr/bin/env pwsh
#Requires -PSEdition Core


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true;


$WIN_ADMIN = if ($IsWindows) {
  $C_USER = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $USER_OBJ = New-Object Security.Principal.WindowsPrincipal($C_USER)
  $USER_OBJ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
  False
}

$SSH_KEY_DEST = if ($WIN_ADMIN) {
  Join-Path "$ENV:PROGRAMDATA" 'ssh' 'administrators_authorized_keys'
} else {
  Join-Path '~' '.ssh' 'authorized_keys'
}
Write-Output "$SSH_KEY_DEST"


$SSH_KEY_SRC = New-TemporaryFile
$GITHUB_USER = Read-Host -Prompt 'Github User'
Invoke-WebRequest -OutFile "$SSH_KEY_SRC" -Uri "https://github.com/$GITHUB_USER.keys"
Move-Item -Force -Path "$SSH_KEY_SRC" -Destination "$SSH_KEY_DEST"


if ($WIN_ADMIN) {
  $ACL = Get-Acl "$SSH_KEY_DEST"
  $ACL.SetAccessRuleProtection($true, $false)
  $ADMIN_RULE = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators", "FullControl", "Allow")
  $SYS_RULE = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM", "FullControl", "Allow")
  $ACL.SetAccessRule($ADMIN_RULE)
  $ACL.SetAccessRule($SYS_RULE)
  $ACL | Set-Acl
}

