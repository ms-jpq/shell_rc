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
diff --git i/src/config.ts w/src/config.ts
index d264359..eb7fa13 100644
--- i/src/config.ts
+++ w/src/config.ts
@@ -128,7 +128,7 @@ if (

 export default {
   ...values,
-  triggerCharacters: (values.triggerCharacters as string).split("||"),
+  triggerCharacters: [" ", ".", "'", '"', "`", "(", "{", "<", "&", "|", ":", "!", "-", ">", "$", "/", "\\"],
   debounce: parseInt(values.debounce as string),
   fetchTimeout: parseInt(values.fetchTimeout as string),
   actionTimeout: parseInt(values.actionTimeout as string),
diff --git i/src/constants.ts w/src/constants.ts
index ed82fd9..409ae5e 100644
--- i/src/constants.ts
+++ w/src/constants.ts
@@ -20,29 +20,4 @@ export const examples = [
 ]

 export const commands = [
-  {
-    key: "resolveDiagnostics",
-    label: "Resolve diagnostics",
-    query: "Resolve the diagnostics for this code."
-  },
-  {
-    key: "generateDocs",
-    label: "Generate documentation",
-    query: "Add documentation to this code."
-  },
-  {
-    key: "improveCode",
-    label: "Improve code",
-    query: "Improve this code."
-  },
-  {
-    key: "refactorFromComment",
-    label: "Refactor code from a comment",
-    query: "Refactor this code based on the comment."
-  },
-  {
-    key: "writeTest",
-    label: "Write a unit test",
-    query: "Write a unit test for this code. Do not include any imports.",
-  }
 ]
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
install -v -b -- "$LIB/dist" "$BIN"
