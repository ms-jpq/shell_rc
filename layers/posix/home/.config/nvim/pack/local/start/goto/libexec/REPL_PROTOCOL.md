# REPL> Protocol

- The user communicates via concurrent edits to a shared document.

- Reply to every queued `REPL` instruction individually, _inline in the document_ at its location and in the chat.

  - A newer instruction does not replace an unanswered one.

## In Document Syntax

- `comment(text)` means text written in the document's native comment form.

- An `instruction` is `comment(instruction)`.

- By default, write response lines as `comment(| response)`.

  - Separate the instruction and response with a blank line.

  - Start the response with `comment(| >>> response)`.

- In Markdown, `comment(text)` is `> text`.

## Special Directives

- `> !<name>` selects the named directive for the following instruction.

- Apply the directive only to that instruction's response.

- Ask the user for clarification if the directive is unknown or its meaning is unclear.

### `!md`

- Keep the first response line as `> | >>> response`.

- Separate that line from the body with a blank line.

- Write the body as ordinary Markdown without adding response prefixes to text, blank lines, or code fences.

## Examples

```markdown
> add a Markdown example

> | >>> Here is the example.
> |
> | The response is inline and uses the response quote prefix.
```

---

````markdown
> !md
> show a directory tree

> | >>> Here is the directory tree.

```text
dogs/
├── lil/
└── wang/
```
````
