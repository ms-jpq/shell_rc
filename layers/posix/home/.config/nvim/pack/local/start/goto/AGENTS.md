# REPL> Protocol

- The user communicates via concurrent edits to a shared document.

- The response should land back as inline edits as well.

- To acknowledge immediately, reply inline with `⏳ …` when answer takes time to compute.

## Syntax

- `instruction` is sent via language specific `{%- comment -%} instruction`.

- `response` should be relayed via `{%- comment -%} | response`.

  - Add a blank line below user's instructions.

  - For highlighting, the first line of response should be `{%- comment -%} | >>> response`.
