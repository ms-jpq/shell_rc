def identfix: if .unit == "\t" then (."tab-width" |= 2) elif .unit == "    " then {unit: "  ", "tab-width": 2} else . end;

. as $presets
  | $user[0] as $usr
  | $usr["$"] as $common
  | $usr.language | with_entries(.value."language-servers" |= $common) | . as $user_langs
  | $presets.language | map({ (.name): (."language-servers" |= $common | pick(."language-servers")) }) | add as $pre_langs
  | [$presets.language[] | select(.indent)] | map({ (.name): (.indent |= identfix | pick(.indent)) }) | add as $pre_indent
  | $pre_indent * $pre_langs * $user_langs | to_entries | map({name: .key} * .value) as $langs
  | {language: $langs, "language-server": $usr."language-server"}

