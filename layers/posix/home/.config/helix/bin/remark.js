#!/usr/bin/env -S -- node
"use strict"

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
const PREFIX_SPACE = /^[ \t]/
const QUOTE_PREFIX = /^(?:[ \t]*>[ \t]?)+/

/**
 * @param {Paragraph} para
 * @returns {Paragraph[]}
 */
const splitParagraph = (para) => {
  /** @type {Paragraph["children"][]} */
  const groups = [[]]

  for (const [i, child] of para.children.entries()) {
    const prev = para.children[i - 1]
    if (i > 0 && child.type === "strong" && /\n$/.test(prev?.value ?? "")) {
      const tail = groups.at(-1).at(-1)
      tail.value = tail.value.replace(/\n+$/, "")
      if (!tail.value) {
        groups.at(-1)?.pop()
      }
      groups.push([])
    }
    groups.at(-1)?.push(child)
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

/**
 * @param {Blockquote} node
 * @param {{ source: string, response: boolean }} options
 * @returns {{ prefix: string, source: string }}
 */
const quoteContent = (node, { source, response }) => {
  const raw = source.slice(node.position.start.offset, node.position.end.offset)
  const lines = raw.split(LINE_ENDING)
  if (response && raw.startsWith(">>>")) {
    return { prefix: ">>>", source: raw }
  }

  const [first] = node.children
  const leading = first?.type === "paragraph" ? first.children.at(0) : undefined
  if (leading?.type === "text" && leading.value.startsWith("|")) {
    const contents = lines.map((line) => line.replace(QUOTE_PREFIX, ""))
    if (contents.every((line) => !line || line.startsWith("|"))) {
      return {
        prefix: "> |",
        source: contents.map((line) => `> ${line || "|"}`).join("\n"),
      }
    }
  }
  return { prefix: ">", source: raw }
}

/**
 * @param {string} source
 * @param {{ prefix: string, format: (markdown: string) => string }} options
 * @returns {string}
 */
const formatPrefixed = (source, { prefix, format }) => {
  const markdown = source
    .split(LINE_ENDING)
    .map((line) =>
      prefix && line.startsWith(prefix)
        ? line.slice(prefix.length).replace(PREFIX_SPACE, "")
        : line,
    )
    .join("\n")
  return format(markdown)
    .replace(/\n$/, "")
    .split(LINE_ENDING)
    .map((line) => prefix + (prefix && line ? " " : "") + line)
    .join("\n")
}

/** @type {Plugin<[(markdown: string) => string], Root>} */
const xformMarkdown = (format) => (tree) =>
  visit(tree, "code", (node) => {
    if (node.lang === "markdown") {
      node.value = format(node.value).replace(/\n$/, "")
    }
  })

/**
 * @param {string} source
 * @param {{ response?: boolean }} options
 * @returns {string}
 */
const format = (source, { response = false } = {}) => {
  /** @type {Options} */
  const options = {
    handlers: {
      blockquote(node, _, state, info) {
        const { prefix, source: content } = quoteContent(node, {
          source,
          response,
        })
        const leave = state.enter("blockquote")
        const tracker = state.createTracker(info)
        tracker.move(`${prefix} `)
        tracker.shift(prefix.length + 1)
        const quoted = formatPrefixed(content, {
          prefix,
          format: (markdown) =>
            prefix === ">"
              ? state.containerFlow(node, tracker.current())
              : format(markdown, { response: prefix === "> |" }),
        })
        leave()
        return quoted
      },
    },
  }
  return remark()
    .use(frontmatter, ["yaml", "toml"])
    .use(xformList)
    .use(xformParagraph)
    .use(xformMarkdown, format)
    .data("settings", options)
    .processSync(source)
    .toString()
}

stdout.write(format(await text(stdin)))
