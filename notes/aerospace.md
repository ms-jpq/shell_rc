# ~/.config/aerospace/aerospace.toml

```toml
start-at-login = true
after-startup-command = ['layout tiles']
```

# ID mapping

```bash
osascript -e 'id of app "<app-name>"'
```

```bash
lsappinfo list
```

```toml
[[on-window-detected]]
if.app-id = 'net.kovidgoyal.kitty'
run       = 'move-node-to-workspace 1'

[[on-window-detected]]
if.app-id = 'org.mozilla.firefox'
run       = 'move-node-to-workspace 3'

[[on-window-detected]]
if.app-id = 'org.whispersystems.signal-desktop'
run       = 'move-node-to-workspace 4'

[[on-window-detected]]
if.app-id = 'com.tencent.xinWeChat'
run       = 'move-node-to-workspace 4'

[[on-window-detected]]
if.app-id = 'com.apple.Safari'
run       = 'move-node-to-workspace 5'

[[on-window-detected]]
if.app-id = 'us.zoom.xos'
run       = 'move-node-to-workspace 7'

[[on-window-detected]]
if.app-id = 'com.apple.iCal'
run       = 'move-node-to-workspace 9'

[[on-window-detected]]
if.app-name-regex-substring = '^mpv$'
run                         = 'move-node-to-workspace 10'
```

# Spacing

```toml
[gaps]
inner.horizontal = 6
inner.vertical   = 6
outer.bottom     = 6
outer.left       = 6
outer.right      = 6
outer.top        = 6
```
