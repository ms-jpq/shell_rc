#!/usr/bin/env -S -- powershell

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'


function basic {
    # UTC BIOS
    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -Type 'DWord' -Value 1

    # Allow Scripting
    Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted'

    # Private Firewall
    Set-NetConnectionProfile -NetworkCategory 'Private'

    # Allow Ping
    Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv4-In)' -Enabled "$true"
    Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv6-In)' -Enabled "$true"

    # NoPassword
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LimitBlankPasswordUse' -Type 'DWord' -Value 0

    # Show File Ext
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type 'DWord' -Value 0
    # Stop-Process -Force -ProcessName: 'Explorer'

    # Disable Defrag
    Disable-ScheduledTask -TaskName 'Microsoft\Windows\Defrag\ScheduledDefrag'
}


function ssh {
    Add-WindowsCapability -Online -Name 'OpenSSH.Server'
    Set-Service -Name 'sshd' -StartupType 'Automatic' -Status 'Running'

    $WIN_ADMIN = if (!(Test-Path variable:global:IsWindows) -Or $IsWindows) {
        $C_USER = [Security.Principal.WindowsIdentity]::GetCurrent()
        $USER_OBJ = New-Object Security.Principal.WindowsPrincipal($C_USER)
        $USER_OBJ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        0
    }

    $SSH_KEY_DST = if ($WIN_ADMIN) {
        Join-Path -Path "$ENV:PROGRAMDATA" 'ssh' | Join-Path -ChildPath 'administrators_authorized_keys'
    }
    else {
        Join-Path -Path '~' '.ssh' | Join-Path -ChildPath 'authorized_keys'
    }
    Write-Output "$SSH_KEY_DST"

    $SSH_KEY_SRC = New-TemporaryFile
    $GITHUB_USER = Read-Host -Prompt 'Github User'
    Invoke-WebRequest -OutFile $SSH_KEY_SRC -Uri "https://github.com/$GITHUB_USER.keys"
    Move-Item -Force -Path $SSH_KEY_SRC -Destination $SSH_KEY_DST


    if ($WIN_ADMIN) {
        $ACL = Get-Acl $SSH_KEY_DST
        $ACL.SetAccessRuleProtection($true, $false)
        $ADMIN_RULE = New-Object system.security.accesscontrol.filesystemaccessrule('Administrators', 'FullControl', 'Allow')
        $SYS_RULE = New-Object system.security.accesscontrol.filesystemaccessrule('SYSTEM', 'FullControl', 'Allow')
        $ACL.SetAccessRule($ADMIN_RULE)
        $ACL.SetAccessRule($SYS_RULE)
        $ACL | Set-Acl

        Write-Output '--> ACL SET'
    }
}


function rdp {
    # No Sleep on AC
    POWERCFG /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0

    # RDP On
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Type 'DWord' -Value 0

    # RDP Firewall
    Enable-NetFirewallRule -Name 'RemoteDesktop*'
}


basic
rdp
ssh

Write-Output '--> DONE'

# Remove-Item -Path Function:basic Function:winrm Function:ssh Function:rdp
