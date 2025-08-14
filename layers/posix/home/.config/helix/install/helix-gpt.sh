#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

URI='https://github.com/leona/helix-gpt/archive/refs/heads/master.tar.gz'

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
rm -fr -- "$LIB"
mv -v -f -- "$RUN/"* "$LIB"

if ! hash -- bun npm > /dev/null; then
  set -x
  exit
fi

read -r -d '' -- PATCH <<- 'PATCH' || true
diff --git i/src/events/completions.ts w/src/events/completions.ts
index ffe96b7..b6469dc 100644
--- i/src/events/completions.ts
+++ w/src/events/completions.ts
@@ -79,20 +79,6 @@ export const completions = (lsp: Service) => {
       );
     log("calling completion event");

-    ctx.sendDiagnostics(
-      [
-        {
-          message: "Fetching completion...",
-          severity: DiagnosticSeverity.Information,
-          range: {
-            start: { line: request.params.position.line, character: 0 },
-            end: { line: request.params.position.line + 1, character: 0 },
-          },
-        },
-      ],
-      config.completionTimeout,
-    );
-
     try {
       var hints = await assistant.completion(
         { contentBefore, contentAfter },
PATCH

pushd -- "$LIB" > /dev/null
git apply --ignore-space-change --ignore-whitespace --whitespace=nowarn <<< "$PATCH"
npm run -- build:bin
popd > /dev/null

# shellcheck disable=SC2154
rm -fr -- "$BIN"
# shellcheck disable=SC2154
mv -vf -- "$LIB/dist" "$BIN"
