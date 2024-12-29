# Mail

[Reference](https://github.com/neomutt/neomutt/tree/main/contrib/oauth2)

## Initial Authorization

set up

```bash
~/.local/opt/isync/oauth.sh --verbose --provider microsoft \
  --authorize \
  --client-id '<client_id>' \
  --email '<email>' \
  --authflow localhostauthcode \
  --
  '~/.local/state/isync/<email>.oauth.gpg'
```

verify

```bash
~/.local/opt/isync/oauth.sh --verbose --provider microsoft \
  --test \
  --
  '~/.local/state/isync/<email>.oauth.gpg'
```

## `mbsync`

```
AuthMechs XOAUTH2
PassCmd "~/.local/opt/isync/oauth.sh -- ~/.local/state/isync/<email>.oauth.gpg"
```
