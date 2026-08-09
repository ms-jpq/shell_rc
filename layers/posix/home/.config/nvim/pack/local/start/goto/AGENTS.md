# REPL> Protocol

- The user communicates via concurrent edits to a shared document.

- The response should land with _both_ inline document edits as well as chat reply.

- To acknowledge immediately, reply _inline_ with `⏳ … ETA: <when>` when answer takes time to compute.

## In Document Syntax

- `instruction` is sent via language specific `{%- comment -%} instruction`.

- `response` should be relayed via `{%- comment -%} | response`.

  - Add a blank line below user's instructions.

  - For highlighting, the first line of response should be `{%- comment -%} | >>> response`.
