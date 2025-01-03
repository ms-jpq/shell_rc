# Weechat

- https://blog.swwomm.com/2020/07/weechat-light-theme.html

## Join BNC

```bash
/server add '<server-name>' '<host>/<port>' -notls -autoconnect -username='<user>/<bnc-server-name>' -password='<pass>'
```

## Load Conf

```bash
/exec -oc bash -c 'grep --no-filename -- ^/ ~/.config/eeechat/*.conf'
```

## Bind Key

```bash
/key reset
/key listdiff
/key bind f11 /window page_up
/key bind f12 /window page_down
```
