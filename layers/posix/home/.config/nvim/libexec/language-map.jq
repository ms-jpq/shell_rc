#!/usr/bin/env -S -- jq --exit-status --from-file

. as $stdin
| $lmap[] as $mapping
| $stdin | .language | [to_entries[] | select(.value.formatter)]
| map({key: ($mapping[.key] // .key), value: (.value.formatter | .args |= . // [])})
| from_entries
