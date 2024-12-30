# Mail

## SASL XOAuth2

```bash
brew install --HEAD --formula -- ./formulae/cyrus-sasl-xoauth2.rb ./formulae/isync.rb
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
