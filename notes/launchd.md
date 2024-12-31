# LaunchD

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
