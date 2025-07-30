#!/usr/bin/env -S -- node

import { ok } from "node:assert/strict"
import { spawn } from "node:child_process"
import { parseArgs } from "node:util"
import { once } from 'node:events';

const {
  values: { tabsize },
} = parseArgs({
  options: {
    tabsize: { type: "string" },
  },
})
ok(tabsize)

const p1 = spawn("sortd", ["json"], { stdio: ["inherit", "pipe", "inherit"] })

const p2 = spawn("prettier.js", ["--filetype=json", "--tabsize", tabsize], { stdio: [p1.stdout, "inherit", "inherit"] })

await Promise.all([once(p1, "exit"), once(p2, "close")])
