# GPG

- `[C]` Certifying: A key certificate is an assertion that a certain key belongs to a certain entity

- `[E]` Encrypting:

- `[S]` Signing:

- `[A]` Authenticating:

## Primary Key

Never use primary keys for anything except for **certifying** `1:N` subkeys

```bash
gpg --fingerprint
```

```bash
# Generate public + private keys
gpg --batch --passphrase '' --quick-generate-key '<fingerprint>' 'default' 'cert' 'never'
```

```bash
gpg --delete-secret-key '<fingerprint>'
gpg --delete-keys '<fingerprint>'
```

## Subkeys

Single purpose keys, ie. one per device / service acc

```bash
gpg --quick-add-key '<id>'
```
