#!/usr/bin/env -S -- jq --exit-status --from-file

. as $stdin
| $lmap[] as $mapping
| $stdin | .language
| [to_entries[] | select(.value.formatter) | .value as $v | ($mapping[.key] // [.key])[] | {key: ., value: $v}]
| map({key: .key, value: (.value.formatter | .args |= . // [])})
| from_entries
