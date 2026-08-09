#!/usr/bin/env -S -- node

import { ok } from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { mkdirSync, writeFileSync } from "node:fs"
import { homedir, tmpdir } from "node:os"
import { join, sep } from "node:path"
import { platform } from "node:process"
import { parseArgs } from "node:util"

const {
  values: { ignoreScripts },
  positionals,
} = parseArgs({
  allowNegative: true,
  allowPositionals: true,
  options: {
    ignoreScripts: { type: "boolean", default: true },
  },
})

const [pkg, ...pkgs] = positionals.map((a) => a.trim())

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
  "npm" + (platform === "win32" ? ".cmd" : ""),
  [
    "install",
    `--ignore-scripts=${ignoreScripts}`,
    "--no-package-lock",
    "--no-update-notifier",
    "--no-fund",
    "--cache",
    join(tmpdir(), "npm"),
    "--no-progress",
    "--prefix",
    home,
  ],
  { shell: platform === "win32", stdio: "inherit" },
)

if (error) {
  console.warn(error)
} else if (signal) {
  throw signal
} else {
  process.exitCode = status ?? undefined
}
