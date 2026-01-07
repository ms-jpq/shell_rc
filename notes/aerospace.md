# ~/.config/aerospace/aerospace.toml

```toml
start-at-login = true
after-startup-command = ['layout tiles']
```

# ID mapping

```bash
osascript -e 'id of app "<app-name>"'
```

```toml
[[on-window-detected]]
if.app-id = 'org.mozilla.firefox'
run       = 'move-node-to-workspace 3'

[[on-window-detected]]
if.app-id = 'org.whispersystems.signal-desktop'
run       = 'move-node-to-workspace 5'

[[on-window-detected]]
if.app-id = 'com.tencent.xinWeChat'
run       = 'move-node-to-workspace 5'

[[on-window-detected]]
if.app-id = 'us.zoom.xos'
run       = 'move-node-to-workspace 7'
```
