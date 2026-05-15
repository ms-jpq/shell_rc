# LaunchD

- https://www.launchd.info/

- https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html

- https://www.manpagez.com/man/5/launchd.plist/

- https://gist.github.com/dabrahams/4092951

## Start

Note: `--` is harmful

```bash
launchctl kickstart gui/501/org.gnupg.gpg-agent
```

## Stop

```bash
launchctl stop org.gnupg.gpg-agent
```

## Restart

Note: `-k` will not start the service if not already running

```bash
launchctl kickstart -k '<domain-target>/<service-id>'
```

# os_log

## systemd-cat

```bash
printf -- '%s\n' '<hola>' | logger -t '<tag>'
```

## Tail

```bash
log stream --process logger --info --debug
```
