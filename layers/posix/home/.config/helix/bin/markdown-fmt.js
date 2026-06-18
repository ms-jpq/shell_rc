#!/usr/bin/env -S -- node
"use strict"

import { ok } from "node:assert/strict"
import { spawn } from "node:child_process"
import { once } from "node:events"
import { parseArgs } from "node:util"

const {
  values: { filename, tabsize },
} = parseArgs({
  options: {
    filename: { type: "string" },
    tabsize: { type: "string" },
  },
})
ok(filename)
ok(tabsize)

const p1 = spawn("remark", [], {
  stdio: ["inherit", "pipe", "inherit"],
})

const p2 = spawn(
  "run-prettier",
  ["--filename", filename, "--tabsize", tabsize],
  {
    stdio: [p1.stdout, "inherit", "inherit"],
  },
)

const [[code1], [code2]] = await Promise.all([
  once(p1, "exit"),
  once(p2, "close"),
])

process.exitCode = code1 + code2
