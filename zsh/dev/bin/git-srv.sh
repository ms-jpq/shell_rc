#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

GIT_EXEC_PATH="$(git --exec-path)"
GIT_DIR="$(git --no-optional-locks rev-parse --path-format=absolute --git-common-dir)"
WEB_DIR="$GIT_DIR/gitweb"
GITWEB_CONFIG="$WEB_DIR/gitweb_config.perl"
TMP="$WEB_DIR/tmp"
CGI_BIN="$WEB_DIR/cgi-bin"
INFO="$(git --info-path)"
WEB="${INFO%/*}/gitweb"
ROOT="$(git --no-optional-locks rev-parse --path-format=absolute --show-toplevel)"
NAME="${ROOT##*/}"

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    ln -sf -- "$src" "$dst"
  fi
}

rm -fr -- "$WEB_DIR"
mkdir -p -- "$CGI_BIN" "$TMP"
link "$WEB/static" "$CGI_BIN/static"
link "$WEB/gitweb.cgi" "$CGI_BIN/gitweb.cgi"

read -r -d '' -- PERL <<-EOF || true
our \$projectroot = "$ROOT";
our \$git_temp = "$TMP";
our \$projects_list = \$projectroot;

# ADDN
our \$prevent_xss = !0;
our \$omit_owner = !0;
our \$omit_age_column = !0;
our \$fallback_encoding = "utf-16";
our \$site_name = "$NAME";

\$feature{'remote_heads'}{'default'} = [1];
EOF

printf -- '%s\n' "$PERL" >"$GITWEB_CONFIG"

SRV="$(realpath -- "${0%/*}/../libexec/git-instaweb.py")"
export -- GIT_EXEC_PATH GIT_DIR GITWEB_CONFIG
cd -- "$WEB_DIR"
exec -- "$SRV"
