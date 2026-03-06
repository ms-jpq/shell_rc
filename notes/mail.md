# Mail

## SASL XOAuth2

```bash
HOMEBREW_DEVELOPER=1 brew install --HEAD --formula -- ./formulae/cyrus-sasl-xoauth2.rb ./formulae/mblaze.rb
```

```bash
HOMEBREW_DEVELOPER=1 brew reinstall --formula -- ./formulae/cyrus-sasl-xoauth2.rb ./formulae/mblaze.rb
```

## Daemonize

After maildirs have been provisioned

```bash
~/.local/opt/isync/daemonize.sh
```

## Oauth2

[Reference](https://github.com/neomutt/neomutt/tree/main/contrib/oauth2)

### Conf

```
AuthMechs XOAUTH2
PassCmd "~/.local/opt/isync/oauth.sh -- ~/.local/state/isync/<email>.oauth.gpg"
```

### New token

```bash
~/.local/opt/isync/oauth.sh --verbose --provider microsoft \
  --authorize \
  --client-id '<client_id>' \
  --email '<email>' \
  --authflow localhostauthcode \
  --
  '~/.local/state/isync/<email>.oauth.gpg'
```

### Verify token

```bash
~/.local/opt/isync/oauth.sh --verbose --provider microsoft \
  --test \
  --
  '~/.local/state/isync/<email>.oauth.gpg'
```
