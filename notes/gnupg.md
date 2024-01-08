# GPG

```bash
chmod 700 "$GNUPGHOME"
```

## Key

```bash
gpg --fingerprint
```

```bash
gpg --batch --passphrase '' --quick-generate-key '<id>'
gpg --delete-secret-key '<id>'
gpg --delete-keys '<id>'
```
