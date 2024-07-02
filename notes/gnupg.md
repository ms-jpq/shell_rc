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
# Generate primary public + private keys
# <fingerprint> here means ID
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

## Scripting

```bash
# List public keys: `getline` skips current line
gpg --with-colons --list-keys | awk -F: '/^pub:/ { getline; print $10 }'
```

## SSH

### Public Key

```bash
# The without `!`, WILL USE PRIMARY KEY
gpg --export-ssh-key -- '<subkey>'!
```

### Agent

Must use `[S]` signing subkey's keygrip

```bash
# Add '<subkey>' keygrip
"$EDITOR" "$GNUPGHOME/sshcontrol"
```

## Forward

```bash
gpg --export --armor -- '<public-key>' | ssh '<host>' gpg --import
```

SSH: `./layers/posix/home/.config/ssh/9-include.conf`

## GIT

```bash
# The without `!`, WILL USE PRIMARY KEY
git config --global -- user.signingkey '<subkey>'!
```

## Send / Recv

```bash
# All keys
gpg --armor --export-secret-keys --export-options export-backup -- '<fingerprint>' | gpg -v --import
# Public key only
gpg --armor --export
# Excluding primary key
gpg --armor --export-secret-subkeys -- '<fingerprint>'!
```
