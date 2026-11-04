#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { createRequire } from "node:module"
import { EOL, homedir } from "node:os"
import { join } from "node:path"
import { exit, stdin, stdout } from "node:process"
import { text } from "node:stream/consumers"
import { pipeline } from "node:stream/promises"
import { pathToFileURL } from "node:url"

/**
 * @import { Blockquote, Paragraph, Root, Nodes } from "mdast"
 * @import { Options } from "mdast-util-to-markdown"
 * @import { Plugin } from "unified"
 */

const require = createRequire(
  join(
    homedir(),
    ".cache",
    "helix-rt",
    "nodejs",
    "remark",
    "node_modules",
    "_.js",
  ),
)

/** @param {string} specifier */
const _import = (specifier) =>
  import(pathToFileURL(require.resolve(specifier)).href)

/**
 * @type {[
 *   { remark: typeof import("remark").remark },
 *   { default: typeof import("remark-frontmatter").default },
 *   { default: typeof import("remark-gfm").default },
 *   { visit: typeof import("unist-util-visit").visit },
 * ]}
 */
const [{ remark }, { default: frontmatter }, { default: gfm }, { visit }] =
  await (async () => {
    try {
      return await Promise.all([
        _import("remark"),
        _import("remark-frontmatter"),
        _import("remark-gfm"),
        _import("unist-util-visit"),
      ])
    } catch {
      await pipeline(stdin, stdout)
      exit(0)
    }
  })()

const SYN = {
  lineEnding: /\r\n|\n|\r/,
  trailingNewline: /\n$/,
  trailingNewlines: /\n+$/,
  space: /^[ \t]/,
  indent: /^ */,
  markdown: new Set(["markdown", "md"]),
  marker: ">>>",
  reply: "> |",
  quote: ">",
}
const PREFIXES = [
  {
    prefix: SYN.marker,
    spellings: [SYN.marker],
    parent: SYN.reply,
  },
  { prefix: SYN.reply, spellings: [SYN.reply, ">|", ">\t|"] },
  { prefix: SYN.quote, spellings: [SYN.quote] },
]
  .flatMap(({ spellings, ...rule }) =>
    spellings.map((spelling) => ({ ...rule, spelling })),
  )
  .sort((left, right) => right.spelling.length - left.spelling.length)

/**
 * @param {Paragraph} para
 * @returns {Paragraph[]}
 */
const splitParagraph = (para) => {
  /** @type {Paragraph["children"]} */
  let current = []
  /** @type {Paragraph["children"][]} */
  const groups = [current]
  for (const child of para.children) {
    const prev = current.at(-1)
    if (
      child.type === "strong" &&
      prev?.type === "text" &&
      SYN.trailingNewline.test(prev.value)
    ) {
      prev.value = prev.value.replace(SYN.trailingNewlines, "")
      if (!prev.value) {
        current.pop()
      }
      current = []
      groups.push(current)
    }
    current.push(child)
  }
  return groups.length === 1
    ? [para]
    : groups.map((children) => ({ type: "paragraph", children }))
}

/** @type {Plugin<[], Root>} */
const xformList = () => (tree) =>
  visit(tree, "list", (node) => {
    node.spread = true
    for (const item of node.children) {
      item.spread = true
    }
  })

/** @type {Plugin<[], Root>} */
const xformParagraph = () => (tree) => {
  visit(tree, "paragraph", (node, index, parent) => {
    if (parent === undefined || index === undefined) {
      return
    }
    const split = splitParagraph(node)
    if (split.length === 1) {
      return
    }
    parent.children.splice(index, 1, ...split)
    return index + split.length
  })
}

/** @param {Blockquote} node @returns {Set<number>} */
const literalLines = (node) => {
  const literal = new Set()
  visit(node, (child) => {
    if (
      child !== node &&
      ["blockquote", "paragraph", "heading"].includes(child.type)
    ) {
      return "skip"
    }
    if (!["code", "html", "table"].includes(child.type)) {
      return
    }
    ok(child.position)
    for (
      let line = child.position.start.line;
      line <= child.position.end.line;
      line++
    ) {
      literal.add(line)
    }
  })
  return literal
}

/**
 * @typedef {{ prefix: string, lines: string[] }} PrefixBlock
 * @param {Blockquote} node
 * @param {{ source: string, prefix: string }} options
 * @returns {PrefixBlock[]}
 */
const quoteBlocks = (node, { source, prefix }) => {
  ok(node.position)
  const { start, end } = node.position
  const literal = literalLines(node)
  const rules = PREFIXES.filter(
    (rule) => !rule.parent || rule.parent === prefix,
  )
  /** @type {PrefixBlock[]} */
  const blocks = []
  /** @type {PrefixBlock | undefined} */
  let current
  for (const [index, raw] of source
    .slice(start.offset, end.offset)
    .split(SYN.lineEnding)
    .entries()) {
    const line = index
      ? raw.replace(SYN.indent, (indent) => indent.slice(start.column - 1))
      : raw
    const rule = rules.find(
      (rule) =>
        (!literal.has(start.line + index) || rule.prefix === SYN.quote) &&
        line.startsWith(rule.spelling),
    )
    const content = rule
      ? line.slice(rule.spelling.length).replace(SYN.space, "")
      : line
    const endsMarker = current?.prefix === SYN.marker && !rule
    if (
      !current ||
      endsMarker ||
      (content.trim() && rule && rule.prefix !== current.prefix)
    ) {
      current = {
        prefix: rule?.prefix ?? (endsMarker ? "" : SYN.quote),
        lines: [],
      }
      blocks.push(current)
    }
    current.lines.push(content)
  }
  return blocks
}

/** @param {string} text @param {string} prefix @returns {string} */
const quote = (text, prefix) =>
  text
    .replace(SYN.trailingNewline, "")
    .split(SYN.lineEnding)
    .map((line) => (line && prefix ? prefix + " " + line : prefix || line))
    .join(EOL)

/** @param {Nodes} node @returns {boolean} */
const hasTable = (node) => {
  let found = false
  visit(node, (child) => {
    switch (child.type) {
      case "blockquote":
        return "skip"
      case "table":
        found = true
        return false
      default:
        return
    }
  })
  return found
}

/**
 * @param {{ processor: Pick<typeof remark, "compiler">, prefix: string }} options
 * @returns {void}
 */
const xformTable = ({ processor, prefix }) => {
  const compiler = processor.compiler
  ok(compiler)

  processor.compiler = (root, file) => {
    if (prefix !== SYN.reply) {
      const rendered = compiler(root, file)
      return prefix ? quote(rendered, prefix) + EOL : rendered
    }
    return (
      root.children
        .map((child) => ({
          child,
          prefix: hasTable(child) ? SYN.quote : SYN.reply,
        }))
        .map(({ child, prefix }, index, blocks) => {
          const body = quote(
            compiler({ type: "root", children: [child] }, file),
            prefix,
          )
          const separator =
            prefix === SYN.quote || blocks[index - 1]?.prefix === SYN.quote
              ? SYN.quote
              : SYN.reply
          return (index ? EOL + separator + EOL : "") + body
        })
        .join("") + EOL
    )
  }
}

/**
 * @param {string} input
 * @param {{ definitions?: string, prefix?: string }} options
 * @returns {string}
 */
const format = (input, { definitions = "", prefix = "" } = {}) => {
  const source = definitions ? input + EOL + EOL + definitions : input
  const processor = remark().use(frontmatter, ["yaml", "toml"]).use(gfm)

  /** @param {Root} tree @returns {string} */
  const declarations = (tree) => {
    /** @type {string[]} */
    const found = []
    visit(tree, "definition", (node) => {
      found.push(processor.stringify({ type: "root", children: [node] }))
    })
    return found.join(EOL)
  }

  /** @type {Options} */
  const options = {
    handlers: {
      blockquote(node) {
        const blocks = quoteBlocks(node, { source, prefix })
        const local = declarations(
          processor.parse(
            blocks.map(({ lines }) => lines.join(EOL)).join(EOL + EOL),
          ),
        )
        return blocks
          .map(({ prefix, lines }) =>
            format(lines.join(EOL), {
              definitions: [local, combinedDefinitions].join(EOL),
              prefix,
            }).replace(SYN.trailingNewline, ""),
          )
          .join(
            node.children.some(hasTable) ? EOL + SYN.quote + EOL : EOL + EOL,
          )
      },
    },
  }
  /** @type {Plugin<[], Root>} */
  const xformContent = () => (tree) => {
    tree.children = tree.children.filter(
      (node) => (node.position?.start.offset ?? input.length) < input.length,
    )
    visit(tree, "code", (node) => {
      if (SYN.markdown.has(node.lang ?? "")) {
        node.value = format(node.value).replace(SYN.trailingNewline, "")
      }
    })
  }

  const configured = processor
    .use(xformContent)
    .use(xformList)
    .use(xformParagraph)

  const tree = configured.runSync(configured.parse(source))
  const combinedDefinitions = [declarations(tree), definitions].join(EOL)
  const renderer = configured()
  return renderer
    .use(xformTable, { processor: renderer, prefix })
    .data("settings", options)
    .stringify(tree)
}

stdout.write(
  format(await text(stdin))
    .split(SYN.lineEnding)
    .join(EOL),
)
