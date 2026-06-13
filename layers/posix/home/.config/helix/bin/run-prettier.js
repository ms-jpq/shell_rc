#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { constants, existsSync } from "node:fs"
import { access } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, extname, join } from "node:path"
import { cwd, execPath, stdin, stdout } from "node:process"
import { pipeline } from "node:stream/promises"
import { parseArgs } from "node:util"

const {
  values: { filename, tabsize },
  positionals,
} = parseArgs({
  allowPositionals: true,
  options: {
    filename: { type: "string" },
    sort: { type: "boolean" },
    tabsize: { type: "string" },
  },
})
ok(filename)
ok(tabsize)

const node_modules = join(
  homedir(),
  ".cache",
  "helix-rt",
  "nodejs",
  "prettier",
  "node_modules",
)
const bin = join(node_modules, ".bin", "prettier")
const managed = await access(bin, constants.X_OK).then(
  () => true,
  () => false,
)

const _parents = function* (path = cwd()) {
  const parent = dirname(path)
  yield path
  if (parent !== path) {
    yield* _parents(parent)
  }
}

const plugins = {
  [join("@prettier", "plugin-xml", "src", "plugin.js")]: /^xml$/,
  [join("@typespec", "prettier-plugin-typespec", "dist", "index.js")]:
    /^typespec$/,
  [join("prettier-plugin-awk", "out", "index.js")]: /^awk$/,
  [join("prettier-plugin-nginx", "dist", "index.js")]: /^nginx$/,
  [join("prettier-plugin-tailwindcss", "dist", "index.mjs")]: /^(html|js|ts)$/,
  [join("prettier-plugin-organize-imports", "index.js")]: {
    [Symbol.match](str) {
      for (const path of _parents()) {
        const eslint = join(path, "node_modules", ".bin", "eslint")
        if (existsSync(eslint)) {
          return null
        }
      }
      return str.match(/^(js|ts)/)
    },
  },
}

const more_args = new Map([
  [/^json$/, ["--parser=jsonc", "--trailing-comma=none"]],
])

const argv = (function* () {
  const ext = extname(filename).substring(1)
  yield `--stdin-filepath=${filename}`
  yield `--tab-width=${tabsize}`
  yield `--log-level=warn`

  if (managed) {
    for (const [plugin, re] of Object.entries(plugins)) {
      if (ext.match(re)) {
        yield `--plugin=${join(node_modules, plugin)}`
      }
    }
  }

  for (const [re, args] of more_args) {
    if (ext.match(re)) {
      yield* args
    }
  }
})()

const [arg0, head] = managed ? [execPath, [bin]] : ["prettier", []]
const execArgs = [...head, ...argv, ...positionals]
const { error, status, signal } = spawnSync(arg0, execArgs, {
  stdio: "inherit",
})

if (error) {
  throw error
} else if (signal) {
  throw signal
} else {
  if ((process.exitCode = status ?? undefined) !== 0) {
    await pipeline(stdin, stdout)
  }
}
