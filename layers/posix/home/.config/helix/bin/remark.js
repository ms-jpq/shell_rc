#!/usr/bin/env -S -- node
"use strict"

import { createRequire } from "node:module"
import { homedir } from "node:os"
import { join } from "node:path"
import { stdin, stdout } from "node:process"
import { text } from "node:stream/consumers"
import { pipeline } from "node:stream/promises"
import { pathToFileURL } from "node:url"

/**
 * @import { Root, Paragraph } from "mdast"
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
 *   { remark?: typeof import("remark").remark },
 *   { default?: typeof import("remark-frontmatter").default },
 *   { visit?: typeof import("unist-util-visit").visit },
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
    return [{}, {}, {}]
  }
})()

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
      const tail = groups.at(-1)?.at(-1)
      tail.value = tail.value.replace(/\n+$/, "")
      if (!tail.value) {
        groups.at(-1).pop()
      }
      groups.push([])
    }
    groups.at(-1).push(child)
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
    if (parent === undefined || index === undefined) return
    const split = splitParagraph(node)
    if (split.length === 1) {
      return
    }
    parent.children.splice(index, 1, ...split)
    return index + split.length
  })
}

if (!remark || !frontmatter || !visit) {
  await pipeline(stdin, stdout)
} else {
  const src = await text(stdin)

  const out = await remark()
    .use(frontmatter, ["yaml", "toml"])
    .use(xformList)
    .use(xformParagraph)
    .data("settings", { bullet: "-", listItemIndent: "one" })
    .process(src)

  stdout.write(out.toString())
}
