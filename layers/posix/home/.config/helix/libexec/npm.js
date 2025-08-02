#!/usr/bin/env -S -- node

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { mkdirSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join, sep } from "node:path"
import { argv } from "node:process"

const [, , pkg, ...pkgs] = argv
ok(pkg)

const home = join(
  homedir(),
  ".cache",
  "helix-rt",
  "nodejs",
  pkg.replaceAll(sep, "-"),
)
const json = {
  dependencies: Object.fromEntries([pkg, ...pkgs].map((p) => [p, "*"])),
}

mkdirSync(home, { recursive: true })
writeFileSync(join(home, "package.json"), JSON.stringify(json))

const { error, status, signal } = spawnSync(
  "npm",
  ["install", "--no-package-lock", "--prefix", home],
  { stdio: "inherit" },
)

if (error) {
  throw error
} else if (signal) {
  throw signal
} else {
  process.exitCode = status ?? undefined
}
