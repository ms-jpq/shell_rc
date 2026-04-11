#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { spawn } from "node:child_process"
import { once } from "node:events"
import { parseArgs } from "node:util"

const {
  values: { tabsize },
} = parseArgs({
  options: {
    tabsize: { type: "string" },
  },
})
ok(tabsize)

const p1 = spawn("jq", ["--sort-keys", "."], {
  stdio: ["inherit", "pipe", "inherit"],
})

const p2 = spawn(
  "prettier",
  ["--filename=tsconfig.json", "--tabsize", tabsize],
  {
    stdio: [p1.stdout, "inherit", "inherit"],
  },
)

const [[code1], [code2]] = await Promise.all([
  once(p1, "exit"),
  once(p2, "close"),
])

process.exitCode = code1 + code2
