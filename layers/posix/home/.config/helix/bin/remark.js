#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { createRequire } from "node:module"
import { homedir } from "node:os"
import { join } from "node:path"
import { exit, stdin, stdout } from "node:process"
import { text } from "node:stream/consumers"
import { pipeline } from "node:stream/promises"
import { pathToFileURL } from "node:url"

/**
 * @import { Blockquote, Paragraph, Root } from "mdast"
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
 *   { visit: typeof import("unist-util-visit").visit },
 * ]}
 */
const [{ remark }, { default: frontmatter }, { visit }] = await (async () => {
  try {
    return await Promise.all([
      _import("remark"),
      _import("remark-frontmatter"),
      _import("unist-util-visit"),
    ])
  } catch {
    await pipeline(stdin, stdout)
    exit(0)
  }
})()

const LINE_ENDING = /\r\n|\n|\r/
const TRAILING_NEWLINE = /\n$/
const TRAILING_NEWLINES = /\n+$/
const SPACE = /^[ \t]/
const INDENT = /^ */
const MARKDOWN = new Set(["markdown", "md"])
const PREFIXES = [
  { prefix: ">>>", spellings: [">>>"], context: "reply", next: "quote" },
  { prefix: "> |", spellings: ["> |", ">|", ">\t|"], next: "reply" },
  { prefix: ">", spellings: [">"], next: "quote" },
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
      TRAILING_NEWLINE.test(prev.value)
    ) {
      prev.value = prev.value.replace(TRAILING_NEWLINES, "")
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
    if (child.type !== "code" && child.type !== "html") {
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
 * @typedef {{ prefix: string, next: string, lines: string[] }} PrefixBlock
 * @param {Blockquote} node
 * @param {{ source: string, context: string }} options
 * @returns {PrefixBlock[]}
 */
const quoteBlocks = (node, { source, context }) => {
  ok(node.position)
  const { start, end } = node.position
  const literal = literalLines(node)
  const rules = PREFIXES.filter(
    (rule) => !rule.context || rule.context === context,
  )
  /** @type {PrefixBlock[]} */
  const blocks = []
  /** @type {PrefixBlock | undefined} */
  let current
  for (const [index, raw] of source
    .slice(start.offset, end.offset)
    .split(LINE_ENDING)
    .entries()) {
    const line = index
      ? raw.replace(INDENT, (indent) => indent.slice(start.column - 1))
      : raw
    const rule = rules.find(
      (rule) =>
        (!literal.has(start.line + index) || rule.prefix === ">") &&
        line.startsWith(rule.spelling),
    )
    const content = rule
      ? line.slice(rule.spelling.length).replace(SPACE, "")
      : line
    if (
      !current ||
      (content.trim() && rule && rule.prefix !== current.prefix)
    ) {
      current = {
        prefix: rule?.prefix ?? ">",
        next: rule?.next ?? "quote",
        lines: [],
      }
      blocks.push(current)
    }
    current.lines.push(content)
  }
  return blocks
}

/**
 * @param {string} input
 * @param {{ context?: string, definitions?: string }} options
 * @returns {string}
 */
const format = (input, { context = "quote", definitions = "" } = {}) => {
  const source = definitions ? input + "\n\n" + definitions : input
  const processor = remark().use(frontmatter, ["yaml", "toml"])

  /** @type {Options} */
  const options = {
    handlers: {
      blockquote(node) {
        return quoteBlocks(node, { source, context })
          .map(({ prefix, next, lines }) =>
            format(lines.join("\n"), { context: next, definitions })
              .replace(TRAILING_NEWLINE, "")
              .split(LINE_ENDING)
              .map((line) => (line ? prefix + " " + line : prefix))
              .join("\n"),
          )
          .join("\n\n")
      },
    },
  }
  /** @type {Plugin<[], Root>} */
  const xformContent = () => (tree) => {
    tree.children = tree.children.filter(
      (node) => (node.position?.start.offset ?? input.length) < input.length,
    )
    /** @type {string[]} */
    const local = []
    visit(tree, "definition", (node) => {
      local.push(processor.stringify({ type: "root", children: [node] }))
    })
    definitions = [...local, definitions].join("\n")
    visit(tree, "code", (node) => {
      if (MARKDOWN.has(node.lang ?? "")) {
        node.value = format(node.value).replace(TRAILING_NEWLINE, "")
      }
    })
  }
  return processor
    .use(xformContent)
    .use(xformList)
    .use(xformParagraph)
    .data("settings", options)
    .processSync(source)
    .toString()
}

stdout.write(format(await text(stdin)))
