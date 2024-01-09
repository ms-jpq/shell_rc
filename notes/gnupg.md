# GPG

- `[C]` Certifying: A key certificate is an assertion that a certain key belongs to a certain entity

- `[E]` Encrypting:

- `[S]` Signing:

- `[A]` Authenticating:

## Links

- https://www.gnupg.org/faq/gnupg-faq.html

- https://www.reddit.com/r/GnuPG/comments/vjas2e/proper_key_management/

## Primary Key

Never use primary keys for anything except for **certifying** `1:N` subkeys

```bash
gpg --list-keys --with-subkey-fingerprints --with-keygrip
```

```bash
# Generate public + private keys
gpg --batch --passphrase '' --quick-generate-key -- '<fingerprint>' 'default' 'cert' 'never'
```

```bash
gpg --delete-secret-and-public-key '<fingerprint>'
```

## Subkeys

Single purpose keys, ie. one per device / service account

```bash
gpg --batch --passphrase '' --quick-add-key -- '<public-key>' 'default' 'sign,auth,encr'

# ed25519 -> `sign,auth`
# cv25519 -> `encr`
```

```bash
# The without `!`, WILL DELETE PRIMARY KEY TOO
gpg --delete-secret-and-public-key -- '<subkey>'!
```

## SSH

### Public Key

```bash
# The without `!`, WILL USE PRIMARY KEY
gpg --export-ssh-key -- '<subkey>'!
```

### Agent

```bash
# Add '<subkey>' keygrip
"$EDITOR" "$GNUPGHOME/sshcontrol"
```

## Send / Recv

```bash
# All keys
gpg --armor --export-secret-keys -- '<id>' | gpg --import
# Excluding primary key
gpg --armor --export-secret-subkeys -- '<id>'!
# Excluding private (sub*)keys
gpg --armor --export -- '<subkey>'!
```