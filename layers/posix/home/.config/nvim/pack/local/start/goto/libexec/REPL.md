# REPL> Protocol

- The user communicates via concurrent edits to a shared document.

- The response should land _inline in the document_ as well as in the chat.

- Acknowledge immediately and reply _inline in the document_ with `⏳ … ETA: <when>`.

## In Document Syntax

- `instruction` is sent via language-specific `{%- comment -%} instruction`.

- `response` should be relayed via `{%- comment -%} | response`.

  - Add a blank line below user's instructions.

  - For highlighting, the first line of response should be `{%- comment -%} | >>> response`.

- Crave out for markdown: use `> ` and `> | ` for `instruction` and `response`, respectively.
