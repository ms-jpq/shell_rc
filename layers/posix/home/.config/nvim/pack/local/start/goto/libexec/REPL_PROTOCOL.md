# REPL> Protocol

- The user communicates via concurrent edits to a shared document.

- The response should land _inline in the document_ as well as in the chat.

## In Document Syntax

- `comment(text)` means text written in the document's native comment form.

- An `instruction` is `comment(instruction)`.

- A `response` is `comment(| response)`.

  - Add a blank line below user's instructions.

  - Its highlighted first line is `comment(| >>> response)`.

- In Markdown, `comment(text)` is `> text`.

## Example

```markdown
> add a Markdown example

> | >>> ⏳ Adding the example. ETA: now.
> |
> | The response is inline and uses the response quote prefix.
```
