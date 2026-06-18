#!/usr/bin/env -S -- node
"use strict"

import { createRequire } from "node:module"
import { homedir } from "node:os"
import { join } from "node:path"
import { stdin, stdout } from "node:process"
import { text } from "node:stream/consumers"
import { pathToFileURL } from "node:url"

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

const _import = async (specifier) => {
  try {
    return await import(pathToFileURL(require.resolve(specifier)).href)
  } catch {
    return import(specifier)
  }
}

const src = await text(stdin)

const [{ remark }, { visit }] = await Promise.all([
  _import("remark"),
  _import("unist-util-visit"),
])

const looseLists = () => (tree) =>
  visit(tree, "list", (node) => {
    node.spread = true
    for (const item of node.children) {
      item.spread = true
    }
  })

const out = await remark()
  .use(looseLists)
  .data("settings", { bullet: "-", listItemIndent: "one" })
  .process(src)

stdout.write(String(out))
